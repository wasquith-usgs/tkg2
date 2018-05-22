package Tkg2::Plot::BoxPlot::Editor::TailTab;

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
# $Date: 2006/09/15 15:42:24 $
# $Revision: 1.12 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK 
            $WHISKER_WIDTH
           );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_Tails _checkTails);

use Tkg2::Base qw(isNumber Message Show_Me_Internals  getDashList);

$WHISKER_WIDTH = undef;


print $::SPLASH "=";

sub _Tails {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
       
   my ($pw, $box, $template) = @_;
   
   my $tref = $box->{-tail};
   my $wref = $tref->{-whiskers};
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   $tref->{-dashstyle} = 'Solid' if(not defined $tref->{-dashstyle});
   # the above is for backwards compatability
   my @dashstyle = &getDashList(\$tref->{-dashstyle},$font);
   $wref->{-dashstyle} = 'Solid' if(not defined $wref->{-dashstyle});
   # the above is for backwards compatability
   my @dashstyle_whisk = &getDashList(\$wref->{-dashstyle},$font);

   my $f1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f2 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f3 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f4 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f5 = $pw->Frame->pack(-side => 'top', -fill => 'x');     
 
   $f1->Checkbutton(-text     => 'DoIt ',
                    -font     => $fontb,
                    -variable => \$tref->{-doit},
                    -onvalue  => 1,
                    -offvalue => 0)
      ->pack(-side => 'left'); 
      
   $f1->Label(-text => '  Type',
              -font => $fontb)
      ->pack(-side => 'left');  
      
   my @types = ( [ 'command' => 'Range',
                   -font     => $font,
                   -command  => sub { $tref->{-type} = 'Range'  } ],
                 [ 'command' => '1.5*IQR',
                   -font     => $font,
                   -command  => sub { $tref->{-type} = '1.5*IQR'} ],
                 [ 'command' => '3*IQR',
                   -font     => $font,
                   -command  => sub { $tref->{-type} = '3*IQR' } ]
               );  
   $f1->Menubutton(-textvariable => \$tref->{-type},
                   -font         => $fontb,
                   -width        => 8,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -tearoff      => 0,
                   -menuitems    => [ @types ] )
      ->pack(-side => 'left');
   $f1->Label(-text => '  IQR is the interquartile range.',
              -font => $font)
      ->pack(-side => 'left');
   
   
   $f2->Label(-text => 'Tail Width, Color, Style',
              -font => $fontb)
      ->pack(-side => 'left');      
   
   my $linewidth  = $tref->{-linewidth};
   my $_linewidth = sub { $linewidth = shift;
                          $tref->{-linewidth} = $linewidth;
                        };  
   my $whiskerwidth  = $wref->{-linewidth};
   my $_whiskerwidth = sub { $whiskerwidth = shift;
                             $wref->{-linewidth} = $whiskerwidth;
                           };
   my (@linewidth,@whiskerwidth);
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@linewidth, [ 'command' => $_,
                         -font     => $font,
                         -command  => [ $_linewidth, $_ ] ] );
      push(@whiskerwidth, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ $_whiskerwidth, $_ ] ] );
   }
   
   $f2->Menubutton(
      -textvariable => \$linewidth,
      -font         => $fontb,
      -width        => 6,
      -indicator    => 1,
      -relief       => 'ridge',
      -menuitems    => [ @linewidth ],
      -tearoff      => 0)
      ->pack(-side => 'left', -fill => 'x'); 

   my $pickedlinecolor   = $tref->{-linecolor};
   my $pickedlinecolorbg = $pickedlinecolor;
      $pickedlinecolor   = 'none'  if(not defined($pickedlinecolor)   );
      $pickedlinecolorbg = 'white' if(not defined($pickedlinecolorbg) ); 
      $pickedlinecolorbg = 'white' if( $pickedlinecolor eq 'black'    );  
   my $mb_linecolor;    
   my $_linecolor = sub { $pickedlinecolor = shift;
                          my $color   = $pickedlinecolor;
                          my $mbcolor = $pickedlinecolor;
                          $color      =  undef  if($color   eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'black');
                          $tref->{-linecolor} = $color;
                          $mb_linecolor->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor);
                        };     
   my $pickedwhiskercolor   = $wref->{-linecolor};
   my $pickedwhiskercolorbg = $pickedwhiskercolor;
      $pickedwhiskercolor   = 'none'  if(not defined($pickedwhiskercolor)   );
      $pickedwhiskercolorbg = 'white' if(not defined($pickedwhiskercolorbg) ); 
      $pickedwhiskercolorbg = 'white' if( $pickedwhiskercolor eq 'black'    );  
   my $mb_whiskercolor;    
   my $_whiskercolor = sub { $pickedwhiskercolor = shift;
                             my $color   = $pickedwhiskercolor;
                             my $mbcolor = $pickedwhiskercolor;
                             $color      =  undef  if($color   eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $wref->{-linecolor} = $color;
                             $mb_whiskercolor->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                          };     
   my (@linecolor,@whiskercolor);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@linecolor,  [ 'command' => $_,
                          -font     => $font,
                          -command  => [ \&$_linecolor,  $_ ] ] );
      push(@whiskercolor,  [ 'command' => $_,
                             -font     => $font,
                             -command  => [ \&$_whiskercolor,  $_ ] ] );
   }
   
   $mb_linecolor = $f2->Menubutton(
                      -textvariable => \$pickedlinecolor,
                      -font         => $fontb,
                      -width        => 12,
                      -indicator    => 1,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @linecolor ],
                      -background   => $pickedlinecolorbg,
                      -activebackground => $pickedlinecolorbg )
                      ->pack(-side => 'left');
  
   my $mb_dashstyle = $f2->Menubutton(
                          -textvariable => \$tref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @dashstyle ])
                          ->pack(-side => 'left');
  # WHISKERS
  $WHISKER_WIDTH = $template->pixel_to_inch($wref->{-width});
  $f3->Label(-text => "\nWhisker configuration",
             -font => $fontb)
     ->pack(-side => 'left');
  $f4->Checkbutton(-text     => 'DoIt ',
                   -font     => $fontb,
                   -variable => \$wref->{-doit},
                   -onvalue  => 1,
                   -offvalue => 0)
     ->pack(-side => 'left');    
     
  $f4->Label(-text => '  Whisker Width',
             -font => $fontb)
     ->pack(-side => 'left');
  $f4->Entry(-textvariable => \$WHISKER_WIDTH,
             -font         => $font,
             -background   => 'white',
             -width        => 12  )
     ->pack(-side => 'left');  
  
  $f5->Label(-text => 'Line Width, Color, Style',
             -font => $fontb)
     ->pack(-side => 'left'); 
  
  $f5->Menubutton(
      -textvariable => \$whiskerwidth,
      -font         => $fontb,
      -width        => 6,
      -indicator    => 1,
      -relief       => 'ridge',
      -menuitems    => [ @whiskerwidth ],
      -tearoff      => 0)
      ->pack(-side => 'left', -fill => 'x'); 

  $mb_whiskercolor = $f5->Menubutton(
                        -textvariable => \$pickedwhiskercolor,
                        -font         => $fontb,
                        -width        => 12,
                        -indicator    => 1,
                        -relief       => 'ridge',
                        -tearoff      => 0,
                        -menuitems    => [ @whiskercolor ],
                        -background   => $pickedwhiskercolorbg,
                        -activebackground => $pickedwhiskercolorbg )
                        ->pack(-side => 'left'); 

   my $mb_dashstyle2 = $f5->Menubutton(
                          -textvariable => \$wref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @dashstyle_whisk ])
                          ->pack(-side => 'left');


   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');
   
}



sub _checkTails {
   my ($box, $pe) = @_;
   
   my $wref = $box->{-tail}->{-whiskers};
   
   my ($size) = $WHISKER_WIDTH =~ m/([0-9.]+)/;
   if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $WHISKER_WIDTH = $size;
     $wref->{-width} = $pe->fpixels($size);
   }
   else {
     my $mess = "Invalid width for boxplot-tails-whisker\n";
     &Message($pe,'-generic', $mess);
     return 0;
   }
   return 1;
} 

1;
