package Tkg2::Plot::BoxPlot::Editor::CileTab;

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
# $Date: 2006/09/15 15:43:02 $
# $Revision: 1.12 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK
            $LAST_CILE_PAGE_VIEWED
            $TERCILE_WIDTH   
            $QUARTILE_WIDTH     
            $PENTACILE_WIDTH     
            $DECILE_WIDTH     
            $CENTACILE_WIDTH );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_Ciles _checkCiles);

use Tkg2::Base qw(isNumber Message Show_Me_Internals getDashList);

$LAST_CILE_PAGE_VIEWED = 'tcile';

print $::SPLASH "=";


sub _Ciles {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box, $template) = @_;
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   my $nb = $pw->NoteBook(-font => $fontb,
                          -dynamicgeometry => 1)
                 ->pack(-expand => 1, -fill => 'both');
   my $tpage = $nb->add( 'tcile', -label    => 'Tercile',
                                  -raisecmd => sub {$LAST_CILE_PAGE_VIEWED = 'tcile'} );
   my $qpage = $nb->add( 'qcile', -label    => "Quartile",
                                  -raisecmd => sub {$LAST_CILE_PAGE_VIEWED = 'qcile'} );
   my $ppage = $nb->add( 'pcile', -label    => 'Pentacile',
                                  -raisecmd => sub {$LAST_CILE_PAGE_VIEWED = 'pcile'} );
   my $dpage = $nb->add( 'dcile', -label    => 'Decile',
                                  -raisecmd => sub {$LAST_CILE_PAGE_VIEWED = 'dcile'} );
   my $cpage = $nb->add( 'ccile', -label    => 'Centacile',
                                  -raisecmd => sub {$LAST_CILE_PAGE_VIEWED = 'ccile'} );

   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');
   $nb->raise($LAST_CILE_PAGE_VIEWED);
   
   &_really_do_Ciles($tpage,$qpage,$ppage,$dpage,$cpage,$box,$template);
}
 
