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

    my $exact_cat = 0;
    if ( not ref $category ) {
        $exact_cat = 1 if $category =~ /^"/ && $category =~ /"$/;
        $category =~ s/"//g;
    }

    $title      = [ split /\s+/, $title ] if $title;
    $category   = [ split /\s+/, $category ] if $category;
    $ingredient = [ split /\s+/, $ingredient ] if $ingredient;

    my @recipes = import_mm(); 

    my @matched;

    my $i = 0;

    RECIPE: for my $recipe ( @recipes ) {
        # Title support
        if ( $title && @$title ) {
            if ( not all { $recipe->title =~ /$_/i } @$title ) {
                next RECIPE;
            }
        }
        # Category support
        if ( $category && @$category ) {
            for my $c ( @$category ) {
                if ( $exact_cat ) {
                    my $found = 0;

                    for my $cat ( @{ $recipe->categories } ) {
                        if ( $c eq $cat ) {
                            $found = 1;
                            last;
                        }
                    }

                    next RECIPE unless $found;
                }
                else {
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

        push @matched, {
            title       => $recipe->title,
            categories  => join( ', ', sort @{ $recipe->categories } ),
            yield       => $recipe->yield,
            ingredients => join( ', ', map { $_->product } @{ $recipe->ingredients } ),
        };
    }

    $category = '"' . $category . '"' if $exact_cat;

    template 'index' => {
        title      => $title,
        category   => $category,
        ingredient => $ingredient,
        matched    => \@matched,
    };
};

get '/categories' => sub {
    my @mm_recipes = import_mm(); 

    my %categories;

    for my $recipe ( @mm_recipes ) {
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

    my @files = File::Find::Rule->file()->in('public/MMF');

    my @recipes = map { $mm->parse($_) } @files;

    return @recipes; 
}

true;
