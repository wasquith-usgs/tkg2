package Tkg2::Plot::Editors::PlotEditor;

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
# $Date: 2002/08/07 18:25:31 $
# $Revision: 1.34 $

use strict;
use vars qw(@ISA @EXPORT $LAST_PAGE_VIEWED $EDITOR);

use Exporter;
use SelfLoader;

use Tkg2::Base qw(Message isNumber Show_Me_Internals getDashList);
use Tk::NoteBook;

use Tkg2::Help::Help;

use Tkg2::Plot::Editors::EditorWidgets qw(AutoPlotLimitWidget);

@ISA = qw(Exporter SelfLoader);
@EXPORT = qw(PlotEditor); 
$LAST_PAGE_VIEWED = undef;
$EDITOR = "";

print $::SPLASH "=";

1;
__DATA__
# PlotEditor is a large dialog box that controls the settings of parameters that
# are considered to be plot-wide and are not duplicated by additional data added 
# to the plot.
sub PlotEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $template) = (shift, shift, shift); 
   my $pw = $canv->parent;
   my ($mb_plotcolor, $mb_canvascolor);
   my $separator = 47;
   my ($mb_explanfillcolor, $mb_explanlinecolor, $mb_exfontcolor, $mb_ptfontcolor);
   my ($mb_borderwidth, $mb_explanborderwidth, $mb_colspacing);
   my $mb_plotbordercolor;

   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};

   # convenient references
   my $xref  = $self->{-x};
   my $yref  = $self->{-y};
   my $y2ref = $self->{-y2};
   my $exref = $self->{-explanation};
   my $plotborderwidth   = $self->{-borderwidth};
   my $explanborderwidth = $exref->{-outlinewidth};
   my $colspacing        = $exref->{-colspacing};
   
   # BACKWARDS COMPATABILITY FOR TKG2 0.61 and on
   $self->{-borderdashstyle} = 'Solid' if(not defined $self->{-borderdashstyle});
   # the above is for backwards compatability
   my @borderdashstyle = &getDashList(\$self->{-borderdashstyle},$font);
   # BACKWARDS COMPATABILITY FOR TKG2 0.61 and on
   $exref->{-dashstyle} = 'Solid' if(not defined $exref->{-dashstyle});
   # the above is for backwards compatability
   my @exdashstyle = &getDashList(\$exref->{-dashstyle},$font);

   
   
   # all this stuff associated with color is needed to have the menubuttons
   # so the shade of the color
   my $pickedcanvascolor = $template->{-color};
   my $pickedcanvascolorbg = $pickedcanvascolor;
      $pickedcanvascolorbg = 'white' if($pickedcanvascolorbg eq 'black');
         
   my $pickedplotcolor   = $self->{-plotbgcolor};
   my $pickedplotcolorbg = $pickedplotcolor;
      $pickedplotcolor   = 'none'  if(not defined $pickedplotcolor   );
      $pickedplotcolorbg = 'white' if(not defined $pickedplotcolorbg );
      $pickedplotcolorbg = 'white' if($pickedplotcolor eq 'black');
     
   my $pickedbordercolor   = $self->{-bordercolor};
   my $pickedbordercolorbg = $pickedbordercolor;
      $pickedbordercolor   = 'none'  if(not defined $pickedbordercolor   );
      $pickedbordercolorbg = 'white' if(not defined $pickedbordercolorbg );
      $pickedbordercolorbg = 'white' if($pickedbordercolor eq 'black');
      
   my $pickedfillcolor   = $exref->{-fillcolor};
   my $pickedfillcolorbg = $pickedfillcolor;
      $pickedfillcolor   = 'none'  if(not defined $pickedfillcolor   );
      $pickedfillcolorbg = 'white' if(not defined $pickedfillcolorbg );
      $pickedfillcolorbg = 'white' if($pickedfillcolor eq 'black');
      
   my $pickedlinecolor   = $exref->{-outlinecolor};
   my $pickedlinecolorbg = $pickedlinecolor;
      $pickedlinecolor   = 'none'  if(not defined $pickedlinecolor   ); 
      $pickedlinecolorbg = 'white' if(not defined $pickedlinecolorbg );
      $pickedlinecolorbg = 'white' if($pickedlinecolor eq 'black');

   my $ptref = $self->{-plottitlefont};
   my ($ptfontfam, $ptfontwgt, $ptfontslant, $ptfontcolor) =
      ($ptref->{-family},  $ptref->{-weight}, $ptref->{-slant}, $ptref->{-color} );
   my $ptfontcolorbg = $ptfontcolor;
      $ptfontcolorbg = 'white' if($ptfontcolorbg eq 'black');
          
   my $_ptfontfam   = sub { $ptfontfam = shift;
                            $ptref->{-family} = $ptfontfam; };
   my $_ptfontwgt   = sub { $ptfontwgt = shift;
                            $ptref->{-weight} = $ptfontwgt; };
   my $_ptfontslant = sub { $ptfontslant = shift;
                            $ptref->{-slant} = $ptfontslant; };
   my $_ptfontcolor = sub { $ptfontcolor = shift;
                            $ptref->{-color} = $ptfontcolor;
                            my $mbcolor = $ptfontcolor;
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $mb_ptfontcolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor); };
   my $exfontref = $exref->{-font};
   my ($exfontfam, $exfontwgt, $exfontslant, $exfontcolor) =
        ( $exfontref->{-family},  $exfontref->{-weight},
          $exfontref->{-slant} ,  $exfontref->{-color}  );    
   my $exfontcolorbg = $exfontcolor;
      $exfontcolorbg = 'white' if($exfontcolorbg eq 'black');

   my $_exfontfam   = sub { $exfontfam            = shift;
                            $exfontref->{-family} = $exfontfam; };
   my $_exfontwgt   = sub { $exfontwgt            = shift;
                            $exfontref->{-weight} = $exfontwgt; };
   my $_exfontslant = sub { $exfontslant          = shift;
                            $exfontref->{-slant}  = $exfontslant; };
   my $_exfontcolor = sub { $exfontcolor          = shift;
                            $exfontref->{-color}  = $exfontcolor;
                            my $mbcolor = $exfontcolor;
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $mb_exfontcolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor); };
 
   my $_borderwidth = sub { $plotborderwidth      = shift;
                            $self->{-borderwidth} = $plotborderwidth };
                            
   my $_explanborderwidth = sub { $explanborderwidth      = shift;
                                  $exref->{-outlinewidth} = $explanborderwidth };
 
   my $_colspacing = sub { $colspacing = shift;
                           $exref->{-colspacing} = $colspacing };
   
   my $_plotcolor = sub { $pickedplotcolor = shift;
                          my $color   = $pickedplotcolor;
                          my $mbcolor = $pickedplotcolor;
                          $color   =  undef  if($color   eq 'none');
                          $mbcolor = 'white' if($mbcolor eq 'none' or
                                                $mbcolor eq 'black');
                          $self->{-plotbgcolor} = $color;
                          $mb_plotcolor->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor); };
                                                   
   my $_plotbordercolor = sub { $pickedbordercolor = shift;
                                my $color   = $pickedbordercolor;
                                my $mbcolor = $pickedbordercolor;
                                $color   =  undef  if($color   eq 'none');
                                $mbcolor = 'white' if($mbcolor eq 'none' or
                                                      $mbcolor eq 'black');
                                $self->{-bordercolor} = $color;
                                $mb_plotbordercolor->configure(-background       => $mbcolor,
                                                               -activebackground => $mbcolor); };
                                                                                                      
   my $_canvascolor = sub { $pickedcanvascolor  = shift;
                            $template->{-color} = $pickedcanvascolor;
                            my $mbcolor = $pickedcanvascolor;
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $mb_canvascolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                            $canv->configure(-background => $pickedcanvascolor); };

   my $_explanfillcolor = sub { $pickedfillcolor = shift;
                                my $color   = $pickedfillcolor;
                                my $mbcolor = $pickedfillcolor;
                                $color   =  undef  if($color   eq 'none');
                                $mbcolor = 'white' if($mbcolor eq 'none' or
                                                      $mbcolor eq 'black');
                                $exref->{-fillcolor} = $color;
                                $mb_explanfillcolor->configure(-background       => $mbcolor,
                                                               -activebackground => $mbcolor); };
   my $_explanlinecolor = sub { $pickedlinecolor = shift;
                                my $color   = $pickedlinecolor;
                                my $mbcolor = $pickedlinecolor;
                                $color   =  undef  if($color   eq 'none');
                                $mbcolor = 'white' if($mbcolor eq 'none' or
                                                      $mbcolor eq 'black');
                                $exref->{-outlinecolor} = $color;
                                $mb_explanlinecolor->configure(-background       => $mbcolor,
                                                               -activebackground => $mbcolor); };
   
   # now that anonymous subs for controlling the menubuttons are build, we need to build
   # up the arrays that will be used to build the menubuttons.                                            
   my (@plotcolors, @bordercolors, @canvascolors, @explanfillcolors) = ( (), (), (), () );
   my (@explanlinecolors, @exfontcolors, @ptfontcolors) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-COLORS}}) {
      push(@plotcolors,       [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_plotcolor, $_ ] ] );
      push(@bordercolors,     [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_plotbordercolor, $_ ] ] );
      push(@explanfillcolors, [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_explanfillcolor, $_ ] ] );
      push(@explanlinecolors, [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_explanlinecolor, $_ ] ] );
                                    
      next if(/none/o);  # canvas and fonts can not have none coloring 
      push(@canvascolors,     [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_canvascolor, $_ ] ] );
      push(@ptfontcolors,     [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_ptfontcolor, $_ ] ] );         
      push(@exfontcolors,     [ 'command'    => $_,
                                    -font    => $font,
                                    -command => [ \&$_exfontcolor, $_ ] ] );         
   } 

   my (@ptfontfam, @exfontfam) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-FONTS}}) {
      push(@ptfontfam,   [ 'command'    => $_,
                               -font    => $font,
                               -command => [ \&$_ptfontfam, $_ ] ] );
      push(@exfontfam,   [ 'command'    => $_,
                               -font    => $font,
                               -command => [ \&$_exfontfam, $_ ] ] );
   }
   
   my (@ptfontwgt, @exfontwgt) = ( (), () );
   foreach (qw(normal bold)) {
      push(@ptfontwgt,   [ 'command'    => $_,
                               -font    => $font,
                               -command => [ \&$_ptfontwgt, $_ ] ] );
      push(@exfontwgt,   [ 'command'    => $_,
                               -font    => $font,
                               -command => [ \&$_exfontwgt, $_ ] ] );
   }               
   
   my (@ptfontslant, @exfontslant) = ( (), () );
   foreach (qw(roman italic)) {
      push(@ptfontslant,   [ 'command'    => $_,
                                 -font    => $font,
                                 -command => [ \&$_ptfontslant, $_ ] ] );
      push(@exfontslant,   [ 'command'    => $_,
                                 -font    => $font,
                                 -command => [ \&$_exfontslant, $_ ] ] );
   }   
   my (@borderwidth, @explanborderwidth) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
      push(@borderwidth,       [ 'command'    => $_,
                                     -font    => $font,
                                     -command => [ \&$_borderwidth, $_ ] ] );
      push(@explanborderwidth, [ 'command'    => $_,
                                     -font    => $font,
                                     -command => [ \&$_explanborderwidth, $_ ] ] );
   }

   my @colspacing;
   foreach ( qw(0.10i 0.20i 0.30i 0.40i 0.50i 0.60i 0.70i 0.80i 0.90i 1.00i) ) {
      push(@colspacing, [ 'command' => $_,
                          -font     => $font,
                          -command  => [ \&$_colspacing, $_ ] ] );
   } 
   
   my $finishsub;

   my ($xlmargin, $xrmargin) = ($self->{-xlmargin}, $self->{-xrmargin});
   my ($yumargin, $ylmargin) = ($self->{-yumargin}, $self->{-ylmargin});
       $xlmargin = '1.75i' unless( defined $xlmargin );
       $xrmargin = '1i'    unless( defined $xrmargin );
       $yumargin = '1i'    unless( defined $yumargin );
       $ylmargin = '2i'    unless( defined $ylmargin );
       
   foreach ($xlmargin, $xrmargin, $yumargin, $ylmargin) {
       $_ = $template->pixel_to_inch($_);
   }


   my $plottitlexoffset = $self->{-plottitlexoffset};
   my $plottitleyoffset = $self->{-plottitleyoffset};
   foreach ($plottitlexoffset, $plottitleyoffset) {
       $_ = $template->pixel_to_inch($_);
   }
   
   my $explantitlexoffset = $exref->{-titlexoffset};
   my $explantitleyoffset = $exref->{-titleyoffset};
   my $explanvertspacing  = $exref->{-vertspacing};
   my $explanhorzgap      = $exref->{-horzgap};
   foreach ($explantitlexoffset, $explantitleyoffset,
            $explanvertspacing,  $explanhorzgap) {
       $_ = $template->pixel_to_inch($_);   
   }         
         
   my ($px, $py) = (2, 2);

   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Tkg2 Plot Editor');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   $pe->Label(-text => 'CONFIGURE PLOT-WIDE PARAMETERS',
              -font => $fontbig)
      ->pack( -fill =>'x');
      
   my $nb    = $pe->NoteBook(-font => $fontb) 
                  ->pack(-expand => 1, -fill => 'both');   
   my $page1 = $nb->add('page1',
                  -label => 'Plot',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page1'});
   my $page2 = $nb->add('page2',
                  -label => 'Plot Title',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page2'});
   my $page3 = $nb->add('page3',
                  -label => 'Explanation',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page3'});
   $nb->raise($LAST_PAGE_VIEWED);
   
   my $f_m1 = $page1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_m1->Label(-text => 'Left margin  ',
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_m1->Entry(-textvariable => \$xlmargin,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');
   $f_m1->Label(-text => '  Right margin ',
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_m1->Entry(-textvariable => \$xrmargin,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');

        
   my $f_m2 = $page1->Frame->pack(-side => 'top', -fill => 'x');                        
   $f_m2->Label(-text => 'Top margin   ',
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_m2->Entry(-textvariable => \$yumargin,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');
        
   $f_m2->Label(-text => '  Bottom margin',
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_m2->Entry(-textvariable => \$ylmargin,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');


   my $f_c = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_c->Label(-text => 'Page: Color ',
               -font => $fontb)
       ->pack(-side => 'left');   
   $mb_canvascolor = $f_c->Menubutton(
                         -textvariable => \$pickedcanvascolor,
                         -font         => $fontb,
                         -indicator    => 1,
                         -relief       => 'ridge',
                         -menuitems    => [ @canvascolors ],
                         -tearoff      => 0,
                         -background   => $pickedcanvascolorbg,
                         -activebackground => $pickedcanvascolorbg )
                         ->pack(-side => 'left');
  
  
   # Specify auto plot limit configuration, additional data read in after modifying
   # these selections will cause the limits to potentially change.  Each axis can be
   # controlled via the ContinuousAxisEditor, which will usually be the prefered route.
   my $f_a1 = $page1->Frame->pack(-side => 'top', -fill => 'x');   
   &AutoPlotLimitWidget($f_a1,$xref,"  X");
   
   my $f_a2 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   &AutoPlotLimitWidget($f_a2,$yref,"  Y");
   
   my $f_a22 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   &AutoPlotLimitWidget($f_a22,$y2ref," Y2");
   
   
   # Widgets to make the axis square if and only if the axis types are
   # identical
   # 0.50.4 Backwards compatability
   $yref->{-make_axis_square}  = 0 if(not defined $yref->{-make_axis_square});
   $y2ref->{-make_axis_square} = 0 if(not defined $y2ref->{-make_axis_square});
   my $f_asq1 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_asq1->Label(-text => "Square Y1 Axis on X (iff type equal): ",
                  -font => $fontb)
          ->pack(-side => 'left'); 
   $f_asq1->Checkbutton(-font     => $fontb,
                        -variable => \$yref->{-make_axis_square},
                        -onvalue  => 1,
                        -offvalue => 0)
          ->pack(-side => 'left');
   $f_asq1->Button(-text => "Square Axis Now",
                   -font => $fontb,
                   -command => sub { $self->makeAxisSquare($self);
                                     $template->UpdateCanvas($canv); })
          ->pack(-side => 'left');
   

   my $f_asq2 = $page1->Frame->pack(-side => 'top', -fill => 'x');                                                        
   $f_asq2->Label(-text => 'Square Y2 Axis on X (iff type equal): ',
                  -font => $fontb)
          ->pack(-side => 'left');
   $f_asq2->Checkbutton(-font     => $fontb,
                        -variable => \$y2ref->{-make_axis_square},
                        -onvalue  => 1,
                        -offvalue => 0)
          ->pack(-side => 'left');
   
   my $f_bw = $page1->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_bw->Label(-text => "Border width, color, style",
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $mb_borderwidth = $f_bw->Menubutton(
                          -textvariable => \$plotborderwidth,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @borderwidth ],
                          -tearoff      => 0)
                          ->pack(-side => 'left', -fill => 'x');   
   
   $mb_plotbordercolor = $f_bw->Menubutton(
                              -textvariable => \$pickedbordercolor,
                              -font         => $fontb,
                              -indicator    => 1,
                              -width        => 12,
                              -relief       => 'ridge',
                              -menuitems    => [ @bordercolors ],
                              -tearoff      => 0,
                              -background   => $pickedbordercolorbg,
                              -activebackground => $pickedbordercolorbg)
                              ->pack(-side => 'left'); 
   my $mb_borderdashstyle = $f_bw->Menubutton(
                          -textvariable => \$self->{-borderdashstyle},
                          -font         => $fontb,
                          -width        => 8,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @borderdashstyle ])
                          ->pack(-side => 'left');
   my $f_d = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_d->Label(-text => 'Background: Color ',
               -font => $fontb)
       ->pack(-side => 'left');   
   $mb_plotcolor = $f_d->Menubutton(
                       -textvariable => \$pickedplotcolor,
                       -font         => $fontb,
                       -indicator    => 1,
                       -width        => 12,
                       -relief       => 'ridge',
                       -menuitems    => [ @plotcolors ],
                       -tearoff      => 0,
                       -background   => $pickedplotcolorbg,
                       -activebackground => $pickedplotcolorbg)
                       ->pack(-side => 'left');
    
   my $f_sw = $page1->Frame->pack(-side => 'top', -fill => 'x');   
   $f_sw->Button(-text     => 'Switch X/Y axis if no double Y',
                 -font     => $fontb,
                 -command  => sub { $self = $self->switchAxis;
                                    $template->UpdateCanvas($canv); } )
        ->pack(-side => 'left');
  my $f_sp = $page1->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_sp->Button(-text     => 'All axes to percent base',
                -font     => $fontb,
                -command  => sub { $self->configureAxisToPercentBase('x');
                                   $self->configureAxisToPercentBase('y1');
                                   $self->configureAxisToPercentBase('y2');
                                   $template->UpdateCanvas($canv);
                                 } )
       ->pack(-side => 'left');
  $f_sp->Button(-text     => 'All axes to frac. percent base',
                -font     => $fontb,
                -command  => sub { $self->configureAxisToPercentBase('x','frac');
                                   $self->configureAxisToPercentBase('y1','frac');
                                   $self->configureAxisToPercentBase('y2','frac');
                                   $template->UpdateCanvas($canv);
                                 } )
       ->pack(-side => 'left');
   
   my $f_np = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_np->Label(-text => 'Plot Name',
                -font => $fontb,
                -anchor => 'w')
        ->pack(-side => 'top', -fill => 'x');
   $f_np->Entry(-textvariable => \$self->{-username},
                -width        => 30,
                -font         => $font,
                -background   => 'white')
        ->pack(-side => 'top', -fill => 'x');
        
   $self->{-doit} = 1 unless(exists $self->{-doit}); # help with backward
   # compatability for 0.40.  turn doit on unless the plot already
   # knows about it.
   $f_np->Checkbutton(-text     => 'DoIt (actually draw the plot)',
                      -font     => $fontb,
                      -variable => \$self->{-doit},
                      -anchor   => 'w',
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'top', -fill => 'x');

      
   # PAGE 2     
   $page2->Label(-text => "Title",
                 -font => $fontb)
         ->pack(-side => 'top', -anchor => 'w');     
   $page2->Entry(-textvariable => \$self->{-plottitle},
                 -font         => $font,
                 -background   => 'white' )
         ->pack(-side => 'top', -fill => 'x');
   
   my $f_pt = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_pt->Label(-text => 'Font, Size, Wgt, Slant, Color',
                -font => $fontb)
        ->pack(-side => 'top', -anchor => 'w');   
   $f_pt->Menubutton(-textvariable => \$ptfontfam,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @ptfontfam ],
                     -width        => 10)
        ->pack(-side => 'left');
   $f_pt->Entry(-textvariable => \$ptref->{-size},
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left');
   $f_pt->Menubutton(-textvariable => \$ptfontwgt,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @ptfontwgt ],
                     -width        => 6)
        ->pack(-side => 'left');
   $f_pt->Menubutton(-textvariable => \$ptfontslant,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @ptfontslant ],
                     -width        => 6)
        ->pack(-side => 'left');   
   $mb_ptfontcolor = $f_pt->Menubutton(
                          -textvariable => \$ptfontcolor,
                          -font         => $fontb,
                          -indicator    => 1, 
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @ptfontcolors ],
                          -background   => $ptfontcolorbg, 
                          -activebackground => $ptfontcolorbg)        
                          ->pack(-side => 'left');

   
   
   my $f_o1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o1->Label(-text => "Title X-offset",
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_o1->Entry(-textvariable => \$plottitlexoffset,
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left', -fill => 'x');

   $f_o1->Label(-text => "    Y-offset",
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_o1->Entry(-textvariable => \$plottitleyoffset,
                -font         => $font,
                -background   => 'white',
                -width => 10  )
        ->pack(-side => 'left', -fill => 'x');   
   $f_o1->Checkbutton(-text     => "Stack Text",
                      -font     => $fontb,
                      -variable => \$ptref->{-stackit},
                      -onvalue  => 1,
                      -offvalue => 0)
         ->pack(-side => 'left', -fill => 'x');

   
   # EXPLANATION
   my $f_e1 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_e1->Checkbutton(-text     => 'Hide Explanation',
                      -font     => $fontb,
                      -offvalue => 0,
                      -onvalue  => 1,
                      -variable => \$exref->{-hide})
        ->pack(-side => 'left', -fill => 'x');          
   $f_e1->Button(-text    => 'Reset Position',
                 -font    => $fontb,
                 -command => sub { $exref->{-xorigin} = undef;
                                   $exref->{-yorigin} = undef;
                                 })
        ->pack(-side => 'left');
        
   my $f_e11 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_e11->Label(-text => 'Number of columns',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_e11->Entry(-textvariable => \$exref->{-numcol},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 4, )
         ->pack(-side => 'left', -fill => 'x');
   $f_e11->Label(-text => '  Column spacing',
                 -font => $fontb)
        ->pack(-side => 'left');   
   $mb_colspacing = $f_e11->Menubutton(
                          -textvariable => \$colspacing,
                          -font         => $fontb,
                          -indicator    => 1,
                          -width        => 6,
                          -relief       => 'ridge',
                          -menuitems    => [ @colspacing ],
                          -tearoff      => 0)
                          ->pack(-side => 'left');            
               
   $page3->Label(-text => "Explanation Title",
                 -font => $fontb)
         ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   $page3->Entry(-textvariable => \$exref->{-title},
                 -font         => $font,
                 -background   => 'white' )
         ->pack(-side => 'top', -fill => 'x');
   
   my $f_e21 = $page3->Frame->pack(-side => 'top', -fill => 'x');      
   $f_e21->Label(-text => "  Title X-offset (X.Xi or 'auto')",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_e21->Entry(-textvariable => \$explantitlexoffset,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10 )
         ->pack(-side => 'left');
   my $f_e22 = $page3->Frame->pack(-side => 'top', -fill => 'x');           
   $f_e22->Label(-text => "  Title Y-offset (X.Xi or 'auto')",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_e22->Entry(-textvariable => \$explantitleyoffset,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10 )
         ->pack(-side => 'left');
   my $f_e23 = $page3->Frame->pack(-side => 'top', -fill => 'x');      
   $f_e23->Label(-text => "Vertical spacing (X.Xi or 'auto')",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_e23->Entry(-textvariable => \$explanvertspacing,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10 )
        ->pack(-side => 'left');
   my $f_e24 = $page3->Frame->pack(-side => 'top', -fill => 'x');      
   $f_e24->Label(-text => "            Horizontal Gap (X.Xi)",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_e24->Entry(-textvariable => \$explanhorzgap,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10 )
        ->pack(-side => 'left');
      
        

   

   my $f_e5 = $page3->Frame->pack(-side => 'top', -fill => 'x');        
   $f_e5->Label(-text => 'Border color, width, style',
                -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $mb_explanborderwidth = $f_e5->Menubutton(
                                -textvariable => \$explanborderwidth,
                                -font         => $fontb,
                                -indicator    => 1,
                                -relief       => 'ridge',
                                -menuitems    => [ @explanborderwidth ],
                                -tearoff      => 0)
                                ->pack(-side => 'left', -fill => 'x');
   $mb_explanlinecolor = $f_e5->Menubutton(
                              -textvariable => \$pickedlinecolor,
                              -font         => $fontb,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -width        => 12,
                              -menuitems    => [ @explanlinecolors ],
                              -tearoff      => 0,
                              -background   => $pickedlinecolorbg,
                              -activebackground => $pickedlinecolorbg)
                              ->pack(-side => 'left');
   my $mb_exdashstyle = $f_e5->Menubutton(
                          -textvariable => \$exref->{-dashstyle},
                          -font         => $fontb,
                          -width        => 8,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @exdashstyle ])
                          ->pack(-side => 'left');
   
   my $f_e3 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_e3->Label(-text => 'Background color',
                -font => $fontb)
        ->pack(-side => 'left');   
   $mb_explanfillcolor = $f_e3->Menubutton(
                              -textvariable => \$pickedfillcolor,
                              -font         => $fontb,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -width        => 12,
                              -menuitems    => [ @explanfillcolors ],
                              -tearoff      => 0,
                              -background   => $pickedfillcolorbg,
                              -activebackground => $pickedfillcolorbg)
                              ->pack(-side => 'left');
   
   my $f_e6 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_e6->Label(-text => 'Font, Size, Wgt, Slant, Color',
                -font => $fontb)
        ->pack(-side => 'top', -anchor => 'w');   
   $f_e6->Menubutton(-textvariable => \$exfontfam,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @exfontfam ],
                     -width        => 10)
        ->pack(-side => 'left');
   $f_e6->Entry(-textvariable => \$exref->{-font}->{-size},
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left');
   $f_e6->Menubutton(-textvariable => \$exfontwgt,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @exfontwgt ],
                     -width        => 6)
        ->pack(-side => 'left');
   $f_e6->Menubutton(-textvariable => \$exfontslant,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @exfontslant ],
                     -width        => 6)
        ->pack(-side => 'left');   
   $mb_exfontcolor = $f_e6->Menubutton(
                          -textvariable => \$exfontcolor,
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @exfontcolors ],
                          -background   => $exfontcolorbg, 
                          -activebackground => $exfontcolorbg)
                          ->pack(-side => 'left');

   my $f_e7 = $page3->Frame->pack(-side => 'top', -fill => 'x');
      $f_e7->Button(-text    => 'Show/Hide Explanation Entries',
                    -font    => $fontb,
                    -command => sub {
                    $self->ShowHideExplanEntries($canv,$template);
                                    })
           ->pack(-side => 'left');




   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   my $b_apply = $f_b->Button(-text        => 'Apply',
                              -font        => $fontb,
                              -borderwidth => 3,
                              -command     => sub { &$finishsub } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  
   $b_apply->focus;
   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -command     =>
                     sub { my $go = &$finishsub;
                           $pe->destroy if($go);
                         } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  

   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; return; } )
       ->pack(-side => 'left', -padx => $px, -pady => $py);
       
   $f_b->Button(-text    => 'Edit X-axis',
                -font    => $fontb,
                -command => sub { if($self->{-x}->{-discrete}->{-doit}) {
                                     $self->DiscreteAxisEditor($canv, $template,'x');
                                  }
                                  else {
                                     $self->ContinuousAxisEditor($canv, $template,'x');
                                  }
                                } )
       ->pack(-side => 'left');      
   $f_b->Button(-text    => 'Edit Y-axis',
                -font    => $fontb,
                -command => sub { if($self->{-y}->{-discrete}->{-doit}) {
                                     $self->DiscreteAxisEditor($canv, $template,'y');
                                  }
                                  else {
                                     $self->ContinuousAxisEditor($canv, $template,'y');
                                  }
                                } )
       ->pack(-side => 'left');     
   
                        
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -command => sub { &Help($pe,'PlotEditor.pod'); } )
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                   
                   
   # the anonymous sub that handles things when the OK or Apply buttons are pressed. 
   $finishsub = sub { if(not &isNumber($exref->{-font}->{-size}) or
                                       $exref->{-font}->{-size} < 0 ) {
                         &Message($pe,'-generic',"Invalid font size\n");
                         return 0;                  
                      }
                      if( not &isNumber($ptref->{-size} ) or
                           $ptref->{-size} < 0 ) {
                           &Message($pe,'-generic',"Invalid plot title font size\n");
                           return;                  
                      }
                      foreach ($xlmargin, $xrmargin,
                               $yumargin, $ylmargin,
                               $plottitlexoffset,
                               $plottitleyoffset ) {
                         my $v = $_;
                         $v =~ s/i//;
                         if( not defined $v or not &isNumber($v) ) {
                            &Message($pe,'-generic',"Entry is not a number\n");
                            $_ = -1;
                            return 0;
                         }
                         else {
                            s/^([0-9.]+)$/$1i/; # put the inch symbol in the field
                         }
                      }
                      foreach ($explantitlexoffset,
                               $explantitleyoffset,
                               $explanvertspacing,
                               $explanhorzgap) {
                         unless($_ =~ m/auto/io) {;
                            my $v = $_;
                            $v =~ s/i//;
                            if( not &isNumber($v) ) {
                               &Message($pe,'-generic',"Entry is not 'auto' or a number\n");
                               $_ = 'auto';
                               return 0;
                            }
                            $_ = $v."i";
                         }
                      }
                      
                      # convert all these inches values to pixels.
                      $exref->{-titlexoffset} = $explantitlexoffset;
                      $exref->{-titleyoffset} = $explantitleyoffset;
                      $exref->{-vertspacing}  = $explanvertspacing;    
                      $exref->{-horzgap}      = $explanhorzgap;
                      
                      $self->{-xlmargin}         = $pe->fpixels($xlmargin);
                      $self->{-xrmargin}         = $pe->fpixels($xrmargin);
                      $self->{-yumargin}         = $pe->fpixels($yumargin);
                      $self->{-ylmargin}         = $pe->fpixels($ylmargin);
                      $self->{-plottitlexoffset} = $pe->fpixels($plottitlexoffset);
                      $self->{-plottitleyoffset} = $pe->fpixels($plottitleyoffset);
                      $self->configwidth; # makes sure that the all the geometry parameters
                                                # of the plot are consistent.
                      
                      # need to load this plot onto the template->{-plots} array if
                      # it is not already there.  This is done incase a plot was generated
                      # by this plot editor directly instead of dragged onto the page.
                      my $f;
                      map { $f=1 if($_ eq $self) } @{$template->{-plots}};
                      push(@{$template->{-plots}}, $self) if(not $f);
                      
                      # need to perform a substitution on the plot title and the explanation
                      # title as the Tk::Entry widget does not do the \n expansion like "" would.
                      $self->{-plottitle} =~ s/\\n/\n/g;
                      $exref->{-title}    =~ s/\\n/\n/g;
                      
                      $template->UpdateCanvas($canv);
                      return 1;
                    };
}            

1;
