package Tkg2::Plot::Editors::DiscreteAxisEditor;

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
# $Date: 2007/09/07 18:29:14 $
# $Revision: 1.30 $

use strict;
use vars qw(@ISA @EXPORT $LAST_PAGE_VIEWED $XEDITOR $YEDITOR);

use Exporter;
use SelfLoader;

use Tk::NoteBook;

use Tkg2::Base qw(Message isNumber Show_Me_Internals getDashList);
use Tkg2::Help::Help;

@ISA = qw(Exporter SelfLoader);
@EXPORT = qw(DiscreteAxisEditor); 

$LAST_PAGE_VIEWED = undef;
$XEDITOR = "";
$YEDITOR = "";


print $::SPLASH "=";

1;
#__DATA__

######### DISCRETE ###########
sub DiscreteAxisEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($self, $canv, $template, $xoy) = (shift, shift, shift, shift);
   $xoy = ($xoy =~ m/x/i) ? '-x'  :
          ($xoy =~ m/2/i) ? '-y2' : '-y';my $aref = $self->{$xoy};
   my $pw = $canv->parent;
   if($xoy eq '-x') {
      $XEDITOR->destroy if( Tk::Exists($XEDITOR) );
   }
   if($xoy eq '-y' or $xoy eq '-y2') {
      $YEDITOR->destroy if( Tk::Exists($YEDITOR) );   
   }
   my $pe = $pw->Toplevel(-title => 'Tkg2 Discrete Axis Editor');
   $XEDITOR = $pe if($xoy eq '-x');
   $YEDITOR = $pe if($xoy eq '-y' or $xoy eq '-y2');
   $pe->resizable(0,0);
   
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   
   my ($px, $py) = (2, 2);

   my %weight = ( normal => 'normal',
                  bold   => 'bold');
   my %slant  = ( roman  => 'roman',
                  italic => 'italic');
                 
   my ($mb_ax, $mb_for, $e_base, $e_basetolabel, $mb_originwidth, $mb_tickwidth);
   my ($mb_majorgridlinewidth, $mb_minorgridlinewidth);
                 
   my ($mb_labfontcolor, $mb_numfontcolor);
   my ($mb_majorgridlinecolor, $mb_majorgriddashstyle);
   my ($f_special1, $f_special2);
   my ($labfontfam, $labfontwgt, $labfontslant, $labfontcolor) =
        ( $self->{ $xoy}->{-labfont}->{-family},
          $weight{$aref->{-labfont}->{-weight} },
          $slant{ $aref->{-labfont}->{-slant} },
          $aref->{-labfont}->{-color} );    
   my $labfontcolorbg = ($labfontcolor eq 'black') ? 'white' : $labfontcolor;       
   my $_labfontfam   = sub { $labfontfam = shift;
                             $aref->{-labfont}->{-family} = $labfontfam; };
                             
   my $_labfontwgt   = sub { my $wgt = shift; $labfontwgt = $weight{$wgt};
                             $aref->{-labfont}->{-weight} = $wgt; };
                             
   my $_labfontslant = sub { my $slant = shift; $labfontslant = $slant{$slant};
                             $aref->{-labfont}->{-slant} = $slant; };
                             
   my $_labfontcolor = sub { $labfontcolor = shift;
                             my $color = $labfontcolor;
                             my $mbcolor = ($color eq 'black') ? 'white' : $color;
                             $aref->{-labfont}->{-color} = $color;
                             $mb_labfontcolor->configure( -background => $mbcolor,
                                                          -activebackground => $mbcolor);};


   my ($numfontfam, $numfontwgt, $numfontslant, $numfontcolor) =
        ( $aref->{-numfont}->{-family},
          $weight{$aref->{-numfont}->{-weight} },
          $slant{$aref->{-numfont}->{-slant} },
          $aref->{-numfont}->{-color} );  
   my $numfontcolorbg = ($numfontcolor eq 'black') ? 'white' : $numfontcolor;
   
   my $_numfontfam   = sub { $numfontfam = shift;
                             $aref->{-numfont}->{-family} = $numfontfam; };
   my $_numfontwgt   = sub { my $wgt = shift; $numfontwgt = $weight{$wgt};
                             $aref->{-numfont}->{-weight} = $wgt };
   my $_numfontslant = sub { my $slant = shift; $numfontslant = $slant{$slant};
                             $aref->{-numfont}->{-slant} = $slant};
   my $_numfontcolor = sub { $numfontcolor = shift;
                             my $color   = $numfontcolor;
                             my $mbcolor = ($color eq 'black') ? 'white' : $color; 
                             $aref->{-numfont}->{-color} = $color;
                             $mb_numfontcolor->configure ( -background => $mbcolor,
                                                           -activebackground => $mbcolor)};

   $aref->{-gridmajor}->{-dashstyle} = 'Solid'
      if(not defined $aref->{-gridmajor}->{-dashstyle});
   # the above is for backwards compatability
   my @gridmajordashstyle =
                     &getDashList(\$aref->{-gridmajor}->{-dashstyle},$font);

   my $pickedmajorgridlinecolor   = $aref->{-gridmajor}->{-linecolor};
   my $pickedmajorgridlinecolorbg = $pickedmajorgridlinecolor;
      $pickedmajorgridlinecolor   = 'none'  if(not defined $pickedmajorgridlinecolor   );
      $pickedmajorgridlinecolorbg = 'white' if(not defined $pickedmajorgridlinecolorbg );
      $pickedmajorgridlinecolorbg = 'white' if($pickedmajorgridlinecolorbg eq 'black');       
   my $_majorgridlinecolor = sub { $pickedmajorgridlinecolor = shift;
                              my $color   = $pickedmajorgridlinecolor;
                              my $mbcolor = $pickedmajorgridlinecolor;
                              $color   =  undef  if($color   eq 'none');
                              $mbcolor = 'white' if($mbcolor eq 'none');
                              $mbcolor = 'white' if($mbcolor eq 'black');
                              $aref->{-gridmajor}->{-linecolor} = $color;
                              $mb_majorgridlinecolor->configure(-background => $mbcolor,
                                                                -activebackground => $mbcolor); };
                                                      
   my $mb_blankcolor;                               
   my $blankcolor   = $aref->{-blankcolor};
   my $blankcolorbg = $blankcolor;
      $blankcolorbg = 'white' if($blankcolor eq 'black');
   my $_blankcolor  = sub { $blankcolor = shift;
                            $aref->{-blankcolor} = $blankcolor;
                             my $mbcolor = $blankcolor;
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $mb_blankcolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                           };
                                                                                        
                                                       

   my (@labelfam, @numfam) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-FONTS}}) {
      push(@labelfam,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_labfontfam, $_ ] ] );
      push(@numfam,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_numfontfam, $_ ] ] );
   }
   
   my (@labwgt, @numwgt) = ( (), () );
   foreach (qw(normal bold)) {
      push(@labwgt,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_labfontwgt, $_ ] ] );
      push(@numwgt,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_numfontwgt, $_ ] ] );
   }               
   
   my (@labslant, @numslant) = ( (), () );
   foreach (qw(roman italic)) {
      push(@labslant,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_labfontslant, $_ ] ] );
      push(@numslant,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_numfontslant, $_ ] ] );
   }   


   my (@labcolors, @numcolors) = ( (), () );
   my (@majorgridlinecolors, @blankcolors) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-COLORS}}) {
      push(@blankcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_blankcolor, $_ ] ] );
      push(@labcolors,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_labfontcolor,$_] ] );
      push(@numcolors,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_numfontcolor,$_] ] );
      push(@majorgridlinecolors,
          [ 'command'    => $_,
                -font    => $font,
                -command => [ \&$_majorgridlinecolor, $_] ] );  
   }                                             
    
    
   my $laboffset  = $aref->{-laboffset};
   my $lab2offset = (defined $aref->{-lab2offset}) ?
                             $aref->{-lab2offset}  : "0";
   my $numoffset  = $aref->{-numoffset};
   my $ticklength = $aref->{-ticklength};       
   foreach ($laboffset, $lab2offset, $numoffset, $ticklength) {
       $_ = $template->pixel_to_inch($_);   
   }
   
   # BACKWARDS COMPAT FOR 0.72-3 and earlier
   my $clusterspacing = ($aref->{-discrete}->{-clusterspacing}) ?
                         $aref->{-discrete}->{-clusterspacing}  : "0i";
                            
   my $tickwidth   = $aref->{-tickwidth};
   my $majorgridlinewidth = $aref->{-gridmajor}->{-linewidth};

   my $_tickwidth   = sub { $tickwidth   = shift;
                            $aref->{-tickwidth}   = $tickwidth; };
   my $_majorgridlinewidth =
      sub { $majorgridlinewidth = shift;
            $aref->{-gridmajor}->{-linewidth} = $majorgridlinewidth; };

   my (@tickwidth, @majorgridlinewidth) = ( (), () );
   foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
      push(@tickwidth,          [ 'command' => $_,
                                  -command  =>
                                  [ $_tickwidth,   $_ ] ] );
      push(@majorgridlinewidth, [ 'command' => $_, 
                                  -command  =>
                                  [ $_majorgridlinewidth, $_ ] ] ); 
   }
      
    
   my @locations;
   my $location = ucfirst($aref->{-location});
   if($xoy eq '-x' ) {
      @locations = ( [ 'command' => 'Top',
                       -font     => $fontb,
                       -command  => sub { $aref->{-location} = 'top';
                                          $location          = 'Top'; }
                     ],
                     [ 'command' => 'Bottom',
                       -font     => $fontb,
                       -command  => sub { $aref->{-location} = 'bottom';
                                          $location          = 'Bottom'; }
                     ] );
   }
   else {
       @locations = ( [ 'command' => 'Left',
                        -font     => $fontb,
                        -command  => sub { $aref->{-location} = 'left';
                                           $location          = 'Left'; }
                      ],
                      [ 'command' => 'Right',
                        -font     => $fontb,
                        -command  => sub { $aref->{-location} = 'right';
                                           $location          = 'Right'; }
                      ] );
   }    
                       
   my $heading = ($xoy eq '-x')  ? "X"  :
                 ($xoy eq '-y2') ? "Y2" : "Y";
   $pe->Label(-text => "EDIT DISCRETE $heading"."-AXIS CONFIGURATION PARAMETERS",
              -font => $fontbig)->pack( -fill =>'x');
   
   my $nb = $pe->NoteBook(-font => $fontb)->pack(-expand => 1, -fill => 'both');
   my $page1 = $nb->add('page1',
                  -label => 'Axis Parameters',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page1'});
   my $page2 = $nb->add('page2',
                  -label => 'Title and Labels',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page2'});
   my $page3 = $nb->add('page3',
                  -label => 'Ticks and Grid',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page3'});
   $nb->raise($LAST_PAGE_VIEWED);

              
   $page1->Label(-text => "Axis Title", -font => $fontb)
         ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   my $entry = $page1->Scrolled('Text',
                                -scrollbars => 'se',
                                -width      => 30,
                                -font       => $font,
                                -height     => 6,
                                -background => 'white' )
                     ->pack(-side => 'top', -fill => 'x');
   $entry->insert('end', $aref->{-title});  
   $entry->focus;     
          
   my $f_1   = $page1->Frame->pack(-fill => 'x');
   my $f_min = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_min->Label(-text => "Minimum Value", -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$aref->{-min},
                 -font => $font,
                 -bg => 'white', -width => 10  )
         ->pack(-side => 'left', -fill => 'x');
   $f_min->Checkbutton(-text     => 'Reverse Axis  ',
                       -font     => $fontb,
                       -variable => \$aref->{-reverse},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left', -fill => 'x');   
   $f_min->Checkbutton(-text     => 'Double Label',
                       -font     => $fontb,
                       -variable => \$aref->{-doublelabel},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   
       
   my $f_max = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_max->Label(-text => 'Maximum Value', -font => $fontb)
        ->pack(-side => 'left', -anchor => 'w');
   $f_max->Entry(-textvariable => \$aref->{-max},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10  )
         ->pack(-side => 'left', -fill => 'x');
   $f_max->Checkbutton(-text     => 'Hide Numbers and Title ',
                       -font     => $fontb,
                       -variable => \$aref->{-hideit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left', -fill => 'x'); 
   $f_max->Checkbutton(-text     => 'Tick at group',
                       -font     => $fontb,
                       -variable => \$aref->{-discrete}->{-bracketgroup},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left', -fill => 'x'); 
         
         
   my $f_lab = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_lab->Label(-text => 'No. of Categories to Skip', -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_lab->Entry(-textvariable => \$aref->{-labskip},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 10  )
         ->pack(-side => 'left', -fill => 'x');
   $f_lab->Radiobutton(-text     => 'Stack Data',
                       -font     => $fontb,
                       -variable => \$aref->{-discrete}->{-doit},
                       -value    => 'stack')
         ->pack(-side => 'left', -fill => 'x');  
   $f_lab->Radiobutton(-text     => 'Cluster Data',
                       -font     => $fontb,
                       -variable => \$aref->{-discrete}->{-doit},
                       -value    => 'cluster')
         ->pack(-side => 'left', -fill => 'x');                

   my $f_lab2 = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_lab2->Label(-text => 'Cluster spacing',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');   
   $f_lab2->Entry(-textvariable => \$clusterspacing,
                  -font         => $font,
                  -background   => 'white',
                  -width        => 10  )
          ->pack(-side => 'left');
   $f_lab2->Label(-text => 'warning--if too large, clusters overlap.',
                  -font => $font)
          ->pack(-side => 'left');
 
 
   ## LABEL AND NUMBER FONTS
   $page2->Label(-text => "\nTitle and Label Font, ".
                          "Size(pt), Weight, Slant, and Color",
                 -font => $fontb)
         ->pack(-side => 'top', -anchor => 'w');       
   my $f_2 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_2->Label(-text => 'Title', -font => $fontb)->pack(-side => 'left');   
   $f_2->Menubutton(-textvariable => \$labfontfam,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labelfam ])
        ->pack(-side => 'left', -expand => 1);
   $f_2->Entry(-textvariable => \$aref->{-labfont}->{-size},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
        ->pack(-side => 'left', -expand => 1);
   $f_2->Menubutton(-textvariable => \$labfontwgt,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labwgt ],
                    -width        => 6)
        ->pack(-side => 'left', -expand => 1);
   $f_2->Menubutton(-textvariable => \$labfontslant,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labslant ],
                    -width        => 6 )
       ->pack(-side => 'left', -expand => 1);   
   $mb_labfontcolor = $f_2->Menubutton(
                          -textvariable => \$labfontcolor,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -width        => 12,
                          -menuitems    => [ @labcolors ],
                          -background   => $labfontcolorbg,
                          -activebackground => $labfontcolorbg)
                          ->pack(-side => 'left', -expand => 1);      

   my $f_3a = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_3a->Checkbutton(-text     => "Vertically stack title text",
                       -font     => $fontb,
                       -variable => \$aref->{-labfont}->{-stackit},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');            
   $f_3a->Label(-text => "   Angle (for MetaPost)",
               -font => $fontb)
       ->pack(-side => 'left');
   $f_3a->Entry(-textvariable => \$aref->{-labfont}->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');

                  
   my $f_3 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_3->Label(-text => 'Label',
               -font => $fontb)->pack(-side => 'left');   
   $f_3->Menubutton(-textvariable => \$numfontfam,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @numfam ])
       ->pack(-side => 'left', -expand => 1);
   $f_3->Entry(-textvariable => \$aref->{-numfont}->{-size},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left', -expand => 1);
   $f_3->Menubutton(-textvariable => \$numfontwgt,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @numwgt ],
                    -width        => 6)
       ->pack(-side => 'left', -expand => 1);
   $f_3->Menubutton(-textvariable => \$numfontslant,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @numslant ],
                    -width        => 6)
       ->pack(-side => 'left', -expand => 1);   
   $mb_numfontcolor = $f_3->Menubutton(
                          -textvariable => \$numfontcolor,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -width        => 12,
                          -menuitems    => [ @numcolors ],
                          -background   => $numfontcolorbg, 
                          -activebackground => $numfontcolorbg)
                          ->pack(-side => 'left', -expand => 1);
   my $f_3b = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_3b->Checkbutton(-text     => "Vertically stack label text",
                       -font     => $fontb,
                       -variable => \$aref->{-numfont}->{-stackit},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_3b->Label(-text => "   Angle (for MetaPost)",
               -font => $fontb)
       ->pack(-side => 'left');
   $f_3b->Entry(-textvariable => \$aref->{-numfont}->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');
         
   
   my $f_bl = $page2->Frame->pack(-side => 'top', -fill => 'x');
      $f_bl->Checkbutton(-text     => 'Do text blanking with color:',
                         -font     => $fontb,
                         -variable => \$aref->{-blankit},
                         -onvalue  => 1,
                         -offvalue => 0)
           ->pack(-side => 'left');
      $mb_blankcolor = $f_bl->Menubutton(
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

         
   my $f_o1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o1->Label(-text => " Title offset",
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o1->Entry(-textvariable => \$laboffset,
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left', -fill => 'x');
   $f_o1->Label(-text => ' Title and Label Location',
                -font => $fontb)->pack(-side => 'left');
   $f_o1->Menubutton(-textvariable => \$location,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -width        => 10,
                     -menuitems    => [ @locations ] )
        ->pack(-side => 'left', -fill => 'x');  
   my $f_o2 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o2->Label(-text => 'Title2 offset',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o2->Entry(-textvariable => \$lab2offset,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');
  
   my $f_o3 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o3->Label(-text => ' Label offset',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o3->Entry(-textvariable => \$numoffset,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');
        
   
        
   my $f_tick = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_tick->Label(-text => 'Tick Length',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');
   $f_tick->Entry(-textvariable => \$ticklength,
                  -font         => $font,
                  -background   => 'white',
                  -width        => 7 )
          ->pack(-side => 'left', -fill => 'x');
   $f_tick->Label(-text => ' Tick Width',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');
   $mb_tickwidth = $f_tick->Menubutton(
                          -textvariable => \$tickwidth,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @tickwidth ],
                          -tearoff      => 0)
                          ->pack(-side => 'left', -fill => 'x');  
     

   # MAJOR GRIDLINE STUFF
   my $f_g1a = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g1a->Label(-text => "Grid Lines:",
                 -font => $fontb)
         ->pack(-side => 'left');
   my $f_g1 = $page3->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_g1->Checkbutton(-text     => 'Doit',
                      -font     => $fontb,
                      -variable => \$aref->{-gridmajor}->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   $f_g1->Label(-text => ' Width,Color,Style',
                -font => $fontb)->pack(-side => 'left');
   $mb_majorgridlinewidth = $f_g1->Menubutton(
                          -textvariable => \$majorgridlinewidth,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @majorgridlinewidth ],
                          -tearoff      => 0)
                          ->pack(-side => 'left');   
   $mb_majorgridlinecolor = $f_g1->Menubutton(
                          -textvariable => \$pickedmajorgridlinecolor,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -width        => 12,
                          -menuitems    => [ @majorgridlinecolors ],
                          -background   => $pickedmajorgridlinecolorbg, 
                          -activebackground => $pickedmajorgridlinecolorbg)
                          ->pack(-side => 'left');  
   $mb_majorgriddashstyle = $f_g1->Menubutton(
                          -textvariable => \$aref->{-gridmajor}->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @gridmajordashstyle ])
                          ->pack(-side => 'left'); 
             
        

   my $finishsub =
      sub {
         foreach ($laboffset, $lab2offset, $numoffset, $ticklength) {
            s/^([0-9.]+)$/$1i/
         }
         $aref->{-laboffset}  = $pe->fpixels($laboffset);
         $aref->{-lab2offset} = $pe->fpixels($lab2offset);
         $aref->{-numoffset}  = $pe->fpixels($numoffset);
         $aref->{-ticklength} = $pe->fpixels($ticklength); 
         $aref->{-title} = $entry->get('0.0', 'end');
         $aref->{-title} =~ s/\n$//;
         
         $clusterspacing =~ s/^\s+\+//o;
         $clusterspacing =~ m/(-?[0-9.]+)/o;
         $clusterspacing = $1;
         if( defined $clusterspacing and &isNumber($clusterspacing) ) {
            $clusterspacing .= "i";
            $aref->{-discrete}->{-clusterspacing} = $clusterspacing;
         }
         else {
            $clusterspacing = "0i";
            my $text = "The cluster spacing is invalid, setting to zero.\n";
            &Message($pe,'-generic',$text);
            return 0;
         }  
   
         
         if(not &isNumber(   $aref->{-labfont}->{-size})
                          or $aref->{-labfont}->{-size} < 0 ) {
            &Message($pe,'-generic',"Invalid title font size\n");
            return;                  
         }
         if(not &isNumber(   $aref->{-numfont}->{-size})
                          or $aref->{-numfont}->{-size} < 0 ) {
            &Message($pe,'-generic',"Invalid label font size\n");
            return;                  
         }
         my $valid = 1;
         my $min = $aref->{-min};
         my $max = $aref->{-max};
         if($min eq "" and $max eq "") {
            $self->autoConfigurePlotLimits($xoy);
            return 1;
         }
         if($min eq "") {
            $self->autoConfigurePlotLimits($xoy,'justmin');
            return 1;
         }
         if($max eq "") {
            $self->autoConfigurePlotLimits($xoy,'justmax');
            return 1;
         }
         $valid = 0 unless( &isNumber($min) and &isNumber($max) );
         my $range = $max - $min if($valid);
         $valid = 0 if( $valid && $range <=0 );
         unless($valid) {
            &Message($pe,'-generic',"Invalid axis limits\n");
            return 0;
         }
         if(not &isNumber($aref->{-labskip})
                       or $aref->{-labskip} < 0 ) {
                &Message($pe,'-generic',"Invalid number of label skipping\n");
            return 0;
         }
         return 1;
      };

   my @p = (-side => 'left', -padx => $px, -pady => $py);
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   #my $b_test = $f_b->Button(-text        => '!!STEPWISE APPLY!!',
   #                          -font        => $fontb,
   #                          -borderwidth => 3,
   #                          -highlightthickness => 2,
   #                          -command =>
   #                               sub { my $go = &$finishsub;
   #                                     $template->UpdateCanvas($canv,0,'increment') if($go);
   #                                   } )
   #                  ->pack(@p);   
   $f_b->Button(-text        => 'Apply',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { my $go = &$finishsub;
                                  $template->UpdateCanvas($canv) if($go);
                                } )
                ->pack(@p);   
                             
   $f_b->Button(-text        => 'OK',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { my $go = &$finishsub;
                                  $template->UpdateCanvas($canv) if($go);
                                  $pe->destroy;
                                } )
                    ->pack(-side => 'left', -padx => $px, -pady => $py);  
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; })
                ->pack(@p);
                      
   $f_b->Button(-text    => 'Plot Editor',
                -font    => $fontb,
                -command => sub { $self->PlotEditor($canv, $template); })
       ->pack(@p);
                    
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { &Help($pe,'DiscreteAxisEditor.pod'); } )
                ->pack(@p);


}                      
                          

1;
