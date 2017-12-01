package Food::Recipe;

use Dancer qw( :syntax );
use Dancer::Cookies;
use File::Find::Rule;
use List::Util qw( all );
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

                    $quantity = sprintf '%.2f', $quantity if length($decimal) > 7;

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

sub import_mm {
    my $mm = MealMaster->new();

    my @files = File::Find::Rule->file()->in('public/MMF');

    my @recipes = map { $mm->parse($_) } @files;

    return @recipes; 
}

true;
