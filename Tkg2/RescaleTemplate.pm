package Tkg2::RescaleTemplate;

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
# $Date: 2005/08/04 20:37:03 $
# $Revision: 1.9 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(rescaleTemplate);
use Tkg2::Base qw(Show_Me_Internals);

use constant S2    => scalar 2;
use constant S1000 => scalar 1000;

print $::SPLASH "=";

# rescaleTemplate: the tk canvas plots everything except fonts? in
# pixels.  The scale of pixels per inch or the $canv->scaling, which 
# is in pixels per point (point = 1/72 inch) changes depending upon
# the resolutation of the monitor.  It is necessary to determine the
# current value of scaling (see StartTemplate) and then convert between
# it and the scaling that the template was last saved with.
sub rescaleTemplate {  # $template->rescaleTemplate($val1, $val2);
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $currentrunningscale) = @_;
   my $templatescale = $template->{-scaling};

   my $ratio = $currentrunningscale / $templatescale;
   #my $ratio = $templatescale / $currentrunningscale;
   ## Fix the scalable values in the main template
      # fix the scale on the template so it will be updated
      # and consistent with the rest of the changed values in
      # the template when template launched at another resolution
      # in the future.
      $template->{-scaling} = $currentrunningscale;
   ## Fix the scalable values in the -plots
   foreach my $plot ( @{$template->{-plots}} ) {
   
      my $xref = $plot->{-x};
      my @keys = qw(-numoffset -num2offset -laboffset -ticklength);
      map { $xref->{$_} = int($xref->{$_}*S1000*$ratio)/S1000 } @keys;
      #$xref->{-labfont}->{-size} *= $ratio;
      #$xref->{-numfont}->{-size} *= $ratio;
      
      my $yref = $plot->{-y};
      map { $yref->{$_} = int($yref->{$_}*S1000*$ratio)/S1000 } @keys;
      #$yref->{-labfont}->{-size} *= $ratio;
      #$yref->{-numfont}->{-size} *= $ratio;
      
      my $y2ref = $plot->{-y2};
      map { $y2ref->{$_} = int($y2ref->{$_}*S1000*$ratio)/S1000 } @keys;
      #$y2ref->{-labfont}->{-size} *= $ratio;
      #$y2ref->{-numfont}->{-size} *= $ratio;           
      
      my $eref = $plot->{-explanation};  
      
      # Occassionally, for reasons that remain obscure,
      # the coordinates of a hiden explanation become undef.
      # This could be due to user moving the explanation off the 
      # canvas to hide it instead of toggling Hide Explanation in
      # the PlotEditor.  In anycase, the following two conditionals
      # provide protection against undef calculations by centering
      # the explanation origin on the canvas.  Bill Krug, WI is 
      # the only user to have seen this.
      if(not defined $eref->{-xorigin}) {
         my $width  = $template->{-width};
            $width  = $::MW->fpixels("$width"."i");
         $eref->{-xorigin} = $width/S2;
      }
      if(not defined $eref->{-yorigin}) {
         my $height = $template->{-height};
            $height = $::MW->fpixels("$height"."i");
         $eref->{-yorigin} = $height/S2;
      }
      # End of the undef trap on explanation origin.
      
      @keys = qw(-linewidth -horzgap -xorigin -yorigin);
      map { $eref->{$_} = $::MW->fpixels($eref->{$_})
                          if($eref->{$_} =~ /i/io);
            $eref->{$_} *= $ratio
          } @keys;
      #$eref->{-font}->{-size} *= $ratio;
      
      @keys = qw(-xrmargin   -xlmargin   -yumargin   -ylmargin
                 -canvwidth  -canvheight -xpixels    -ypixels
                 -ymincanvas -ymaxcanvas -xmincanvas -xmaxcanvas
                 -plottitlexoffset -plottitleyoffset);
      map { $plot->{$_} = int($plot->{$_}*S1000*$ratio)/S1000 } @keys;
      #$plot->{-plottitlefont}->{-size} *= $ratio;
      
      
      foreach my $dataclass ( @{$plot->{-dataclass}} ) {
         foreach my $dataset ( @{ $dataclass->{-DATA}} ) {
            my $ref = $dataset->{-attributes};
            my $txref = $ref->{-text};
            # Wil Sadler (Sept 2004) experienced uninitialized value warnings for 
            # one of his plots that he was scripting together.  Lets just set undef
            # values to zero if they are not defined--minor hit in CPU time.
            # print STDERR "DEBUG: $txref->{-xoffset} $txref->{-yoffset} $ratio\n";
            $txref->{-xoffset} = 0 if(not defined $txref->{-xoffset});
            $txref->{-yoffset} = 0 if(not defined $txref->{-yoffset});
            $txref->{-xoffset} = int($txref->{-xoffset}*S1000*$ratio)/S1000;
            $txref->{-yoffset} = int($txref->{-yoffset}*S1000*$ratio)/S1000;
            #$txref->{-font}->{-size} *= $ratio;
            $ref->{-points}->{-size} =
               int($ref->{-points}->{-size}*S1000*$ratio)/S1000;
         }
      }
      
   }
   ## Fix the scalable values in the -annobox
      #foreach $anno (@{$template->{-annobox}}) {}
   ## Fix the scalable values in the -annoline
      foreach my $anno ( @{$template->{-annoline}} ) {
        map { $anno->{$_} = int($anno->{$_}*S1000*$ratio)/S1000 } (
                    qw(-x1 -x2 -y1 -y2 -arrow1 -arrow2 -arrow3) );
      }
   ## Fix the scalable values in the -annosymbol
      foreach my $anno ( @{$template->{-annosymbol}} ) {
        map { $anno->{$_} = int($anno->{$_}*S1000*$ratio)/S1000 }
                                  ( qw(-size -xorigin -yorigin) );
      }   
   ## Fix the scalable values in the -annotext
      foreach my $anno ( @{$template->{-annotext}} ) {
        map { $anno->{$_} = int($anno->{$_}*S1000*$ratio)/S1000 }
                                  ( qw(-xorigin -yorigin) );
        #$anno->{-font}->{-size} *= $ratio;
      }     
}

1;
