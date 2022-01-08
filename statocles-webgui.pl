#!/usr/bin/env perl

use File::Path qw(make_path);
use Mojolicious::Lite -signatures;
use Mojo::File;
use Path::Iterator::Rule;
use Time::Piece;
use YAML::XS qw(LoadFile);

use constant FORMAT => 'blog/%s/%s/index.markdown';

get '/' => sub ($c) {
  my $rule = Path::Iterator::Rule->new->name('*.markdown');
  my @files = $rule->all('blog');
  my %posts;
  for my $file (@files) {
    if ($file =~ m|^blog/([\d/]+)/([\w-]+)/index.markdown$|) {
      my $date = $1;
      my $slug = $2;
      $posts{$slug} = {
        date => $date,
        title => titleize($slug),
      };
    }
  }
  my $conf = LoadFile('site.yml');
  $c->render(
    template => 'index',
    posts => \%posts,
    site => $conf->{site}{base_url},
  );
} => 'index';

get '/edit' => sub ($c) {
  my $date = $c->param('date');
  my $slug = $c->param('slug');
  my $file = Mojo::File->new(sprintf FORMAT, $date, $slug);
  $c->render(
    template => 'edit',
    date => $date,
    slug => $slug,
    title => titleize($slug),
    content => $file->slurp,
  );
} => 'view';

post '/edit' => sub ($c) {
  my $v = $c->validation;
  $v->required('date')->size(10)->like(qr|^\d{4}/\d\d/\d\d$|);
  $v->required('slug')->size(1, undef);
  $v->required('content')->size(1, undef);
  my $date = $v->param('date');
  my $slug = $v->param('slug');
  my $content = $v->param('content');
  if ($v->has_error) {
    $c->flash(error => 'Invalid submission!');
    if ($date && $slug) {
      return $c->redirect_to($c->url_for('view')->query(date => $date, slug => $slug));
    }
    else {
      return $c->redirect_to($c->url_for('index'));
    }
  }
  $content =~ s/\r\n/\n/g;
  my $file = Mojo::File->new(sprintf FORMAT, $date, $slug);
  $file->spurt($content);
  return $c->redirect_to($c->url_for('view')->query(date => $date, slug => $slug));
} => 'edit';

post '/new' => sub ($c) {
  my $v = $c->validation;
  $v->required('title', 'trim')->size(1, undef);
  if ($v->has_error) {
    $c->flash(error => 'Invalid submission!');
    return $c->redirect_to($c->url_for('index'));
  }
  my $title = $v->param('title');
  my $slug = slugize($title);
  my $t = localtime;
  my $date = $t->ymd('/');
  my $content = <<"CONTENT";
---                                                                                                                                                                          
status: published
title: $title
tags:
  - foo
---

Teaser markdown content goes here...

---

And the body goes here!

CONTENT
  my $path = "blog/$date/$slug";
  make_path($path) unless -d $path;
  my $file = Mojo::File->new(sprintf FORMAT, $date, $slug);
  $file->spurt($content);
  return $c->redirect_to($c->url_for('edit')->query(date => $date, slug => $slug));
} => 'new';

get '/deploy' => sub ($c) {
  system('statocles', 'deploy') == 0
    or die "Can't deploy: $!";
  $c->flash(message => 'Deployed site!');
  return $c->redirect_to($c->url_for('index'));
} => 'deploy';

sub titleize {
  my ($slug) = @_;
  (my $title = $slug) =~ s/-/ /g;
  $title =~ s/([\w']+)/\u\L$1/g; # Capitalize every word
  return $title;
}

sub slugize {
  my ($title) = @_;
  (my $slug = $title) =~ s/\s+/-/g;
  $slug =~ s/(?!-)[[:punct:]]//g; # Remove all punctuation except the hyphen
  $slug = lc $slug;
  return $slug;
}

app->start;
__DATA__

@@ _flash.html.ep
% if (flash('message')) {
%= tag h1 => (style => 'color:green') => flash('message')
% }
% elsif (flash('error')) {
%= tag h1 => (style => 'color:red') => flash('error')
% }

@@ index.html.ep
% layout 'default';
% title 'Statocles UI Posts';
%= include '_flash'
<p>
  <b><a href="<%= $site %>">Visit Site</a></b>
  |
  <b><a href="<%= url_for('deploy') %>">Deploy</a></b>
</p>
<form action="<%= url_for('new') %>" method="post">
  <label for="title">New post:</label>
  <input type="text" name="title" id="title" placeholder="Blog Post Title"/>
  <input type="submit" value="Submit"/>
</form>
<h2>Posts</h1>
% for my $slug (sort { $posts->{$b}{date} cmp $posts->{$a}{date} || $posts->{$a}{title} cmp $posts->{$b}{title} } keys %$posts) {
<p>
  <%= $posts->{$slug}{date} %>:
  <a href="<%= url_for('view')->query(date => $posts->{$slug}{date}, slug => $slug) %>"><%= $posts->{$slug}{title} %></a>
</p>
% }

@@ edit.html.ep
% layout 'default';
% title 'Statocles UI Post';
%= include '_flash'
<h1><%= $title %></h1>
<h4><%= $date %></h4>
<p></p>
<form method="post">
<input type="hidden" name="date" value="<%= $date %>"/>
<input type="hidden" name="slug" value="<%= $slug %>"/>
<textarea name="content" rows="20" cols="100"><%= $content %></textarea>
<p></p>
<input type="submit" value="Submit"/>
</form>
<p><a href="<%= url_for('index') %>">Back to Posts</a></p>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
