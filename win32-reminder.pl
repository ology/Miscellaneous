#!perl
use strict;
use warnings;

use Time::Local;
use Win32::GUI ();

use constant DEBUG => 1;

my $filename = 'win32-reminder.txt';
unless (-e $filename) {
    open my $fh, '>', $filename
        or die "Can't create $filename: $!";
    close $fh;
}

my @repeats;
my %in_seconds = (
    minutes => 60,
    hours   => 3_600,
    days    => 86_400,
);

my $DOS = Win32::GUI::GetPerlWindow();
unless (DEBUG) {
    Win32::GUI::Hide($DOS);
}

# main Window
my $window = Win32::GUI::Window->new(
    -name  => 'Window',
    -title => 'Reminder App',
    -pos   => [100, 100],
    -size  => [340, 390],
) or die "Can't create new window";

$window->AddTimer('Event', 60000);

$window->AddLabel(
    -text => 'Date:',
    -pos  => [10, 14],
);

my $datetime1 = $window->AddDateTime(
    -name   => 'datetime1',
    -pos    => [40, 10],
    -size   => [180, 20],
    -format => 'longdate',
);

$window->AddLabel(
    -text => 'Time:',
    -pos  => [10, 45],
);

my $datetime2 = $window->AddDateTime(
    -name   => 'datetime2',
    -pos    => [40, 42],
    -size   => [180, 20],
    -format => 'time',
);

$window->AddLabel(
    -text => 'Text:',
    -pos  => [10, 73],
);

my $textfield1 = $window->AddTextfield(
    -name => 'textfield1',
    -pos => [40, 70],
    -size=> [180, 20],
) or die "Failed to create textfield";

$window->AddLabel(
    -text => 'Rep:',
    -pos  => [10, 105],
);

my $textfield2 = $window->AddTextfield(
    -name => 'textfield2',
    -pos => [40, 100],
    -size=> [30, 20],
) or die "Failed to create textfield";

my $combobox1 = $window->AddCombobox(
    -name         => 'combobox1',
    -pos          => [80, 100],
    -size         => [140, 20],
    -vscroll      => 1,
    -dropdownlist => 1,
) or die "Failed to create combobox";

for my $span (qw(minutes hours days)) {
    $combobox1->AddString($span);
}

my $listbox = $window->AddListbox(
    -sort => 1,
    -pos  => [10, 135],
    -size => [304, 185],
);

my $button1 = $window->AddButton(
    -name => 'button1',
    -text => 'Add Reminder',
    -pos  => [230, 100],
);

my $button2 = $window->AddButton(
    -name => 'button2',
    -text => 'Delete Reminder',
    -pos  => [220, 320],
);

#my $button3 = $window->AddButton(
#    -name => 'button3',
#    -text => 'Reset',
#    -pos  => [230, 10],
#);

my @items = list_populate();

# Event loop
$window->Show;
Win32::GUI::Dialog();

unless (DEBUG) {
    Win32::GUI::Show($DOS);
}

exit(0);

# Main window event handler
sub Window_Terminate { return -1 }

sub Event_Timer {
    my $t = time();
warn 'T: ', scalar(localtime $t), "\n";
    @items = sort @items;
    for my $n (0 .. $#items) {
        my $i = $items[$n];
        next unless $i;
        my @line = split / /, $i, 2;
        my $str = defined $line[1] ? $line[1] : '';
warn 'I: ', scalar(localtime $line[0]), "\n";
        if ($line[0] <= $t && $str !~ / \(\d+ \w+\)$/) {
            warn "\t$str : Timer went off!\n";
warn "\tN: $n\n";
            remove_item($listbox, $n);

            $window->AddNotifyIcon(
                -name          => 'NotifyIcon',
                -balloon       => 1,
                -balloon_tip   => $str ? $str : '?',
                -balloon_title => 'Reminder',
                -balloon_icon  => 'warning',
            )->ShowBalloon;
        }
    }

    my @new_repeats;
    for my $n (0 .. $#repeats) {
        my $i = $repeats[$n];
        my @line = split / /, $i, 2;
warn 'REP: ', scalar(localtime $line[0]), "\n";
        if ($line[0] <= $t && $line[1] =~ / \((\d+) (\w+)\)$/) {
            warn "\t$line[1] : Recurring timer went off!\n";
            my $x = $1;
            my $span = $2;
            my $epoch = $line[0] + ($x * $in_seconds{$span});
            push @new_repeats, "$epoch $line[1]";

            $window->AddNotifyIcon(
                -name          => 'NotifyIcon',
                -balloon       => 1,
                -balloon_tip   => $line[1],
                -balloon_title => 'Reminder',
                -balloon_icon  => 'warning',
            )->ShowBalloon;
        }
        else {
            push @new_repeats, $i;
        }
    }
    @repeats = @new_repeats;

    return 0;
}

