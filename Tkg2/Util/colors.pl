#!/usr/bin/perl -w

# ReflectionX colors in ReflectionXrgb.txt from William H. Asquith NT box
# Tkg2/Util/ReflectionXrgb.txt

# Sun Solaris Colors
# /usr/openwin/lib/X11/rgb.txt


use Tie::IxHash;
tie(%RefX, Tie::IxHash);
tie(%SunX, Tie::IxHash);
tie(%both, Tie::IxHash);

open(FH, "<ReflectionXrgb.txt") or die "$!\n";
while(<FH>) {
   chomp;
   @line = split(/\s\t\t*/,$_);
   $line[0] =~ s/\s+$//;
   $line[0] =~ s/^\s+//;
   $RefX{$line[0]} = $line[1];
}
close(FH);

open(FH, "</usr/openwin/lib/X11/rgb.txt") or die "$!\n";
$_ = <FH>; # header line removed
while(<FH>) {
   chomp;
   @line = split(/\s\t\t*/,$_);
   $line[0] =~ s/\s+$//;
   $line[0] =~ s/^\s+//;
   $SunX{$line[0]} = $line[1];
}
close(FH);

#print "Reflection X colors\n";
#map { print "$_ => $RefX{$_}\n" } keys %RefX;

#print "Sun Colors\n";
#map { print "$_ => $SunX{$_}\n" } keys %SunX;

foreach (keys %SunX) {
   if(exists($RefX{$_})) {
      $both{$_} = "$SunX{$_}" if($SunX{$_} eq $RefX{$_}); 
   }
}

print "# A pairwise match of Solaris 2.6 colors and colors from Reflection X 7.10\n";
print "# These colors should be the only ones used by tkg2 to insure maximum compatibility\n";
print "# between platforms\n";
map { print "$_ \t$both{$_}\n" } keys %both;
