#/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Termux::API;
 
my $termux = Termux::API->new;
 
#$termux->toast('testing a toast');
#print Dumper $termux->battery_status;
#print Dumper $termux->camera_info;
#print $termux->clipboard_get;
#print Dumper $termux->contact_list;
#print Dumper $termux->infrared_frequencies; # bah!
#print Dumper $termux->location('gps');
print Dumper $termux->sensor('-l' => 1);
#print Dumper $termux->sensor(-s => 'motion');
#print Dumper $termux->telephony_cellinfo;
#print Dumper $termux->telephony_device;
#print Dumper $termux->tts_engines;
#$termux->vibrate(-d => 2000);
#print Dumper $termux->wifi;
#print Dumper $termux->wifi_scan;
#print Dumper $termux->audio_info;
#$termux->tts_speak("Talk nerdy to me!");
#my $text = $termux->speech_to_text(0);
#print "T: $text\n";
#if ($text =~ /\bon\b/) {
#    $termux->vibrate(-d => 2000);
#    $termux->torch('on');
#}
#else {
#    $termux->torch('off');
#}