sub _really_do_Ciles {
   my ($tpage,$qpage,$ppage,$dpage,$cpage,$box,$template) = @_;
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   my $tref = $box->{-tercile};
   my $qref = $box->{-quartile};
   my $pref = $box->{-pentacile};
   my $dref = $box->{-decile};
   my $cref = $box->{-centacile};
  
   $TERCILE_WIDTH   = $template->pixel_to_inch($tref->{-width});
   $QUARTILE_WIDTH  = $template->pixel_to_inch($qref->{-width});
   $PENTACILE_WIDTH = $template->pixel_to_inch($pref->{-width});
   $DECILE_WIDTH    = $template->pixel_to_inch($dref->{-width});
   $CENTACILE_WIDTH = $template->pixel_to_inch($cref->{-width});
   
   $tref->{-dashstyle} = 'Solid' if(not defined $tref->{-dashstyle});
   # the above is for backwards compatability
   my @tdash = &getDashList(\$tref->{-dashstyle},$font);
   $qref->{-dashstyle} = 'Solid' if(not defined $qref->{-dashstyle});
   # the above is for backwards compatability
   my @qdash = &getDashList(\$qref->{-dashstyle},$font);
   $pref->{-dashstyle} = 'Solid' if(not defined $pref->{-dashstyle});
   # the above is for backwards compatability
   my @pdash = &getDashList(\$pref->{-dashstyle},$font);
   $dref->{-dashstyle} = 'Solid' if(not defined $dref->{-dashstyle});
   # the above is for backwards compatability
   my @ddash = &getDashList(\$dref->{-dashstyle},$font);
   $cref->{-dashstyle} = 'Solid' if(not defined $cref->{-dashstyle});
   # the above is for backwards compatability
   my @cdash = &getDashList(\$cref->{-dashstyle},$font);

   
   my @refs   = ( $tref, $qref, $pref, $dref );
   
       
   my $f1_t = $tpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f2_t = $tpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f3_t = $tpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f4_t = $tpage->Frame->pack(-side => 'top', -fill => 'x');
      $f4_t->Label(-text => "")->pack;
         
   my $f1_q = $qpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f2_q = $qpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f3_q = $qpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f4_q = $qpage->Frame->pack(-side => 'top', -fill => 'x');
      $f4_q->Label(-text => "")->pack;
      
   my $f1_p = $ppage->Frame->pack(-side => 'top', -fill => 'x');
   my $f2_p = $ppage->Frame->pack(-side => 'top', -fill => 'x');
   my $f3_p = $ppage->Frame->pack(-side => 'top', -fill => 'x');
   my $f4_p = $ppage->Frame->pack(-side => 'top', -fill => 'x');
      $f4_p->Label(-text => "")->pack;
            
   my $f1_d = $dpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f2_d = $dpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f3_d = $dpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f4_d = $dpage->Frame->pack(-side => 'top', -fill => 'x');
      $f4_d->Label(-text => "")->pack;
   
   my $f1_c = $cpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f2_c = $cpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f3_c = $cpage->Frame->pack(-side => 'top', -fill => 'x');
   my $f4_c = $cpage->Frame->pack(-side => 'top', -fill => 'x');

   $f1_t->Label(-text => "Tercile (33%)  ",
                -font => $fontb)
        ->pack( -side => 'left', -fill => 'x');
   $f1_q->Label(-text => "Quartile (25%) ",
                -font => $fontb)
        ->pack( -side => 'left', -fill => 'x');
   $f1_p->Label(-text => "Pentacile (20%)",
                -font => $fontb)
        ->pack( -side => 'left', -fill => 'x');
   $f1_d->Label(-text => "Decile (10%):  ",
                -font => $fontb)
        ->pack( -side => 'left', -fill => 'x'); 
   $f1_c->Label(-text => "Centacile (1%):",
                -font => $fontb)
        ->pack( -side => 'left', -fill => 'x'); 
   
   $f1_t->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$tref->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left'); 
   $f1_q->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$qref->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left'); 
   $f1_p->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$pref->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left'); 
   $f1_d->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$dref->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left'); 
   $f1_c->Checkbutton(-text     => 'DoIt ',
                      -font     => $fontb,
                      -variable => \$cref->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left'); 
        
   $f1_t->Label(-text => ' Width',
                -font => $fontb)
       ->pack(-side => 'left');
   $f1_t->Entry(-textvariable => \$TERCILE_WIDTH,
                -font         => $font,
                -background   => 'white',
                -width        => 12  )
       ->pack(-side => 'left');
   $f1_q->Label(-text => ' Width',
                -font => $fontb)
       ->pack(-side => 'left');
   $f1_q->Entry(-textvariable => \$QUARTILE_WIDTH,
                -font         => $font,
                -background   => 'white',
                -width        => 12  )
       ->pack(-side => 'left');
   $f1_p->Label(-text => ' Width',
                -font => $fontb)
       ->pack(-side => 'left');
   $f1_p->Entry(-textvariable => \$PENTACILE_WIDTH,
                -font         => $font,
                -background   => 'white',
                -width        => 12  )
       ->pack(-side => 'left');
   $f1_d->Label(-text => ' Width',
                -font => $fontb)
       ->pack(-side => 'left');
   $f1_d->Entry(-textvariable => \$DECILE_WIDTH,
                -font         => $font,
                -background   => 'white',
                -width        => 12  )
       ->pack(-side => 'left');
   $f1_c->Label(-text => ' Width',
                -font => $fontb)
       ->pack(-side => 'left');
   $f1_c->Entry(-textvariable => \$CENTACILE_WIDTH,
                -font         => $font,
                -background   => 'white',
                -width        => 12  )
       ->pack(-side => 'left');

   # LINE THICKNESSES AND DASH STYLE
   my $linewidth_t  = $tref->{-linewidth};
   my $_linewidth_t = sub { $linewidth_t = shift;
                            $tref->{-linewidth} = $linewidth_t;
                          };    
   my $linewidth_q  = $qref->{-linewidth};
   my $_linewidth_q = sub { $linewidth_q = shift;
                            $qref->{-linewidth} = $linewidth_q;
                          }; 
   my $linewidth_p  = $pref->{-linewidth};
   my $_linewidth_p = sub { $linewidth_p = shift;
                            $pref->{-linewidth} = $linewidth_p;
                          }; 
   my $linewidth_d  = $dref->{-linewidth};
   my $_linewidth_d = sub { $linewidth_d = shift;
                            $dref->{-linewidth} = $linewidth_d;
                          };        
   my $linewidth_c  = $cref->{-linewidth};
   my $_linewidth_c = sub { $linewidth_c = shift;
                            $cref->{-linewidth} = $linewidth_c;
                          };                         
   my (@linewidth_t,@linewidth_q,@linewidth_p,@linewidth_d,@linewidth_c);
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@linewidth_t, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_linewidth_t, $_ ] ] );
      push(@linewidth_q, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_linewidth_q, $_ ] ] );
      push(@linewidth_p, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_linewidth_p, $_ ] ] );
      push(@linewidth_d, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_linewidth_d, $_ ] ] ); 
      push(@linewidth_c, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_linewidth_c, $_ ] ] );                                                           
   }
   

   foreach ($f2_t, $f2_q, $f2_p, $f2_d, $f2_c) {
      $_->Label(-text => 'Line Width, Style',
                -font => $fontb)
        ->pack(-side => 'left'); 
   }       
   $f2_t->Menubutton(
        -textvariable => \$linewidth_t,
        -font         => $fontb,
        -width        => 6,
        -indicator    => 1,
        -relief       => 'ridge',
        -menuitems    => [ @linewidth_t ],
        -tearoff      => 0)
        ->pack(-side => 'left'); 
   $f2_q->Menubutton(
        -textvariable => \$linewidth_q,
        -font         => $fontb,
        -width        => 6,
        -indicator    => 1,
        -relief       => 'ridge',
        -menuitems    => [ @linewidth_q ],
        -tearoff      => 0)
        ->pack(-side => 'left'); 
   $f2_p->Menubutton(
        -textvariable => \$linewidth_p,
        -font         => $fontb,
        -width        => 6,
        -indicator    => 1,
        -relief       => 'ridge',
        -menuitems    => [ @linewidth_p ],
        -tearoff      => 0)
        ->pack(-side => 'left'); 
   $f2_d->Menubutton(
        -textvariable => \$linewidth_d,
        -font         => $fontb,
        -width        => 6,
        -indicator    => 1,
        -relief       => 'ridge',
        -menuitems    => [ @linewidth_d ],
        -tearoff      => 0)
        ->pack(-side => 'left');   
   $f2_c->Menubutton(
        -textvariable => \$linewidth_c,
        -font         => $fontb,
        -width        => 6,
        -indicator    => 1,
        -relief       => 'ridge',
        -menuitems    => [ @linewidth_c ],
        -tearoff      => 0)
        ->pack(-side => 'left');     

   my $mb_dashstyle_t = $f2_t->Menubutton(
                          -textvariable => \$tref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @tdash ])
                          ->pack(-side => 'left');
   my $mb_dashstyle_q = $f2_q->Menubutton(
                          -textvariable => \$qref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @qdash ])
                          ->pack(-side => 'left');   
   my $mb_dashstyle_p = $f2_p->Menubutton(
                          -textvariable => \$pref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @pdash ])
                          ->pack(-side => 'left');   
   my $mb_dashstyle_d = $f2_d->Menubutton(
                          -textvariable => \$dref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @ddash ])
                          ->pack(-side => 'left');   
   my $mb_dashstyle_c = $f2_c->Menubutton(
                          -textvariable => \$cref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @cdash ])
                          ->pack(-side => 'left');   


   #### LINE COLOR ############
   
   my $pickedlinecolor_t   = $tref->{-linecolor};
   my $pickedlinecolorbg_t = $pickedlinecolor_t;
      $pickedlinecolor_t   = 'none'  if(not defined($pickedlinecolor_t)   );
      $pickedlinecolorbg_t = 'white' if(not defined($pickedlinecolorbg_t) ); 
      $pickedlinecolorbg_t = 'white' if( $pickedlinecolor_t eq 'black'    );  
   my $mb_linecolor_t;    
   my $_linecolor_t = sub { $pickedlinecolor_t = shift;
                            my $color   = $pickedlinecolor_t;
                            my $mbcolor = $pickedlinecolor_t;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $tref->{-linecolor} = $color;
                            $mb_linecolor_t->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
                        
   my $pickedlinecolor_q   = $qref->{-linecolor};
   my $pickedlinecolorbg_q = $pickedlinecolor_q;
      $pickedlinecolor_q   = 'none'  if(not defined($pickedlinecolor_q)   );
      $pickedlinecolorbg_q = 'white' if(not defined($pickedlinecolorbg_q) ); 
      $pickedlinecolorbg_q = 'white' if( $pickedlinecolor_q eq 'black'    );  
   my $mb_linecolor_q;    
   my $_linecolor_q = sub { $pickedlinecolor_q = shift;
                            my $color   = $pickedlinecolor_q;
                            my $mbcolor = $pickedlinecolor_q;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $qref->{-linecolor} = $color;
                            $mb_linecolor_q->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };
   
   my $pickedlinecolor_p   = $pref->{-linecolor};
   my $pickedlinecolorbg_p = $pickedlinecolor_p;
      $pickedlinecolor_p   = 'none'  if(not defined($pickedlinecolor_p)   );
      $pickedlinecolorbg_p = 'white' if(not defined($pickedlinecolorbg_p) ); 
      $pickedlinecolorbg_p = 'white' if( $pickedlinecolor_p eq 'black'    );  
   my $mb_linecolor_p;    
   my $_linecolor_p = sub { $pickedlinecolor_p = shift;
                            my $color   = $pickedlinecolor_p;
                            my $mbcolor = $pickedlinecolor_p;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $pref->{-linecolor} = $color;
                            $mb_linecolor_p->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
   
   my $pickedlinecolor_d   = $dref->{-linecolor};
   my $pickedlinecolorbg_d = $pickedlinecolor_d;
      $pickedlinecolor_d   = 'none'  if(not defined($pickedlinecolor_d)   );
      $pickedlinecolorbg_d = 'white' if(not defined($pickedlinecolorbg_d) ); 
      $pickedlinecolorbg_d = 'white' if( $pickedlinecolor_d eq 'black'    );  
   my $mb_linecolor_d;    
   my $_linecolor_d = sub { $pickedlinecolor_d = shift;
                            my $color   = $pickedlinecolor_d;
                            my $mbcolor = $pickedlinecolor_d;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $dref->{-linecolor} = $color;
                            $mb_linecolor_d->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };          

   my $pickedlinecolor_c   = $cref->{-linecolor};
   my $pickedlinecolorbg_c = $pickedlinecolor_c;
      $pickedlinecolor_c   = 'none'  if(not defined($pickedlinecolor_c)   );
      $pickedlinecolorbg_c = 'white' if(not defined($pickedlinecolorbg_c) ); 
      $pickedlinecolorbg_c = 'white' if( $pickedlinecolor_c eq 'black'    );  
   my $mb_linecolor_c;    
   my $_linecolor_c = sub { $pickedlinecolor_c = shift;
                            my $color   = $pickedlinecolor_c;
                            my $mbcolor = $pickedlinecolor_c;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $cref->{-linecolor} = $color;
                            $mb_linecolor_c->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };          

   
   my (@linecolor_t,@linecolor_q,@linecolor_p,@linecolor_d,@linecolor_c);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@linecolor_t,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_linecolor_t,  $_ ] ] );
      push(@linecolor_q,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_linecolor_q,  $_ ] ] );
      push(@linecolor_p,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_linecolor_p,  $_ ] ] );
      push(@linecolor_d,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_linecolor_d,  $_ ] ] );
      push(@linecolor_c,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_linecolor_c,  $_ ] ] );
   }
        
   $f3_t->Label(-text => 'Line Color, Fill ', 
                -font => $fontb)
        ->pack(-side => 'left');
   $f3_q->Label(-text => 'Line Color, Fill ',
                -font => $fontb)
        ->pack(-side => 'left');
   $f3_p->Label(-text => 'Line Color, Fill ',
                -font => $fontb)
        ->pack(-side => 'left');
   $f3_d->Label(-text => 'Line Color, Fill ',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $f3_c->Label(-text => 'Line Color, Fill ',
                -font => $fontb)
        ->pack(-side => 'left'); 
   
   $mb_linecolor_t = $f3_t->Menubutton(
                          -textvariable => \$pickedlinecolor_t,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linecolor_t ],
                          -background   => $pickedlinecolorbg_t,
                          -activebackground => $pickedlinecolorbg_t )
                          ->pack(-side => 'left');
   
   $mb_linecolor_q = $f3_q->Menubutton(
                          -textvariable => \$pickedlinecolor_q,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linecolor_q ],
                          -background   => $pickedlinecolorbg_q,
                          -activebackground => $pickedlinecolorbg_q )
                          ->pack(-side => 'left');
                          
   $mb_linecolor_p = $f3_p->Menubutton(
                          -textvariable => \$pickedlinecolor_p,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linecolor_p ],
                          -background   => $pickedlinecolorbg_p,
                          -activebackground => $pickedlinecolorbg_p )
                          ->pack(-side => 'left');                        
   
   
   $mb_linecolor_d = $f3_d->Menubutton(
                          -textvariable => \$pickedlinecolor_d,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linecolor_d ],
                          -background   => $pickedlinecolorbg_d,
                          -activebackground => $pickedlinecolorbg_d )
                          ->pack(-side => 'left');
                          
   $mb_linecolor_c = $f3_c->Menubutton(
                          -textvariable => \$pickedlinecolor_c,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linecolor_c ],
                          -background   => $pickedlinecolorbg_c,
                          -activebackground => $pickedlinecolorbg_c )
                          ->pack(-side => 'left');
   
   
   
   ###### FILL COLOR ###############
   my $pickedfillcolor_t   = $tref->{-fillcolor};
   my $pickedfillcolorbg_t = $pickedfillcolor_t;
      $pickedfillcolor_t   = 'none'  if(not defined($pickedfillcolor_t)   );
      $pickedfillcolorbg_t = 'white' if(not defined($pickedfillcolorbg_t) ); 
      $pickedfillcolorbg_t = 'white' if( $pickedfillcolor_t eq 'black'    );  
   my $mb_fillcolor_t;    
   my $_fillcolor_t = sub { $pickedfillcolor_t = shift;
                            my $color   = $pickedfillcolor_t;
                            my $mbcolor = $pickedfillcolor_t;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $tref->{-fillcolor} = $color;
                            $mb_fillcolor_t->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
                        
   my $pickedfillcolor_q   = $qref->{-fillcolor};
   my $pickedfillcolorbg_q = $pickedfillcolor_q;
      $pickedfillcolor_q   = 'none'  if(not defined($pickedfillcolor_q)   );
      $pickedfillcolorbg_q = 'white' if(not defined($pickedfillcolorbg_q) ); 
      $pickedfillcolorbg_q = 'white' if( $pickedfillcolor_q eq 'black'    );  
   my $mb_fillcolor_q;    
   my $_fillcolor_q = sub { $pickedfillcolor_q = shift;
                            my $color   = $pickedfillcolor_q;
                            my $mbcolor = $pickedfillcolor_q;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $qref->{-fillcolor} = $color;
                            $mb_fillcolor_q->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };
   
   my $pickedfillcolor_p   = $pref->{-fillcolor};
   my $pickedfillcolorbg_p = $pickedfillcolor_p;
      $pickedfillcolor_p   = 'none'  if(not defined($pickedfillcolor_p)   );
      $pickedfillcolorbg_p = 'white' if(not defined($pickedfillcolorbg_p) ); 
      $pickedfillcolorbg_p = 'white' if( $pickedfillcolor_p eq 'black'    );  
   my $mb_fillcolor_p;    
   my $_fillcolor_p = sub { $pickedfillcolor_p = shift;
                            my $color   = $pickedfillcolor_p;
                            my $mbcolor = $pickedfillcolor_p;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $pref->{-fillcolor} = $color;
                            $mb_fillcolor_p->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
   
   my $pickedfillcolor_d   = $dref->{-fillcolor};
   my $pickedfillcolorbg_d = $pickedfillcolor_d;
      $pickedfillcolor_d   = 'none'  if(not defined($pickedfillcolor_d)   );
      $pickedfillcolorbg_d = 'white' if(not defined($pickedfillcolorbg_d) ); 
      $pickedfillcolorbg_d = 'white' if( $pickedfillcolor_d eq 'black'    );  
   my $mb_fillcolor_d;    
   my $_fillcolor_d = sub { $pickedfillcolor_d = shift;
                            my $color   = $pickedfillcolor_d;
                            my $mbcolor = $pickedfillcolor_d;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $dref->{-fillcolor} = $color;
                            $mb_fillcolor_d->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        }; 
                                 
   my $pickedfillcolor_c   = $cref->{-fillcolor};
   my $pickedfillcolorbg_c = $pickedfillcolor_c;
      $pickedfillcolor_c   = 'none'  if(not defined($pickedfillcolor_c)   );
      $pickedfillcolorbg_c = 'white' if(not defined($pickedfillcolorbg_c) ); 
      $pickedfillcolorbg_d = 'white' if( $pickedfillcolor_c eq 'black'    );  
   my $mb_fillcolor_c;    
   my $_fillcolor_c = sub { $pickedfillcolor_c = shift;
                            my $color   = $pickedfillcolor_c;
                            my $mbcolor = $pickedfillcolor_c;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $cref->{-fillcolor} = $color;
                            $mb_fillcolor_c->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };          
 
   my (@fillcolor_t,@fillcolor_q,@fillcolor_p,@fillcolor_d,@fillcolor_c);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@fillcolor_t,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_fillcolor_t,  $_ ] ] );
      push(@fillcolor_q,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_fillcolor_q,  $_ ] ] );
      push(@fillcolor_p,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_fillcolor_p,  $_ ] ] );
      push(@fillcolor_d,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_fillcolor_d,  $_ ] ] );
      push(@fillcolor_c,  [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_fillcolor_c,  $_ ] ] );
   }
   
   $mb_fillcolor_t = $f3_t->Menubutton(
                          -textvariable => \$pickedfillcolor_t,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @fillcolor_t ],
                          -background   => $pickedfillcolorbg_t,
                          -activebackground => $pickedfillcolorbg_t )
                          ->pack(-side => 'left');
   
   $mb_fillcolor_q = $f3_q->Menubutton(
                          -textvariable => \$pickedfillcolor_q,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @fillcolor_q ],
                          -background   => $pickedfillcolorbg_q,
                          -activebackground => $pickedfillcolorbg_q )
                          ->pack(-side => 'left');
                          
   $mb_fillcolor_p = $f3_p->Menubutton(
                          -textvariable => \$pickedfillcolor_p,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @fillcolor_p ],
                          -background   => $pickedfillcolorbg_p,
                          -activebackground => $pickedfillcolorbg_p )
                          ->pack(-side => 'left');                        
   
   
   $mb_fillcolor_d = $f3_d->Menubutton(
                          -textvariable => \$pickedfillcolor_d,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @fillcolor_d ],
                          -background   => $pickedfillcolorbg_d,
                          -activebackground => $pickedfillcolorbg_d )
                          ->pack(-side => 'left');
   $mb_fillcolor_c = $f3_c->Menubutton(
                          -textvariable => \$pickedfillcolor_c,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @fillcolor_c ],
                          -background   => $pickedfillcolorbg_c,
                          -activebackground => $pickedfillcolorbg_c )
                          ->pack(-side => 'left');
}


sub _checkCiles {
   my ($box, $pe) = @_;  
   
   my %refs = ( -tercile   => $TERCILE_WIDTH,
                -quartile  => $QUARTILE_WIDTH,
                -pentacile => $PENTACILE_WIDTH,
                -decile    => $DECILE_WIDTH,
                -centacile => $CENTACILE_WIDTH );
  
   foreach my $key (sort keys %refs) {
     my $wref = \$refs{$key};
     my ($size) = $$wref =~ m/([0-9.]+)/;
     if( defined($size) and &isNumber($size) ) {
        $size .= "i";
        $$wref = $size;
        $box->{$key}->{-width} = $pe->fpixels($size);
     }
     else {
        my $mess = "Invalid box width for $key\n";
        &Message($pe,'-generic', $mess);
        return 0;
     }
   }
   return 1;
}


1;
