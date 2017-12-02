package Food::Recipe;

use Dancer qw( :syntax );
use Dancer::Cookies;
use File::Find::Rule;
use List::Util qw( all first );
use Math::Fraction;
use MealMaster;

our $VERSION = '0.3';

any '/' => sub {
    my $title      = params->{title};
    my $category   = params->{category};
    my $ingredient = params->{ingredient};

    # Turn multi-word strings into lists
    $title      = [ split /\s+/, $title ] if $title;
    $category   = [ split /\s+/, $category ] if $category;
    $ingredient = [ split /\s+/, $ingredient ] if $ingredient;

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
    my @recipes = import_mm(); 

    my %categories;

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
    my $title = params->{title} or die 'No title provided';
    my $yield = params->{yield};

    my $ingredients;

    my @recipes = import_mm(); 

    my @match = grep { $_->title eq $title } @recipes;

    if ( $yield ) {
        my ($number) = split( / /, $match[0]->yield );
        my $factor = $yield / $number;

        for my $i ( @{ $match[0]->ingredients } ) {
            my $quantity = $i->quantity;
            if ( $quantity ) {
                $quantity =~ s/ /+/;
                $quantity = eval $quantity;
                $quantity *= $factor;

                if ( $quantity =~ /\./ ) {
                    my @parts   = split( /\./, $quantity );
                    my $integer = $parts[0] eq '0' ? '' : "$parts[0] ";
                    my $decimal = "0.$parts[1]";

                    # Handle the broken behavior of Math::Fraction
                    $quantity = sprintf '%.2f', $quantity if length($decimal) > 7;

                    # Handle the broken behavior of Math::Fraction
                    $decimal = sprintf '%.2f', $decimal if length($decimal) > 7;
                    $decimal = eval { frac($decimal) };
                    die "Can't frac($decimal): $@" if $@;

                    $quantity = $quantity . " ($integer$decimal)";
                }
            }

            push @$ingredients, {
                quantity => $quantity,
                measure  => $i->measure,
                product  => $i->product,
            };
        }
    }

    my $recipe;
    $recipe = {
        title       => $match[0]->title,
        categories  => $match[0]->categories,
        yield       => $match[0]->yield,
        ingredients => $match[0]->ingredients,
        directions  => $match[0]->directions,
    } if @match;

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
    my $title = params->{title} or die 'No title provided';

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
    my $title = params->{title} or die 'No title provided';

    cookie( list => '' );

    redirect '/recipe?title=' . $title;
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
        tb => sub { return ( $_[0] * 0.5, 'oz' ) },         # tablespoon
        ts => sub { return ( $_[0] * 0.167, 'oz' ) },       # teaspoon
        T  => sub { return ( $_[0] * 0.5, 'oz' ) },         # tablespoon
        t  => sub { return ( $_[0] * 0.167, 'oz' ) },       # teaspoon
    };

    my @recipes = import_mm(); 

    my $list = cookie('list');
    $list = [ split /\s*\|\s*/, $list ]
        if $list;

    my @items;

    for my $i ( @$list ) {
        RECIPE: for my $recipe ( @recipes ) {
            if ( $recipe->title eq $i ) {
                push @items, $recipe;
                last RECIPE;
            }
        }
    }

# Sum quantities
my $items = {};
for my $recipe ( @items ) {
    for my $ingredient ( @{ $recipe->ingredients } ) {
        my $quantity = $ingredient->quantity;
        $quantity =~ s/ /+/;
        $quantity = 1 unless $quantity;

        push @{ $items->{ $ingredient->product } }, {
            measure  => $ingredient->measure || 'ea',
            quantity => eval $quantity,
        };
    }
}

# Convert units if needed
my $listx;
for my $item ( keys %$items ) {
    for my $ingredient ( @{ $items->{$item} } ) {
        my ( $quantity, $measure ) = ( $ingredient->{quantity}, $ingredient->{measure} );
        if ( exists $units->{ $ingredient->{measure} } ) {
            # Convert units
            ( $quantity, $measure ) = $units->{ $ingredient->{measure} }->( $ingredient->{quantity} );
        }

        push @{ $listx->{$item} }, {
            measure  => $measure,
            quantity => $quantity,
        };
    }
}

# Consolidate ingredients of the same unit
my $listy;
for my $item ( keys %$listx ) {
    my $measure;
    my $quantity = 0;
    for my $ingredient ( @{ $listx->{$item} } ) {
        $measure = $ingredient->{measure};
        $quantity += $ingredient->{quantity};
    }
    $listy->{$item} = {
        measure  => $measure,
        quantity => $quantity,
    };
}

    template 'list' => {
        list => \@items,
        shop => $listy,
    };
};

sub import_mm {
    my $mm = MealMaster->new();

    my @files = File::Find::Rule->file()->in('public/MMF');

    my @recipes = map { $mm->parse($_) } @files;

    return @recipes; 
}

true;
