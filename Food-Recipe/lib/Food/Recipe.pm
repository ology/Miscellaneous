package Food::Recipe;

use Dancer ':syntax';

use MealMaster;

our $VERSION = '0.1';

any '/' => sub {
    my $title      = params->{title};
    my $category   = params->{category};
    my $ingredient = params->{ingredient};

    $title      = [ split /\s+/, $title ] if $title;
    $category   = [ split /\s+/, $category ] if $category;
    $ingredient = [ split /\s+/, $ingredient ] if $ingredient;

    my $mm = MealMaster->new();
    my $file = '/Users/gene/Documents/MealMaster-31000.mmf';
    my @mm_recipes = $mm->parse($file);

    # Set the recipes to search over
    my @recipes;
    for my $recipe ( @mm_recipes ) {
        if ( $title && @$title ) {
            for my $t ( @$title ) {
                push @recipes, $recipe
                    if $recipe->title =~ /$t/i;
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

get '/recipe' => sub {
    my $title = params->{title} or die 'No title provided';

    my $mm = MealMaster->new();
    my $file = '/Users/gene/Documents/MealMaster-31000.mmf';
    my @mm_recipes = $mm->parse($file); 

    my @match = grep { $_->title eq $title } @mm_recipes;

    my $recipe;
    $recipe = {
        title       => $match[0]->title,
        categories  => $match[0]->categories,
        ingredients => $match[0]->ingredients,
        directions  => $match[0]->directions,
    } if @match;

    template 'recipe' => {
        recipe => $recipe,
    };
};

true;
