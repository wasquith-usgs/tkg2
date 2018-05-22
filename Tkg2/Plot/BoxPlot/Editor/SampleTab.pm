package Tkg2::Plot::BoxPlot::Editor::SampleTab;

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
# $Date: 2007/09/14 17:45:34 $
# $Revision: 1.13 $

use strict;

use Exporter;
use vars qw( @ISA
             @EXPORT_OK
             $SAMPLE_OFFSET
           );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_Sample  _checkSample);

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

$SAMPLE_OFFSET = undef;

print $::SPLASH "=";


sub _Sample {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box, $template) = @_;
   my $sref = $box->{-sample};
   
   my ($mb_fontcolor, $mb_format);
      
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
    
   my %format = ( free   => 'Free',
                  fixed  => 'Fixed',
                  sci    => 'Scientific',
                  sig    => 'Significant' ); 
 
      
   my @format = (
      [ 'command' => 'Free',
        -font     => $font,
        -command  => sub { $sref->{-format}  = 'free';
                           $mb_format->configure(
                                     -text => $format{ $sref->{-format} } );
                         } ],
      [ 'command' => 'Fixed',
        -font     => $font,
        -command  => sub { $sref->{-format} = 'fixed';
                           $mb_format->configure(
                                     -text => $format{ $sref->{-format} } );
                         } ],
      [ 'command' => 'Scientific',
        -font     => $font,
        -command  => sub { $sref->{-format}  = 'sci';
                           $mb_format->configure(
                                     -text => $format{ $sref->{-format} } );
                         } ],
      [ 'command' => 'Significant',
        -font     => $font,
        -command  => sub { $sref->{-format}  = 'sig';
                           $mb_format->configure(
                                     -text => $format{ $sref->{-format} } );
                         } ] );                       



   my $fontref = $sref->{-font};
   my ($fontfam, $fontwgt, $fontslant, $fontcolor) =
           ( $fontref->{-family},
             $fontref->{-weight},
             $fontref->{-slant},
             $fontref->{-color}  );
   my $_fontcolor = sub { $fontcolor = shift;
                          $fontref->{-color} = $fontcolor;
                          my $mbcolor = $fontcolor;
                          $mbcolor    = 'white' if($mbcolor eq 'black');
                          $mb_fontcolor->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor);
                        };
      
   
   my @fontcolors   = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      next if(/none/);
      push(@fontcolors,   [ 'command' => $_,
                            -font     => $font,
                            -command  => [ $_fontcolor,   $_ ] ] );
   }
 
   my $fontcolorbg = $fontcolor;
      $fontcolorbg = 'white' if($fontcolor eq 'black');
   my $_fontfam    = sub { $fontfam            = shift;
                           $fontref->{-family} = $fontfam;
                         };
   my $_fontwgt    = sub { $fontwgt            = shift;
                           $fontref->{-weight} = $fontwgt;
                         };
   my $_fontslant  = sub { $fontslant          = shift;
                           $fontref->{-slant}  = $fontslant;
                         };
   my @fontfam   = ();
   foreach ( @{$::TKG2_CONFIG{-FONTS}} ) {
      push(@fontfam, [ 'command' => $_,
                       -font     => $font,
                       -command  => [ $_fontfam, $_ ] ] );
   }
    
   my @fontwgt   = ();
   foreach ( qw(normal bold) ) {
      push(@fontwgt, [ 'command' => $_,
                       -font     => $font,
                       -command  => [ $_fontwgt, $_ ] ] );
   }               
   
   my @fontslant = ();
   foreach ( qw(roman italic) ) {
      push(@fontslant, [ 'command' => $_,
                         -font     => $font,
                         -command  => [ $_fontslant, $_ ] ] );
   }   
   
   
   my $f1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f1->Checkbutton(-text     => 'DoIt ',
                    -font     => $fontb,
                    -variable => \$sref->{-doit},
                    -onvalue  => 1,
                    -offvalue => 0)
      ->pack(-side => 'left');   
   $f1->Label(-text => ' Location:',
              -font => $fontb)
      ->pack(-side => 'left', -anchor => 'w');
   $f1->Radiobutton(-text     => 'Above/Left',
                    -font     => $fontb,
                    -variable => \$sref->{-location},
                    -value    => 'Above/Left')
      ->pack(-side => 'left', -fill => 'x');
   $f1->Radiobutton(-text     => 'Below/Right',
                    -font     => $fontb,
                    -variable => \$sref->{-location},
                    -value    => 'Below/Right')
      ->pack(-side => 'left', -fill => 'x');      
                    
   $f1->Label(-text => '  Offset',
              -font => $fontb)
      ->pack(-side => 'left', -anchor => 'w');
      
   $SAMPLE_OFFSET = $template->pixel_to_inch($sref->{-offset});
   
   $f1->Entry(-textvariable => \$SAMPLE_OFFSET,
              -font         => $font,
              -background   => 'white',
              -width        => 8 )
      ->pack(-side => 'left', -fill => 'x');   
      
   my $f2 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f2->Label(-text => 'Font, Size, Wgt, Slant, Color',
              -font => $fontb)
      ->pack(-side => 'top', -anchor => 'w');   
   $f2->Menubutton(-textvariable => \$fontfam,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -tearoff      => 0,
                   -menuitems    => [ @fontfam ],
                   -width        => 10)
      ->pack(-side => 'left');
   $f2->Entry(-textvariable => \$fontref->{-size},
              -font         => $font,
              -background   => 'white',
              -width        => 4  )
      ->pack(-side => 'left');
   $f2->Menubutton(-textvariable => \$fontwgt,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -tearoff      => 0,
                   -menuitems    => [ @fontwgt ],
                   -width        => 6)
      ->pack(-side => 'left');
   $f2->Menubutton(-textvariable => \$fontslant,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -tearoff      => 0,
                   -menuitems    => [ @fontslant ],
                   -width        => 6)
      ->pack(-side => 'left');   
   $mb_fontcolor = $f2->Menubutton(
                      -textvariable => \$fontcolor,
                      -font         => $fontb,
                      -width        => 12,
                      -indicator    => 1, 
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @fontcolors ],
                      -background   => $fontcolorbg,
                      -activebackground => $fontcolorbg)        
                      ->pack(-side => 'left');
                

   
   my $f3 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f3->Label(-text => 'Format and Decimals',
              -font => $fontb)
      ->pack(-side => 'left');
   $mb_format = $f3->Menubutton(
                   -text      => $format{$sref->{-format}},
                   -font      => $fontb,
                   -indicator => 1,
                   -tearoff   => 0,
                   -relief    => 'ridge',
                   -menuitems => [ @format ],
                   -width     => 12 )
                   ->pack(-side => 'left'); 
   $f3->Entry(-textvariable => \$sref->{-decimal},
              -font         => $font,
              -background   => 'white',
              -width        => 6  )
      ->pack(-side => 'left');   
      
   
   my $f4 = $pw->Frame->pack(-side => 'top', -fil => 'x');
   $f4->Checkbutton(-text     => 'Commify ',
                    -font     => $fontb,
                    -variable => \$sref->{-commify},
                    -onvalue  => 1,
                    -offvalue => 0)
      ->pack(-side => 'left'); 
   $f4->Checkbutton(-text     => 'Stack Text ',
                    -font     => $fontb,
                    -variable => \$fontref->{-stackit},
                    -onvalue  => 1,
                    -offvalue => 0,
                    -command  =>
                    sub { if($fontref->{-stackit}) {
                             $fontref->{-parenthesis} = 0;
                          }
                        } )
      ->pack(-side => 'left'); 
   $f4->Checkbutton(-text     => 'Use Parenthesis',
                    -font     => $fontb,
                    -variable => \$fontref->{-parenthesis},
                    -onvalue  => 1,
                    -offvalue => 0,
                    -command  =>
                    sub { if($fontref->{-parenthesis}) { 
                             $fontref->{-stackit} = 0;
                          }
                        } )
      ->pack(-side => 'left');

   my $f5 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f5->Label(-text => '  Angle (for MetaPost)',
               -font => $fontb)
       ->pack(-side => 'left', -anchor => 'w');
   $f5->Entry(-textvariable => \$fontref->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left', -fill => 'x');


   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');      
}




sub _checkSample {
   my ($box, $pe) = @_;
   
   my $sref = $box->{-sample};
  
   my ($size) = $SAMPLE_OFFSET =~ m/([0-9.]+)/;
   if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $SAMPLE_OFFSET = $size;
     $sref->{-offset} = $pe->fpixels($size);
   }
   else {
     my $mess = "Invalid offset for boxplot-sample_size\n";
     &Message($pe,'-generic', $mess);
     return 0;
   }   
   return 1;
}  

1;
