package Mojolicious::Command::Author::generate::lite_gene;
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

Mojolicious::Command::Author::generate::lite_gene - Gene's custom lite app generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate lite-gene [OPTIONS] [NAME]

    mojo generate lite-gene
    mojo generate lite-gene foo.pl

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::lite_gene> generate fully functional L<Mojolicious::Lite> applications.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::lite_gene> inherits all attributes from L<Mojolicious::Command> and implements
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

L<Mojolicious::Command::Author::generate::lite_gene> inherits all methods from L<Mojolicious::Command> and implements
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
  my $thing = $c->param('thing') || '';
  my $stuff = $self->every_param('stuff');
  $stuff = [qw(abc 123 xyz 667)] unless @$stuff;
  $c->render(
    template => 'index',
    thing    => $thing,
    stuff    => $stuff,
  );
} => 'index';

post '/' => sub ($c) {
  my $v = $c->validation;
  $v->required('thing')->size(0, 10);
  my $thing = $v->param('thing');
  if ($v->error('thing')) {
    $c->flash(error => 'Invalid thing!');
    $thing = '';
  }
  $v->optional('stuff', 'trim');
  my $stuff = $v->every_param('stuff');
  $c->redirect_to(
    $c->url_for('index')->query(thing => $thing, stuff => $stuff)
  );
} => 'update';

get '/help' => sub ($c) {
  $c->render(template => 'help');
} => 'help';

app->start;

<% %>__DATA__

<% %>@@ index.html.ep
%% layout 'default';
      <form action="<%%= url_for('update') %>" method="post">
        <div class="form-group form-row">
          <label for="thing">Thing:</label>
          <input type="text" class="form-control form-control-sm" id="thing" name="thing" value="<%%= $thing %>" placeholder="A thing" title="Thing!" aria-describedby="thingHelp">
          <small id="thingHelp" class="form-text text-muted">What, why, how?</small>
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

<% %>@@ help.html.ep
%% layout 'default';
      <ul>
        <li>What?</li>
        <li>Why?</li>
        <li>How?</li>
        <li>When?</li>
      </ul>

<% %>@@ layouts/default.html.ep
%% title 'Things & Stuff!';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js" integrity="sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+" crossorigin="anonymous"></script>
    <title><%%= title %></title>
    <style>
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
    </style>
  </head>
  <body>
    <div class="container padpage">
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
