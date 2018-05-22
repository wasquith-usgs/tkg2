package Tkg2::Plot::BoxPlot::Draw::DrawText;

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
# $Date: 2007/09/14 17:45:29 $
# $Revision: 1.14 $

use strict;

use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA       = qw( Exporter );
@EXPORT_OK = qw( _drawText );

use Tkg2::Base qw(Show_Me_Internals isNumber commify deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAnnoTextMetaPost);


print $::SPLASH "=";


sub _drawText {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($low_limit, $up_limit, $boxdata, $plot, $canv, $x, $y,
       $tag, $boxstyle, $limits, $real_limits) = @_;

   my %para = %{ $boxstyle->{-sample} };
    
   return 0 unless($para{-doit});
   
   my $orient = $boxstyle->{-orientation};
   my $text   = $boxdata->{-number_samples};
   
   my $ftref = $para{-font};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font  = $canv->fontCreate($tag."specialplotfont",
                      -family => $ftref->{-family},
                      -size   => ($ftref->{-size}*
                                  $::TKG2_ENV{-SCALING}*
                                  $::TKG2_CONFIG{-ZOOM}),
                      -weight => $ftref->{-weight},
                      -slant  => $ftref->{-slant} );
      
   my $numcommify = $para{-commify};
   my $numformat  = $para{-format};
   my $numdecimal = $para{-decimal};
   my $format;
   
   my $style  = $para{-location};
   my $offset = $para{-offset};
   
   if(defined($text) and &isNumber($text)) { # consider formatting only if number
      unless($numformat eq 'free') {
         FORMAT: {
            $format = "%0.$numdecimal"."e", last FORMAT if($numformat eq 'sci');
            $format = "%0.$numdecimal"."f", last FORMAT if($numformat eq 'fixed');
            $format = "%0.$numdecimal"."g", last FORMAT if($numformat eq 'sig');
         }
         $text = sprintf("$format", $text);
      }
      $text = &commify($text) if($numcommify);
   }
   
   $text =~ s/(.)/$1\n/g if($ftref->{-stackit});
   return 0 unless( defined $text );
   
   $text = "(".$text.")" if( $ftref->{-parenthesis}
                                      and
                             not $ftref->{-stackit} );
                            
   # Finished preparing the text string
   
   # now determine the coordinates for the text
   my ($r_xmin, $r_ymin, $r_xmax, $r_ymax) = @$real_limits;
   
   my $xref   = $plot->{-x};
   my $yref   = $plot->{-y};
   my $xtype  = $xref->{-type};
   my $ytype  = $yref->{-type};
   my $revx   = $xref->{-reverse};
   my $revy   = $yref->{-reverse};
   
   my ($newx, $newy);  
   my $anchor;
       
   if($orient eq 'vertical') {
      $newy = ($style =~ /above/io) ? $up_limit : $low_limit;
      # newy could remain undefined if the sample is too small to
      # have upper and lower limits (???) -- set to the middle of the plot.
      $newy = ($r_ymin+$r_ymax)/2 if(not defined $newy);
      if($style =~ /above/io) {
         $anchor = ($revy) ? 'n' : 's';
      }
      else {
         $anchor = ($revy) ? 's' : 'n';
      }
      #$anchor = ($style =~ /above/io and not $revy) ? 's' : 'n';
      $newy   = ($newy < $r_ymin ) ? $r_ymin :
                ($newy > $r_ymax ) ? $r_ymax : $newy; 
      $newy   = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $newy); 
      $newy  += ($style =~ /above/io) ? -$offset : $offset;       
      $newy   = $plot->revAxis('-y',$newy) if($revy);
      
      $newx = $x;
   }
   else {
      $newx = ($style =~ /above/io) ? $up_limit : $low_limit;
      # newx could remain undefined if the sample is too small to
      # have upper and lower limits (???) -- set to the middle of the plot.
      $newx = ($r_xmin+$r_xmax)/2 if(not defined $newx);
      if($style =~ /above/io) {
         $anchor = ($revy) ? 'w' : 'e';
      }
      else {
         $anchor = ($revy) ? 'e' : 'w';
      }
      $newx   = ($newx < $r_xmin ) ? $r_xmin :
                ($newx > $r_xmax ) ? $r_xmax : $newx; 
      $newx   = $plot->transReal2CanvasGLOBALS('X', $ytype, 1, $newx); 
      $newx  += ($style =~ /above/io) ? $offset : -$offset;    
      $newx   = $plot->revAxis('-x',$newx) if($revx);
        
      $newy = $y;
   }
   
   # finally draw the text
   $canv->createText($newx,$newy,
                     -text   => $text,
                     -font   => $font,
                     -anchor => $anchor, 
                     -fill   => $ftref->{-color},
                     -tags   => $tag);
   createAnnoTextMetaPost($newx,$newy,
                          {-text => $text,
                           -fill => $ftref->{-color},
                           -anchor => $anchor,
                           -family => $ftref->{-family},
                           -weight => $ftref->{-weight},
                           -size => $ftref->{-size},
                           -slant => $ftref->{-slant},
                           -angle => $ftref->{-rotation},});

  $canv->fontDelete($tag."specialplotfont"); 
  return 1;
}

1;
