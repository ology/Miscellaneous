#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JWT;

# XXX Get the user_id from a database instead of hardcoding gene!
my $user = 'gene';

get '/' => sub {
  my $c = shift;

  my $expires = time() + 60 * 60; # 1 hour from now
  my $jwt = $c->jwt->claims({ user_id => $user })->expires($expires)->encode;
  my $url = $c->url_for('reset')->to_abs->query(token => $jwt);

  # Email the url instead of rendering it
  $c->render(template => 'index', url => $url);
};

get '/reset' => sub {
  my $c = shift;
  my $token = $c->param('token');
  my $claims = eval { $c->jwt->decode($token) };
  if ($claims && $claims->{user_id} && $claims->{exp}) {
    if ($claims->{user_id} eq $user && $claims->{exp} >= time()) {
      $c->render(template => 'reset');
    }
    else {
      return $c->reply->not_found;
    }
  }
  else {
    return $c->reply->not_found;
  }
} => 'reset';

post '/reset' => sub {
  my $c = shift;
  my $v = $c->validation;
  $v->required('password')->size(4, 50);
  $v->required('confirm')->size(4, 50)->equal_to('password');
  if ($v->has_error) {
    $c->render(text => 'Fail!');
  }
  else {
    $c->render(text => 'Success!');
  }
};

helper jwt => sub { Mojo::JWT->new(secret => shift->app->secrets->[0]) };

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome!</h1>
<a href="<%= $url %>">Reset!</a>

@@ reset.html.ep
% layout 'default';
% title 'Reset';
<h1>Reset!</h1>
<form method="post">
  Password: <input type="password" name="password">
  <br>
  Confirm: <input type="password" name="confirm">
  <br>
  <input type="submit" value="Submit">
</form>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
