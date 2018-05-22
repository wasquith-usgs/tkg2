#!/usr/bin/perl -w

&startXvfb();
print `/bin/rm test.pdf`;
print `tkg2 --display=":1.0" -format=pdf -autoexit test.tkg2`;
&stopXvfb();

sub startXvfb {
   use strict;
   my ($server, $screen, $log) = @_;
   $log    = ($log)    ? $log    : "/var/tmp/Xvfb.log";
   $server = ($server) ? $server : ":1";
   $screen = ($screen) ? $screen :  "0";
   open(ERR, ">$log") or die "Could not open $log because $!\n";
   print ERR "Start up of Xvfb\n";
   my $xvfb = "/usr/X11R6/bin/Xvfb $server -screen $screen 1280x1024x8"; 
   print ERR "Command: $xvfb\n"; print "about\n";
   my $pid = `$xvfb &`;
   print "PID $pid";
   chomp $pid;
   (undef, $pid) = split(/\s+/,$pid);
   $pid = "not defined, error somewhere" if(not defined $pid);
   print ERR "PID: $pid\n";
   return $pid;
}


sub stopXvfb {
   use strict;
   my ($pid) = @_;
   unless($pid =~ /error/) {
      print ERR `/usr/bin/kill $pid`;
   }
   close(ERR);
}