sub button1_Click {
    my @days = qw(sunday monday tuesday wednesday thursday friday);

    my ($year, $month, $day) = $datetime1->GetDateTime;
    my ($hour, $minute, $second) = $datetime2->GetTime;

    my $epoch = timelocal($second, $minute, $hour, $day, $month - 1, $year);

    my $stamp = sprintf '%d-%02d-%02d %02d:%02d:%02d',
        $year, $month, $day, $hour, $minute, $second;

    my $text = $textfield1->GetLine(0);
    my $nreps = $textfield2->GetLine(0);

    $textfield1->SelectAll;
    $textfield1->ReplaceSel('');
    $textfield2->SelectAll;
    $textfield2->ReplaceSel('');

    if ($nreps) {
        my $sel = $combobox1->GetString($combobox1->GetCurSel) || 'minutes';
        $nreps .= ' ' . $sel;
        $text .= " ($nreps)";

        my $t = time();

        my $recur = $epoch;

        if ($recur < $t && $text =~ / \((\d+) (\w+)\)$/) {
            my $x = $1;
            my $span = $2;
            while ($recur < $t) {
                $recur += ($x * $in_seconds{$span});
            }
        }
        push @repeats, "$recur $text";
    }

    push @items, "$epoch $text";

    $listbox->AddString("$stamp $text");

    open my $fh, '>>', $filename
        or die "Can't append to $filename: $!";
    print $fh "$epoch $text\n";
    close $fh;
}

sub button2_Click {
    my $item = $listbox->SelectedItem;
    if (defined $item) {
        remove_item($listbox, $item);
    }
}

#sub button3_Click {
#    my ($second, $minute, $hour, $day, $month, $year) = localtime;
#    $datetime1->SetDate($day, $month + 1, $year + 1900);
#    $datetime2->SetTime($hour, $minute, $second);
#}

sub list_populate {
    my @list_items;

    open my $fh, '<', $filename
        or die "Can't read $filename: $!";

    while (my $line = readline($fh)) {
        chomp $line;
        next unless $line;

        push @list_items, $line;

        my @line = split / /, $line, 2;

        my ($second, $minute, $hour, $day, $month, $year) = localtime $line[0];
        my $stamp = sprintf '%d-%02d-%02d %02d:%02d:%02d',
            $year + 1900, $month + 1, $day, $hour, $minute, $second;

        $listbox->AddString("$stamp $line[1]");

        if ($line[1] =~ / \((\d+) (\w+)\)$/) {
            my $x = $1;
            my $span = $2;
            my $epoch = $line[0];
            my $t = time();
            while ($epoch < $t) {
                $epoch += ($x * $in_seconds{$span});
            }
warn 'R: ', scalar(localtime $epoch), " $line[1]\n";
            push @repeats, "$epoch $line[1]";
        }
    }

    close $fh;

    return sort @list_items;
}

sub remove_item {
    my ($LB, $item) = @_;

    $LB->RemoveItem($item);

    my @new_items;

    my $string = $items[$item];

    open my $fh, '>', $filename
        or die "Can't write $filename: $!";

    for my $i (@items) {
        next if $i eq $string;
        print $fh "$i\n";
        push @new_items, $i;
    }

    close $fh;

    @items = @new_items;

    my ($text, $x, $span) = $string =~ /^\d+ (.+?) \((\d+) (\w+)\)$/;

    my @new_repeats;
    for my $i (@repeats) {
        next if $i =~ /$text \($x $span\)$/;
        push @new_repeats, $i;
    }
    @repeats = @new_repeats;
}
