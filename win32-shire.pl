#!perl

# http://ology.net/tmp/shire.bmp

use strict;
use warnings;

use Win32::GUI ();
use Date::Tolkien::Shire ();
#use Time::Local qw(timelocal);
#use Test::Time time => timelocal(0,0,0,5,0,2021);

use constant DEBUG => 0;

my $DOS = Win32::GUI::GetPerlWindow();
unless (DEBUG) {
    Win32::GUI::Hide($DOS);
}

my $image = Win32::GUI::Bitmap->new('shire.bmp');
die 'Could not find shire bitmap' unless $image;

my ($width, $height) = $image->Info;

my $main = Win32::GUI::Window->new(
    -name   => 'Shire Time',
    -text   => 'Shire Time',
    -left   => 0,
    -top    => 0,
    -height => $height, 
    -width  => $width,
);

my $bitmap = $main->AddLabel(
    -name   => 'Bitmap',
    -left   => 0,
    -top    => 0,
    -height => $height,
    -width  => $width,
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

unless (DEBUG) {
    Win32::GUI::Show($DOS);
}

exit(0);
