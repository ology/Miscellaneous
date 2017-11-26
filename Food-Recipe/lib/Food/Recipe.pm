package Food::Recipe;

use Dancer ':syntax';

use File::Find::Rule;
use List::Util qw( all );
use MealMaster;
use Storable;

our $VERSION = '0.1';

any '/' => sub {
    my $title      = params->{title};
    my $category   = params->{category};
    my $ingredient = params->{ingredient};

    $title      = [ split /\s+/, $title ] if $title;
    $category   = [ split /\s+/, $category ] if $category;
    $ingredient = [ split /\s+/, $ingredient ] if $ingredient;

    my @mm_recipes = import_mm(); 

    # Set the recipes to search over
    my @recipes;
    for my $recipe ( @mm_recipes ) {
        if ( $title && @$title ) {
            if ( all { $recipe->title =~ /$_/i } @$title ) {
                push @recipes, $recipe;
            }
        }
        else {
            push @recipes, $recipe;
        }
    }

    my @matched;

    my $i = 0;

    RECIPE: for my $recipe ( @recipes ) {
        # Category support
        if ( $category && @$category ) {
            for my $c ( @$category ) {
                next RECIPE unless grep { $_ =~ /$c/i } @{ $recipe->categories };
            }
        }
        # Ingredient support
        if ( $ingredient && @$ingredient ) {
            for my $i ( @$ingredient ) {
                next RECIPE unless grep { $_->product =~ /$i/i } @{ $recipe->ingredients };
            }
        }

        push @matched, {
            title       => $recipe->title,
            categories  => join( ' ', sort @{ $recipe->categories } ),
            yield       => $recipe->yield,
            ingredients => join( ' ', map { $_->product } @{ $recipe->ingredients } ),
        };
    }

    template 'index' => {
        title      => $title,
        category   => $category,
        ingredient => $ingredient,
        matched    => \@matched,
    };
};

get '/recipe' => sub {
    my $title = params->{title} or die 'No title provided';

    my @mm_recipes = import_mm(); 

    my @match = grep { $_->title eq $title } @mm_recipes;

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

    my @recipes;

    my @files = File::Find::Rule->file()->in('public/MMF');

    for my $file ( @files ) {
        push @recipes, $mm->parse($file);
    }

    return @recipes; 
}

true;
