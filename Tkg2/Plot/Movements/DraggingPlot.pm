package Tkg2::Plot::Movements::DraggingPlot;

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
# $Revision: 1.10 $

use strict;
use Tk;


sub new {
   my (  $pkg, $canv, $template, $plot) =
      ( shift, shift,     shift, shift);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline1",undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline2",undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline3",undef);
   my $self = { -canvas   => $canv,
                -plot     => $plot,
                -template => $template};
   return bless $self, $pkg;
}

sub bindStart {
   my $drag = shift;
   my $canv = $drag->{-canvas};
   $canv->configure(-cursor => 'crosshair');
       
   $canv->Tk::bind("<Button-1>", [\&_startDrag, $drag, Ev('x'), Ev('y')]);
}

sub _startDrag {
   my ($canv, $drag, $x, $y) = @_;
   
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragplot','blue');
   $canv->createRectangle($x, $y, $x, $y,
                             -width => 1,
                             -tags => [ 'tempanno', 'boxanno']);
   my ($startx, $starty) = ($x, $y);
   $canv->Tk::bind("<Motion>", [\&_size, $drag,   Ev('x'), Ev('y'),
                                         $startx, $starty]);
   $canv->Tk::bind("<Button-1>", [\&_endDrag, $drag,   Ev('x'), Ev('y'),
                                              $startx, $starty]);
}

sub _size {
   my ($canv, $drag, $x, $y, $startx, $starty) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   &{$drag->{-template}->{-markrulerXY}}($canv,$x,$y,'dragplot','blue');
   $canv->coords("tempanno", $startx, $starty, $x, $y);
}

sub _endDrag {
   my ($canv, $drag, $x, $y, $startx, $starty) = @_;
   my $template = $drag->{-template};   
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragplot',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline1",undef);
   &{$template->{-markrulerXY}}($canv,undef,undef, "plotline2",undef);   
   my $w = $canv->cget(-width);
   my $h = $canv->cget(-height);
   
   $canv->coords("tempanno", $startx, $starty, $x, $y);
   my ($x1, $y1, $x2, $y2) = $canv->bbox("tempanno"); 
   $canv->dtag("tempanno");
   my $plot = $drag->{-plot};
    
   my $args = [$template->{-markrulerEv}, Ev('x'), Ev('y')];
   $canv->Tk::bind("<Motion>", $args);
   
   $plot->{-xrmargin} = $w - $x2;
   $plot->{-xlmargin} = $x1;
   $plot->{-yumargin} = $y1;
   $plot->{-ylmargin} = $h - $y2;
   $plot->configwidth; # the first -y axis is used because it must
                             # defined first and provides the basis of the
                             # optional tagging along of the second one
   
   my $arr = $template->{-plots};
   push(@$arr, $plot);
   $template->{-plots} = $arr;
   $canv->Tk::bind("<Button-1>", "");
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}

1;
