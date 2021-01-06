#!perl

# http://ology.net/tmp/shire.bmp

use strict;
use warnings;

use Win32::GUI ();
use Date::Tolkien::Shire ();
#use Time::Local qw(timelocal);
#use Test::Time time => timelocal(0,0,0,5,0,2021);

my $image = Win32::GUI::Bitmap->new('shire.bmp');
die 'Could not find shire bitmap' unless $image;

my ($width, $height) = $image->Info;

my $main = Win32::GUI::Window->new(
    -name   => 'Shire Time',
    -text   => 'Shire Time',
    -height => $height, 
    -width  => $width,
    -left   => 0,
    -top    => 0,
);

my $bitmap = $main->AddLabel(
    -name   => 'Bitmap',
    -left   => 0,
    -top    => 0,
    -width  => $width,
    -height => $height,
    -bitmap => $image,
);  
 
$main->Center;
$main->Show;

my $dts = Date::Tolkien::Shire->new(time());
my $on_date = $dts->on_date;
$on_date =~ s/\n/\r\n/g;

my $text = $main->AddTextfield(
    -text      => $on_date,
    -left      => 200,
    -top       => 50,
    -height    => 100,
    -width     => $width - 2 * 200,
    -multiline => 1,
    -readonly  => 1,
    -align     => 'center',
);

Win32::GUI::Dialog();
