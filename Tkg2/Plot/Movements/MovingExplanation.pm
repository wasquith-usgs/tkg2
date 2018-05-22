package Tkg2::Plot::Movements::MovingExplanation;

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
# $Date: 2002/08/07 18:30:29 $
# $Revision: 1.9 $

use strict;
use Tk;


sub new {
   my (  $pkg, $canv, $template, $plot, $width, $height) = @_;
   my $self = { -canvas   => $canv,
                -plot     => $plot,
                -template => $template,
                -width    => $width,
                -height   => $height };
   return bless $self, $pkg;
}

sub bindStart {
   my $drag = shift;
   my $canv = $drag->{-canvas};
   $canv->configure(-cursor => 'crosshair');
   $canv->Tk::bind("<Button-3>", [\&_startMove, $drag, Ev('x'), Ev('y')]);
 }

sub _startMove {
   my ($canv, $drag, $x, $y) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   my $width  = $drag->{-width};
   my $height = $drag->{-height};   
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragexplan1','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width,$y+$height,
                                          'dragexplan2','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width/2,$y+$height/2,
                                          'dragexplan3','blue');  
   $canv->Tk::bind("<Motion>", [\&_move, $drag,  Ev('x'), Ev('y'),
                                         $width, $height ] );
   $canv->Tk::bind("<Button-3>", [\&_endMove, $drag,  Ev('x'), Ev('y'),
                                              $width, $height ] );
}

sub _move {
   my ($canv, $drag, $x, $y, $width, $height) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);   
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragexplan1','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width,$y+$height,
                                          'dragexplan2','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width/2,$y+$height/2,
                                          'dragexplan3','blue');               
   $canv->coords("rectexplan", $x, $y, $x+$width, $y+$height);
}

sub _endMove {
   my ($canv, $drag, $x, $y, $width, $height) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragexplan1',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragexplan2',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragexplan3',undef);   

   $canv->coords("rectexplan", $x, $y, $x+$width, $y+$height);
   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);

   my $plot = $drag->{-plot};
   $plot->{-explanation}->{-xorigin} = $x;
   $plot->{-explanation}->{-yorigin} = $y;
       
   $canv->Tk::bind("<Button-3>", "");
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}


1;
