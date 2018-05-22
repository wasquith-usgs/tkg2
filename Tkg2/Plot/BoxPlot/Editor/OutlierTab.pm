package Tkg2::Plot::BoxPlot::Editor::OutlierTab;

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
# $Revision: 1.13 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK
            $TYPE1_SYMBOL_SIZE
            $TYPE2_SYMBOL_SIZE );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_Outliers _checkOutliers);

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

$TYPE1_SYMBOL_SIZE    = undef;
$TYPE2_SYMBOL_SIZE    = undef;

print $::SPLASH "=";


sub _Outliers {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box, $template) = @_;
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
  
   
   my $o1ref = $box->{-type1_outliers};
   my $o2ref = $box->{-type2_outliers};
   
   $TYPE1_SYMBOL_SIZE = $template->pixel_to_inch($o1ref->{-size});
   $TYPE2_SYMBOL_SIZE = $template->pixel_to_inch($o2ref->{-size});
   
   
   # Symbology
   my $_symbology = sub {
      my $ref = shift;
      return (
                     [ 'command' => 'Circle',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =    'Circle'} ],
      
                     [ 'command' => 'Square',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =    'Square'} ],
      
                     [ 'command' => 'Triangle',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =  'Triangle'} ],

                     [ 'command' => 'Arrow',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =     'Arrow'} ],

                     [ 'command' => 'Phoenix',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =   'Phoenix'} ],

                     [ 'command' => 'ThinBurst',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =   'ThinBurst'} ],

                     [ 'command' => 'Burst',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =       'Burst'} ],

                     [ 'command' => 'FatBurst',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =    'FatBurst'} ],
      
                     [ 'command' => 'Cross',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =     'Cross'} ],
      
                     [ 'command' => 'Star',
                       -font     => $font,
      -command => sub { $ref->{-symbol} =      'Star'} ],
      
                     [ 'command' => 'Horz Bar',
                       -font     => $font,
      -command => sub { $ref->{-symbol} = 'Horz Bar' } ],
      
                     [ 'command' => 'Vert Bar',
                       -font     => $font,
      -command => sub { $ref->{-symbol} = 'Vert Bar' } ] );
   };
   my @type1symbols = &$_symbology($o1ref);
   my @type2symbols = &$_symbology($o2ref);
   
   my $o1ptoutlinewidth  = $o1ref->{-outlinewidth};                        
   my $_o1ptoutlinewidth = sub { $o1ptoutlinewidth = shift;
                                 $o1ref->{-outlinewidth} = $o1ptoutlinewidth;
                               };
   my $o2ptoutlinewidth  = $o2ref->{-outlinewidth};                        
   my $_o2ptoutlinewidth = sub { $o2ptoutlinewidth = shift;
                                 $o2ref->{-outlinewidth} = $o2ptoutlinewidth;
                               };
   my (@o1ptoutlinewidth, @o2ptoutlinewidth);
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@o1ptoutlinewidth, [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_o1ptoutlinewidth, $_ ] ] );
      push(@o2ptoutlinewidth, [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_o2ptoutlinewidth, $_ ] ] );
   }
    
   
   my $o1pickedpointoutline   = $o1ref->{-outlinecolor};
   my $o1pickedpointoutlinebg = $o1pickedpointoutline;
      $o1pickedpointoutline   = 'none'  if(not defined($o1pickedpointoutline)   );
      $o1pickedpointoutlinebg = 'white' if(not defined($o1pickedpointoutlinebg) );
      $o1pickedpointoutlinebg = 'white' if( $o1pickedpointoutline eq 'black'    );         
   my $o1mb_pointoutline;
   my $_o1pointoutline = sub { $o1pickedpointoutline = shift;
                               my $color   = $o1pickedpointoutline;
                               my $mbcolor = $o1pickedpointoutline;
                               $color      =  undef  if($color   eq 'none' );
                               $mbcolor    = 'white' if($mbcolor eq 'none' );
                               $mbcolor    = 'white' if($mbcolor eq 'black');
                               $o1ref->{-outlinecolor} = $color;
                               $o1mb_pointoutline->configure(-background       => $mbcolor,
                                                             -activebackground => $mbcolor);
                             };
                           
   my $o1pickedpointfill   = $o1ref->{-fillcolor};
   my $o1pickedpointfillbg = $o1pickedpointfill;
      $o1pickedpointfill   = 'none'  if(not defined($o1pickedpointfill)   );
      $o1pickedpointfillbg = 'white' if(not defined($o1pickedpointfillbg) );
      $o1pickedpointfillbg = 'white' if( $o1pickedpointfill eq 'black'    ); 
   my $o1mb_pointfill;
   my $_o1pointfill = sub { $o1pickedpointfill = shift;
                            my $color   = $o1pickedpointfill;
                            my $mbcolor = $o1pickedpointfill;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $o1ref->{-fillcolor} = $color;
                            $o1mb_pointfill->configure(-background       => $mbcolor,
                                                     -activebackground => $mbcolor);
                          };  
                          
                              
   my $o2pickedpointoutline   = $o2ref->{-outlinecolor};
   my $o2pickedpointoutlinebg = $o2pickedpointoutline;
      $o2pickedpointoutline   = 'none'  if(not defined($o2pickedpointoutline)   );
      $o2pickedpointoutlinebg = 'white' if(not defined($o2pickedpointoutlinebg) );
      $o2pickedpointoutlinebg = 'white' if( $o2pickedpointoutline eq 'black'    );         
   my $o2mb_pointoutline;
   my $_o2pointoutline = sub { $o2pickedpointoutline = shift;
                               my $color   = $o2pickedpointoutline;
                               my $mbcolor = $o2pickedpointoutline;
                               $color      =  undef  if($color   eq 'none' );
                               $mbcolor    = 'white' if($mbcolor eq 'none' );
                               $mbcolor    = 'white' if($mbcolor eq 'black');
                               $o2ref->{-outlinecolor} = $color;
                               $o2mb_pointoutline->configure(-background       => $mbcolor,
                                                             -activebackground => $mbcolor);
                             };
                           
   my $o2pickedpointfill   = $o2ref->{-fillcolor};
   my $o2pickedpointfillbg = $o2pickedpointfill;
      $o2pickedpointfill   = 'none'  if(not defined($o2pickedpointfill)   );
      $o2pickedpointfillbg = 'white' if(not defined($o2pickedpointfillbg) );
      $o2pickedpointfillbg = 'white' if( $o2pickedpointfill eq 'black'    ); 
   my $o2mb_pointfill;
   my $_o2pointfill = sub { $o2pickedpointfill = shift;
                            my $color   = $o2pickedpointfill;
                            my $mbcolor = $o2pickedpointfill;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $o2ref->{-fillcolor} = $color;
                            $o2mb_pointfill->configure(-background       => $mbcolor,
                                                     -activebackground => $mbcolor);
                          };                           
   my (@o1pointoutline, @o1pointfill,@o2pointoutline, @o2pointfill);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@o1pointoutline, [ 'command' => $_,
                              -font     => $font,
                              -command  => [ \&$_o1pointoutline, $_ ] ] );
      push(@o1pointfill,    [ 'command' => $_,
                              -font     => $font,
                              -command  => [ \&$_o1pointfill,    $_ ] ] );
      push(@o2pointoutline, [ 'command' => $_,
                              -font     => $font,
                              -command  => [ \&$_o2pointoutline, $_ ] ] );
      push(@o2pointfill,    [ 'command' => $_,
                              -font     => $font,
                              -command  => [ \&$_o2pointfill,    $_ ] ] );
   }
   
   
   # TYPE 1 OUTLIERS
   my $fo1_1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $fo1_1->Label(-text => "Type 1 Outliers:",
                 -font => $fontb)
         ->pack(-side => 'left');
   $fo1_1->Label(-text => "$o1ref->{-description}",
                 -font => $font)
         ->pack(-side => 'left');   
   my $fo1_2 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $fo1_2->Checkbutton(-text     => 'DoIt ',
                       -font     => $fontb,
                       -variable => \$o1ref->{-doit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $fo1_2->Menubutton(-textvariable => \$o1ref->{-symbol},
                      -font         => $fontb,
                      -width        => 8,
                      -indicator    => 1,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @type1symbols ] )
         ->pack(-side => 'left');
        
               
   $fo1_2->Label(-text => ' Size',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $fo1_2->Entry(-textvariable => \$TYPE1_SYMBOL_SIZE,
                 -font          => $font,
                 -background   => 'white',
                 -width        => 8  )
         ->pack(-side => 'left'); 
   $fo1_2->Label(-text => ' Edge',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   my $o1mb_ptoutlinewidth = $fo1_2->Menubutton(
                                   -textvariable => \$o1ptoutlinewidth,
                                   -font         => $fontb,
                                   -width        => 6,
                                   -indicator    => 1,
                                   -relief       => 'ridge',
                                   -menuitems    => [ @o1ptoutlinewidth ],
                                   -tearoff      => 0)
                                   ->pack(-side => 'left', -fill => 'x');      
   $fo1_2->Label(-text => ' Angle',
                 -font => $fontb)
         ->pack(-side => 'left');
   $fo1_2->Entry(-textvariable => \$o1ref->{-angle},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 4 )
         ->pack(-side => 'left');

   my $fo1_3 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $fo1_3->Label(-text => '   Edge Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $o1mb_pointoutline = $fo1_3->Menubutton(
                              -textvariable => \$o1pickedpointoutline,
                              -font         => $fontb,
                              -width        => 12,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -tearoff      => 0,
                              -menuitems    => [ @o1pointoutline ],
                              -background   => $o1pickedpointoutlinebg,
                              -activebackground => $o1pickedpointoutlinebg )
                              ->pack(-side => 'left');   
   $fo1_3->Label(-text => ' Fill',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $o1mb_pointfill = $fo1_3->Menubutton(
                           -textvariable => \$o1pickedpointfill,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @o1pointfill ],
                           -background   => $o1pickedpointfillbg,
                           -activebackground => $o1pickedpointfillbg )
                           ->pack(-side => 'left');  
   
   # TYPE 2 OUTLIERS
   my $fo2_1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $fo2_1->Label(-text => "Type 2 Outliers:",
                 -font => $fontb)
         ->pack(-side => 'left');
   $fo2_1->Label(-text => "$o2ref->{-description}",
                 -font => $font)
         ->pack(-side => 'left');
   
   my $fo2_2 = $pw->Frame->pack(-side => 'top', -fill => 'x');       
   $fo2_2->Checkbutton(-text     => 'DoIt ',
                       -font     => $fontb,
                       -variable => \$o2ref->{-doit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $fo2_2->Menubutton(-textvariable => \$o2ref->{-symbol},
                      -font         => $fontb,
                      -width        => 8,
                      -indicator    => 1,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @type2symbols ] )
         ->pack(-side => 'left');
        
               
   $fo2_2->Label(-text => ' Size',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $fo2_2->Entry(-textvariable => \$TYPE2_SYMBOL_SIZE,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 8  )
         ->pack(-side => 'left'); 
   $fo2_2->Label(-text => ' Edge',
                -font => $fontb)
         ->pack(-side => 'left'); 
   my $o2mb_ptoutlinewidth = $fo2_2->Menubutton(
                                   -textvariable => \$o2ptoutlinewidth,
                                   -font         => $fontb,
                                   -width        => 6,
                                   -indicator    => 1,
                                   -relief       => 'ridge',
                                   -menuitems    => [ @o2ptoutlinewidth ],
                                   -tearoff      => 0)
                                   ->pack(-side => 'left', -fill => 'x');      
   $fo2_2->Label(-text => ' Angle',
                 -font => $fontb)
         ->pack(-side => 'left');
   $fo2_2->Entry(-textvariable => \$o2ref->{-angle},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 4 )
         ->pack(-side => 'left');

   my $fo2_3 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $fo2_3->Label(-text => '   Edge Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $o2mb_pointoutline = $fo2_3->Menubutton(
                              -textvariable => \$o2pickedpointoutline,
                              -font         => $fontb,
                              -width        => 12,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -tearoff      => 0,
                              -menuitems    => [ @o2pointoutline ],
                              -background   => $o2pickedpointoutlinebg,
                              -activebackground => $o2pickedpointoutlinebg )
                              ->pack(-side => 'left');   
   $fo2_3->Label(-text => ' Fill',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $o2mb_pointfill = $fo2_3->Menubutton(
                           -textvariable => \$o2pickedpointfill,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @o2pointfill ],
                           -background   => $o2pickedpointfillbg,
                           -activebackground => $o2pickedpointfillbg )
                           ->pack(-side => 'left');  

   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');
   
}


sub _checkOutliers {
  my ($box, $pe) = @_;

  my $o1ref   = $box->{-type1_outliers};
  my $o2ref   = $box->{-type2_outliers};
  
  my ($size) = $TYPE1_SYMBOL_SIZE =~ m/([0-9.]+)/;
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $TYPE1_SYMBOL_SIZE = $size;
     $o1ref->{-size} = $pe->fpixels($size);
  }
  else {
     my $mess = "Invalid symbol size for boxplot-type1_outliers\n";
     &Message($pe,'-generic', $mess);
     return 0;
  }
  
  $size = undef;

  ($size) = $TYPE2_SYMBOL_SIZE =~ m/([0-9.]+)/;
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $TYPE2_SYMBOL_SIZE = $size;
     $o2ref->{-size} = $pe->fpixels($size);
  }
  else {
     my $mess = "Invalid symbol size for boxplot-type2_outliers\n";
     &Message($pe,'-generic', $mess);
     return 0;
  }
  
  return 1;
}



1;
