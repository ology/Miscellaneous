package Food::Recipe;

use Dancer qw( :syntax );
use Dancer::Cookies;
use File::Find::Rule;
use List::Util qw( all );
use Math::Fraction;
use MealMaster;
use Storable;

our $VERSION = '0.4';

any '/' => sub {
    # Load the form variables
    my $title      = params->{title};
    my $category   = params->{category};
    my $ingredient = params->{ingredient};

    # Turn multi-word strings into lists
    $title      = [ split /\s+/, $title ] if $title;
    $category   = [ split /\s+/, $category ] if $category;
    $ingredient = [ split /\s+/, $ingredient ] if $ingredient;

    # Load the recipes
    my @recipes = import_mm(); 

    my @matched;

    my $i = 0;

    # Filter the recipes
    RECIPE: for my $recipe ( @recipes ) {
        # Title support
        if ( $title && @$title ) {
            if ( not all { $recipe->title =~ /\Q$_\E/i } @$title ) {
                next RECIPE;
            }
        }

        # Category support
        if ( $category && @$category ) {
            for my $c ( @$category ) {
                next RECIPE unless grep { $_ =~ /\Q$c\E/i } @{ $recipe->categories };
            }
        }

        # Ingredient support
        if ( $ingredient && @$ingredient ) {
            for my $i ( @$ingredient ) {
                next RECIPE unless grep { $_->product =~ /\Q$i\E/i } @{ $recipe->ingredients };
            }
        }

        # If we have made it this far, populate our matches
        push @matched, {
            title       => $recipe->title,
            categories  => join( ', ', sort @{ $recipe->categories } ),
            yield       => $recipe->yield,
            ingredients => join( ', ', map { $_->product } @{ $recipe->ingredients } ),
        };
    }

    template 'index' => {
        title      => $title,
        category   => $category,
        ingredient => $ingredient,
        matched    => \@matched,
        total      => scalar(@recipes),
    };
};

get '/categories' => sub {
    # Load the recipes
    my @recipes = import_mm(); 

    my %categories;

    # Extract and normalize the categories
    for my $recipe ( @recipes ) {
        for my $cat ( @{ $recipe->categories } ) {
            $cat =~ s/^\s+//;
            $cat =~ s/\s+$//;
            $cat = ucfirst lc $cat;
            $categories{$cat}++;
        }
    }

    template 'categories' => {
        categories => \%categories,
    };
};

any '/recipe' => sub {
    # Load the form variables
    my $title = params->{title} or die 'No title provided';
    my $yield = params->{yield};

    my $ingredients;

    # Load the recipes
    my @recipes = import_mm(); 

    my @match = grep { $_->title eq $title } @recipes;

    # Convert the number of servings
    if ( $yield ) {
        my ($number) = split( / /, $match[0]->yield );
        my $factor = $yield / $number;

        for my $i ( @{ $match[0]->ingredients } ) {
            # Make sure the quantity is an arithmetic expression
            my $quantity = $i->quantity;
            if ( $quantity ) {
                $quantity =~ s/ /+/;
                $quantity = eval $quantity;
                $quantity *= $factor;

                # Handle a quantity with a fractional part
                if ( $quantity =~ /\./ ) {
                    my @parts   = split( /\./, $quantity );
                    my $integer = $parts[0] eq '0' ? '' : "$parts[0] ";
                    my $decimal = "0.$parts[1]";

                    # Handle the broken behavior of Math::Fraction
                    $quantity = sprintf '%.2f', $quantity if length($decimal) > 8;

                    # Handle the broken behavior of Math::Fraction
                    $decimal = sprintf '%.2f', $decimal if length($decimal) > 8;
                    $decimal = eval { frac($decimal) };
                    die "Can't frac($decimal): $@" if $@;

                    $quantity = $quantity . " ($integer$decimal)";
                }
            }

            # Keep a list of converted ingredients to display
            push @$ingredients, {
                quantity => $quantity,
                measure  => $i->measure,
                product  => $i->product,
            };
        }
    }

    # Save the recipe to display, if there is a match
    my $recipe;
    $recipe = {
        title       => $match[0]->title,
        categories  => $match[0]->categories,
        yield       => $match[0]->yield,
        ingredients => $match[0]->ingredients,
        directions  => $match[0]->directions,
    } if @match;

    # Change the shopping list cookie to an array reference to display
    my $list = cookie('list');
    $list = [ split /\s*\|\s*/, $list ]
        if $list;

    template 'recipe' => {
        recipe      => $recipe,
        yield       => $yield,
        ingredients => $ingredients,
        list        => $list,
    };
};

