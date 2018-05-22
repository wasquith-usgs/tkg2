package Tkg2::DataMethods::Set::DrawDataEditor;

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
# $Date: 2007/09/07 18:20:37 $
# $Revision: 1.52 $

use strict;
use vars qw(@ISA @EXPORT_OK $LAST_PAGE_VIEWED $EDITOR);
use Exporter;
use SelfLoader;
use Tk::NoteBook;
use Tkg2::Help::Help;
use Tkg2::Base qw(Message isNumber Show_Me_Internals getDashList);

@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(DrawDataEditor);          

$LAST_PAGE_VIEWED = 'page1';
$EDITOR = "";

print $::SPLASH "=";

1;
#__DATA__
# DrawDataEditor
# This dialog is the interface for configuring the plotting style of the
# various plot types.  The point and line symbology can be changed.  The 
# formating and offsets of text or annontation plots can be altered etc.
# This dialog is really for Plot2D objects, yet it is also intimately tied
# with the data.  WHA is uncertain whether a new editor will have to be 
# developed for more complicated future plots such as box or stiff.  This is
# a BIG dialog box, sorry!          
sub DrawDataEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $data, $canv, $template, $plot) = @_;
   my ($mb_pointoutline,   $mb_lineoutline      );
   my ($mb_linedashstyle);
   my ($mb_pointfill,      $mb_shadecolor       );
   my ($mb_ptoutlinewidth, $mb_lineoutlinewidth );
   my ($mb_barcolor,       $mb_baroutlinewidth  );
   my ($mb_baroutline, $mb_blankcolor);
   my ($mb_rugxlinewidth, $mb_rugylinewidth);
   my ($mb_rugxlinecolor, $mb_rugylinecolor);
   
   my $attr       = $data->{-attributes};
  
   my $pointref   = $attr->{-points};
   my $lineref    = $attr->{-lines};
   my $shaderef   = $attr->{-shade};
   my $barref     = $attr->{-bars};
   my $textref    = $attr->{-text};
   my $specialref = $attr->{-special_plot};
   
   
   # Backwards compatibility for rug plots--May 2005
   $pointref->{-rugx}->{-linewidth} = '0.005i'
         if(not defined $pointref->{-rugx}->{-linewidth});
   $pointref->{-rugy}->{-linewidth} = '0.005i'
         if(not defined $pointref->{-rugy}->{-linewidth});   
   $pointref->{-rugx}->{-linecolor} = 'black'
         if(not defined $pointref->{-rugx}->{-linecolor});
   $pointref->{-rugy}->{-linecolor} = 'black'
         if(not defined $pointref->{-rugy}->{-linecolor});
   $pointref->{-rugx}->{-size} = '0.15i'
         if(not defined $pointref->{-rugx}->{-size});
   $pointref->{-rugy}->{-size} = '0.15i'
         if(not defined $pointref->{-rugy}->{-size});


   # VERSION 1.01+ BACKWARDS COMPATABILITY
   $lineref->{-arrow} = 'none' if(not defined($lineref->{-arrow} ) );
   $lineref->{-arrow1} = 10    if(not defined($lineref->{-arrow1}) );
   $lineref->{-arrow2} = 17    if(not defined($lineref->{-arrow2}) );
   $lineref->{-arrow3} = 8     if(not defined($lineref->{-arrow3}) );
   # END BACKWARDS COMPATABILITY

	 
   my $pointdoit  = $pointref->{-doit};
   my $rugx       = $pointref->{-rugx};
   my $rugy       = $pointref->{-rugy};
   my $rugxdoit   = $rugx->{-doit};
   my $rugydoit   = $rugy->{-doit};
   my $rugxboth   = $rugx->{-both};
   my $rugyboth   = $rugy->{-both};
   my $rugxnegate = $rugx->{-negate};
   my $rugynegate = $rugy->{-negate};
   
   
   my $linedoit   = $lineref->{-doit};
   my $stepit     = $lineref->{-stepit};
   my $arrow1     = $lineref->{-arrow1};
   my $arrow2     = $lineref->{-arrow2};
   my $arrow3     = $lineref->{-arrow3};
   foreach ($arrow1, $arrow2, $arrow3) { $_ = $template->pixel_to_inch($_); }

   my $shadedoit  = $shaderef->{-doit};
   my $bardoit    = $barref->{-doit};
   
   my ($finishsub, $pe);
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
 
   my $pw = $canv->parent;
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   $pe = $pw->Toplevel(-title => 'Edit Data Drawing Styles');
   $EDITOR = $pe;
   $pe->resizable(0,0);   
   my @pointsymbol = (
                     [ 'command' => 'Circle',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =    'Circle'} ],
      
                     [ 'command' => 'Square',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =    'Square'} ],
      
                     [ 'command' => 'Triangle',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =  'Triangle'} ],

                     [ 'command' => 'Arrow',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =     'Arrow'} ],

                     [ 'command' => 'Phoenix',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =   'Phoenix'} ],

                     [ 'command' => 'ThinBurst',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} = 'ThinBurst'} ],

                     [ 'command' => 'Burst',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =     'Burst'} ],

                     [ 'command' => 'FatBurst',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =  'FatBurst'} ],
            
                     [ 'command' => 'Cross',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =     'Cross'} ],
      
                     [ 'command' => 'Star',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} =      'Star'} ],
      
                     [ 'command' => 'Horz Bar',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} = 'Horz Bar' } ],
      
                     [ 'command' => 'Vert Bar',
                       -font     => $font,
      -command => sub { $pointref->{-symbol} = 'Vert Bar' } ] );
  
   $lineref->{-dashstyle} = 'Solid' if(not defined $lineref->{-dashstyle});
   # the above is for backwards compatability
   my @linedashstyle = &getDashList(\$lineref->{-dashstyle},$font);

   my $pickedpointoutline   = $pointref->{-outlinecolor};
   my $pickedpointoutlinebg = $pickedpointoutline;
      $pickedpointoutline   = 'none'  if(not defined $pickedpointoutline    );
      $pickedpointoutlinebg = 'white' if(not defined $pickedpointoutlinebg  );
      $pickedpointoutlinebg = 'white' if( $pickedpointoutline eq 'black'    );         
   my $_pointoutline = sub { $pickedpointoutline = shift;
                             my $color   = $pickedpointoutline;
                             my $mbcolor = $pickedpointoutline;
                             $color      =  undef  if($color   eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $pointref->{-outlinecolor} = $color;
                             $mb_pointoutline->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                           };
			   
   my $pickedrugxlinecolor   = $rugx->{-linecolor};
   my $pickedrugxlinecolorbg = $pickedrugxlinecolor;
      $pickedrugxlinecolor   = 'none'  if(not defined $pickedrugxlinecolor    );
      $pickedrugxlinecolorbg = 'white' if(not defined $pickedrugxlinecolorbg  ); 
      $pickedrugxlinecolorbg = 'white' if( $pickedrugxlinecolor eq 'black'    );      
   my $_rugxlinecolor = sub { $pickedrugxlinecolor = shift;
                            my $color   = $pickedrugxlinecolor;
                            my $mbcolor = $pickedrugxlinecolor;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $rugx->{-linecolor} = $color;
                            $mb_rugxlinecolor->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                          };                     


   my $pickedrugylinecolor   = $rugy->{-linecolor};
   my $pickedrugylinecolorbg = $pickedrugylinecolor;
      $pickedrugylinecolor   = 'none'  if(not defined $pickedrugylinecolor    );
      $pickedrugylinecolorbg = 'white' if(not defined $pickedrugylinecolorbg  ); 
      $pickedrugylinecolorbg = 'white' if( $pickedrugylinecolor eq 'black'    );      
   my $_rugylinecolor = sub { $pickedrugylinecolor = shift;
                            my $color   = $pickedrugylinecolor;
                            my $mbcolor = $pickedrugylinecolor;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $rugy->{-linecolor} = $color;
                            $mb_rugylinecolor->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                          };                     


   my $pickedlineoutline   = $lineref->{-linecolor};
   my $pickedlineoutlinebg = $pickedlineoutline;
      $pickedlineoutline   = 'none'  if(not defined $pickedlineoutline    );
      $pickedlineoutlinebg = 'white' if(not defined $pickedlineoutlinebg  ); 
      $pickedlineoutlinebg = 'white' if( $pickedlineoutline eq 'black'    );      
   my $_lineoutline = sub { $pickedlineoutline = shift;
                            my $color   = $pickedlineoutline;
                            my $mbcolor = $pickedlineoutline;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $lineref->{-linecolor} = $color;
                            $mb_lineoutline->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                          };                     

   my $pickedpointfill   = $pointref->{-fillcolor};
   my $pickedpointfillbg = $pickedpointfill;
      $pickedpointfill   = 'none'  if(not defined $pickedpointfill   );
      $pickedpointfillbg = 'white' if(not defined $pickedpointfillbg );
      $pickedpointfillbg = 'white' if( $pickedpointfill eq 'black'   ); 
   my $_pointfill = sub { $pickedpointfill = shift;
                          my $color   = $pickedpointfill;
                          my $mbcolor = $pickedpointfill;
                          $color      =  undef  if($color   eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'black');
                          $pointref->{-fillcolor} = $color;
                          $mb_pointfill->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor);
                        };      

   my $pickedbarcolor   = $barref->{-fillcolor};
   my $pickedbarcolorbg = $pickedbarcolor;
      $pickedbarcolor   = 'none'  if(not defined $pickedbarcolor    );
      $pickedbarcolorbg = 'white' if(not defined $pickedbarcolorbg  ); 
      $pickedbarcolorbg = 'white' if( $pickedbarcolor eq 'black'    ); 
   my $_barcolor = sub { $pickedbarcolor = shift;
                         my $color   = $pickedbarcolor;
                         my $mbcolor = $pickedbarcolor;
                         $color      =  undef  if($color   eq 'none' );
                         $mbcolor    = 'white' if($mbcolor eq 'none' );
                         $mbcolor    = 'white' if($mbcolor eq 'black');
                         $barref->{-fillcolor} = $color;
                         $mb_barcolor->configure(-background       => $mbcolor,
                                                 -activebackground => $mbcolor);
                       }; 

   my $pickedbaroutline   = $barref->{-outlinecolor};
   my $pickedbaroutlinebg = $pickedbaroutline;
      $pickedbaroutline   = 'none'  if(not defined $pickedbaroutline    );
      $pickedbaroutlinebg = 'white' if(not defined $pickedbaroutlinebg  ); 
      $pickedbaroutlinebg = 'white' if( $pickedbaroutline eq 'black'    ); 
   my $_baroutline = sub { $pickedbaroutline = shift;
                           my $color   = $pickedbaroutline;
                           my $mbcolor = $pickedbaroutline;
                           $color   =  undef  if($color   eq 'none' );
                           $mbcolor = 'white' if($mbcolor eq 'none' );
                           $mbcolor = 'white' if($mbcolor eq 'black');
                           $barref->{-outlinecolor} = $color;
                           $mb_baroutline->configure(-background       => $mbcolor,
                                                     -activebackground => $mbcolor);
                         }; 

   my $pickedshadecolor   = $shaderef->{-fillcolor};
   my $pickedshadecolorbg = $pickedshadecolor;
      $pickedshadecolor   = 'none'  if(not defined $pickedshadecolor    );
      $pickedshadecolorbg = 'white' if(not defined $pickedshadecolorbg  ); 
      $pickedshadecolorbg = 'white' if( $pickedshadecolor eq 'black'    ); 
   my $_shadecolor = sub { $pickedshadecolor = shift;
                           my $color   = $pickedshadecolor;
                           my $mbcolor = $pickedshadecolor;
                           $color      =  undef  if($color   eq 'none' );
                           $mbcolor    = 'white' if($mbcolor eq 'none' );
                           $mbcolor    = 'white' if($mbcolor eq 'black');
                           $shaderef->{-fillcolor} = $color;
                           $mb_shadecolor->configure(-background       => $mbcolor,
                                                     -activebackground => $mbcolor);
                         };     
   
   my $blankcolor   = $pointref->{-blankcolor};
   my $blankcolorbg = $blankcolor;
      $blankcolorbg = 'white' if($blankcolor eq 'black');
   my $_blankcolor  = sub { $blankcolor = shift;
                            $pointref->{-blankcolor} = $blankcolor;
                             my $mbcolor = $blankcolor;
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $mb_blankcolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                           };

                                                    
   my ( @pointoutline, @lineoutline, @pointfill  ) = ( (), (), () );
   my ( @rugxlinecolor, @rugylinecolor           ) = ( (), ()     );          
   my ( @shadecolor,   @barcolor,    @baroutline ) = ( (), (), () );
   my ( @blankcolors ) = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@pointoutline, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointoutline, $_ ] ] );
      push(@rugxlinecolor, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_rugxlinecolor, $_ ] ] );
      push(@rugylinecolor, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_rugylinecolor, $_ ] ] );
      push(@lineoutline,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_lineoutline,  $_ ] ] );
      push(@pointfill,    [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointfill,    $_ ] ] );
      push(@shadecolor,   [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_shadecolor,   $_ ] ] );
      push(@barcolor,     [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_barcolor,     $_ ] ] );
      push(@baroutline,   [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_baroutline,   $_ ] ] );
      next if(/none/);
      push(@blankcolors,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_blankcolor,   $_ ] ] );
      
   }

   my $ptoutlinewidth   = $pointref->{-outlinewidth};
   my $rugxlinewidth    = $rugx->{-linewidth};
   my $rugylinewidth    = $rugy->{-linewidth};
   my $lineoutlinewidth = $lineref->{-linewidth};
   my $baroutlinewidth  = $barref->{-outlinewidth};
   my (@ptoutlinewidth, @lineoutlinewidth, @baroutlinewidth) = ( (), (), () );
   my (@rugxlinewidth, @rugylinewidth) = ( (), () );
   my $_ptoutlinewidth   = sub { $ptoutlinewidth = shift;
                                 $pointref->{-outlinewidth} = $ptoutlinewidth;
                               };
   my $_rugxlinewidth    = sub { $rugxlinewidth = shift;
                                 $rugx->{-linewidth} = $rugxlinewidth;
                               };
   my $_rugylinewidth    = sub { $rugylinewidth = shift;
                                 $rugy->{-linewidth} = $rugylinewidth;
                               };
   my $_lineoutlinewidth = sub { $lineoutlinewidth = shift;
                                 $lineref->{-linewidth}     = $lineoutlinewidth;
                               };                           
   my $_baroutlinewidth  = sub { $baroutlinewidth = shift;
                                 $barref->{-outlinewidth}   = $baroutlinewidth;
                               };                           

   my $shadedir  = $shaderef->{-shadedirection};
   my $bardir    = $barref->{-direction};
   my $_shadedir = sub { $shadedir = shift;
                         $shaderef->{-shadedirection} = $shadedir;
                       };

   my $_bardir   = sub { $bardir = shift;
                         $barref->{-direction} = $bardir;
                       };
   my (@shadedir, @bardir) = ( (), () );
   foreach ( qw(below above left right) ) {
      push(@shadedir,  [ 'command' => $_,
                         -font     => $font,
                         -command  => [ \&$_shadedir, $_] ] );
      push(@bardir,    [ 'command' => $_,
                         -font     => $font,
                         -command  => [ \&$_bardir,   $_] ] );
   }
   push(@shadedir,  [ 'command' => 'shade between',
                      -font     => $font,
                      -command  => [ \&$_shadedir, 'shade between'] ] );
   push(@bardir,    [ 'command' => 'horz bar between',
                      -font     => $font,
                      -command  => [ \&$_bardir,   'bar between'] ] );

   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@ptoutlinewidth,   [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_ptoutlinewidth,   $_ ] ] );
      push(@rugxlinewidth,    [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_rugxlinewidth,   $_ ] ] );
      push(@rugylinewidth,    [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_rugylinewidth,   $_ ] ] );
      push(@lineoutlinewidth, [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_lineoutlinewidth, $_ ] ] );
      push(@baroutlinewidth,  [ 'command' => $_,
                                -font     => $font,
                                -command  => [ $_baroutlinewidth,  $_ ] ] );
   }

   my $ptsize   = $pointref->{-size};
      $ptsize   = $template->pixel_to_inch($ptsize);

   my $rugxsize = $rugx->{-size};
      $rugxsize = $template->pixel_to_inch($rugxsize);
   my $rugysize = $rugy->{-size};
      $rugysize = $template->pixel_to_inch($rugysize);
      
   my $barwidth = $barref->{-barwidth};
      $barwidth = $template->pixel_to_inch($barwidth);  

   my $num2skip = $pointref->{-num2skip};

   my $xoffset  = $textref->{-xoffset};
   my $yoffset  = $textref->{-yoffset};
      $xoffset  = $template->pixel_to_inch($xoffset);
      $yoffset  = $template->pixel_to_inch($yoffset);   

   my $leadbegoffset = $textref->{-leaderline}->{-beginoffset};
   my $leadendoffset = $textref->{-leaderline}->{-endoffset};
      $leadbegoffset = $template->pixel_to_inch($leadbegoffset);
      $leadendoffset = $template->pixel_to_inch($leadendoffset);
   
   # BEGIN PAGE 3--a little out of order!!!!!!
   my $_displayTextPlotOptions = sub {
      #######################################
      ## DIALOG DISPLAY STUFF FOR A TEXT PLOT
      #######################################
      my ($data, $frame) = (shift, shift);
      my $attr = $data->{-attributes}->{-text};
      my ($mb_fontcolor, $mb_format, $mb_anchor, $mb_justify);
      my $mb_blankcolor;
      my ($mb_leadercolor, $mb_leaderwidth);
      
      my %format = ( free   => 'Free',
                     fixed  => 'Fixed',
                     sci    => 'Scientific',
                     sig    => 'Significant' ); 
 
      
      my @format = (
         [ 'command' => 'Free',
           -font     => $font,
           -command  => sub { $attr->{-numformat}  = 'free';
                              $mb_format->configure(
                                        -text => $format{ $attr->{-numformat} } );
                            } ],
         [ 'command' => 'Fixed',
           -font     => $font,
           -command  => sub { $attr->{-numformat} = 'fixed';
                              $mb_format->configure(
                                        -text => $format{ $attr->{-numformat} } );
                            } ],
         [ 'command' => 'Scientific',
           -font     => $font,
           -command  => sub { $attr->{-numformat}  = 'sci';
                              $mb_format->configure(
                                        -text => $format{ $attr->{-numformat} } );
                            } ],
         [ 'command' => 'Significant',
           -font     => $font,
           -command  => sub { $attr->{-numformat}  = 'sig';
                              $mb_format->configure(
                                        -text => $format{ $attr->{-numformat} } );
                            } ] );    
      
      my $anchor  = $attr->{-anchor};
      my $justify = $attr->{-justify};
                      
      my $_justify = sub { $justify = shift;
                           $attr->{-justify} = $justify; };
                        
      my $_anchor  = sub { $anchor = shift;
                           $attr->{-anchor} = $anchor };                                         
      my @justify = ();
      foreach ( qw(center left right) ) {
         push(@justify,
              [ 'command' => $_,
                -font     => $font,
                -command  => [ \&$_justify, $_ ] ] );
      }
   
      my @anchor = ();
      foreach ( qw(center n ne e se s sw w nw) ) {
         push(@anchor,
              [ 'command' => $_,
                -font     => $font,
                -command  => [ \&$_anchor, $_ ] ] );
      }     



      my $fontref = $attr->{-font};

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
      
      my $blankcolor   = $fontref->{-blankcolor};
      my $blankcolorbg = $blankcolor;
         $blankcolorbg = 'white' if($blankcolor eq 'black');
      my $_blankcolor  = sub { $blankcolor = shift;
                               $fontref->{-blankcolor} = $blankcolor;
                                my $mbcolor = $blankcolor;
                                $mbcolor    = 'white' if($mbcolor eq 'black');
                                $mb_blankcolor->configure(-background       => $mbcolor,
                                                          -activebackground => $mbcolor);
                              };
      

      my $leaderref           = $attr->{-leaderline};
      my $pickedleadercolor   = $leaderref->{-color};
      my $pickedleadercolorbg = $pickedleadercolor;
         $pickedleadercolor   = 'none'  if(not defined $pickedleadercolor);
         $pickedleadercolorbg = 'white' if(not defined $pickedleadercolorbg);
         $pickedleadercolorbg = 'white' if($pickedleadercolor eq 'black');
      my $_leadercolor  = sub { $pickedleadercolor = shift;
                                my $color   = $pickedleadercolor;
                                my $mbcolor = $pickedleadercolor;
                                $color      =  undef  if($color   eq 'none' );
                                $mbcolor    = 'white' if($mbcolor eq 'none' );
                                $mbcolor    = 'white' if($mbcolor eq 'black');
                                $leaderref->{-color} = $color;
                                $mb_leadercolor->configure(-background       => $mbcolor,
                                                           -activebackground => $mbcolor);
                              };
   
      my @fontcolors   = ();
      my @leadercolors = ();
      my @blankcolors  = ();
      foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
         push(@leadercolors, [ 'command' => $_,
                               -font     => $font,
                               -command  => [ $_leadercolor, $_ ] ] );
         next if(/none/);
         push(@fontcolors,   [ 'command' => $_,
                               -font     => $font,
                               -command  => [ $_fontcolor,   $_ ] ] );
         push(@blankcolors, [ 'command' => $_,
                               -font     => $font,
                               -command  => [ $_blankcolor, $_ ] ] );
      }

      my $leaderwidth  = $leaderref->{-width};
      my @leaderwidth  = ();
      my $_leaderwidth = sub { $leaderwidth = shift;
                               $leaderref->{-width} = $leaderwidth;
                             };
      foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
         push(@leaderwidth, [ 'command' => $_,
                              -font     => $font,
                              -command  => [ $_leaderwidth, $_ ] ] );
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
      
      my $f_1 = $frame->Frame->pack(-side => 'top', -fill => 'x');  
      $f_1->Checkbutton(-text     => 'DoIt   ',
                        -font     => $fontb,
                        -variable => \$attr->{-doit},
                        -onvalue  => 1,
                        -offvalue => 0, )
          ->pack(-side => 'left');    
      $f_1->Label(-text => '  Anchor',
                 -font => $fontb)
          ->pack(-side => 'left');
      $mb_anchor = $f_1->Menubutton(
                       -textvariable => \$anchor,
                       -font         => $fontb,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -tearoff      => 0,
                       -menuitems    => [ @anchor ],
                       -activebackground => 'white')
                       ->pack(-side => 'left');          
       $f_1->Label(-text => '  Angle (for MetaPost)',
                   -font => $fontb)
           ->pack(-side => 'left', -anchor => 'w');   
       $f_1->Entry(-textvariable => \$fontref->{-rotation},
                   -font         => $font,
                   -background   => 'white',
                   -width        => 4  )
           ->pack(-side => 'left');
          
          
      my $f2 = $frame->Frame->pack(-side => 'top', -fill => 'x');
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
      $mb_justify = $f2->Menubutton(
                       -textvariable => \$justify,
                       -font         => $fontb,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -tearoff      => 0,
                       -menuitems    => [ @justify ],
                       -activebackground => 'white')
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
                

   
      my $f3 = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f3->Label(-text => 'X-offset',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
      $f3->Entry(-textvariable => \$xoffset,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 8 )
         ->pack(-side => 'left', -fill => 'x');
      $f3->Label(-text => '  Y-offset',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
      $f3->Entry(-textvariable => \$yoffset,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 8 )
         ->pack(-side => 'left', -fill => 'x');
      $f3->Checkbutton(-text     => 'Stack Text',
                       -font     => $fontb,
                       -variable => \$fontref->{-stackit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left'); 
       
      my $f4 = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f4->Checkbutton(-text => 'Do blanking below with color:',
                       -font => $fontb,
                       -variable => \$fontref->{-blankit},
                       -onvalue => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
      $mb_blankcolor = $f4->Menubutton(
                          -textvariable => \$blankcolor,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1, 
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @blankcolors ],
                          -background   => $blankcolorbg,
                          -activebackground => $blankcolorbg)        
                          ->pack(-side => 'left');   
         
         
      my $f_f = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f_f->Label(-text => 'Format and Decimals',
                  -font => $fontb)
          ->pack(-side => 'left');
      $mb_format = $f_f->Menubutton(
                       -text      => $format{$attr->{-numformat}},
                       -font      => $fontb,
                       -indicator => 1,
                       -tearoff   => 0,
                       -relief    => 'ridge',
                       -menuitems => [ @format ],
                       -width     => 12 )
                       ->pack(-side => 'left'); 
       $f_f->Entry(-textvariable => \$attr->{-numdecimal},
                   -font         => $font,
                   -background   => 'white',
                   -width        => 6  )
           ->pack(-side => 'left');   
       $f_f->Checkbutton(-text     => 'Commify',
                         -font     => $fontb,
                         -variable => \$attr->{-numcommify},
                         -onvalue  => 1,
                         -offvalue => 0)
           ->pack(-side => 'left');    
      
      
      # BACKWARDS COMPATABILITY FOR 0.60-2 AND BELOW
      $leaderref->{-flip_lines_with_shuffle} = 1
          unless(exists $leaderref->{-flip_lines_with_shuffle});
      $leaderref->{-overlap_correction_doit} = 0
          unless(exists $leaderref->{-overlap_correction_doit});
      # END OF BACKWARDS COMPATABILITY
        
      my $f_lead  = $frame->Frame->pack(-side => 'top', -expand => 1);
      my $f_lead1 = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f_lead1->Label(-text   => "\nLeader Lines:",
                      -font   => $fontb,
                      -anchor => 'w')
              ->pack(-side => 'top', -fill => 'x');
      $f_lead1->Checkbutton(
              -text     => 'DoIt',
              -font     => $fontb,
              -variable => \$leaderref->{-doit},
              -onvalue  => 1,
              -offvalue => 0)
             ->pack(-side => 'left');
      $f_lead1->Checkbutton(
              -text     => 'Automatic overlap correction (cpu intensive)',
              -font     => $fontb,
              -variable => \$leaderref->{-overlap_correction_doit},
              -onvalue  => 1,
              -offvalue => 0)
             ->pack(-side => 'left');
      
      my $f_lead1a = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f_lead1a->Checkbutton(
              -text     => 'ShuffleIt (can be used with overlap correction)',
              -font     => $fontb,
              -variable => \$leaderref->{-shuffleit},
              -onvalue  => 1,
              -offvalue => 0)
             ->pack(-side => 'left');
      my $f_lead1aa = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f_lead1aa->Checkbutton(
              -text     => 'Flip every other line when shuffling',
              -font     => $fontb,
              -variable => \$leaderref->{-flip_lines_with_shuffle},
              -onvalue  => 1,
              -offvalue => 0)
             ->pack(-side => 'left');
                          
      my $f_lead1b = $frame->Frame->pack(-side => 'top', -fill => 'x');
      $f_lead1b->Label(-text => 'Width and Color',
                       -font => $fontb)
               ->pack(-side => 'left', -anchor => 'w');            
      $mb_leaderwidth = $f_lead1b->Menubutton(
                                 -textvariable => \$leaderwidth,
                                 -font         => $fontb,
                                 -width        => 6,
                                 -indicator    => 1,
                                 -relief       => 'ridge',
                                 -menuitems    => [ @leaderwidth ],
                                 -tearoff      => 0)
                                 ->pack(-side => 'left', -fill => 'x');
      $mb_leadercolor = $f_lead1b->Menubutton(
                                 -textvariable     => \$pickedleadercolor,
                                 -font             => $fontb,
                                 -width            => 12,
                                 -indicator        => 1, 
                                 -relief           => 'ridge',
                                 -tearoff          => 0,
                                 -menuitems        => [ @leadercolors ],
                                 -background       => $pickedleadercolorbg,
                                 -activebackground => $pickedleadercolorbg)        
                                 ->pack(-side => 'left');
          
      my $f_lead2 = $frame->Frame->pack(-side => 'top', -fill => 'x');  
      $f_lead2->Label(-text => '  Begin offset',
                      -font => $fontb)
              ->pack(-side => 'left', -anchor => 'w');                   
      $f_lead2->Entry(-textvariable => \$leadbegoffset,
                      -font         => $font,
                      -background   => 'white',
                      -width        => 8 )
              ->pack(-side => 'left', -fill => 'x');
      $f_lead2->Label(-text => '  End offset',
                      -font => $fontb)
              ->pack(-side => 'left', -anchor => 'w');
      $f_lead2->Entry(-textvariable => \$leadendoffset,
                      -font         => $font,
                      -background   => 'white',
                      -width        => 8 )
              ->pack(-side => 'left', -fill => 'x');
      my $f_lead3 = $frame->Frame->pack(-side => 'top', -fill => 'x'); 
      $f_lead3->Label(-text => ' Lines',
                      -font => $fontb)
               ->pack(-side => 'left');
      my $t_lead_lines = $f_lead3->Scrolled('Text',
                                 -font       => $font,
                                 -scrollbars => 'e',
                                 -width      => 20,
                                 -height     => 3,
                                 -background => 'white')
                                 ->pack(-side => 'left');
      my $linetext = " Lines are defined by length in\n".
                     " inches and angle in degrees\n".
                     " clockwise from horizontal.\n".
                     " e.g. 'length:angle' or '0.1i:-45'";
      $f_lead3->Label(-text    => $linetext,
                      -font    => $fontb,
                      -justify => "l")
              ->pack(-side => 'left');
      my $leader_lines = $leaderref->{-lines};
      foreach my $line (@$leader_lines) {
         my $angle  = $line->{-angle};
         my $length = $template->pixel_to_inch($line->{-length});
         $t_lead_lines->insert('end',"$length:$angle\n");
      }
      return $t_lead_lines;
   }; # END OF PAGE 3



   # BUILD THE MAIN DIALOG BOX
   
   my $nb = $pe->NoteBook(-font => $fontb,
                          -dynamicgeometry => 1)->pack;#(-expand => 1, -fill => 'both');
   my $page1 = $nb->add( 'page1', -label => 'Points'     );
   my $page2 = $nb->add( 'page2', -label => 'Lines'      );
   my $page3 = $nb->add( 'page3', -label => 'Text'       );
   my $page4 = $nb->add( 'page4', -label => 'Shading'    );
   my $page5 = $nb->add( 'page5', -label => 'Bars'       );
   my $page6 = $nb->add( 'page6', -label => 'Error Lines');
   my $page7 = $nb->add( 'page7', -label => 'Special Plot');
   
   # WHA has not figured out if it is appropriate to draw lines and
   # shading with the discrete clustering modeling introduced in version 0.22
   if(   $plot->{-x}->{-discrete}->{-doit}
      or $plot->{-y}->{-discrete}->{-doit} ) {
      $nb->pageconfigure('page2', -state => 'disabled');
      $nb->pageconfigure('page4', -state => 'disabled');
   }
   if(ref($specialref)) {
      $specialref->SpecialPlotEditor($page7,$template,$self);
   }
   else {
      $nb->pageconfigure('page7', -state => 'disabled');
   }
   # raise the last note book tab that was used
   $nb->raise($LAST_PAGE_VIEWED);
   
   
   ######## POINT SYMBOLOGY
   # BEGIN PAGE 1
   my $f_11 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_11->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$pointdoit,
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   $f_11->Menubutton(-textvariable => \$pointref->{-symbol},
                     -font         => $fontb,
                     -width        => 8,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @pointsymbol ] )
        ->pack(-side => 'left');
        
               
   $f_11->Label(-text => ' Size',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $f_11->Entry(-textvariable => \$ptsize,
                -font          => $font,
                -background   => 'white',
                -width        => 8  )
        ->pack(-side => 'left'); 
   $f_11->Label(-text => ' Edge',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_ptoutlinewidth = $f_11->Menubutton(
                             -textvariable => \$ptoutlinewidth,
                             -font         => $fontb,
                             -width        => 6,
                             -indicator    => 1,
                             -relief       => 'ridge',
                             -menuitems    => [ @ptoutlinewidth ],
                             -tearoff      => 0)
                             ->pack(-side => 'left', -fill => 'x');      
   $f_11->Label(-text => ' Angle',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_11->Entry(-textvariable => \$pointref->{-angle},
                -font         => $font,
                -background   => 'white',
                -width        => 4 )
        ->pack(-side => 'left');
    
   my $f_13 = $page1->Frame->pack(-side => 'top', -fill => 'x');   
   $f_13->Label(-text => '   Edge Color',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointoutline = $f_13->Menubutton(
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
   $f_13->Label(-text => ' Fill',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointfill = $f_13->Menubutton(
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
   
   my $f_14 = $page1->Frame->pack(-side => 'top', -fill => 'x');   
   $f_14->Label(-text => '   No. to skip drawing',
                -font => $fontb)
        ->pack(-side => 'left');    
   $f_14->Entry(-textvariable => \$num2skip,
                -font         => $font,
                -background   => 'white',
                -width        => 8  )
        ->pack(-side => 'left');
   
   
   my $f_15 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_15->Checkbutton(-text => 'Do blanking below with color:',
                      -font => $fontb,
                      -variable => \$pointref->{-blankit},
                      -onvalue => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   $mb_blankcolor = $f_15->Menubutton(
                         -textvariable => \$blankcolor,
                         -font         => $fontb,
                         -width        => 12,
                         -indicator    => 1, 
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @blankcolors ],
                         -background   => $blankcolorbg,
                         -activebackground => $blankcolorbg)        
                         ->pack(-side => 'left');   
			 
			 
   my $rug_frame = $page1->Frame(-borderwidth => 2, -relief => 'ridge')
                         ->pack(-side => 'top', -fill => 'x');
   my $f_16x = $rug_frame->Frame->pack(-side => 'top', -fill => 'x');
   $f_16x->Checkbutton(-text     => 'Rug X-axis DoIt ',
                       -font     => $fontb,
                       -variable => \$rugxdoit,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_16x->Checkbutton(-text     => 'Both axes ',
                       -font     => $fontb,
                       -variable => \$rugxboth,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_16x->Checkbutton(-text     => 'Invert the fibers ',
                       -font     => $fontb,
                       -variable => \$rugxnegate,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   my $f_17x = $rug_frame->Frame->pack(-side => 'top', -fill => 'x');   
   $f_17x->Label(-text => '   Rug X-axis Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $mb_rugxlinecolor = $f_17x->Menubutton(
                           -textvariable => \$pickedrugxlinecolor,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @rugxlinecolor ],
                           -background   => $pickedrugxlinecolorbg,
                           -activebackground => $pickedrugxlinecolorbg )
                           ->pack(-side => 'left');   
   $f_17x->Label(-text => ' Edge',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $mb_rugxlinewidth = $f_17x->Menubutton(
                             -textvariable => \$rugxlinewidth,
                             -font         => $fontb,
                             -width        => 6,
                             -indicator    => 1,
                             -relief       => 'ridge',
                             -menuitems    => [ @rugxlinewidth ],
                             -tearoff      => 0)
                             ->pack(-side => 'left', -fill => 'x');   
   $f_17x->Label(-text => ' Size',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $f_17x->Entry(-textvariable => \$rugxsize,
                 -font          => $font,
                 -background   => 'white',
                 -width        => 8  )
         ->pack(-side => 'left'); 

   my $f_16y = $rug_frame->Frame->pack(-side => 'top', -fill => 'x');
   $f_16y->Checkbutton(-text     => 'Rug Y-axis DoIt ',
                       -font     => $fontb,
                       -variable => \$rugydoit,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_16y->Checkbutton(-text     => 'Both Axes ',
                       -font     => $fontb,
                       -variable => \$rugyboth,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_16y->Checkbutton(-text     => 'Invert the fibers ',
                       -font     => $fontb,
                       -variable => \$rugynegate,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   my $f_17y = $rug_frame->Frame->pack(-side => 'top', -fill => 'x');   
   $f_17y->Label(-text => '   Rug Y-axis Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $mb_rugylinecolor = $f_17y->Menubutton(
                           -textvariable => \$pickedrugylinecolor,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @rugylinecolor ],
                           -background   => $pickedrugylinecolorbg,
                           -activebackground => $pickedrugylinecolorbg )
                           ->pack(-side => 'left');   
   $f_17y->Label(-text => ' Edge',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $mb_rugylinewidth = $f_17y->Menubutton(
                             -textvariable => \$rugylinewidth,
                             -font         => $fontb,
                             -width        => 6,
                             -indicator    => 1,
                             -relief       => 'ridge',
                             -menuitems    => [ @rugylinewidth ],
                             -tearoff      => 0)
                             ->pack(-side => 'left', -fill => 'x');      
   $f_17y->Label(-text => ' Size',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $f_17y->Entry(-textvariable => \$rugysize,
                 -font          => $font,
                 -background   => 'white',
                 -width        => 8  )
         ->pack(-side => 'left'); 
      
   ######## LINE STYLES
   # BEGIN PAGE 2
   my $f_20 = $page2->Frame->pack(-side => 'top', -fill => 'x');  
   $f_20->Checkbutton(-text     => 'DoIt   ',
                      -font     => $fontb,
                      -variable => \$linedoit,
                      -onvalue  => 1,
                      -offvalue => 0,
                      -command  => sub { $shadedoit = 0 if( not $linedoit );
                                         $stepit    = 0 if( not $linedoit );
                                       } )
        ->pack(-side => 'left');    
   
   my $f_21 = $page2->Frame->pack(-side => 'top', -fill => 'x');  
   $f_21->Label(-text => 'Width, Color, Style',
                -font => $fontb)
        ->pack(-side => 'left');        
   $mb_lineoutlinewidth = $f_21->Menubutton(
                               -textvariable => \$lineoutlinewidth,
                               -font         => $fontb,
                               -width        => 6,
                               -indicator    => 1,
                               -relief       => 'ridge',
                               -menuitems    => [ @lineoutlinewidth ],
                               -tearoff      => 0)
                               ->pack(-side => 'left'); 
        
   $mb_lineoutline = $f_21->Menubutton(
                          -textvariable => \$pickedlineoutline,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @lineoutline ],
                          -background   => $pickedlineoutlinebg,
                          -activebackground => $pickedlineoutlinebg )
                          ->pack(-side => 'left');

   $mb_linedashstyle = $f_21->Menubutton(
                          -textvariable => \$lineref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 8,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linedashstyle ])
                          ->pack(-side => 'left');
   
   my $f_22 = $page2->Frame->pack(-side => 'top', -fill => 'x');  
   $f_22->Radiobutton(-text     => 'No Step',
                      -font     => $fontb,
                      -variable => \$stepit,
                      -value    => 0,
                      -command  => sub { $linedoit = 1 if($stepit
                                                           and not $linedoit);
                                       } )
        ->pack(-side => 'left'); 
   $f_22->Radiobutton(-text     => 'StepIt',
                      -font     => $fontb,
                      -variable => \$stepit,
                      -value    => 1,
                      -command  => sub { $linedoit = 1 if($stepit
                                                          and not $linedoit);
                                       } )
        ->pack(-side => 'left');      
   $f_22->Radiobutton(-text     => 'Over-StepIt',
                      -font     => $fontb,
                      -variable => \$stepit,
                      -value    => 2,
                      -command  => sub { $linedoit = 1 if($stepit
                                                          and not $linedoit);
                                       } )
        ->pack(-side => 'left');      

  my $f_23 = $page2->Frame()->pack(-side => 'top', -fill => 'x');
     $f_23->Label(-text => 'Arrow distances (1, 2, 3)',
                  -font => $fontb)
          ->pack(-side => 'left');
     $f_23->Entry(-textvariable => \$arrow1,
                  -font         => $fontb,
                  -background   => 'white',
                  -width        => 10)
          ->pack(-side => 'left');
     $f_23->Entry(-textvariable => \$arrow2,
                  -font         => $fontb,
                  -background   => 'white',
                  -width        => 10)
          ->pack(-side => 'left');
     $f_23->Entry(-textvariable => \$arrow3,
                  -font         => $fontb,
                  -background   => 'white',
                  -width        => 10)
          ->pack(-side => 'left');
    
   my $f_24 = $page2->Frame()->pack(-side => 'top', -fill => 'x');
      $f_24->Label(-text => 'Arrow style',
                   -font => $fontb)
           ->pack(-side => 'left', -fill => 'x');
      $f_24->Radiobutton(-text     => 'none   ',
                         -font     => $fontb,
                         -variable => \$lineref->{-arrow},
                         -value    => 'none')
           ->pack(-side => 'left', -fill => 'x');
      $f_24->Radiobutton(-text     => 'first  ',
                         -font     => $fontb,
                         -variable => \$lineref->{-arrow},
                         -value    => 'first')
           ->pack(-side => 'left', -fill => 'x');
      $f_24->Radiobutton(-text     => 'last   ',
                         -font     => $fontb,
                         -variable => \$lineref->{-arrow},
                         -value    => 'last')
           ->pack(-side => 'left', -fill => 'x');
      $f_24->Radiobutton(-text     => 'both   ',
                         -font     => $fontb,
                         -variable => \$lineref->{-arrow},
                         -value    => 'both')
           ->pack(-side => 'left', -fill => 'x');


        
        
   ######## SHADE STYLES
   # BEGIN PAGE 4
   my $f_31 = $page4->Frame->pack(-side => 'top', -fill => 'x');
   $f_31->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$shadedoit,
                      -onvalue  => 1,
                      -offvalue => 0,
                      -command  => sub { $linedoit = 1 if($shadedoit); } )
        ->pack(-side => 'left');
   $f_31->Checkbutton(-text     => 'Shade To Origin (if applicable axis is linear)',
                      -font     => $fontb,
                      -variable => \$shaderef->{-shade2origin},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   my $f_32 = $page4->Frame->pack(-side => 'top', -fill => 'x');
   $f_32->Label(-text => "Direction",
                -font => $fontb)
        ->pack(-side => 'left');$f_32->Menubutton(-textvariable => \$shadedir,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -width        => 16,
                     -menuitems    => [ @shadedir ])
       ->pack(-side => 'left');      
   $f_32->Label(-text => '  Fill',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_shadecolor = $f_32->Menubutton(
                         -textvariable => \$pickedshadecolor,
                         -font         => $fontb,
                         -width        => 12,
                         -indicator    => 1,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @shadecolor ],
                         -background   => $pickedshadecolorbg,
                         -activebackground => $pickedshadecolorbg )
        ->pack(-side => 'left');       


   ######## BAR STYLES
   # BEGIN PAGE 5
   my $f_41 = $page5->Frame->pack(-side => 'top', -fill => 'x');
   $f_41->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$bardoit,
                      -onvalue  => 1,
                      -offvalue => 0 )
        ->pack(-side => 'left');
   $f_41->Label(-text => "Direction",
                -font => $fontb)
        ->pack(-side => 'left');
   $f_41->Menubutton(-textvariable => \$bardir,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @bardir ])
       ->pack(-side => 'left');
   $f_41->Label(-text => "  Bar width",
                -font => $fontb)
        ->pack(-side => 'left');
   $f_41->Entry(-textvariable => \$barwidth,
                -font         => $font,
                -background   => 'white',
                -width        => 6)
        ->pack(-side => 'left');
                
   $f_41->Label(-text => '  Width',
                -font => $fontb)
        ->pack(-side => 'left');        
   $mb_baroutlinewidth = $f_41->Menubutton(
                              -textvariable => \$baroutlinewidth,
                              -font         => $fontb,
                              -width        => 6,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -menuitems    => [ @baroutlinewidth ],
                              -tearoff      => 0)
                              ->pack(-side => 'left', -fill => 'x'); 
        
   my $f_42 = $page5->Frame->pack(-side => 'top', -fill => 'x');            
   $f_42->Label(-text => '  Color',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_baroutline = $f_42->Menubutton(
                         -textvariable => \$pickedbaroutline,
                         -font         => $fontb,
                         -width        => 12,
                         -indicator    => 1,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @baroutline ],
                         -background   => $pickedbaroutlinebg,
                         -activebackground => $pickedbaroutlinebg )
                         ->pack(-side => 'left');     
           
   $f_42->Label(-text => '  Fill',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_barcolor = $f_42->Menubutton(
                       -textvariable => \$pickedbarcolor,
                       -font         => $fontb,
                       -width        => 12,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -tearoff      => 0,
                       -menuitems    => [ @barcolor ],
                       -background   => $pickedbarcolorbg,
                       -activebackground => $pickedbarcolorbg )
        ->pack(-side => 'left');  
   
   
   
   my $plotstyle = $attr->{-plotstyle};
   my $leaderlines;
   if($plotstyle =~ /text/io) {
      $leaderlines = &$_displayTextPlotOptions($data,$page3);
   }
   else {
      $nb->pageconfigure('page3',-state => 'disabled');
   }
        
   if($plotstyle eq 'X-Y Error Bar' or
      $plotstyle eq 'X-Y Error Limits') {
      &_displayXErrorOptions($data,$page6);
      &_displayYErrorOptions($data,$page6);
   }
   elsif($plotstyle eq 'Y-Error Bar' or
         $plotstyle eq 'Y-Error Limits') {
      &_displayYErrorOptions($data,$page6);
   }
   else {
      $nb->pageconfigure('page6',-state => 'disabled');
   }
   
   my ($px, $py) = (2, 2);  
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'bottom', -fill => 'x', -expand => 1);
   my $b_apply = $f_b->Button(
                     -text               => 'Apply',
                     -borderwidth        => 3,
                     -highlightthickness => 2,
                     -font               => $fontb,
                     -command => sub { my $go = &$finishsub;
                                       return unless($go);
                                       $template->UpdateCanvas($canv);
                                     } )
                     ->pack(-side => 'left', -padx => $px, -pady => $py);   
                             
   $b_apply->focus;                     
   $f_b->Button(
       -text               => 'OK',
       -borderwidth        => 3,
       -highlightthickness => 2,
       -font               => $fontb,
       -command     => sub { my $go = &$finishsub;
                             return unless($go);
                             $pe->destroy;
                             $template->UpdateCanvas($canv);
                           } )
       ->pack(-side => 'left', -padx => $px, -pady => $py); 
   
   HELP_USER: {
      my $edclass = \$Tkg2::DataMethods::Class::DataClassEditor::EDITOR;
      my $edset   = \$Tkg2::DataMethods::Set::DataSetEditor::EDITOR;
      if(Tk::Exists($$edclass) or Tk::Exists($$edset) ) {
      $f_b->Button(
          -text               => "OK and Exit\nThe two data editors",
          -font               => $fontb,
          -highlightthickness => 2,
          -command => sub { my $go = &$finishsub;
                            return unless($go);
                            $$edclass->destroy if( Tk::Exists( $$edclass ) );
                            $$edset->destroy   if( Tk::Exists( $$edset   ) );
                            $pe->destroy;
                            $template->UpdateCanvas($canv);
                          } )
          ->pack(-side => 'left', -padx => $px, -pady => $py);
      }
   }
   
                     
   $f_b->Button(-text    => "Cancel",
                -font    => $fontb,
                -command => sub { $pe->destroy; })
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text    => "Help",
                -padx    => 4,
                -pady    => 4,
                -font    => $fontb, 
                -command => sub { &Help($pe,'DrawDataEditor.pod') } )
       ->pack(-side => 'left', -padx => $px, -pady => $py);     


   $finishsub = sub {
      $ptsize =~ m/([0-9.]+)/o;
      $ptsize = $1;
      if( defined $ptsize and &isNumber($ptsize) ) {
         $ptsize .= "i";
         $pointref->{-size} = $pe->fpixels($ptsize);
      }
      else {
         my $text = "Invalid symbol size\n";
         &Message($pe,'-generic', $text);
         return 0;
      }
      $rugxsize =~ m/([0-9.]+)/o;
      $rugxsize = $1;
      if( defined $rugxsize and &isNumber($rugxsize) ) {
         $rugxsize .= "i";
         $rugx->{-size} = $pe->fpixels($rugxsize);
      }      
      else {
         my $text = "Invalid rug x size\n";
         &Message($pe,'-generic', $text);
         return 0;
      }      
      $rugysize =~ m/([0-9.]+)/o;
      $rugysize = $1;
      if( defined $rugysize and &isNumber($rugysize) ) {
         $rugysize .= "i";
         $rugy->{-size} = $pe->fpixels($rugysize);
      }      
      else {
         my $text = "Invalid rug y size\n";
         &Message($pe,'-generic', $text);
         return 0;
      }            
      
      if( defined $num2skip and &isNumber($num2skip) ) {
         $num2skip = int($num2skip); # insure integer
         $pointref->{-num2skip} = $num2skip;
      }
      else {
         my $text = "Invalid number of points to skip drawing\n";
         &Message($pe,'-generic', $text);
         return 0;
      }
      
      foreach ($arrow1, $arrow2, $arrow3) { s/^([0-9.]+)$/$1i/ };  
      $lineref->{-arrow1} = $pe->fpixels($arrow1);
      $lineref->{-arrow2} = $pe->fpixels($arrow2);
      $lineref->{-arrow3} = $pe->fpixels($arrow3);
      
      $barwidth =~ m/([0-9.]+)/o;
      $barwidth = $1;
      if( defined $ptsize and &isNumber($barwidth) ) {
         $barref->{-barwidth} = $pe->fpixels($barwidth."i");
      }
      else {
         my $text = "Invalid bar width\n";
         &Message($pe,'-generic',$text);
         return 0;
      }
      if($attr->{-plotstyle} =~ /text/io) {
         my $newlines = &_retrieve_leader_lines_from_widget($pe, $leaderlines);
         return 0 unless($newlines);
         $textref->{-leaderline}->{-lines} = $newlines;
         
         my $offsets_ok = &_check_offsets($pe, $attr,
                                          $xoffset, $yoffset,
                                          $leadbegoffset, $leadendoffset );
         return 0 unless($offsets_ok);
      }
      if(ref($specialref)) {
        my $special_ok = $specialref->checkConfiguration($pe);
        return 0 unless($special_ok);
      }

      $shaderef->{-shade2origin} = 0 if($shadedir eq 'shade between');
      
      $pointref->{-doit}  = $pointdoit;
      $pointref->{-rugx}->{-doit} = $rugxdoit;
      $pointref->{-rugy}->{-doit} = $rugydoit;
      $pointref->{-rugx}->{-both} = $rugxboth;
      $pointref->{-rugy}->{-both} = $rugyboth;
      $pointref->{-rugx}->{-negate} = $rugxnegate;
      $pointref->{-rugy}->{-negate} = $rugynegate;
            
      $lineref->{-doit}   = $linedoit;
      $lineref->{-stepit} = $stepit;
      $shaderef->{-doit}  = $shadedoit;
      $barref->{-doit}    = $bardoit;      
      
      $LAST_PAGE_VIEWED = $nb->raised();
      return 1;      
   };
  
}



# _check_offsets is used internally by the finishsub in the DrawDataEditor
# to validate that number fields for the text instructions in the text tab
sub _check_offsets {
   my (   $pe, $attr, $xoffset, $yoffset, $leadbegoffset, $leadendoffset ) =
      ( shift, shift,   shift,     shift,         shift,          shift );
   my $textref = $attr->{-text};
   $xoffset =~ s/^\s+\+//o;
   $xoffset =~ m/(-?[0-9.]+)/o;
   $xoffset = $1;
   if( &isNumber($xoffset) ) {
      $xoffset .= "i";
      $textref->{-xoffset} = $pe->fpixels($xoffset);
   }
   else {
      my $text = "The X-offset is invalid.\n";
      &Message($pe,'-generic',$text);
      return 0;
   }  
   
   $yoffset =~ s/^\s+\+//o; 
   $yoffset =~ m/(-?[0-9.]+)/o;
   $yoffset = $1;
   if( &isNumber($yoffset) ) {
      $yoffset .= "i";
      $textref->{-yoffset}  = $pe->fpixels($yoffset);
   }
   else {
      my $text = "The Y-offset is invalid.\n";
      &Message($pe,'-generic',$text);
      return 0;
   }
   
   $leadbegoffset =~ s/^\s+\+//o; 
   $leadbegoffset =~ m/(-?[0-9.]+)/o;
   $leadbegoffset = $1;
   if( &isNumber($leadbegoffset) ) {
      $leadbegoffset .= "i";
      $textref->{-leaderline}->{-beginoffset} = $pe->fpixels($leadbegoffset);
   }
   else {
      my $text = "The leader line beginning offset is invalid.\n";
      &Message($pe,'-generic',$text);
      return 0;
   }
   
   $leadendoffset =~ s/^\s+\+//o;
   $leadendoffset =~ m/(-?[0-9.]+)/o;
   $leadendoffset = $1;
   if( &isNumber($leadendoffset) ) {
      $leadendoffset .= "i";
      $textref->{-leaderline}->{-endoffset} = $pe->fpixels($leadendoffset);
   }
   else {
      my $text = "The leader line ending offset is invalid.\n";
      &Message($pe,'-generic',$text);
      return 0;
   }     
         
   if( not &isNumber($textref->{-numdecimal}) ) {
      my $text = "Invalid number of decimals for text format\n";
      &Message($pe,'-generic',$text);
      return 0;
   }
   return 1;
}

sub _retrieve_leader_lines_from_widget {
   my ($pe, $leaderlines) = (shift, shift);
   # loop through the leader line widget
   my $lines_from_widget = $leaderlines->get('0.0','end');
   $lines_from_widget =~ s/^\s+//o;
   $lines_from_widget =~ s/\s+$//o;
   $lines_from_widget =~ s/\n+$//o;
   my (@lines) = split(/\n/, $lines_from_widget, -1);
   my @newlines = ();
   foreach my $line (@lines) {
      my ($length,$angle) = split(/:/o, $line, 2);
      if( $length eq "" or not defined $length ) {
         &Message($pe,'-generic','A leader line length is undefined.');
         return 0;
      } 
      if( $angle eq "" or not defined $angle ) {
         &Message($pe,'-generic','A leader line angle is undefined.');
         return 0;
      }
      $length =~ m/([0-9.]+)/o;
      $length = $1;
      if( &isNumber($length) ) {
         $length .= "i";
         $length  = $pe->fpixels($length);
      }
      else {
         &Message($pe, '-generic', "The leader line length is invalid");
         return 0;
      }
      if( not &isNumber($angle) ) {
         &Message($pe, '-generic', "The leader line angle is invalid");
         return 0;
      }
      push(@newlines, { -angle => $angle, -length => $length } );
   }
   return [ @newlines ];
}

# Additional GUI stuff

sub _displayXErrorOptions {
   my ($data, $pe) = ( shift, shift);
   my ($mb_errorbarcolor, $mb_width, $mb_dashstyle);
   my $attr         = $data->{-attributes}->{-xerrorbar};
   my $errorwidth   = $attr->{-width};
   my $errorcolor   = $attr->{-color};
   my $errorcolorbg = $errorcolor;
      $errorcolor   = 'none'  if(not defined $errorcolor    );
      $errorcolorbg = 'white' if(not defined $errorcolorbg  );
      $errorcolorbg = 'white' if( $errorcolor eq 'black'    );
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   $attr->{-dashstyle} = 'Solid' if(not defined $attr->{-dashstyle});
   # the above is for backwards compatability
   my @dashstyle = &getDashList(\$attr->{-dashstyle},$font);

   
   my $_errorcolor = sub { $errorcolor = shift;
                           my $color   = $errorcolor;
                           my $mbcolor = $errorcolor;
                           $color   =  undef  if($color   eq 'none');
                           $mbcolor = 'white' if($mbcolor eq 'none');
                           $mbcolor = 'white' if($mbcolor eq 'black');
                           $attr->{-color} =  $color;
                           $mb_errorbarcolor->configure(-background       => $mbcolor,
                                                        -activebackground => $mbcolor);
                         };
   
   my @errorcolors = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@errorcolors, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ \&$_errorcolor,  $_ ] ] );
   }
   
   my $_errorwidth = sub { $errorwidth = shift;
                           $attr->{-width} = $errorwidth; };
   my @width = () ;
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
       push(@width, [ 'command' => $_,
                      -font     => $font,
                      -command  => [ $_errorwidth, $_ ] ] );          
   }
   my $frame = $pe->Frame->pack(-side => 'top', -fill => 'x');
   my $f1 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f1->Label(-text => "\nX-ERROR LINE ATTRIBUTES: ",
              -font => $fontb)
      ->pack(-side => 'left', -fill => 'x');
   my $f2 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f2->Label(-text => 'Width, Color, Style',
              -font => $fontb)
      ->pack(-side => 'left');
   $mb_width = $f2->Menubutton(
                  -textvariable => \$errorwidth,
                  -font         => $fontb,
                  -indicator    => 1,
                  -relief       => 'ridge',
                  -menuitems    => [ @width ],
                  -tearoff      => 0)
                  ->pack(-side => 'left', -fill => 'x');  

   $mb_errorbarcolor = $f2->Menubutton(
                          -textvariable => \$errorcolor,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @errorcolors ],
                          -background   => $errorcolorbg, 
                          -activebackground => $errorcolorbg)        
                          ->pack(-side => 'left');
   $mb_dashstyle = $f2->Menubutton(
                          -textvariable => \$attr->{-dashstyle},
                          -font         => $fontb,
                          -width        => 8,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @dashstyle ])
                          ->pack(-side => 'left');
                          

   my $f3 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f3->Label(-text => 'Whisker width',
              -font => $fontb)
      ->pack(-side => 'left', -anchor => 'w');
   $f3->Entry(-textvariable => \$attr->{-whiskerwidth},
              -font         => $font,
              -background   => 'white',
              -width        => 10 )
      ->pack(-side => 'left', -fill => 'x');
   }



sub _displayYErrorOptions {
   my ($data, $pe) = ( shift, shift);
   my ($mb_errorbarcolor, $mb_width, $mb_dashstyle);
   my $attr = $data->{-attributes}->{-yerrorbar};
   my $errorwidth = $attr->{-width};
   my $errorcolor = $attr->{-color};
   my $errorcolorbg = $errorcolor;
      $errorcolor   = 'none'  if(not defined $errorcolor    );
      $errorcolorbg = 'white' if(not defined $errorcolorbg  ); 
      $errorcolorbg = 'white' if( $errorcolor eq 'black'    );
      
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};      

   $attr->{-dashstyle} = 'Solid' if(not defined $attr->{-dashstyle});
   # the above is for backwards compatability
   my @dashstyle = &getDashList(\$attr->{-dashstyle},$font);

   my $_errorcolor = sub { $errorcolor = shift;
                           my $color   = $errorcolor;
                           my $mbcolor = $errorcolor;
                           $color      =  undef  if($color   eq 'none');
                           $mbcolor    = 'white' if($mbcolor eq 'none');
                           $mbcolor    = 'white' if($mbcolor eq 'black');
                           $attr->{-color} =  $color;
                           $mb_errorbarcolor->configure(-background       => $mbcolor,
                                                        -activebackground => $mbcolor);
                         };
   
   my @errorcolors = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@errorcolors, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ \&$_errorcolor,  $_ ] ] );
   }
   
   my $_errorwidth = sub { $errorwidth = shift;
                           $attr->{-width} = $errorwidth; };
   my @width = ();
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
       push(@width, [ 'command' => $_,
                      -font     => $font,
                      -command  => [ $_errorwidth, $_ ] ] );
   }
   
   
   my $frame = $pe->Frame->pack(-side => 'top', -fill => 'x');
   my $f1 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f1->Label(-text => "\nY-ERROR LINE ATTRIBUTES: ",
              -font => $fontb)
      ->pack(-side => 'left', -fill => 'x');
   my $f2 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f2->Label(-text => 'Width, Color, Style',
              -font => $fontb)->pack(-side => 'left');
   $mb_width = $f2->Menubutton(
                  -textvariable => \$errorwidth,
                  -font         => $fontb,
                  -indicator    => 1,
                  -relief       => 'ridge',
                  -menuitems    => [ @width ],
                  -tearoff      => 0)
        ->pack(-side => 'left', -fill => 'x');  

   $mb_errorbarcolor = $f2->Menubutton(
                          -textvariable => \$errorcolor,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @errorcolors ],
                          -background   => $errorcolorbg, 
                          -activebackground => $errorcolorbg)        
                          ->pack(-side => 'left');
   $mb_dashstyle = $f2->Menubutton(
                          -textvariable => \$attr->{-dashstyle},
                          -font         => $fontb,
                          -width        => 8,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @dashstyle ])
                          ->pack(-side => 'left');
   
   my $f3 = $frame->Frame->pack(-side => 'top', -fill => 'x');
   $f3->Label(-text => 'Whisker width',
              -font => $fontb)
      ->pack(-side => 'left', -anchor => 'w');
   $f3->Entry(-textvariable => \$attr->{-whiskerwidth},
              -font         => $font,
              -background   => 'white',
              -width => 10 )
      ->pack(-side => 'left', -fill => 'x');
}


1;
