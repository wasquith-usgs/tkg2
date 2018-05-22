package Tkg2::Plot::Movements::MovingPlot;

=head1 LICENSE

     This Tkg2 module is authored by William H. Asquith.
     
     This program is free software; you can redistribute it and/or
     modify it under the same terms as Perl itself.

        You should have received a copy of the Perl license along with
        Perl; see the file README in Perl distribution.
 
        You should have received a copy of the GNU General Public License
        along with Perl; see the file Copying.  If not, write to the
              Free Software Foundation
              675 Mass Avenue
              Cambridge, MA 02139, USA.

        You should have received a copy of the Artistic License
        along with Perl; see the file Artistic.


Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be held responsible.  Furthermore,
portions of this software (tkg2 and related modules) were developed by
the Author as an employee of the U.S. Geological Survey Water Resources
Division, neither the USGS, the Department of the Interior, or other
entities of the Federal Government make any claim whatsoever about
suitability, reliability, editability or usability of this product.

With this all-native Perl and Open-Source software from this moment on
you have the whole Open-Source Community at your disposal.

=cut

# $Author: wasquith $
# $Date: 2002/08/07 18:29:25 $
# $Revision: 1.8 $

use strict;
use Tk;

 
sub new {
   my (  $pkg, $canv, $template, $plot, $width, $height) =
      ( shift, shift,     shift, shift,  shift,   shift);
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
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragplot1','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width,$y+$height,
                                          'dragplot2','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width/2,$y+$height/2,
                                          'dragplot3','blue');  
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
   &{$template->{-markrulerXY}}($canv,$x,$y,'dragplot1','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width,$y+$height,
                                          'dragplot2','blue');
   &{$template->{-markrulerXY}}($canv,$x+$width/2,$y+$height/2,
                                          'dragplot3','blue');               
   $canv->coords("rectplot", $x, $y, $x+$width, $y+$height);
}

sub _endMove {
   my ($canv, $drag,    $x,    $y, $width, $height) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragplot1',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragplot2',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'dragplot3',undef);   

   $canv->coords("rectplot", $x, $y, $x+$width, $y+$height);
   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);

   
   my $plot = $drag->{-plot};
   $plot->{-xlmargin} = $x;
   $plot->{-yumargin} = $y;
   $plot->config_xrylmargins_from_xlyumarins;
    
   $canv->Tk::bind("<Button-3>", "");
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}

1;
