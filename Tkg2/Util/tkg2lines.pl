#!/usr/bin/perl -w
use Tk;
$mw = new MainWindow;
$canv = $mw->Canvas(-width => 300, -height => 400)->pack;
$x = 10;  $y = 10;
for( my $i=0.0000; $i<=0.1; $i += 0.005) {  
   $canv->createLine($x,$y,$x+200,$y, -width => $i."i");
   my $t = sprintf("%0.3f"."i", $i);
   $canv->createText($x+230, $y, -text => $t);  $y += 15; }
$canv->postscript(-file => 'line.ps', -width => 300, -height => 400);
MainLoop;

__END__

=head1 Tkg2 Line Thickness Displayer

This little utility can be used to see what line thickness resolution
is possible and that the postscript options is working on default
printer.

=cut
