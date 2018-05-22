package Tkg2::Plot::BoxPlot::Editor::ShowDataTab;

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
# $Date: 2006/09/17 01:52:22 $
# $Revision: 1.14 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK $DATA_SYMBOL_SIZE );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw( _ShowData _checkShowData );

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

$DATA_SYMBOL_SIZE = undef;

print $::SPLASH "=";


sub _ShowData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box, $template) = @_;
   
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
  
   my $dref = $box->{-show_data};
   
   $DATA_SYMBOL_SIZE = $template->pixel_to_inch($dref->{-size});
                        
   my $ptoutlinewidth  = $dref->{-outlinewidth};                        
   my $_ptoutlinewidth = sub { $ptoutlinewidth = shift;
                               $dref->{-outlinewidth} = $ptoutlinewidth;
                             };
   my @ptoutlinewidth;
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@ptoutlinewidth, [ 'command' => $_,
                              -font     => $font,
                              -command  => [ $_ptoutlinewidth, $_ ] ] );
   }
   
   

      
   my $pickedpointoutline   = $dref->{-outlinecolor};
   my $pickedpointoutlinebg = $pickedpointoutline;
      $pickedpointoutline   = 'none'  if(not defined($pickedpointoutline)   );
      $pickedpointoutlinebg = 'white' if(not defined($pickedpointoutlinebg) );
      $pickedpointoutlinebg = 'white' if( $pickedpointoutline eq 'black'    );         
   my $mb_pointoutline;
   my $_pointoutline = sub { $pickedpointoutline = shift;
                             my $color   = $pickedpointoutline;
                             my $mbcolor = $pickedpointoutline;
                             $color      =  undef  if($color   eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $dref->{-outlinecolor} = $color;
                             $mb_pointoutline->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                           };
                           
   my $pickedpointfill   = $dref->{-fillcolor};
   my $pickedpointfillbg = $pickedpointfill;
      $pickedpointfill   = 'none'  if(not defined($pickedpointfill)   );
      $pickedpointfillbg = 'white' if(not defined($pickedpointfillbg) );
      $pickedpointfillbg = 'white' if( $pickedpointfill eq 'black'    ); 
   my $mb_pointfill;
   my $_pointfill = sub { $pickedpointfill = shift;
                          my $color   = $pickedpointfill;
                          my $mbcolor = $pickedpointfill;
                          $color      =  undef  if($color   eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'black');
                          $dref->{-fillcolor} = $color;
                          $mb_pointfill->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor);
                        };      
                        
   my (@pointoutline, @pointfill);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@pointoutline, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointoutline, $_ ] ] );
      push(@pointfill,    [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointfill,    $_ ] ] );
   }
        

   
   # Symbology

   my @pointsymbol = (
                     [ 'command' => 'Circle',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =    'Circle'} ],
      
                     [ 'command' => 'Square',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =    'Square'} ],
      
                     [ 'command' => 'Triangle',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =  'Triangle'} ],

                     [ 'command' => 'Arrow',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =     'Arrow'} ],

                     [ 'command' => 'Phoenix',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =   'Phoenix'} ],

                     [ 'command' => 'ThinBurst',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =   'ThinBurst'} ],

                     [ 'command' => 'Burst',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =       'Burst'} ],

                     [ 'command' => 'FatBurst',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =    'FatBurst'} ],
      
                     [ 'command' => 'Cross',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =     'Cross'} ],
      
                     [ 'command' => 'Star',
                       -font     => $font,
      -command => sub { $dref->{-symbol} =      'Star'} ],
      
                     [ 'command' => 'Horz Bar',
                       -font     => $font,
      -command => sub { $dref->{-symbol} = 'Horz Bar' } ],
      
                     [ 'command' => 'Vert Bar',
                       -font     => $font,
      -command => sub { $dref->{-symbol} = 'Vert Bar' } ] );
    

  my $f_2 = $pw->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_2->Label(-text => "Symbology for showing the actual data:",
              -font => $fontb)
      ->pack(-side => 'left');
  
  my $f_3 = $pw->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_3->Checkbutton(-text     => 'DoIt ',
                     -font     => $fontb,
                     -variable => \$dref->{-doit},
                     -onvalue  => 1,
                     -offvalue => 0)
       ->pack(-side => 'left');
  $f_3->Radiobutton(-text     => 'first',
                    -font     => $fontb,
                    -variable => \$dref->{-plot_order},
                    -value    => 'first')
      ->pack(-side => 'left');
  $f_3->Label(-text => ' or ',
              -font => $fontb)
      ->pack(-side => 'left');
  $f_3->Radiobutton(-text     => 'last',
                    -font     => $fontb,
                    -variable => \$dref->{-plot_order},
                    -value    => 'last')
      ->pack(-side => 'left');
       
  my $f_4 = $pw->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_4->Menubutton(-textvariable => \$dref->{-symbol},
                     -font         => $fontb,
                     -width        => 8,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @pointsymbol ] )
        ->pack(-side => 'left');
        
               
   $f_4->Label(-text => ' Size',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $f_4->Entry(-textvariable => \$DATA_SYMBOL_SIZE,
                -font          => $font,
                -background   => 'white',
                -width        => 8  )
        ->pack(-side => 'left'); 
   $f_4->Label(-text => ' Edge',
               -font => $fontb)
        ->pack(-side => 'left'); 
   my $mb_ptoutlinewidth = $f_4->Menubutton(
                             -textvariable => \$ptoutlinewidth,
                             -font         => $fontb,
                             -width        => 6,
                             -indicator    => 1,
                             -relief       => 'ridge',
                             -menuitems    => [ @ptoutlinewidth ],
                             -tearoff      => 0)
                             ->pack(-side => 'left', -fill => 'x');      
   $f_4->Label(-text => ' Angle',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_4->Entry(-textvariable => \$dref->{-angle},
                -font         => $font,
                -background   => 'white',
                -width        => 4 )
        ->pack(-side => 'left');
    
   my $f_41 = $pw->Frame->pack(-side => 'top', -fill => 'x');   
   $f_41->Label(-text => '   Edge Color',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointoutline = $f_41->Menubutton(
                           -textvariable => \$pickedpointoutline,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @pointoutline ],
                           -background   => $pickedpointoutlinebg,
                           -activebackground => $pickedpointoutlinebg )
                           ->pack(-side => 'left');   
   $f_41->Label(-text => ' Fill',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointfill = $f_41->Menubutton(
                        -textvariable => \$pickedpointfill,
                        -font         => $fontb,
                        -width        => 12,
                        -indicator    => 1,
                        -relief       => 'ridge',
                        -tearoff      => 0,
                        -menuitems    => [ @pointfill ],
                        -background   => $pickedpointfillbg,
                        -activebackground => $pickedpointfillbg )
                        ->pack(-side => 'left');  
   
   my $exref = $box->{-explanation_settings};
   my $f_ex = $pw->Frame(-relief => 'groove',
                         -borderwidth => 4)
                 ->pack(-side => 'top', -expand => 1, -fill => 'both');
   my $f_51 = $f_ex->Frame->pack(-side => 'top', -fill => 'x');   
   $f_51->Label(-text => "\nSETTINGS FOR THE BOXPLOT EXPLANATION",
                -font => $fontb)
        ->pack(-side => "top");
   my $f_52 = $f_ex->Frame->pack(-side => 'top', -fill => 'x');
   $f_52->Label(-text => "Height or size parameter of boxplot explanation ",
                -font => $fontb)
        ->pack(-side => 'left');
   $f_52->Entry(-textvariable  => \$exref->{-size},
                -font         => $font,
                -background   => 'white',
                -width        => 6 )
         ->pack(-side => 'left');
   $f_52->Label(-text => " (inches)",
                -font => $fontb)
        ->pack(-side => 'left');
   my $f_53 = $f_ex->Frame->pack(-side => 'top', -fill => 'x');
   $f_53->Label(-text => "Extra spacing above the boxplot explanation     ",
                -font => $fontb)
        ->pack(-side => 'left');
   $f_53->Entry(-textvariable  => \$exref->{-spacing_top},
                -font         => $font,
                -background   => 'white',
                -width        => 6 )
         ->pack(-side => 'left');
   $f_53->Label(-text => " (inches)",
                -font => $fontb)
        ->pack(-side => 'left');
   # backwards compatability
   $exref->{-use_percent_sign} = 0 if(not exists $exref->{-use_percent_sign});
   my $f_54 = $f_ex->Frame->pack(-side => 'top', -fill => 'x');
   $f_54->Checkbutton(-text     => "Use percent sign (%) in explanation",
                      -font     => $font,
                      -variable => \$exref->{-use_percent_sign})
         ->pack(-side => 'left');
}


sub _checkShowData {
  my ($box, $pe) = @_;

  my $dref   = $box->{-show_data};
  my $mess;
  my ($size) = $DATA_SYMBOL_SIZE =~ m/([0-9.]+)/;
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $DATA_SYMBOL_SIZE = $size;
     $dref->{-size} = $pe->fpixels($size);
  }
  else {
     $mess = "Invalid symbol size for boxplot-show_data-symbology.";
     &Message($pe,'-generic', $mess);
     return 0;
  }
  
  my $exref = $box->{-explanation_settings};
     $exref->{-size} = '1.0i' if(not defined $exref->{-size});
          # BACKWARD COMPATABILITY: Tkg2 0.76 error trapped on undefined values.
  ($size) = $exref->{-size} =~ m/([0-9.]+)/;
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $exref->{-size} = $size;
  }
  else {
     $mess = "Invalid height parameter for boxplot explanation.";
     &Message($pe,'-generic', $mess);
     $exref->{-size} = "1i";
     return 0;
  }
  
  ($size) = $exref->{-spacing_top} =~ m/([0-9.]+)/;
     $exref->{-spacing_top} = '0.65i' if(not defined $exref->{-spacing_top});
          # BACKWARD COMPATABILITY: Tkg2 0.76 error trapped on undefined values.
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $exref->{-spacing_top} = $size;
  }
  else {
     $mess = "Invalid top spacing parameter for boxplot explanation.";
     &Message($pe,'-generic', $mess);
     $exref->{-spacing_top} = ".65i";
     return 0;
  }  
  
  return 1;
}

1;