post '/add' => sub {
    # Load the form variables
    my $title = params->{title} or die 'No title provided';

    # Add the item to the shopping list
    my $list = cookie('list');
    my %list;
    if ( $list || $title ) {
        @list{ split /\s*\|\s*/, $list } = undef;
        $list{$title} = undef;
        cookie( list => join( '|', keys %list ) );
    }

    redirect '/recipe?title=' . $title;
    halt;
};

post '/clear' => sub {
    # Load the form variables
    my $title = params->{title} or die 'No title provided';

    # Clear the shopping list
    cookie( list => '' );

    redirect '/recipe?title=' . $title;
    halt;
};

post '/remove' => sub {
    # Load the form variables
    my $title = params->{title} or die 'No title provided';

    # Remove the given item from the shopping list
    my $list = cookie('list');
    my %list;
    if ( $title ) {
        @list{ split /\s*\|\s*/, $list } = undef;
        delete $list{$title};
        cookie( list => join( '|', keys %list ) );
    }

    redirect '/list';
    halt;
};

get '/list'  => sub {
    # Unit conversion dispatch table
    my $units = {
        c  => sub { return ( $_[0] * 8, 'oz' ) },           # cup
        cn => sub { return ( $_[0] * 12, 'oz' ) },          # can
        dr => sub { return ( $_[0] * 0.0016907, 'oz' ) },   # drop
        ds => sub { return ( $_[0] * 0.03125, 'oz' ) },     # dash
        pn => sub { return ( $_[0] * 0.013, 'oz' ) },       # pinch
        pt => sub { return ( $_[0] * 16, 'oz' ) },          # pint
        tb => sub { return ( $_[0] * 0.5, 'oz' ) },         # tablespoon
        ts => sub { return ( $_[0] * 0.167, 'oz' ) },       # teaspoon
        T  => sub { return ( $_[0] * 0.5, 'oz' ) },         # tablespoon
        t  => sub { return ( $_[0] * 0.167, 'oz' ) },       # teaspoon
    };

    # Load the recipes
    my @recipes = import_mm(); 

    # Change the shopping list cookie to an array reference to display
    my $list = cookie('list');
    $list = [ split /\s*\|\s*/, $list ]
        if $list;

    my @items;

    # Find the given recipe by title
    for my $i ( @$list ) {
        RECIPE: for my $recipe ( @recipes ) {
            if ( $recipe->title eq $i ) {
                push @items, $recipe;
                last RECIPE;
            }
        }
    }

    # Sum quantities and convert units
    my $items = {};
    for my $recipe ( @items ) {
        for my $ingredient ( @{ $recipe->ingredients } ) {
            my $measure  = $ingredient->measure || 'ea';
            my $quantity = $ingredient->quantity;
            $quantity =~ s/ /+/;
            $quantity = 1 unless $quantity;
            $quantity = eval $quantity;

            if ( exists $units->{$measure} ) {
                # Convert units
                ( $quantity, $measure ) = $units->{$measure}->($quantity);
            }

            push @{ $items->{ $ingredient->product } }, {
                measure  => $measure,
                quantity => $quantity,
            };
        }
    }

    # Consolidate ingredients of the same unit
    my $shop;
    for my $item ( keys %$items ) {
        my $measure;
        my $quantity = 0;
        for my $ingredient ( @{ $items->{$item} } ) {
            $measure = $ingredient->{measure};
            $quantity += $ingredient->{quantity};
        }

        $quantity = sprintf '%.2f', $quantity if length($quantity) > 8;

        $shop->{$item} = {
            measure  => $measure,
            quantity => $quantity,
        };
    }

    template 'list' => {
        list => \@items,
        shop => $shop,
    };
};

get '/help'  => sub {
    template 'help' => {};
};

sub import_mm {
    my $recipes;
    my $file = 'recipes.dat';

    if ( -e $file ) {
        $recipes = retrieve $file;
    }
    else {
        my $mm = MealMaster->new();

        my @files = File::Find::Rule->file()->in('public/MMF');

        $recipes = [ map { $mm->parse($_) } @files ];

        store $recipes, $file;
    }

    return @$recipes; 
}

true;
