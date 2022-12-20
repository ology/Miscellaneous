package Mojolicious::Command::Author::generate::lite_app;
use Mojo::Base 'Mojolicious::Command';

has description => 'Generate Mojolicious::Lite application';
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, $name) = (shift, shift || 'myapp.pl');
  $self->render_to_rel_file('liteapp', $name);
  $self->chmod_rel_file($name, 0744);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::lite_app - Lite app generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate lite-app [OPTIONS] [NAME]

    mojo generate lite-app
    mojo generate lite-app foo.pl

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::lite_app> generate fully functional L<Mojolicious::Lite> applications.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::lite_app> inherits all attributes from L<Mojolicious::Command> and implements
the following new ones.

=head2 description

  my $description = $app->description;
  $app            = $app->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $app->usage;
  $app      = $app->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::lite_app> inherits all methods from L<Mojolicious::Command> and implements
the following new ones.

=head2 run

  $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ liteapp
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

get '/' => sub ($c) {
  my $thing = $c->param('thing');
  $c->render(
    template => 'index',
    thing    => $thing,
  );
} => 'index';

post '/' => sub ($c) {
  my $thing = $c->param('thing');
  $c->redirect_to($c->url_for('index')->query(thing => $thing));
} => 'update';

app->start;

<% %>__DATA__

<% %>@@ index.html.ep
%% layout 'default';
%% title 'Thing!';
<form method="post">
  <div class="form-group form-row">
    <label for="thing">Thing:</label>
    <input type="text" class="form-control form-control-sm" id="thing" name="thing" value="<%%= $thing %>" placeholder="A thing" title="Thing!" aria-describedby="thingHelp">
    <small id="thingHelp" class="form-text text-muted">What, why, how?</small>
  </div>
  <input type="submit" class="btn btn-sm btn-primary" name="submit" value="Submit" title="Submit form">
</form>

<% %>@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="/css/fontawesome.css" rel="stylesheet">
    <link href="/css/solid.css" rel="stylesheet">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js" integrity="sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+" crossorigin="anonymous"></script>
    <title><%%= title %></title>
    <style>
      .padpage {
        padding-top: 10px;
      }
      .small {
        font-size: small;
        color: darkgrey;
      }
    </style>
  </head>
  <body>
    <div class="container padpage">
      <h3><a href="/"><%%= title %></a></h3>
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
