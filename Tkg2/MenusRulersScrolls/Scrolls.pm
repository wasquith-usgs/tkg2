package Tkg2::MenusRulersScrolls::Scrolls;

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
# $Date: 2002/08/07 18:33:58 $
# $Revision: 1.9 $

use strict;

use Tkg2::Base qw(Show_Me_Internals);

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(buildScrollBars configureScrollBars);


print $::SPLASH "=";

sub buildScrollBars {
    &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
    
    my ($template, $fcanv, $hedge, $vedge, $width, $height) = @_;

    my $vscrollbar = $fcanv->Scrollbar(-width => '13')
                           ->pack(-side => 'right', -fill => 'y');
   
    my $hscrollbar = $fcanv->Scrollbar(-orient => 'horizontal',
                                       -width  => '13')
                           ->pack(-side => 'bottom', -fill => 'x'); 

    my $ftop = $fcanv->Frame()->pack(-fill=>'x',-side=>'top');
       $ftop->Canvas(-height => $hedge,
                     -width  => $vedge)
            ->pack(-side => 'left');          
    my $hcanv = $ftop->Canvas(-scrollregion => [ 0, 0, $width, 0 ],
                              -height       => $hedge,
                              -background   => 'grey90' )
                     ->pack(-side => 'right', -expand => 1, -fill => 'x');

 
    my $vcanv = $fcanv->Canvas(-scrollregion => [ 0, 0, 0, $height ],
                               -width        => $vedge,
                               -background   => 'grey90')
                      ->pack( -side => 'left', -fill => 'y'); 
                    
    return ($hscrollbar, $vscrollbar, $hcanv, $vcanv);              
}    


sub configureScrollBars {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $canv, $hscrollbar, $vscrollbar, $hcanv, $vcanv) = @_;
                           
   # Configure each scrollbar to talk to each canvas
   $vscrollbar->configure(
       -command => sub { map { $_->yview(@_) } ($vcanv, $canv) } );
   $hscrollbar->configure(
       -command => sub { map { $_->xview(@_) } ($hcanv, $canv) } );

   # Configure each canvas to talk to the correct scrollbar
   map { $_->configure(-yscrollcommand => [ \&_vscroll_canvas,
           $vscrollbar, $_, [ $vcanv, $canv ] ] )
       } ($vcanv, $canv);
   
   map { $_->configure(-xscrollcommand => [ \&_hscroll_canvas,
           $hscrollbar, $_, [ $hcanv, $canv ] ] )
       } ($hcanv, $canv);
}

sub _vscroll_canvas {
   # do not remove the shifts on the @_
   my ($sb, $scrolledcanv, $canvi) = ( shift, shift, shift);
   $sb->set(@_);
   my ($top, $bottom) = $scrolledcanv->yview;
   map { $_->yview("moveto" => $top) } (@$canvi);
}

sub _hscroll_canvas {
   # do not remove the shifts on the @_
   my ($sb, $scrolledcanv, $canvi) = ( shift, shift, shift);
   $sb->set(@_);
   my ($left, $right) = $scrolledcanv->xview;
   map { $_->xview("moveto" => $left) } (@$canvi);
}


1;
