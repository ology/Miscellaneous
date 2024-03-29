package Mojolicious::Command::Author::generate::gene;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize);

has description => 'Generate Mojolicious application directory structure';
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, $class) = (shift, shift || 'MyApp');

  # Script
  my $name = class_to_file $class;
  $self->render_to_rel_file('mojo', "$name/script/$name", {class => $class});
  $self->chmod_rel_file("$name/script/$name", 0744);

  # Application class
  my $app = class_to_path $class;
  $self->render_to_rel_file('appclass', "$name/lib/$app", {class => $class});

  # Config file (using the default moniker)
  $self->render_to_rel_file('config', "$name/@{[decamelize $class]}.yml");

  # Controller
  my $controller = "${class}::Controller::Main";
  my $path       = class_to_path $controller;
  $self->render_to_rel_file('controller', "$name/lib/$path", {class => $controller});

  # Test
  $self->render_to_rel_file('test', "$name/t/basic.t", {class => $class});

  # Static file
  $self->render_to_rel_file('static', "$name/public/index.html");
  $self->create_dir("$name/public/assets");
  $self->create_dir("$name/public/assets/css");
  $self->render_to_rel_file('style', "$name/public/assets/css/style.css");
  $self->create_dir("$name/public/assets/js");
  $self->render_to_rel_file('script', "$name/public/assets/js/script.js");

  # Templates
  $self->render_to_rel_file('layout',  "$name/templates/layouts/default.html.ep");
  $self->render_to_rel_file('index', "$name/templates/main/index.html.ep");
  $self->render_to_rel_file('help', "$name/templates/main/help.html.ep");
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::gene - Gene's custom app generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate gene [OPTIONS] [NAME]

    mojo generate gene
    mojo generate gene TestApp
    mojo generate gene My::TestApp

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::gene> generates application directory structures for fully functional
L<Mojolicious> applications.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::gene> inherits all attributes from L<Mojolicious::Command> and implements the
following new ones.

=head2 description

  my $description = $app->description;
  $app            = $app->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $app->usage;
  $app      = $app->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::gene> inherits all methods from L<Mojolicious::Command> and implements the
following new ones.

=head2 run

  $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ mojo
#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;
use Mojolicious::Commands;

Mojolicious::Commands->start_app('<%= $class %>');

@@ appclass
package <%= $class %>;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {

  my $config = $self->plugin('NotYAMLConfig');
  $self->plugin('DefaultHelpers');

  $self->secrets($config->{secrets});

  my $r = $self->routes;
  $r->get('/')    ->to('Main#index') ->name('index');
  $r->post('/')   ->to('Main#update')->name('update');
  $r->get('/help')->to('Main#help')  ->name('help');
}

1;

@@ controller
package <%= $class %>;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
  my $thing = $self->param('thing') || '';
  my $stuff = $self->every_param('stuff');
  $stuff = [qw(abc 123 xyz 667)] unless @$stuff;
  $self->render(
    thing => $thing,
    stuff => $stuff,
  );
}

sub update ($self) {
  my $v = $self->validation;
  $v->required('thing')->size(0, 10);
  my $thing = $v->param('thing');
  if ($v->error('thing')) {
    $self->flash(error => 'Invalid thing!');
    $thing = '';
  }
  $v->optional('stuff', 'trim');
  my $stuff = $v->every_param('stuff');
  $self->redirect_to(
    $self->url_for('index')->query(thing => $thing, stuff => $stuff)
  );
}

sub help ($self) { $self->render }

1;

@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome!</title>
  </head>
  <body>
    <h2>Welcome!</h2>
    This is the static document "public/index.html",
    <a href="/">click here</a> to get back to the start.
  </body>
</html>

@@ style
body {
  background-color: lightblue;
}
.padpage {
  padding-top: 10px;
  padding-bottom: 10px;
}
.small {
  font-size: small;
  color: darkgrey;
}
.danger {
  color: red;
}

@@ script

@@ test
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('<%= $class %>');

$t->ua->max_redirects(1);

$t->get_ok($t->app->url_for('index'))
  ->status_is(200)
  ->content_like(qr/Thing:/)
  ->element_exists('label[for=thing]')
  ->element_exists('input[name=thing][type=text]')
  ->element_exists('input[type=submit]');
;

$t->post_ok($t->app->url_for('index'), form => { thing => 'xyz' })
  ->status_is(200)
  ->element_exists('input[name=thing][type=text][value=xyz]')
;

$t->post_ok($t->app->url_for('index'), form => { thing => 'x' x 99 })
  ->status_is(200)
  ->content_like(qr/Invalid thing/)
;

$t->get_ok($t->app->url_for('help'))
  ->status_is(200)
;

done_testing();

@@ layout
%% title 'Things & Stuff!';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <link rel="stylesheet" href="/assets/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js" integrity="sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+" crossorigin="anonymous"></script>
    <script src="/assets/js/script.js"></script>
    <title><%%= title %></title>
  </head>
  <body>
    <div class="container padpage">
%% if (my $error = flash 'error') {
      <h1 class="danger"><%%= $error %></h1>
%% }
      <h3><a href="<%%= url_for('index') %>"><%%= title %></a></h3>
<%%= content %>
      <p></p>
      <div class="small">
        <hr>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
        | <a href="/help">Help!</a>
      </div>
    </div>
  </body>
</html>

@@ index
%% layout 'default';
      <form action="<%%= url_for('update') %>" method="post">
        <div class="form-group form-row">
          <label for="thing"><b>Thing:</b></label>
          <input type="text" class="form-control form-control-sm" id="thing" name="thing" value="<%%= $thing %>" placeholder="A thing" title="Thing!" aria-describedby="thingHelp">
          <small id="thingHelp" class="form-text text-muted">0 to 10 characters</small>
        </div>
        <div class="form-group form-row">
          <b>Stuff:</b>
          <ol>
%% for my $x (@$stuff) {
            <li><input type="text" class="form-control form-control-sm" name="stuff" value="<%%= $x %>" placeholder="An item" title="An item"></li>
%% }
          </ol>
        </div>
        <input type="submit" class="btn btn-sm btn-primary" name="submit" value="Submit" title="Submit form">
      </form>

@@ help
%% layout 'default';
      <ul>
        <li>What?</li>
        <li>Why?</li>
        <li>How?</li>
        <li>When?</li>
      </ul>

@@ config
% use Mojo::Util qw(sha1_sum steady_time);
---
secrets:
  - <%= sha1_sum $$ . steady_time . rand  %>
