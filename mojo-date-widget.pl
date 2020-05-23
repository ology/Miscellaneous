#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

app->start;
__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
  </head>
  <body>
    <%= content %>
  </body>
</html>

@@ index.html.ep
% layout 'default';
% title 'Dynamic Date Widgets';
<label for="year">Year:</label>
<select name="year" id="year">
% my $y = (localtime)[5] + 1900;
% for my $year ($y - 5 .. $y + 5) {
    <option value="<%= $year %>"
    % if ($year == $y) {
    selected
    % }
    ><%= $year %></option>
% }
</select>
<label for="month">Month:</label>
<select name="month" id="month">
% my $m = (localtime)[4] + 1;
% for my $month (1 .. 12) {
    <option value="<%= $month %>"
    % if ($month == $m) {
    selected
    % }
    ><%= $month %></option>
% }
</select>
<label for="day">Day:</label>
<select name="day" id="day">
</select>
<script>
jQuery(function($) {
    function leapyear(year) {
        return year % 100 === 0 ? year % 400 === 0 : year % 4 === 0;
    }

    var nums = {1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31};

    function setDays() {
        var year = $('select[name="year"]').val();
        if (leapyear(year)) {
            nums[2] = 29;
        }
        else {
            nums[2] = 28;
        }
        $('select[name="day"]').empty();
        var i;
        for (i = 1; i <= nums[$('select[name="month"]').val()]; i++) {
            $('select[name="day"]').append('<option value="' + i + '">' + i + '</option>');
        }
    }

    setDays();

    $('select[name="year"], select[name="month"]').change(function () {
        setDays();
    });
});
</script>
