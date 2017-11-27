package Food::Recipe;

use Dancer qw( :syntax );
use File::Find::Rule;
use List::Util qw( all );
use MealMaster;

our $VERSION = '0.2';

any '/' => sub {
    my $title      = params->{title};
    my $category   = params->{category};
    my $ingredient = params->{ingredient};

    # Are we matching an exact category?
    my $exact_cat = 0;
    if ( $category && not( ref $category ) ) {
        $exact_cat = 1 if $category =~ /^"/ && $category =~ /"$/;
        $category =~ s/"//g;
    }

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
            if ( not all { $recipe->title =~ /$_/i } @$title ) {
                next RECIPE;
            }
        }

        # Category support
        if ( $category && @$category ) {
            if ( $exact_cat ) {
                my $in_cat = join ' ', @$category;
                my $found  = 0;

                for my $r_cat ( @{ $recipe->categories } ) {
                    $found = 1 if $in_cat eq $r_cat;
                    last;
                }

                next RECIPE unless $found;
            }
            else {
                for my $c ( @$category ) {
                    next RECIPE unless grep { $_ =~ /$c/i } @{ $recipe->categories };
                }
            }
        }

        # Ingredient support
        if ( $ingredient && @$ingredient ) {
            for my $i ( @$ingredient ) {
                next RECIPE unless grep { $_->product =~ /$i/i } @{ $recipe->ingredients };
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
    };
};

get '/categories' => sub {
    my @recipes = import_mm(); 

    my %categories;

    for my $recipe ( @recipes ) {
        for my $cat ( @{ $recipe->categories } ) {
            $categories{$cat}++;
        }
    }

    template 'categories' => {
        categories => \%categories,
    };
};

get '/recipe' => sub {
    my $title = params->{title} or die 'No title provided';

    my @recipes = import_mm(); 

    my @match = grep { $_->title eq $title } @recipes;

    my $recipe;
    $recipe = {
        title       => $match[0]->title,
        categories  => $match[0]->categories,
        yield       => $match[0]->yield,
        ingredients => $match[0]->ingredients,
        directions  => $match[0]->directions,
    } if @match;

    template 'recipe' => {
        recipe => $recipe,
    };
};

sub import_mm {
    my $mm = MealMaster->new();

    my @files = File::Find::Rule->file()->in('public/MMF');

    my @recipes = map { $mm->parse($_) } @files;

    return @recipes; 
}

true;
