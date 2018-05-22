package Tkg2::Plot::Movements::ResizingPlot;

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software (tkg2 and related modules) were
developed by the Author as an employee of the U.S. Geological Survey
Water-Resources Division, neither the USGS, the Department of the
Interior, or other entities of the Federal Government make any claim
whatsoever about suitability, reliability, editability or usability
of this product.

=cut

# $Author: wasquith $
# $Date: 2002/08/07 18:29:25 $
# $Revision: 1.9 $

use strict;
use Tk;
  

sub new {
   my (  $pkg, $canv, $template, $plot, $tag) =
      ( shift, shift, shift, shift, shift, shift);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline1",undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline2",undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline3",undef);

   my $self = { -canvas   => $canv,
                -template => $template,
                -plot     => $plot,
                -which    => $tag };
   return bless $self, $pkg;
}

sub bindStart {
   my $drag = shift;
   my $canv = $drag->{-canvas};
   $canv->configure(-cursor => 'crosshair');
   $canv->Tk::bind("<Button-1>", [\&_startResizing, $drag, Ev('x'), Ev('y')]);
}

sub _startResizing {
   my ($canv, $drag, $x, $y) = @_;
   my $template = $drag->{-template};
   my ($xlmargin, $xpxl) = ( $drag->{-plot}->{-xlmargin}, $drag->{-plot}->{-xpixels} );
   my ($yumargin, $ypxl) = ( $drag->{-plot}->{-yumargin}, $drag->{-plot}->{-ypixels} );
   my $which = $drag->{-which};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x, $y);
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragplot','blue');

   my ($startx1, $starty1, $startx2, $starty2);   
   SWITCH: {
      if($which =~ m/lowerleft/)  { ($startx1, $starty1) = ($xpxl+$xlmargin, $yumargin       ); last SWITCH; }
      if($which =~ m/lowerright/) { ($startx1, $starty1) = ($xlmargin,       $yumargin       ); last SWITCH; }
      if($which =~ m/upperright/) { ($startx1, $starty1) = ($xlmargin,       $ypxl+$yumargin ); last SWITCH; }
      if($which =~ m/upperleft/)  { ($startx1, $starty1) = ($xpxl+$xlmargin, $ypxl+$yumargin ); last SWITCH; }
      
      if($which =~ m/middlebottom/) {
         ($startx1, $starty1, $startx2) = ($xlmargin,       $yumargin, $xpxl+$xlmargin ); last SWITCH; }
      if($which =~ m/middletop/)    {
         ($startx1, $starty1, $startx2) = ($xlmargin, $ypxl+$yumargin, $xpxl+$xlmargin ); last SWITCH; }

      if($which =~ m/middleright/)  {
         ($startx1, $starty1, $starty2) = ($xlmargin,       $yumargin, $ypxl+$yumargin ); last SWITCH; }
      if($which =~ m/middleleft/)   {
         ($startx1, $starty1, $starty2) = ($xpxl+$xlmargin, $yumargin, $ypxl+$yumargin ); last SWITCH; }
   }


   if($which =~ /lower|upper/) {
      $canv->createRectangle($startx1, $starty1, $x, $y,
                             -width => 1, -tags => [ 'tempanno', 'boxanno']);
      $canv->Tk::bind("<Motion>", [\&_sizebyCorner,  $drag, Ev('x'), Ev('y'), $startx1, $starty1]);
      $canv->Tk::bind("<Button-1>", [\&_endResizing, $drag, Ev('x'), Ev('y'), $startx1, $starty1]);
   }
   elsif($which =~ /top|bottom/) {
      $canv->createRectangle($startx1, $starty1, $startx2, $y,
                              -width => 1, -tags => [ 'tempanno', 'boxanno']);
      $canv->Tk::bind("<Motion>", [\&_sizebyTorB,    $drag, $startx1, Ev('y'), $startx2, $starty1]);
      $canv->Tk::bind("<Button-1>", [\&_endResizing, $drag, $startx1, Ev('y'), $startx2, $starty1]);
   }
   else {
      $canv->createRectangle($startx1, $starty1, $x, $starty2,
                              -width => 1, -tags => [ 'tempanno', 'boxanno']);
      $canv->Tk::bind("<Motion>", [\&_sizebySide,    $drag, Ev('x'), $starty1, $startx1, $starty2]);
      $canv->Tk::bind("<Button-1>", [\&_endResizing, $drag, Ev('x'), $starty1, $startx1, $starty2]);   
   
   }
}

sub _sizebyCorner {
   my ($canv, $drag, $x, $y, $startx, $starty) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x, $y);
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragplot','blue');
   $canv->coords("tempanno", $startx, $starty, $x, $y);
}

sub _sizebyTorB {
   my ($canv, $drag, $startx1, $y, $startx2, $starty2) = @_;
   my $template = $drag->{-template};
   $y = $canv->canvasy($y);
   (undef, $y) = $template->snap_to_grid($startx1, $y);
   &{$template->{-markrulerXY}}($canv,$startx1,$y,'dragplot','blue');
   $canv->coords("tempanno", $startx1, $y, $startx2, $starty2);
}

sub _sizebySide {
   my ($canv, $drag, $x, $starty1, $startx2, $starty2) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasy($x);
   ($x, undef) = $template->snap_to_grid($x, $starty1);
   &{$template->{-markrulerXY}}($canv,$x,$starty1,'dragplot','blue');
   $canv->coords("tempanno", $x, $starty1, $startx2, $starty2);
}

sub _endResizing {
   my ($canv, $drag,    $x,    $y, $startx, $starty) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragplot',undef);
   
   my $w = $canv->cget(-width);
   my $h = $canv->cget(-height);
   
   $canv->coords("tempanno", $startx, $starty, $x, $y);
   my ($x1, $y1, $x2, $y2) = $canv->bbox("tempanno"); 
   $canv->dtag("tempanno");
   my $plot = $drag->{-plot};

   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);
   
   $plot->{-xrmargin} = $w - $x2;
   $plot->{-xlmargin} = $x1;
   $plot->{-yumargin} = $y1;
   $plot->{-ylmargin} = $h - $y2;
   $plot->configwidth;
   
   $canv->Tk::bind("<Button-1>","");
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}

1;
