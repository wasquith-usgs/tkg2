package Tkg2::Plot::Editors::ContinuousAxisEditor;

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
# $Revision: 1.81 $

use strict;
use vars qw(@ISA @EXPORT $LOGOFFSET_EDITOR $LAST_PAGE_VIEWED
            $XEDITOR $YEDITOR);

use Exporter;
use SelfLoader;

use Tkg2::Time::TimeMethods;
use Tkg2::Base qw(Message isNumber strip_space arrayhasNumbers isInteger
                  Show_Me_Internals getDashList strip_commas repackit);
use Tkg2::Help::Help;

use Tk::NoteBook;

use Date::Calc qw(Days_in_Month);

use Tkg2::Plot::Editors::EditorWidgets qw(AutoPlotLimitWidget);

@ISA = qw(Exporter SelfLoader);
@EXPORT = qw(ContinuousAxisEditor); 

$LOGOFFSET_EDITOR = "";
$LAST_PAGE_VIEWED = undef;
$XEDITOR = "";
$YEDITOR = "";

my ($min_offset, $max_offset); # values that need global scope so that
  # the APPLY button will be able to update the min and max with offset
  # adjustment on the logeditor.  Used by _update_min_offset_and_max_offset($aref);
  # subroutine

print $::SPLASH "=";

1;
#__DATA__

sub ContinuousAxisEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($self, $canv, $template, $xoy) = (shift, shift, shift, shift);
   # PERL5.8 CORRECTION RESEARCH
   #if(isInteger($self->{-y}->{-logoffset})) {
   #  print STDERR "BUG: begin continuousaxiseditor offset is an integer\n";
   #}
   #else {
   #  print STDERR "BUG: begin continuousaxiseditor offset is not an integer\n";
   #}
   $xoy = ($xoy =~ m/x/i) ? '-x'  :
          ($xoy =~ m/2/i) ? '-y2' : '-y';
   my $pw = $canv->parent;
   if($xoy eq '-x') {
      $XEDITOR->destroy if( Tk::Exists($XEDITOR) );
   }
   if($xoy eq '-y' or $xoy eq '-y2') {
      $YEDITOR->destroy if( Tk::Exists($YEDITOR) );
   }
   my $aref = $self->{$xoy};
   my $labfontref = $aref->{-labfont};
   my $numfontref = $aref->{-numfont};
   my $pe = $pw->Toplevel(-title => 'Tkg2 Continuous Axis Editor');
   
   $XEDITOR = $pe if($xoy eq '-x');
   $YEDITOR = $pe if($xoy eq '-y' or $xoy eq '-y2' );
   #$pe->resizable(0,0);
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   my ($px, $py) = (2, 2);


   my %axis   = ( linear => 'Linear',
                  log    => 'Log10',
                  prob   => 'Probability',
                  grv    => 'Gumbel',
                  time   => 'Time Series');
   my %format = ( free   => 'Free',
                  fixed  => 'Fixed',
                  sci    => 'Scientific',
                  sig    => 'Significant'); 
   my %weight = ( normal => 'normal',
                  bold   => 'bold');
   my %slant  = ( roman  => 'roman',
                  italic => 'italic');
                 
   my ($mb_ax, $mb_for, $mb_originwidth, $mb_tickwidth);
   my ($mb_majorgridlinewidth, $mb_minorgridlinewidth);
   my ($mb_majorgriddashstyle, $mb_minorgriddashstyle);
   my ($mb_origindashstyle);
   
   my ($e_base, $e_basetolabel, $e_baseminor);
   
   my $para =  {  -major            => "",
                  -minor            => "",
                  -basemajor        => "",
                  -baseminor        => "",
                  -basemajortolabel => "",
               };
   # Load any existing major or minor ticks into the para hash
   # if and only if an array is available to insertion.
   $para->{-major} = join("  ",@{$aref->{-major}}) if(ref $aref->{-major});
   $para->{-minor} = join("  ",@{$aref->{-minor}}) if(ref $aref->{-minor});
   
   my ($mb_labfontcolor, $mb_numfontcolor, $mb_majorgridlinecolor);
   my ($mb_minorgridlinecolor, $mb_origincolor);
   my ($f_special1, $f_special2);
   my $labfontfam   = $labfontref->{-family};
   my $labfontwgt   = $weight{$labfontref->{-weight} };
   my $labfontslant = $slant{$labfontref->{-slant}  };
   my $labfontcolor = $labfontref->{-color};
       
   my $labfontcolorbg = ($labfontcolor eq 'black') ? 'white' : $labfontcolor;       
   my $_labfontfam   = sub { $labfontfam            = shift;
                             $labfontref->{-family} = $labfontfam;
                           };
                             
   my $_labfontwgt   = sub { my $wgt                = shift;
                             $labfontwgt            = $weight{$wgt};
                             $labfontref->{-weight} = $wgt;
                           };
                             
   my $_labfontslant = sub { my $slant             = shift;
                             $labfontslant         = $slant{$slant};
                             $labfontref->{-slant} = $slant;
                           };
                             
   my $_labfontcolor = sub { $labfontcolor = shift;
                             my $color     = $labfontcolor;
                             my $mbcolor   = ($color eq 'black') ? 'white' : $color;
                             $aref->{-labfont}->{-color} = $color;
                             $mb_labfontcolor->configure(
                                             -background       => $mbcolor,
                                             -activebackground => $mbcolor );
                           };


   my $numfontfam   = $numfontref->{-family};
   my $numfontwgt   = $weight{ $numfontref->{-weight} };
   my $numfontslant = $slant{  $numfontref->{-slant}  };
   my $numfontcolor = $numfontref->{-color};
       
   my $numfontcolorbg = ($numfontcolor eq 'black') ? 'white' : $numfontcolor;
   
   my $_numfontfam   = sub { $numfontfam            = shift;
                             $numfontref->{-family} = $numfontfam;
                           };
                           
   my $_numfontwgt   = sub { my $wgt                = shift;
                             $numfontwgt            = $weight{$wgt};
                             $numfontref->{-weight} = $wgt;
                           };
                           
   my $_numfontslant = sub { my $slant              = shift;
                             $numfontslant          = $slant{$slant};
                             $numfontref->{-slant}  = $slant;
                           };
                           
   my $_numfontcolor = sub { $numfontcolor = shift;
                             my $color     = $numfontcolor;
                             my $mbcolor   = ($color eq 'black') ? 'white' : $color; 
                             $numfontref->{-color} = $color;
                             $mb_numfontcolor->configure(
                                             -background       => $mbcolor,
                                             -activebackground => $mbcolor);
                           };

   $aref->{-gridmajor}->{-dashstyle} = 'Solid'
      if(not defined $aref->{-gridmajor}->{-dashstyle});
   # the above is for backwards compatability
   my @gridmajordashstyle = &getDashList(\$aref->{-gridmajor}->{-dashstyle},$font);

   my $pickedmajorgridlinecolor   = $aref->{-gridmajor}->{-linecolor};
   my $pickedmajorgridlinecolorbg = $pickedmajorgridlinecolor;
      $pickedmajorgridlinecolor   = 'none'  if(not defined($pickedmajorgridlinecolor)   );
      $pickedmajorgridlinecolorbg = 'white' if(not defined($pickedmajorgridlinecolorbg) );
      $pickedmajorgridlinecolorbg = 'white' if($pickedmajorgridlinecolorbg eq 'black');       
   my $_majorgridlinecolor = sub {
                                   $pickedmajorgridlinecolor = shift;
                                   my $color   = $pickedmajorgridlinecolor;
                                   my $mbcolor = $pickedmajorgridlinecolor;
                                   $color      =  undef  if($color   eq 'none');
                                   $mbcolor    = 'white' if($mbcolor eq 'none');
                                   $mbcolor    = 'white' if($mbcolor eq 'black');
                                   $aref->{-gridmajor}->{-linecolor} = $color;
                                   $mb_majorgridlinecolor->configure(
                                                         -background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                                 };

   $aref->{-gridminor}->{-dashstyle} = 'Solid'
      if(not defined $aref->{-gridminor}->{-dashstyle});
   # the above is for backwards compatability
   my @gridminordashstyle = &getDashList(\$aref->{-gridminor}->{-dashstyle},$font);

   my $pickedminorgridlinecolor   = $aref->{-gridminor}->{-linecolor};
   my $pickedminorgridlinecolorbg = $pickedminorgridlinecolor;
      $pickedminorgridlinecolor   = 'none'  if(not defined($pickedminorgridlinecolor)   );
      $pickedminorgridlinecolorbg = 'white' if(not defined($pickedminorgridlinecolorbg) );
      $pickedminorgridlinecolorbg = 'white' if($pickedminorgridlinecolorbg eq 'black');  
   my $_minorgridlinecolor = sub {
                                   $pickedminorgridlinecolor = shift;
                                   my $color   = $pickedminorgridlinecolor;
                                   my $mbcolor = $pickedminorgridlinecolor;
                                   $color      =  undef  if($color   eq 'none');
                                   $mbcolor    = 'white' if($mbcolor eq 'none');
                                   $mbcolor    = 'white' if($mbcolor eq 'black');
                                   $aref->{-gridminor}->{-linecolor} = $color;
                                   $mb_minorgridlinecolor->configure(
                                                         -background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                                 };

   $aref->{-origindashstyle} = 'Solid'
      if(not defined $aref->{-origindashstyle});
   # the above is for backwards compatability
   my @origindashstyle = &getDashList(\$aref->{-origindashstyle},$font);
   
   my $pickedorigincolor   = $aref->{-origincolor};
   my $pickedorigincolorbg = $pickedorigincolor;
      $pickedorigincolor   = 'none'  if(not defined($pickedorigincolor)   );
      $pickedorigincolorbg = 'white' if(not defined($pickedorigincolorbg) );
      $pickedorigincolorbg = 'white' if($pickedorigincolorbg eq 'black');                  
   my $_origincolor = sub {
                            $pickedorigincolor = shift;
                            my $color   = $pickedorigincolor;
                            my $mbcolor = $pickedorigincolor;
                            $color      =  undef  if($color   eq 'none');
                            $mbcolor    = 'white' if($mbcolor eq 'none');
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $aref->{-origincolor} = $color;
                            $mb_origincolor->configure(
                                           -background       => $mbcolor,
                                           -activebackground => $mbcolor);
                          };
   
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
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_labfontfam, $_ ] ] );
      push(@numfam,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_numfontfam, $_ ] ] );
   }
   
   my (@labwgt, @numwgt) = ( (), () );
   foreach (qw(normal bold)) {
      push(@labwgt,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_labfontwgt, $_ ] ] );
      push(@numwgt,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_numfontwgt, $_ ] ] );
   }               
   
   my (@labslant, @numslant) = ( (), () );
   foreach (qw(roman italic)) {
      push(@labslant,
           [ 'command' => $_,
             -font     => $font,,
             -command  => [ \&$_labfontslant, $_ ] ] );
      push(@numslant,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_numfontslant, $_ ] ] );
   }   


   my (@labcolors, @numcolors, @origincolors) = ( (), (), () );
   my (@majorgridlinecolors, @minorgridlinecolors, @blankcolors) = ( (), (), () );
   foreach (@{$::TKG2_CONFIG{-COLORS}}) {
      push(@blankcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_blankcolor, $_ ] ] );
      push(@labcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_labfontcolor,$_] ] );
      push(@numcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_numfontcolor,$_] ] );
      push(@majorgridlinecolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_majorgridlinecolor, $_] ] );  
      push(@minorgridlinecolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_minorgridlinecolor, $_] ] );  
      push(@origincolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_origincolor, $_] ] );      
   }                                             
    
    
   my $laboffset  = $aref->{-laboffset};
   my $lab2offset = (defined $aref->{-lab2offset}) ?
                             $aref->{-lab2offset}  : "0i";
   my $numoffset  = $aref->{-numoffset};
   my $ticklength = $aref->{-ticklength};       
   foreach ($laboffset, $lab2offset, $numoffset, $ticklength) {
       $_ = $template->pixel_to_inch($_);   
   }
       
   my $tickwidth   = $aref->{-tickwidth};
   my $majorgridlinewidth = $aref->{-gridmajor}->{-linewidth};
   my $minorgridlinewidth = $aref->{-gridminor}->{-linewidth};
   my $originwidth = $aref->{-originwidth};
   my $_tickwidth   = sub { $tickwidth   = shift;
                            $aref->{-tickwidth}   = $tickwidth; };
   my $_majorgridlinewidth = sub { $majorgridlinewidth = shift;
                                   $aref->{-gridmajor}->{-linewidth} = $majorgridlinewidth; };
   my $_minorgridlinewidth = sub { $minorgridlinewidth = shift;
                                   $aref->{-gridminor}->{-linewidth} = $minorgridlinewidth; };

   my $_originwidth = sub { $originwidth = shift;
                            $aref->{-originwidth} = $originwidth; };
   my (@tickwidth, @majorgridlinewidth, @minorgridlinewidth, @originwidth) = ( (), (), (), () );
   foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
      push(@tickwidth,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ $_tickwidth,   $_ ] ] );
      push(@majorgridlinewidth,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ $_majorgridlinewidth, $_ ] ] ); 
      push(@minorgridlinewidth,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ $_minorgridlinewidth, $_ ] ] );      
      push(@originwidth,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ $_originwidth, $_ ] ] );
   }
   
   my @locations;
   my $location = ucfirst($aref->{-location});
   if($xoy eq '-x' ) {
      @locations = ( [ 'command' => 'Top',
                       -font     => $font,
                       -command  => sub { $aref->{-location} = 'top';
                                          $location          = 'Top'; } ],
                     [ 'command' => 'Bottom',
                       -font     => $font,
                       -command  => sub { $aref->{-location} = 'bottom';
                                          $location          = 'Bottom'; } ] );
   }
   else {
       @locations = ( [ 'command' => 'Left',
                        -font     => $font,
                        -command  => sub { $aref->{-location} = 'left';
                                           $location          = 'Left'; } ],
                      [ 'command' => 'Right',
                        -font     => $font,
                        -command  => sub { $aref->{-location} = 'right';
                                           $location          = 'Right'; } ] );
   }   
                       
   my @format =  ( [ 'command' => 'Free',
                     -font     => $font,
                     -command  => sub { $aref->{-numformat} = 'free';
              $mb_for->configure(-text => $format{$aref->{-numformat}}); } ],
                   [ 'command' => 'Fixed',
                     -font     => $font,
                     -command  => sub {  $aref->{-numformat} = 'fixed';
              $mb_for->configure(-text => $format{$aref->{-numformat}}); } ],
                   [ 'command' => 'Scientific',
                     -font     => $font,
                     -command  => sub { $aref->{-numformat} = 'sci';
              $mb_for->configure(-text => $format{$aref->{-numformat}}); } ],
                   [ 'command' => 'Significant',
                     -font     => $font,
                     -command  => sub { $aref->{-numformat} = 'sig';
              $mb_for->configure(-text => $format{$aref->{-numformat}}); } ] );                       
                                                               


   my ($dt_begin, $dt_end); # temporary storage hashes for beginning and
   # ending date time fields to make the time dialog boxes easier to read
   # and use, these are defined coming out of the _timeeditor1
   my @type = ( [ 'command' => 'Linear',
                  -font     => $font,
      -command => sub { $aref->{-type} = 'linear';
                        $mb_ax->configure(-text => $axis{$aref->{-type}});
                        $para->{-major} = undef;
                        $para->{-minor} = undef;
                        $aref->{-major} = undef;
                        $aref->{-minor} = undef;
                        my $oldmin = $aref->{-autominlimit};
                        my $oldmax = $aref->{-automaxlimit};
                        $f_special2->packForget if(Tk::Exists($f_special2));
                        $self->autoConfigurePlotLimits($xoy);
                        $aref->{-autominlimit} = $oldmin;
                        $aref->{-automaxlimit} = $oldmax;
                        $f_special2 = &_lineareditor1($self,$canv, $f_special1, $xoy, $para);
                      } ],
                [ 'command' => 'Log10',
                  -font     => $font,
      -command => sub { $aref->{-type} = 'log';
                        $mb_ax->configure(-text => $axis{$aref->{-type}});
                        $aref->{-basemajor}        = [];
                        $aref->{-basemajortolabel} = [];
                        $aref->{-baseminor}        = [];
                        $para->{-major}            = "";
                        $para->{-minor}            = "";
                        $aref->{-major}            = [];
                        $aref->{-minor}            = [];
                        my $oldmin = $aref->{-autominlimit};
                        my $oldmax = $aref->{-automaxlimit};
                        $f_special2->packForget if(Tk::Exists($f_special2));
                        $self->autoConfigurePlotLimits($xoy);
                        $aref->{-autominlimit} = $oldmin;
                        $aref->{-automaxlimit} = $oldmax;
                        ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                                 &_logeditor1($self, $canv, $f_special1, $xoy, $para);
                      } ],
                [ 'command' => 'Probability',
                  -font     => $font,
      -command => sub { $aref->{-type} = 'prob';
                        $mb_ax->configure(-text => $axis{$aref->{-type}});
                        $aref->{-basemajor}        = [];
                        $aref->{-basemajortolabel} = [];
                        $aref->{-baseminor}        = [];
                        $para->{-major}            = "";
                        $para->{-minor}            = "";
                        $aref->{-major}            = [];
                        $aref->{-minor}            = [];
                        my $oldmin = $aref->{-autominlimit};
                        my $oldmax = $aref->{-automaxlimit};
                        $f_special2->packForget if(Tk::Exists($f_special2));
                        $self->autoConfigurePlotLimits($xoy);
                        $aref->{-autominlimit} = $oldmin;
                        $aref->{-automaxlimit} = $oldmax;
                        ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                                 &_probeditor1($self,$canv, $f_special1, $xoy, $para);
                      } ],
                [ 'command' => 'Gumbel',
                  -font     => $font,
      -command => sub { $aref->{-type} = 'grv';
                        $mb_ax->configure(-text => $axis{$aref->{-type}});
                        $aref->{-basemajor}        = [];
                        $aref->{-basemajortolabel} = [];
                        $aref->{-baseminor}        = [];
                        $para->{-major}            = "";
                        $para->{-minor}            = "";
                        $aref->{-major}            = [];
                        $aref->{-minor}            = [];
                        my $oldmin = $aref->{-autominlimit};
                        my $oldmax = $aref->{-automaxlimit};
                        $f_special2->packForget if(Tk::Exists($f_special2));
                        $self->autoConfigurePlotLimits($xoy);
                        $aref->{-autominlimit} = $oldmin;
                        $aref->{-automaxlimit} = $oldmax;
                        ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                                 &_probeditor1($self,$canv, $f_special1, $xoy, $para);
                      } ],
                [ 'command' => 'Time Series',
                  -font     => $font,
                  -command  => sub { $aref->{-type} = 'time'; 
                                     $mb_ax->configure(-text => $axis{$aref->{-type}});
                                     my $oldmin = $aref->{-autominlimit};
                                     my $oldmax = $aref->{-automaxlimit};
                                     $f_special2->packForget if(Tk::Exists($f_special2));
                                     $self->autoConfigurePlotLimits($xoy);
                                     $aref->{-autominlimit} = $oldmin;
                                     $aref->{-automaxlimit} = $oldmax;
                                     ($f_special2, $dt_begin, $dt_end) =
                                       &_timeeditor1($self,$canv, $f_special1, $xoy); } ] ); 
   
   my $heading = ($xoy eq '-x')  ? "X"  :
                 ($xoy eq '-y2') ? "Y2" : "Y";
   $pe->Label(-text => "EDIT $heading"."-AXIS CONFIGURATION PARAMETERS",
              -font => $fontbig)->pack( -fill =>'x'); 
  
   my $nb = $pe->NoteBook(-font => $fontb)->pack(-expand => 1, -fill => 'both');
   my $page1 = $nb->add('page1',
                  -label => 'Axis Parameters',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page1'});
   my $page2 = $nb->add('page2',
                  -label => 'Title, Labels, and Ticks',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page2'});
   my $page3 = $nb->add('page3',
                  -label => 'Grid and Origin',
                  -raisecmd => sub {$LAST_PAGE_VIEWED = 'page3'});
   $nb->raise($LAST_PAGE_VIEWED);
   
   $page1->Label(-text   => "\nAxis Title",
                 -font   => $fontb,
                 -anchor => 'w')
         ->pack(-side => 'top', -fill => 'x', -anchor => 'w');
   my $entry = $page1->Scrolled('Text', -scrollbars => 'se',
                             -font   => $font,
                             -width  => 30,
                             -height => 5,
                             -bg     => 'white' )
                  ->pack(-side => 'top', -fill => 'x');
   $entry->insert('end', $aref->{-title});  
   $entry->focus;     
   
        
   my $f_a = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_a->Label(-text => 'Axis Type',
               -font => $fontb)
       ->pack(-side => 'left');
   $mb_ax = $f_a->Menubutton(-text      => $axis{$aref->{-type}},
                             -font      => $fontb,
                             -indicator => 1,
                             -tearoff   => 0,
                             -relief    => 'ridge',
                             -menuitems => [ @type ],
                             -width     => 11 )
                ->pack(-side => 'left'); 
   my $f_aa = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_aa->Checkbutton(-text     => 'Reverse Axis  ',
                     -font     => $fontb,
                     -variable => \$aref->{-reverse},
                     -onvalue  => 1,
                     -offvalue => 0)
       ->pack(-side => 'left');
   $f_aa->Checkbutton(-text     => 'Hide Numbers and Title  ',
                     -font     => $fontb,
                     -variable => \$aref->{-hideit},
                     -onvalue  => 1,
                     -offvalue => 0)
       ->pack(-side => 'left');
   $f_aa->Checkbutton(-text     => 'Double Label',
                     -font     => $fontb,
                     -variable => \$aref->{-doublelabel},
                     -onvalue  => 1,
                     -offvalue => 0)
        ->pack(-side => 'left');
   

   # Specify auto plot limit configuration, additional data read in after modifying
   # these selections will cause the limits to potentially change.  Each axis can be
   # controlled via the ContinuousAxisEditor, which will usually be the prefered route.
   my $f_auto = $page1->Frame(-borderwidth => 2,
                              -relief => 'groove')
                      ->pack(-side => 'top', -fill => 'x');   
   &AutoPlotLimitWidget($f_auto,$aref,$heading);


   $f_special1 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   if($aref->{-type} eq 'linear') {
      $f_special2 = &_lineareditor1($self,$canv, $f_special1, $xoy, $para); }
   elsif($aref->{-type} eq 'log') {
      ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                    &_logeditor1($self,$canv, $f_special1, $xoy, $para); }
   elsif($aref->{-type} eq 'prob') {
      ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                    &_probeditor1($self,$canv, $f_special1, $xoy, $para); } 
   elsif($aref->{-type} eq 'grv') {
      ($f_special2, $e_base, $e_basetolabel, $e_baseminor) =
                    &_probeditor1($self,$canv, $f_special1, $xoy, $para); }
   elsif($aref->{-type} eq 'time') {
      ($f_special2, $dt_begin, $dt_end) = 
                    &_timeeditor1($self,$canv, $f_special1, $xoy, $para); }
   else { &Message($pe,'-generic',
                       "Axis type '$aref->{-type}' is not recognized");
        } 
   
   ## TITLE AND LABEL FONTS
   $page2->Label(-text => "\nTitle Font, Size(pt), Weight, Slant, and Color",
                 -font => $fontb)
         ->pack(-side => 'top', -anchor => 'w');       
   my $f_1 = $page2->Frame->pack(-side => 'top', -fill => 'x');   
   $f_1->Menubutton(-textvariable => \$labfontfam,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labelfam ])
       ->pack(-side => 'left');
   $f_1->Entry(-textvariable => \$labfontref->{-size},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');
   $f_1->Menubutton(-textvariable => \$labfontwgt,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labwgt ],
                    -width        => 6)
       ->pack(-side => 'left');
   $f_1->Menubutton(-textvariable => \$labfontslant, 
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @labslant ],
                    -width => 6)
       ->pack(-side => 'left');   
   $mb_labfontcolor = $f_1->Menubutton(
                    -textvariable => \$labfontcolor,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -width        => 12,
                    -menuitems    => [ @labcolors ],
                    -background   => $labfontcolorbg,
                    -activebackground => $labfontcolorbg)
                    ->pack(-side => 'left');      
   my $f_2a = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_2a->Checkbutton(-text     => "Vertically stack title text",
                       -font     => $fontb,
                       -variable => \$labfontref->{-stackit},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_2a->Label(-text => "   Angle (for MetaPost)",
               -font => $fontb)
       ->pack(-side => 'left');
   $f_2a->Entry(-textvariable => \$labfontref->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');

  $page2->Label(-text => "\nLabel Font, Size(pt), Weight, Slant, and Color",
                -font => $fontb)
        ->pack(-side => 'top', -anchor => 'w');       
               
   my $f_3 = $page2->Frame->pack(-side => 'top', -fill => 'x');   
   $f_3->Menubutton(-textvariable => \$numfontfam,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @numfam ])
       ->pack(-side => 'left');
   $f_3->Entry(-textvariable => \$numfontref->{-size},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');
   $f_3->Menubutton(-textvariable => \$numfontwgt,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @numwgt ],
                    -width        => 6)
       ->pack(-side => 'left');
   $f_3->Menubutton(-textvariable => \$numfontslant,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge', 
                    -tearoff      => 0,
                    -menuitems    => [ @numslant ],
                    -width        => 6)
       ->pack(-side => 'left');   
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
                    ->pack(-side => 'left');

   my $f_2b = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_2b->Checkbutton(-text     => "Vertically stack label text",
                       -font     => $fontb,
                       -variable => \$numfontref->{-stackit},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_2b->Label(-text => "   Angle (for MetaPost)",
               -font => $fontb)
       ->pack(-side => 'left');
   $f_2b->Entry(-textvariable => \$numfontref->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');

        
   my $f_bl = $page2->Frame->pack(-side => 'top', -fill => 'x');
      $f_bl->Checkbutton(-text => 'Do text blanking with color:',
                         -font => $fontb,
                         -variable => \$aref->{-blankit},
                         -onvalue => 1,
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

   # Backwards compatability for 0.50.3, set to 1 unless already defined
   $aref->{-labelmin} = 1 unless(defined $aref->{-labelmin});
   $aref->{-labelmax} = 1 unless(defined $aref->{-labelmax});
   my $f_edge1 = $page2->Frame->pack(-side => 'top', -fill => 'x');   
   $f_edge1->Checkbutton(-text     => "Label minimum  ",
                       -font     => $fontb,
                       -variable => \$aref->{-labelmin},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
  # my $f_edge1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_edge1->Checkbutton(-text     => "Label maximum",
                       -font     => $fontb,
                       -variable => \$aref->{-labelmax},
                       -anchor   => 'w',
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left'); 
  
   
   # BACKWARD COMPATABILITY FOR 0.51.1, NOT REALLY NEED, BUT
   # INSURES THE FIELD IS FILLED.
   $aref->{-min_to_begin_labeling} = ""
      if(not defined $aref->{-min_to_begin_labeling});
   $aref->{-max_to_end_labeling}   = ""
      if(not defined $aref->{-max_to_end_labeling});
   
   # Backwards compatability for 0.61, set to 0 unless already defined
   $aref->{-tick_to_actual_min_and_max} = 0
                     unless(defined $aref->{-tick_to_actual_min_and_max});
   
   my $f_tolabel1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_tolabel1->Label(-text => "Mininum to begin labels",
                 -font => $fontb)
             ->pack(-side => 'left', -anchor => 'w');
   $f_tolabel1->Entry(-textvariable => \$aref->{-min_to_begin_labeling},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
             ->pack(-side => 'left', -fill => 'x');
 
   my $f_tolabel2 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_tolabel2->Label(-text => 'Maximum to end labels  ',
                 -font => $fontb)
             ->pack(-side => 'left', -anchor => 'w');
   $f_tolabel2->Entry(-textvariable => \$aref->{-max_to_end_labeling},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');

   my $f_tolabel3 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_tolabel3->Checkbutton(
              -text     => "Tick to actual minimum and maximum of the axis",
              -font     => $fontb,
              -variable => \$aref->{-tick_to_actual_min_and_max},
              -anchor   => 'nw',
              -justify  => 'left',
              -onvalue  => 1,
              -offvalue => 0)
              ->pack(-side => 'left', -fill => 'x');  

               
   my $f_o1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   #$f_o1->Label(-text => "\n")->pack(-fill => 'x');     
   $f_o1->Label(-text => 'Title and label location',
                -font => $fontb)->pack(-side => 'left');
   $f_o1->Menubutton(-textvariable => \$location,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @locations ] )
        ->pack(-side => 'left', -fill => 'x');        
         
   my $f_o2 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o2->Label(-text => 'Title Offset',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o2->Entry(-textvariable => \$laboffset,
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left', -fill => 'x');
   $f_o2->Label(-text => ' Title2 Offset',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o2->Entry(-textvariable => \$lab2offset,
                -font         => $font,
                -background   => 'white',
                -width        => 10  )
        ->pack(-side => 'left', -fill => 'x');
   my $f_o3 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_o3->Label(-text => 'Label Offset',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_o3->Entry(-textvariable => \$numoffset,
                -font         => $font,
                -background   => 'white',
                -width        => 10 )
        ->pack(-side => 'left', -fill => 'x');
   
  
   
   
   
        
   my $f_tick = $page2->Frame->pack(-side => 'top', -fill => 'x');        
   $f_tick->Label(-text => 'Major Tick Length',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');
   $f_tick->Entry(-textvariable => \$ticklength,
                  -font => $font,
                  -background   => 'white',
                  -width        => 7 )
          ->pack(-side => 'left', -fill => 'x');
   $f_tick->Label(-text => ' Tick Width',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');
   $mb_tickwidth = $f_tick->Menubutton(-textvariable => \$tickwidth,
                                       -font         => $fontb,
                                       -indicator    => 1,
                                       -relief       => 'ridge',
                                       -menuitems    => [ @tickwidth ],
                                       -tearoff      => 0)
                          ->pack(-side => 'left', -fill => 'x');  
        
               
   $f_tick->Label(-text => ' Minor/Major',
                  -font => $fontb)
          ->pack(-side => 'left', -anchor => 'w');
   $f_tick->Entry(-textvariable => \$aref->{-tickratio},
                  -font         => $font,
                  -background   => 'white',
                  -width        => 4 )
          ->pack(-side => 'left', -fill => 'x');


   my $f_f = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_f->Label(-text => 'Label Format, Decimals',
               -font => $fontb)
       ->pack(-side => 'left');
   $mb_for = $f_f->Menubutton(-text      => $format{$aref->{-numformat}},
                              -font      => $fontb,
                              -indicator => 1,
                              -tearoff   => 0,
                              -relief    => 'ridge',
                              -menuitems => [ @format ],
                              -width     => 12 )
                 ->pack(-side => 'left'); 
   $f_f->Entry(-textvariable => \$aref->{-numdecimal}, 
               -font         => $font,
               -background   => 'white',
               -width        => 6  )
        ->pack(-side => 'left');   
   $f_f->Checkbutton(-text     => 'Commify Numbers',
                     -font     => $fontb,
                     -variable => \$aref->{-numcommify},
                     -onvalue  => 1,
                     -offvalue => 0)
        ->pack(-side => 'left');


   # MAJOR GRIDLINE STUFF
   my $f_g11 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g11->Label(-text => 'Major Grid Lines:',
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
                          -indicator    => 1, -relief => 'ridge',
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
        
        
   # MINOR GRIDLINE STUFF
   my $f_g2a = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g2a->Label(-text => 'Minor Grid Lines:',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   my $f_g2 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g2->Checkbutton(-text     => 'Doit',
                      -font     => $fontb,
                      -variable => \$aref->{-gridminor}->{-doit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   $f_g2->Label(-text => ' Width,Color,Style',
                -font => $fontb)
        ->pack(-side => 'left');
   $mb_minorgridlinewidth = $f_g2->Menubutton(
                          -textvariable => \$minorgridlinewidth,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @minorgridlinewidth ],
                          -tearoff      => 0)
                                 ->pack(-side => 'left');   
   $mb_minorgridlinecolor = $f_g2->Menubutton(
                          -textvariable => \$pickedminorgridlinecolor,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -width        => 12,
                          -menuitems    => [ @minorgridlinecolors ],
                          -background   => $pickedminorgridlinecolorbg,
                          -activebackground => $pickedminorgridlinecolorbg)
                                 ->pack(-side => 'left');       
   $mb_minorgriddashstyle = $f_g2->Menubutton(
                          -textvariable => \$aref->{-gridminor}->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @gridminordashstyle ])
                          ->pack(-side => 'left'); 

   # ORIGIN STUFF
   my $f_g3a = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g3a->Label(-text => 'Origin Line:     ',
                 -font => $fontb)
          ->pack(-side => 'left'); 
   my $f_g3 = $page3->Frame->pack(-side => 'top', -fill => 'x');
   $f_g3->Checkbutton(-text     => 'Doit',
                      -font     => $fontb,
                      -variable => \$aref->{-origindoit},
                      -onvalue  => 1,
                      -offvalue => 0)
        ->pack(-side => 'left');
   $f_g3->Label(-text => ' Width,Color,Style',
                -font => $fontb)
        ->pack(-side => 'left');
   $mb_originwidth = $f_g3->Menubutton(-textvariable => \$originwidth, 
                                       -font         => $fontb,
                                       -indicator    => 1,
                                       -relief       => 'ridge',
                                       -menuitems    => [ @originwidth ],
                                       -tearoff      => 0)
                          ->pack(-side => 'left');   
   $mb_origincolor = $f_g3->Menubutton(-textvariable => \$pickedorigincolor,
                                       -font         => $fontb,
                                       -indicator    => 1, 
                                       -relief       => 'ridge',
                                       -tearoff      => 0,
                                       -width        => 12,
                                       -menuitems    => [ @origincolors ],
                                       -background   => $pickedorigincolorbg, 
                                       -activebackground => $pickedorigincolorbg)
                          ->pack(-side => 'left');     
   $mb_origindashstyle = $f_g3->Menubutton(
                          -textvariable => \$aref->{-origindashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @origindashstyle ])
                          ->pack(-side => 'left');      

   my $finishsub = sub {
          $aref->{-majorstep} = 1 if( $aref->{-majorstep} eq "" );
          $aref->{-majorstep} =  abs( $aref->{-majorstep} );
          foreach ($laboffset, $lab2offset, $numoffset, $ticklength) {
             s/^([0-9.]+)$/$1i/
          }
          $aref->{-laboffset}  = $pe->fpixels($laboffset);
          $aref->{-lab2offset} = $pe->fpixels($lab2offset);
          $aref->{-numoffset}  = $pe->fpixels($numoffset);
          $aref->{-ticklength} = $pe->fpixels($ticklength); 
          $aref->{-title} = $entry->get('0.0', 'end');
          $aref->{-title} =~ s/\n$//;
          my $type = $aref->{-type};
          if( not &isNumber($aref->{-tickratio} ) or
                            $aref->{-tickratio} < 0 ) {
             &Message($pe,'-generic',"Invalid tick ratio\n");
             return;                  
          }
          if( not &isNumber($aref->{-numdecimal} ) or
                            $aref->{-numdecimal} < 0 ) {
             &Message($pe,'-generic',"Invalid number of decimals\n");
             return;                  
          }
          if( not &isNumber($aref->{-labfont}->{-size} ) or
                            $aref->{-labfont}->{-size} < 0 ) {
             &Message($pe,'-generic',"Invalid label font size\n");
             return;                  
          }
          if( not &isNumber($aref->{-numfont}->{-size} ) or
                            $aref->{-numfont}->{-size} < 0 ) {
             &Message($pe,'-generic',"Invalid number font size\n");
             return;                  
          }
          if( not &isNumber($aref->{-logoffset}) ) {
             my $mess = "The value entered ($aref->{-logoffset} ".
                        "for a logarithmic offset ".
                        "is not a number.  Please revise.";
             &Message($pe, '-generic', $mess);
             return;
          }          
          if($type eq 'time') {
                
              ($dt_begin, $dt_end) = &_timeAsk_if_DateFieldsEmpty($aref,$dt_begin,$dt_end);           
              ($dt_begin, $dt_end) = &_timeShortCuts($dt_begin, $dt_end);
              
              # Finally, check                                     
              # kick off warnings if the hhmmss fields do not seem
              # to be proper
              my $additional_text = "Double digit hh:mm:ss fields are required ".
                                    "and ss can also be fractional.";
              if($dt_begin->{-time} !~ m/:\d\d:/o) {
              
                 &Message($pe,'-generic',
                    "Beginning hh:mm:ss field does not have enough colons.  ".
                    "$additional_text");
                 return;
              }
              if($dt_end->{-time} !~ m/:\d\d:/o) {
                 &Message($pe,'-generic',
                    "Ending hh:mm:ss field does not have enough colons.  ".
                    "$additional_text");
                 return;
              }
              
              # make copies of the date fields so that substitution support
              # will work

              my $begin_date = $dt_begin->{-date};
              my $end_date   = $dt_end->{-date}; 
              
              
              # Ok, by now we should have a valid date of some sort
              # in the date field that contains //.  Now we need to get
              # rid of these.
              $begin_date =~ s%[/]%%go;  # strip all forward slashes
                $end_date =~ s%[/]%%go;  # strip all forward slashes
              
              # Here we actually check to see whether or not the field
              # is valid
              my $minstring = $begin_date.$dt_begin->{-time};
              my $min = &DecodeTkg2DateandTime($minstring);
              if(not defined $min) {
                 &Message($pe,'-generic',"Invalid beginning date limit\n");
                 return;
              }
              
              my $maxstring = $end_date.$dt_end->{-time};
              my $max = &DecodeTkg2DateandTime($maxstring);
              if(not defined $max) {
                 &Message($pe,'-generic',"Invalid ending date limit\n");
                 return;
              }    
              $min = &repackit($min);  # PERL5.8 CORRECTION
              $max = &repackit($max);  # PERL5.8 CORRECTION

              if( $max-$min <= 0 ) {
                 &Message($pe,'-generic',
                 "Min date/time greater than max date/time. . . ".
                 "Invalid date limits\n");
                 return;
              }

              $aref->{-min} = $min;
              $aref->{-max} = $max;
              $aref->{-time}->{-min} = $minstring;
              $aref->{-time}->{-max} = $maxstring;
              # PERL5.8 CORRECTION RESEARCH
              #print "BUG: $min, $max   and   $minstring, $maxstring\n";
          }
          else {
             my $range;
             CONFIG_LIMITS: {
                my $_special_todo_for_log = sub {
                   $e_base->delete(0, 'end');
                   $e_base->insert('end', "@{$aref->{-basemajor}}");
                   $e_basetolabel->delete(0, 'end');
                   $e_basetolabel->insert('end', "@{$aref->{-basemajortolabel}}");
                   $e_baseminor->delete(0, 'end');
                   $e_baseminor->insert('end', "@{$aref->{-baseminor}}");
                };  # end _special_todo_for_log
             
             
                my $valid = 1;
                my $min = $aref->{-min};
                my $max = $aref->{-max};
                if($min eq "" and $max eq "") {
                   $self->autoConfigurePlotLimits($xoy);
                   &$_special_todo_for_log() if($type eq 'log');
                   return 1;
                }
                if($min eq "") {
                   $self->autoConfigurePlotLimits($xoy,'justmin');
                   &$_special_todo_for_log() if($type eq 'log');
                   return 1;
                }
                if($max eq "") {
                   $self->autoConfigurePlotLimits($xoy,'justmax');
                   &$_special_todo_for_log() if($type eq 'log');
                   return 1;
                }
                $valid = 0 unless( &isNumber($min) and &isNumber($max) );
                $range = $max - $min if($valid);
                $valid = 0 if( $valid && $range <=0 );
                $valid = 0 if( $type eq 'log' and ($min <= 0 || $max <= 0 ) );  
                unless($valid) {
                   if($type eq 'prob' or $type eq 'grv') {
                      if( $range <=0 ) {
                         # We go ahead and set the limits for the probability
                         # axis because the limits are reasonably well
                         # bounded by logic [0,1] unlike linear or log.
                         &Message($pe,'-generic',
                         "Probability maximum can not be <= minimum\n".
                         "Arbitrarily setting minimum to 1 percent or 0.01 and ".
                         "setting maximum to 99 percent or 0.99.  To give you ".
                         "an example pair of settings.\n");
                         $aref->{-min} = 0.01;
                         $aref->{-max} = 0.99;
                         return 0;
                      }
                   }
                   else {
                      print "$aref->{-min}\n";
                      &Message($pe,'-generic',"Invalid axis limits: ".
                                              "$aref->{-min} and $aref->{-max}\n");
                      return 0;
                   }
                }
                if(not &isNumber($aref->{-numminor}) or
                                 $aref->{-numminor} < 0 ) {
                      &Message($pe,'-generic',"Invalid number of minor ticks\n");
                      return 0;
                }
                
                # we now know that the minimum and maximum for the axis
                # lets see if we need to do something with the 
                # min_to_begin_labeling and max_to_end_labeling
                if($aref->{-min_to_begin_labeling} ne "") {
                   if(not &isNumber($aref->{-min_to_begin_labeling})) {
                      &Message($pe,'-generic',"Invalid minimum to ".
                                              "begin labeling.");
                      $aref->{-min_to_begin_labeling} = "";
                      return 0;
                   }
                   if($aref->{-min_to_begin_labeling} < $min) {
                      &Message($pe,'-generic',"Minimum to begin labeling is ".
                               "less than axis minimum, setting to null.");
                      $aref->{-min_to_begin_labeling} = "";
                      return 0;
                   }
                   if($aref->{-min_to_begin_labeling} >= $max) {
                      &Message($pe,'-generic',"Minimum to begin labeling is ".
                               "greater than or equal to axis maximum, ".
                               "setting to null.");
                      $aref->{-min_to_begin_labeling} = "";
                      return 0;
                   }
                }
                if($aref->{-max_to_end_labeling} ne "") {
                   if(not &isNumber($aref->{-max_to_end_labeling})) {
                      &Message($pe,'-generic',"Invalid maximum to ".
                                              "end labeling.");
                      $aref->{-max_to_end_labeling} = "";
                      return 0;
                   }
                   if($aref->{-max_to_end_labeling} > $max) {
                      &Message($pe,'-generic',"Maximum to end labeling is ".
                               "greater than axis maximum, setting to null.");
                      $aref->{-max_to_end_labeling} = "";
                      return 0;
                   }
                   if($aref->{-max_to_end_labeling} <= $min) {
                      &Message($pe,'-generic',"Maximum to end labeling is ".
                               "less than or equal to axis minimum, ".
                               "setting to null.");
                      $aref->{-max_to_end_labeling} = "";
                      return 0;
                   }
                   if($aref->{-min_to_begin_labeling} ne "" and
                      $aref->{-max_to_end_labeling}   ne "" and
                      $aref->{-min_to_begin_labeling} >= 
                      $aref->{-max_to_end_labeling} ) {
                      $aref->{-min_to_begin_labeling} = "";
                      $aref->{-max_to_end_labeling}   = "";
                      &Message($pe,'-generic',"Minimum to begin labeling is ".
                               "greater than or equal to Maximum to end ".
                               "labeling.  This is inconsistent, setting to null.");
                      return 0;
                   }
                }
             
             }
             if(defined($para->{-major})) {
                $para->{-major} = &strip_commas($para->{-major});
                $para->{-major} = &strip_space($para->{-major});
                my @array = split(/\s+/, $para->{-major});
                if(not &arrayhasNumbers(@array)) {
                   &Message($pe,'-generic',
                                "Invalid special major ticks\n");
                   return 0;
                }
                $aref->{-major} = [ @array ];
             }
             if($para->{-minor}) {
                $para->{-minor} = &strip_commas($para->{-minor});
                $para->{-minor} = &strip_space($para->{-minor});
                my @array = split(/\s+/, $para->{-minor});
                if(not &arrayhasNumbers(@array)) {
                   &Message($pe,'-generic',
                                "Invalid special minor ticks\n");
                   return 0;
                }
                $aref->{-minor} = [ @array ];
             }
             if($type eq 'linear') {
                if(not &isNumber($aref->{-majorstep}) or
                                   $aref->{-majorstep} < 0 ) {
                   &Message($pe,'-generic',
                                "Invalid number of major steps\n");
                   return 0;
                }
                if(not &isNumber($aref->{-labskip}) or
                                   $aref->{-labskip} < 0 ) {
                   &Message($pe,'-generic',
                                "Invalid number of label skipping\n");
                   return 0;
                }
                if( ( ($range/$aref->{-majorstep}) *
                       $aref->{-numminor} ) >= 1000 ) {
                   &Message($pe,'-generic',
                                "Over 1000 ticks on axis, too many!\n");
                   return 0;
                }
             }
          }
          
          # best trap on the transform equation for now, the Draw::DrawLabels.pm
          # provides the eval wrapper and another check that a valid
          # equation was placed in field
          if( $type eq 'linear' or $type eq 'log' ) {
              $aref->{-labelequation} = 0
                  if( not defined $aref->{-labelequation} or 
                                  $aref->{-labelequation} eq "" );
          }
          
          # insure that neither 0 or 1 can be used as probability limits
          if($type eq 'prob' or $type eq 'grv') {
             my $min = $aref->{-min};
             my $max = $aref->{-max};
             if( $min <=0 or $min >= 1) {
                 &Message($pe,'-generic',
                 "Probability minimum can not be <= 0 or >= 1.\n".
                 "Arbitrarily setting to 1 percent or 0.01.\n");
                 $aref->{-min} = 0.01;
                 return 0;
             }
             if( $max >= 1 or $max <= 0) {
                 &Message($pe,'-generic',
                 "Probability maximum can not be >= 1 or <= 0.\n".
                 "Arbitrarily setting to 99 percent or 0.99.\n");
                 $aref->{-max} = 0.99;
                 return 0;
             }
          }
      
          if( $type eq 'prob' or $type eq 'log' or $type eq 'grv' ) {
             if(              ref($aref->{-logoffset}) ne 'ARRAY'
                and not &isNumber($aref->{-logoffset}) ) {
                &Message($pe,'-generic',"Log offset is not a number.\n");
                return 0;
             }
             if( defined($para->{-basemajor}) ) {
                $para->{-basemajor} = &strip_space($para->{-basemajor});
                my @array = split(/\s+/, $para->{-basemajor});
                if(not &arrayhasNumbers(@array)) {
                   my $mess = "Invalid base major ticks\n";
                   &Message($pe,'-generic',$mess);
                   return 0;
                }
                else {
                   $aref->{-basemajor} = [ @array ];
                }   
             }
             if( defined $para->{-basemajortolabel} ) {
                $para->{-basemajortolabel} = &strip_space($para->{-basemajortolabel});
                my @array = split(/\s+/, $para->{-basemajortolabel});
                if(not &arrayhasNumbers(@array)) {
                   my $mess = "Invalid base major ticks to label\n";
                   &Message($pe,'-generic', $mess);
                   return 0;
                }
                else {
                   $aref->{-basemajortolabel} = [ @array ];
                }       
             }
             
             if( defined($para->{-baseminor}) ) {
                $para->{-baseminor} = &strip_space($para->{-baseminor});
                my @array = split(/\s+/, $para->{-baseminor});
                if(not &arrayhasNumbers(@array)) {
                   my $mess = "Invalid base minor ticks\n";
                   &Message($pe,'-generic',$mess);
                   return 0;
                }
                else {
                   $aref->{-baseminor} = [ @array ];
                }            
             }
          }
          # PERL5.8 CORRECTION RESEARCH
          #if(&isInteger($self->{-y}->{-logoffset})) {
              #print STDERR "BUG: finishsub continuousaxiseditor offset is an integer\n";
          #}
          #else {
          #    print STDERR "BUG: finishsub continuousaxiseditor offset is not an integer\n";
          #}
          $aref->{-min} = &repackit($aref->{-min}); # PERL5.8 CORRECTION
          $aref->{-max} = &repackit($aref->{-max}); # PERL5.8 CORRECTION
          return 1;  };
 
   my $restoresub = sub {
             my $type = $aref->{-type};
             if($type eq 'linear') {  # restore the linear settings
                $aref->{-labelequation} = 0;
             }
             elsif($type eq 'log') { # restore the log settings
                $aref->{-labelequation} = 0;
                my @entries = ( $e_base, $e_basetolabel, $e_baseminor);
                map { $_->delete(0,'end') } @entries;
                $e_base->insert(       'end', "@{ $::TKG2_CONFIG{-LOG_BASE_MAJOR_TICKS} }" );
                $e_basetolabel->insert('end', "@{ $::TKG2_CONFIG{-LOG_BASE_MAJOR_LABEL} }" );
                $e_baseminor->insert(  'end', "@{ $::TKG2_CONFIG{-LOG_BASE_MINOR_TICKS} }" ); 
             }
             elsif($type eq 'prob' or $type eq 'gum') {
                my @entries = ( $e_base, $e_basetolabel, $e_baseminor);
                map { $_->delete(0,'end') } @entries;
                $e_base->insert(       'end', "@{ $::TKG2_CONFIG{-PROB_BASE_MAJOR_TICKS} }" );
                $e_basetolabel->insert('end', "@{ $::TKG2_CONFIG{-PROB_BASE_MAJOR_LABEL} }" );
                $e_baseminor->insert(  'end', "@{ $::TKG2_CONFIG{-PROB_BASE_MINOR_TICKS} }" ); 
             }
             elsif($type eq 'time') {
             
             }
             else { warn "Invalid axis type in ContinuousAxisEditor \$restoresub\n"; }
          };
   
   my @p = (-side => 'left', -padx => $px, -pady => $py);
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'bottom', -fill => 'x');   
   my $f_t = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'bottom', -fill => 'both', -expand => 1);  
      $f_t->Label(-text=>' ')->pack(-side => 'top', -fill => 'y', -expand => 1); 
   my $b_apply = $f_b->Button(-text        => 'Apply',
                              -font        => $fontb,
                              -borderwidth => 3,
                              -highlightthickness => 2,
                              -command =>
                                  sub { print $::MESSAGE "CONTINUOUS_AXIS_EDITOR\n";
                                        &_update_min_offset_and_max_offset($aref);
                                        &Perl5_8_BUG_Detective($self,caller);
                                        my $go = &$finishsub;
                                        &Perl5_8_BUG_Detective($self,caller);
                                        print $::MESSAGE "END CONTINUOUS_AXIS_EDITOR\n\n\n";
                                        $template->UpdateCanvas($canv) if($go);
                                      } )
                     ->pack(@p);   
                             
   $b_apply->focus;
   $f_b->Button(-text        => 'OK',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { print $::MESSAGE "CONTINUOUS_AXIS_EDITOR\n";
                                  &Perl5_8_BUG_Detective($self,caller);
                                  my $go = &$finishsub;
                                  $template->UpdateCanvas($canv) if($go);
                                  &Perl5_8_BUG_Detective($self,caller);
                                  print $::MESSAGE "END CONTINUOUS_AXIS_EDITOR\n\n\n";
                                  $pe->destroy; } )
       ->pack(@p);  
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; })
       ->pack(@p);
                      
   $f_b->Button(-text    => 'Defaults',
                -font    => $fontb,
                -command => sub { &$restoresub; })
       ->pack(@p);                   
   $f_b->Button(-text    => 'Plot Editor',
                -font    => $fontb,
                -command => sub { $self->PlotEditor($canv, $template); })
       ->pack(@p);
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { &Help($pe,'ContinuousAxisEditor.pod'); } )
       ->pack(@p);
   #my $b_test = $f_b->Button(-text        => '!!Debug Apply!!',
   #                          -font        => $fontb,
   #                          -borderwidth => 3,
   #                          -highlightthickness => 2,
   #                          -command =>
   #                               sub { my $go = &$finishsub;
   #                                     $template->UpdateCanvas($canv,0,'increment') if($go);
   #                                   } )
   #                  ->pack(@p);
}                      
                 

sub Perl5_8_BUG_Detective {
    my ($plot,$pkg,$filename,$line) = @_;
    my $xmin   = $plot->{-x}->{-min};
    my $ymin   = $plot->{-y}->{-min};
    my $y2min  = $plot->{-y2}->{-min};
    my $xmax   = $plot->{-x}->{-max};
    my $ymax   = $plot->{-y}->{-max};
    my $y2max  = $plot->{-y2}->{-max};
    my $xtype  = $plot->{-x}->{-type};
    my $ytype  = $plot->{-y}->{-type};
    my $y2type = $plot->{-y2}->{-type};
    print $::MESSAGE
          "$pkg  $filename  $line\n",
          "  xtype=$xtype | ytype=$ytype | y2type=$y2type |",
          " xmin=$xmin | xmax=$xmax | ymin=$ymin | ymax=$ymax |",
          " y2min=$y2min | y2max=$y2max\n";
}


###############################################
# LINEAR EDITOR
###############################################                 
sub _lineareditor1 {
   my ($self, $canv, $pe, $xoy, $para) =
                 ( shift, shift, shift, shift, shift);
   
   # When this subroutine is invoked, the user has more than
   # likely actually changed the axis type.  Thus, it because
   # necessary to delete all of the parse data cache
   my $dataclass = $self->{-dataclass};
   foreach my $dataset (@{$dataclass}) {
      map { delete( $_->{-parseData} ) } @{$dataset->{-DATA}};
   }
   
   my $aref = $self->{$xoy};
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   my $f_1 = $pe->Frame->pack(-fill => 'x');
   my $f_min = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_min->Label(-text => "Minimum",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$aref->{-min},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   $f_min->Label(-text => "  Major Tick Interval",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w'); 
   $f_min->Entry(-textvariable => \$aref->{-majorstep},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');  
        
   my $f_max = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_max->Label(-text => 'Maximum',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_max->Entry(-textvariable => \$aref->{-max},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   $f_max->Label(-text => "  No. of Minor Ticks ",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w'); 
   $f_max->Entry(-textvariable => \$aref->{-numminor},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   
   my $f_lab = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_lab->Label(-text => 'No. of Numbers to Skip',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_lab->Entry(-textvariable => \$aref->{-labskip},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   my $f_lab1 = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_lab1->Button(-text     => 'Axis to percent base',
                   -font     => $fontb,
                   -command  => sub { $self->configureAxisToPercentBase($xoy);} )
          ->pack(-side => 'left');
   $f_lab1->Button(-text     => 'Axis to fractional percent base',
                   -font     => $fontb,
                   -command  => sub { $self->configureAxisToPercentBase($xoy,'frac');} )
          ->pack(-side => 'left');

   &_labelEquation($f_1,$fontb,\$aref->{-labelequation});
   
   &_specialTicks($f_1,$fontb,\$para->{-major},\$para->{-minor});
   return $f_1;
}



###############################################
# LOG EDITOR
###############################################
sub _logeditor1 {
   my ($self, $canv, $pe, $xoy, $para) =
                       ( shift, shift, shift, shift, shift);
   
   # When this subroutine is invoked, the user has more than
   # likely actually changed the axis type.  Thus, it because
   # necessary to delete all of the parse data cache
   my $dataclass = $self->{-dataclass};
   foreach my $dataset (@{$dataclass}) {
      map { delete( $_->{-parseData} ) } @{$dataset->{-DATA}};
   }
   
   my $aref = $self->{$xoy};
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $smfont  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-small};
   
   
   # Make sure that we have valid entries
   # These conditionals can only? be triggered if the axis
   # type is changed without loading data into the plot.
   $aref->{-min} = 0.01 if($aref->{-min} < 0);
   $aref->{-max} = 100  if($aref->{-max} < 0);

   my $e_baseminor;
   my @minor_shortcuts = (
       [ 'command' => 'Clear Minor Ticks',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end'); } ],
       "-",
       [ 'command' => '   Half Ticks  (.50)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            my $int;
                            foreach (10..100) {
                               next if(/0$/o);
                               $int = $_/5;
                               next if($int ne int($int));
                               push(@minors, $_/10);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => 'Quarter Ticks  (.25)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            my $int;
                            foreach (100..1000) {
                               $int = $_/25;
                               next if($int ne int($int) or /00$/o);
                               push(@minors, $_/100);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => ' Barely Dense  (.20)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            my $int;
                            foreach (10..100) {
                               next if(/0$/o);
                               $int = $_/2;
                               next if($int ne int($int));
                               push(@minors, $_/10);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => '        Dense  (.10)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            foreach (10..100) {
                               next if(/0$/o);
                               push(@minors, $_/10);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => ' Fairly Dense  (.02)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            my $int;
                            foreach (100..1000) {
                               next if(/00$/o);
                               $int = $_/2;
                               next if($int ne int($int));
                               push(@minors, $_/100);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => '  Super Dense  (.01)',
         -font     => $smfont,
         -command  => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            foreach (100..1000) {
                               next if(/00$/o);
                               push(@minors, $_/100);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
       [ 'command' => '   Mega Dense (.001)',
          -font    => $smfont,
          -command => sub { $e_baseminor->delete(0,'end');
                            my @minors;
                            foreach (1000..10000) {
                               next if(/000$/o);
                               push(@minors, $_/1000);
                            }
                            $e_baseminor->insert('end',"@minors");
                          } ],
      );


   my $f_1   =  $pe->Frame->pack(-fill => 'x');
   my $f_min = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_min->Label(-text => "Minimum",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$aref->{-min},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   $f_min->Label(-text => '  Maximum',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$aref->{-max},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
        ->pack(-side => 'left', -fill => 'x');
   $f_min->Checkbutton(
         -text     => 'Simple axis',
         -font     => $fontb,
         -variable => \$aref->{-usesimplelog},
         -onvalue  => 1,
         -offvalue => 0, )
         ->pack(-side => 'left');

   &_update_min_offset_and_max_offset($aref);

   my $f_off = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
      $f_off->Label(-text => "Min w/offset",
                      -font => $font)
              ->pack(-side => 'left', -anchor => 'w'); 
      $f_off->Entry(-textvariable => \$min_offset,
                      -font         => $font,
                      -relief       => 'raised',
                      -state        => 'disabled',
                      -width        => 8,
                      -borderwidth  => 1  )
              ->pack(-side => 'left', -fill => 'x');    
      $f_off->Label(-text => " Max w/offset",
                      -font => $font)
              ->pack(-side => 'left', -anchor => 'w'); 
      $f_off->Entry(-textvariable => \$max_offset,
                      -font         => $font,
                      -width        => 8,
                      -relief       => 'raised',
                      -state        => 'disabled',
                      -borderwidth  => 1)
              ->pack(-side => 'left', -fill => 'x');  
   $f_off->Label(-text => " Offset",
                 -font => $font)
          ->pack(-side => 'left', -anchor => 'w');
   $f_off->Entry(-textvariable => \$aref->{-logoffset},
                 -font         => $font,
                 -width        => 7,
		 -bg           => 'white',
                 -borderwidth  => 1)
         ->pack(-side => 'left', -fill => 'x');
   $f_off->Button(-text => 'update min/max',
                  -font => $fontb,
                  -command =>
              sub { &_update_min_offset_and_max_offset($aref);
                  } )
         ->pack(-side => 'left', -padx => 5, -anchor => 'w', -fill => 'x');  
   
   
   $f_1->Label(-text => "Base Major Ticks to DRAW (1 2 4)",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 1, -anchor => 'w');
   my $e_base = $f_1->Entry(-textvariable => \$para->{-basemajor},
                            -font         => $font,
                            -background   => 'white' )
                    ->pack(-side => 'top', -fill => 'x');
   $e_base->delete(0, 'end');
   if(not defined $aref->{-basemajor} ) {
      $e_base->insert('end', "@{$::TKG2_CONFIG{-LOG_BASE_MAJOR_TICKS}}");
   }
   else {
      $e_base->insert('end', "@{$aref->{-basemajor}}");
   }
    
   $f_1->Label(-text => "Base Major Ticks to LABEL (1 2 4)",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 1, -anchor => 'w');
   my $e_basetolabel = $f_1->Entry(-textvariable => \$para->{-basemajortolabel},
                                   -font         => $font,
                                   -background   => 'white' )
                           ->pack(-side => 'top', -fill => 'x');
   $e_basetolabel->delete(0, 'end');
   if(not defined $aref->{-basemajortolabel} ) {
      $e_basetolabel->insert('end', "@{$::TKG2_CONFIG{-LOG_BASE_MAJOR_LABEL}}");
   }
   else {
      $e_basetolabel->insert('end', "@{$aref->{-basemajortolabel}}");
   } 
   
   $f_1->Label(-text => "Base Minor Ticks to DRAW--".
                        "Use the convenience buttons below to help set minors.",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 1, -anchor => 'w');
   $e_baseminor = $f_1->Scrolled("Entry", -scrollbars => 's',
                                    -textvariable => \$para->{-baseminor},
                                    -font         => $font,
                                    -background   => 'white' )
                         ->pack(-side => 'top', -fill => 'x');
   $e_baseminor->delete(0, 'end');     
   if(not defined $aref->{-baseminor} ) {
      $e_baseminor->insert('end', "@{$::TKG2_CONFIG{-LOG_BASE_MINOR_TICKS}}");
   }
   else {
      $e_baseminor->insert('end', "@{$aref->{-baseminor}}");
   }
   
      
   my $f_minors_1 = $f_1->Frame
                        ->pack(-side   => 'top',
                               -fill   => 'x',
                               -expand => 1);
   $f_minors_1->Menubutton(-text      => 'Premade Minor Ticks',
                           -font      => $smfont,
                           -indicator => 1,
                           -tearoff   => 0,
                           -relief    => 'ridge',
                           -menuitems => [ @minor_shortcuts ],
                           -width     => 20 )
              ->pack(-side => 'left');
   $f_minors_1->Label(-text => "use to modify the minor ticking (step or values)",
                      -font => $smfont)
              ->pack(-side => 'left');    
   
   &_labelEquation($f_1,$fontb,\$aref->{-labelequation});
   
   &_specialTicks($f_1,$fontb,\$para->{-major},\$para->{-minor});
   return ($f_1, $e_base, $e_basetolabel, $e_baseminor);                                     
}

sub _update_min_offset_and_max_offset {
   my ($aref) = @_;
   $min_offset = $aref->{-min} + $aref->{-logoffset};
   $max_offset = $aref->{-max} + $aref->{-logoffset};
}
 
###############################################
# PROBABILITY EDITOR
###############################################
sub _probeditor1 {
   my ($self, $canv, $pe, $xoy, $para) =
        ( shift, shift, shift, shift, shift );
   
   # When this subroutine is invoked, the user has more than
   # likely actually changed the axis type.  Thus, it because
   # necessary to delete all of the parse data cache
   my $dataclass = $self->{-dataclass};
   foreach my $dataset (@{$dataclass}) {
      map { delete( $_->{-parseData} ) } @{$dataset->{-DATA}};
   }
   
   my $aref = $self->{$xoy};
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};

   # Make sure that we have valid entries
   # These conditionals can only? be triggered if the axis
   # type is changed without loading data into the plot.
   $aref->{-min} = 0.01 if($aref->{-min} < 0 or $aref->{-min} > 1);
   $aref->{-max} = 0.99 if($aref->{-max} > 1 or $aref->{-max} < 0);
   
   my $f_1 = $pe->Frame->pack(-fill => 'x');
   my $f_min = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_min->Label(-text => "Minimum",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$aref->{-min},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   $f_min->Label(-text => '    (1-Prob)',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');  
   $f_min->Checkbutton(-text     => 'Doit',
                       -font     => $fontb,
                       -variable => \$aref->{-invertprob},
                       -onvalue  => 1,
                       -offvalue => 0 )
         ->pack(-side => 'left', -fill => 'x');
              
   my $f_max = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_max->Label(-text => 'Maximum',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_max->Entry(-textvariable => \$aref->{-max},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'left', -fill => 'x');
   $f_max->Label(-text => '   RI style:',
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_max->Checkbutton(-text     => 'Doit',
                       -variable => \$aref->{-probUSGStype},
                       -font     => $fontb,
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left', -fill => 'x');
       
   $f_1->Label(-text => "\nMajor Ticks to DRAW in probability (.1 .2 .99)",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   my $e_base = $f_1->Scrolled("Entry", -scrollbars => 's',
                               -font         => $font,
                               -textvariable => \$para->{-basemajor},
                               -background   => 'white' )
                    ->pack(-side => 'top', -fill => 'x');
   $e_base->delete(0, 'end');
   if(not defined $aref->{-basemajor} ) {
      $e_base->insert('end', "@{$::TKG2_CONFIG{-PROB_BASE_MAJOR_TICKS}}");
   }
   else {
      $e_base->insert('end', "@{$aref->{-basemajor}}");
   }
   
   
   $f_1->Label(-text => "Major Ticks to LABEL in probability (.1 .2 .99)",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   my $e_basetolabel = $f_1->Scrolled("Entry", -scrollbars => 's',
                                      -textvariable => \$para->{-basemajortolabel},
                                      -font         => $font,
                                      -background   => 'white' )
                           ->pack(-side => 'top', -fill => 'x');
   $e_basetolabel->delete(0, 'end');
   if(not defined $aref->{-basemajortolabel} ) {
      $e_basetolabel->insert('end', "@{$::TKG2_CONFIG{-PROB_BASE_MAJOR_LABEL}}");
   }
   else {
      $e_basetolabel->insert('end', "@{$aref->{-basemajortolabel}}");
   }

   $f_1->Label(-text => "Minor Ticks to DRAW in probability (.11 .23 .991)",
               -font => $fontb)
       ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   my $e_baseminor = $f_1->Scrolled("Entry", -scrollbars => 's',
                                    -textvariable => \$para->{-baseminor},
                                    -font         => $font,
                                    -background   => 'white' )
                         ->pack(-side => 'top', -fill => 'x');
   $e_baseminor->delete(0, 'end');
   if(not defined $aref->{-baseminor} ) {
      $e_baseminor->insert('end', "@{$::TKG2_CONFIG{-PROB_BASE_MINOR_TICKS}}");
   }
   else {
      $e_baseminor->insert('end', "@{$aref->{-baseminor}}");
   }     
     
   &_specialTicks($f_1,$fontb,\$para->{-major},\$para->{-minor});
   return ($f_1, $e_base, $e_basetolabel, $e_baseminor);                                
}


sub _labelEquation {
   my ($frame, $font, $eq_ref) = @_;
   $frame->Label(-text => "\nLabel Transform Equation ".
                          "(0 for none, use '\$x' as variable even if Y-axis)",
                 -font => $font)
         ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   $frame->Entry(-textvariable => $eq_ref,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 15  )
         ->pack(-side => 'top', -fill => 'x');
}


sub _specialTicks {
   my ($frame, $font, $major_ref, $minor_ref) = @_;
   
   my $f_1 = $frame->Frame()
                   ->pack(-side => 'top', -fill => 'x');     
   $f_1->Label(-text => 'Special Major Ticks (.4 21 5000)',
               -font => $font)
       ->pack(-side => 'left');
   $f_1->Entry(-textvariable => $major_ref,
               -font         => $font,
               -background   => 'white'  )
       ->pack(-side => 'left', -fill => 'x', -expand => 1);
   my $f_2 = $frame->Frame()
                   ->pack(-side => 'top', -fill => 'x'); 
   $f_2->Label(-text => 'Special Minor Ticks (.4 21 5000)',
               -font => $font)
       ->pack(-side => 'left');     
   $f_2->Entry(-textvariable => $minor_ref,
               -font         => $font,
               -background   => 'white' )
       ->pack(-side => 'left', -fill => 'x', -expand => 1);
}

########################################################################
# TIME STUFF
########################################################################

###############################################
# TIME EDITOR
###############################################
sub _timeeditor1 {
   my ($self, $canv, $pe, $xoy) = (shift, shift, shift, shift);
   
   # When this subroutine is invoked, the user has more than
   # likely actually changed the axis type.  Thus, it because
   # necessary to delete all of the parse data cache
   my $dataclass = $self->{-dataclass};
   foreach my $dataset (@{$dataclass}) {
      map { delete( $_->{-parseData} ) } @{$dataset->{-DATA}};
   }
   
   my $aref = $self->{$xoy};
   my $tref = $aref->{-time};
   
   my $begin = {};
   my $end   = {};
   
   GET_DATE_TIME: {
      
      # As far as WHA knows, the only way for -max to be undefined is
      # when the user has toggled to time axis from another without tkg2
      # seeing any data at first.  In these circumstances, we'll use the
      # current water year as minimum and maximum limits (see -max below).
      if(not $tref->{-min}) {
         my ($yyyy, $mm, $dd, $hh, $min, $ss) =
                            &BEGINNING_OF_WATERYEAR_as_parsed_String(); 
         $tref->{-min} = "$yyyy$mm$dd$hh:$min:$ss"; # show as beginning of wateryear
      }
      
      ($begin->{-date}, $begin->{-time}) =
                            &String_2_TwoFields($tref->{-min});
                            
      if(not $tref->{-max}) {  # see comments above about -min
         my ($yyyy, $mm, $dd, $hh, $min, $ss) =
                            &ENDING_OF_WATERYEAR_as_parsed_String(); 
         $tref->{-max} = "$yyyy$mm$dd$hh:$min:$ss"; # show as ending of wateryear
      }
      
      ($end->{-date}, $end->{-time}) =
                            &String_2_TwoFields($tref->{-max});
   }
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   my $f_1 = $pe->Frame->pack(-fill => 'x');
   my @p = (-side => 'left', -fill => 'x');

   my $f_min = $f_1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_min->Label(-text => "Beginning Date (yyyy/mm/dd and hh:mm:ss)",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w');
   $f_min->Entry(-textvariable => \$begin->{-date},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
        ->pack(-side => 'left', -fill => 'x');
   $f_min->Entry(-textvariable => \$begin->{-time},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
        ->pack(-side => 'left', -fill => 'x');
        
   my $f_max = $f_1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_max->Label(-text => "   Ending Date (yyyy/mm/dd and hh:mm:ss)",
                 -font => $fontb)
         ->pack(-side => 'left', -anchor => 'w'); 
   $f_max->Entry(-textvariable => \$end->{-date},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
         ->pack(-side => 'left', -fill => 'x');    
   $f_max->Entry(-textvariable => \$end->{-time},
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
         ->pack(-side => 'left', -fill => 'x');    

   
   my $f_showyr = $f_1->Frame->pack(-side => 'top', -fill => 'x');
   $f_showyr->Checkbutton(-text     => 'Show year',
                          -font     => $fontb,
                          -onvalue  => 1,
                          -offvalue => 0,
                          -variable => \$tref->{-showyear} )
            ->pack(@p);     
   
   # New widget for version 0.40, this test is for backwards compatability
   $tref->{-show_day_as_additional_string} = 0
       unless($tref->{-show_day_as_additional_string});
   my $f_dow = $f_1->Frame->pack(-side => 'top', -fill => 'x');
   $f_dow->Checkbutton(-text     => 'Show day of week     ',
                       -font     => $fontb,
                       -onvalue  => 1,
                       -offvalue => 0,
                       -variable => \$tref->{-show_day_as_additional_string} )
            ->pack(@p);
   # New widget for version 0.40, this test is for backwards compatability
   $tref->{-show_day_of_year_instead} = 0
       unless($tref->{-show_day_of_year_instead});
   my $f_doy = $f_dow->Frame->pack(-side => 'top', -fill => 'x');
   $f_doy->Checkbutton(-text     => 'Show day of year instead of date',
                       -font     => $fontb,
                       -onvalue  => 1,
                       -offvalue => 0,
                       -variable => \$tref->{-show_day_of_year_instead} )
            ->pack(@p);   
   # New widget for version 0.61, this test is for backwards compatability
   $tref->{-compact_months_in_publication_style} = 0
      unless($tref->{-compact_months_in_publication_style});
   my $f_pubs = $f_1->Frame->pack(-side => 'top', -fill => 'x');
   $f_pubs->Checkbutton(-text    => 'Abbreviated months in pub. style '.
                                    '(periods, June, July, Sept.)',
                       -font     => $fontb,
                       -onvalue  => 1,
                       -offvalue => 0,
                       -variable => \$tref->{-compact_months_in_publication_style} )
            ->pack(@p);   
            
   # New widget for version 0.52, this test is for backwards compatability
   $tref->{-labeldensity} = 1 unless($tref->{-labeldensity});
   $tref->{-labeldepth}   = 1 unless($tref->{-labeldepth});
   $tref->{-labellevel1}  = 1 if(not defined $tref->{-labellevel1});
   my $f_den = $f_1->Frame->pack(-side => 'top', -fill => 'x');
   $f_den->Scale(-label        => 'Label Depth',
                 -font         => $fontb,
                 -from         => 1,
                 -to           => 3,
                 -resolution   => 1,
                 -showvalue    => 0,
                 -variable     => \$tref->{-labeldepth},
                 -orient       => 'horizontal',
                 -tickinterval => 1, )
         ->pack(-side => 'left');  
   $f_den->Scale(-label        => 'Label Density',
                 -font         => $fontb,
                 -from         => 1,
                 -to           => 3,
                 -resolution   => 1,
                 -showvalue    => 0,
                 -variable     => \$tref->{-labeldensity},
                 -orient       => 'horizontal',
                 -tickinterval => 1, )
         ->pack(-side => 'left');
   $f_den->Checkbutton(-text     => 'Label Level 1',
                       -font     => $fontb,
                       -onvalue  => 1,
                       -offvalue => 0,
                       -variable => \$tref->{-labellevel1} )
         ->pack(-side => 'left');            

   &_timeCalculators($f_1,$aref);
   
   return ($f_1, $begin, $end);
}


sub _timeCalculators {
   my ($f,$aref) = @_;
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   
   # The following widgets display the internal date/time representation.
   # They are here ONLY for reference to the super advanced user.
   # The dialog box can be used as a date/time calculator--albeit
   #  a little cumbersome, but there this is likely only useful to 
   #  someone debugging something.
   my $f_1 = $f->Frame->pack(-side => 'top', -fill => 'x');   
      $f_1->Label(-text => "Computed date-time representations ".
                           "(hit Apply to verify update)",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w'); 
   my $f_2 = $f->Frame->pack(-side => 'top', -fill => 'x');   
      $f_2->Label(-text => " Minimum",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w'); 
      $f_2->Entry(-textvariable => \$aref->{-min},
                  -font         => $font,
                  -relief       => 'raised',
                  -state        => 'disabled',
                  -width        => 16,
                  -borderwidth  => 1  )
          ->pack(-side => 'left', -fill => 'x');
      $f_2->Label(-text => "(days since January 1, 1900)",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w');         
   my $f_3 = $f->Frame->pack(-side => 'top', -fill => 'x');   
      $f_3->Label(-text => " Maximum",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w'); 
      $f_3->Entry(-textvariable => \$aref->{-max},
                  -font         => $font,
                  -width        => 16,
                  -relief       => 'raised',
                  -state        => 'disabled',
                  -borderwidth  => 1)
          ->pack(-side => 'left', -fill => 'x');    
      $f_3->Label(-text => "(days since January 1, 1900)",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w');

   my $isleapyear = 'Press';
   my $whatyear   = '2000';
   my $f_4 = $f->Frame->pack(-side => 'top', -fill => 'x');   
      $f_4->Label(-text => "Handy Date Calculator Tools:",
                  -font => $font)
          ->pack(-side => 'top', -anchor => 'w'); 
      $f_4->Label(-text => " Is year",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w'); 
      $f_4->Entry(-textvariable => \$whatyear,
                  -font         => $font,
                  -width        => 6,
                  -borderwidth  => 1)
          ->pack(-side => 'left', -fill => 'x');  
      $f_4->Label(-text => "a leap year?",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w');
      $f_4->Button(-textvariable => \$isleapyear,
                   -font         => $font,
                   -width        => 5,
                   -relief       => 'raised',
                   -command => sub {
                       $isleapyear = ($whatyear =~ m/^\d{4}$/o) ?
                                &isLeapYear($whatyear) : 'badyr'} )
          ->pack(-side => 'left', -fill => 'x');
   
   my $doy      = 'Press';
   my $whatdate = '10/04/1969';
   my $f_5 = $f->Frame->pack(-side => 'top', -fill => 'x');   
      $f_5->Label(-text => " This day",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w'); 
      $f_5->Entry(-textvariable => \$whatdate,
                  -font         => $font,
                  -width        => 12,
                  -borderwidth  => 1)
          ->pack(-side => 'left', -fill => 'x');  
      $f_5->Label(-text => "is the",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w');
      $f_5->Button(-textvariable => \$doy,
                   -font         => $font,
                   -width        => 7,
                  -relief       => 'raised',
                  -command => sub {
                      $doy = ($whatdate =~ m/(\d\d)\/(\d\d)\/(\d{4})/) ?
                        &whatDayOfYear($3,$1,$2) : 'baddate'; } )
          ->pack(-side => 'left', -fill => 'x');
      $f_5->Label(-text => "day of the year.",
                  -font => $font)
          ->pack(-side => 'left', -anchor => 'w');
}



sub _timeAsk_if_DateFieldsEmpty {
   my ($aref, $b, $e) = @_;    # axis ref, date/time beginning, date/time ending
   my $tref = $aref->{-time};  # reference to the time hash
   
   # Remove leading and trailing space
   $b->{-date} = &strip_space( $b->{-date} );
   $b->{-time} = &strip_space( $b->{-time} );
   $e->{-date} = &strip_space( $e->{-date} );
   $e->{-time} = &strip_space( $e->{-time} );
   
   # Substitutions, which are not wanted if a word character is present
   # otherwise we have issues with getting the shortcuts to work
   # insure? foreward slash in place
   $b->{-date} =~ s%[.\-\s]%/%go if($b->{-date} !~ m|\w|o);
   $e->{-date} =~ s%[.\-\s]%/%go if($e->{-date} !~ m|\w|o);
   
   # insure? colons in place
   $b->{-time} =~ s%[.\-\s/]%:%go if($b->{-time} !~ m|\w|o);
   $e->{-time} =~ s%[.\-\s/]%:%go if($e->{-time} !~ m|\w|o);
   
   # TEST FOR EMPTY DATE FIELDS
   # If the fields are empty, try to default back to the minimum or maximum
   # data, set the axis minimum, code this minimum to time and set it in
   # the time references, and finally, set the microhashes that are used
   # in the dialog boxes.  If the data min or max are not known, these
   # settings are bipassed--_timeShortCuts will end up setting
   # the fields if they are still empty
   my $min = $aref->{-datamin}->{-whenlinear};
   # Try to use the data minimum and maximums
   if(not $b->{-date} and defined $min) {
      $aref->{-min} = $min;
                      $min =    &RecodeTkg2DateandTime($min);
      $tref->{-min} = $min;
      ($b->{-date}, $b->{-time}) = &String_2_TwoFields($min);
   }
   my $max = $aref->{-datamax}->{-whenlinear};
   if(not $e->{-date} and defined $max) {
      $aref->{-max} = $max;
                      $max =    &RecodeTkg2DateandTime($max);
      $tref->{-max} = $max;
      ($e->{-date}, $e->{-time}) = &String_2_TwoFields($max);             
   }
   return ($b, $e);
}    


sub _timeShortCuts {
   my ($b, $e) = @_;

   $b = &_timeShortCuts_beginning($b);
   $e = &_timeShortCuts_ending($e);
   
   return ($b, $e);
}


sub _timeShortCuts_beginning {
   my ($b) = @_;
   
   my ($b1, $b2) = ($b->{-date}, $b->{-time}); # initialize
   
   # Provide the user the ability to be lazy and if only
   # a four digit year was entered, then at Dec 31
   $b1 = "$1/01/01" if($b1 =~ m/^(\d{4})$/o);
   
   # Provide the user with another lazy feature, add the 
   # ending of the month if it was left off
   $b1 = "$1/$2/01" if($b1 =~ m/^(\d{4})[\/.](\d{1,2})$/o);

   
   # EMPTY DATE FIELDS  Minimum, use the last of this year
   if(not $b1) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/01/01", "00:00:00");
   }
   # BEGINNING OF WATER YEAR plus or minus a day offset
   elsif($b1 =~ /^wyr?([-+]?\d*)/o or $b2 =~ /^wyr?([+-]?\d*)/o) {
      print "B: $b1 and $b2 provide $1\n";
      my ($yyyy, $mm, $dd, $hh, $min, $ss) =
                                &BEGINNING_OF_WATERYEAR_as_parsed_String($1);
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # RIGHT 'NOW'     
   elsif($b1 =~ /^now/o   or $b2 =~ /now/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # THEN or YR-
   # one year ago from now (see just above) or typing yr- will do
   elsif($b1 =~ /^(then|yr\-)/io   or $b2 =~ /then|yr\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      $yyyy--;
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # YR+ one year from now
   elsif($b1 =~ /^yr\+/o or $b2 =~ /yr\+/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      $yyyy++;
      ( $b1, $b2 )  = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # YESTERDAY  one day ago from now
   elsif($b1 =~ /^yes/o or $b2 =~ /yes/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &YESTERDAY_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # TOMORROW   one day ago from now
   elsif($b1 =~ /^tom/io or $b2 =~ /tom/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &TOMORROW_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # WK+ one week from now
   elsif($b1 =~ /^wk\+/io or $b2 =~ /wk\+/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &WEEKPLUS_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # WK- one week backwards from now
   elsif($b1 =~ /^wk\-/io or $b2 =~ /wk\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &WEEKMINUS_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # MN+  one week from now
   elsif($b1 =~ /^mn\+/io or $b2 =~ /mn\+/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &MONTHPLUS_as_parsed_String(); 
      ( $b1, $b2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # MN- one month backwards from now
   elsif($b1 =~ /^mn\-/io or $b2 =~ /mn\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &MONTHMINUS_as_parsed_String(); 
      ( $b1, $b2 ) = ( "$yyyy/$mm/$dd","$hh:$min:$ss");
   }
   else {
      # do nothing, continue checking.
   }

   $b->{-date} = &_clean_date_field($b1);
   $b->{-time} = &_short_cuts_on_time_component_only($b2);

   return $b;
}

sub _timeShortCuts_ending {
   my ($e) = @_;

   my ($e1, $e2) = ($e->{-date}, $e->{-time}); # initialize
   
   # Provide the user the ability to be lazy and if only
   # a four digit year was entered, then at Dec 31
   $e1 = "$1/12/31" if($e1 =~ m/^(\d{4})$/o);
   
   # Provide the user with another lazy feature, add the 
   # ending of the month if it was left off
   $e1 = "$1/$2/".&Days_in_Month($1,$2)
                        if($e1 =~ m/^(\d{4})[\/.](\d{1,2})$/o);
   
   # EMPTY DATE FIELDS  Maximum, use the last of this year
   if(not $e1) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/12/31", "00:00:00");
   }
   # ENDING OF WATER YEAR plus or minus a day offset
   elsif($e1 =~ /^wyr?([-+0-9]*)/o or $e2 =~ /^wyr?([-+0-9]*)/o) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) =
                                &ENDING_OF_WATERYEAR_as_parsed_String($1);
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # RIGHT 'NOW'     
   elsif($e1 =~ /^now/o   or $e2 =~ /now/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # THEN or YR-
   # one year ago from now (see just above) or typing yr- will do
   elsif($e1 =~ /^(then|yr\-)/io   or $e2 =~ /then|yr\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      $yyyy--;
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # YR+ one year from now
   elsif($e1 =~ /^yr\+/o or $e2 =~ /yr\+/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String(); 
      $yyyy++;
      ( $e1, $e2 )  = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # YESTERDAY  one day ago from now
   elsif($e1 =~ /^yes/o or $e2 =~ /yes/o ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &YESTERDAY_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # TOMORROW   one day ago from now
   elsif($e1 =~ /^tom/io or $e2 =~ /tom/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &TOMORROW_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # WK+ one week from now
   elsif($e1 =~ /^wk\+/io or $e2 =~ /wk\+/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &WEEKPLUS_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # WK- one week backwards from now
   elsif($e1 =~ /^wk\-/io or $e2 =~ /wk\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &WEEKMINUS_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # MN+  one week from now
   elsif($e1 =~ /^mn\+/io or $e2 =~ /mn\+/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &MONTHPLUS_as_parsed_String(); 
      ( $e1, $e2 ) = ("$yyyy/$mm/$dd", "$hh:$min:$ss");
   }
   # MN- one month backwards from now
   elsif($e1 =~ /^mn\-/io or $e2 =~ /mn\-/io ) {
      my ($yyyy, $mm, $dd, $hh, $min, $ss) = &MONTHMINUS_as_parsed_String(); 
      ( $e1, $e2 ) = ( "$yyyy/$mm/$dd","$hh:$min:$ss");
   }
   else {
      # do nothing, continue checking.
   }
   
   $e->{-date} = &_clean_date_field($e1);
   $e->{-time} = &_short_cuts_on_time_component_only($e2);
   
   return $e;
}

sub _clean_date_field {
   $_ = $_[0];  # a date component of a date/time field (yyyy:mm::dd)
   s/\/$//o;    # strip any trailing forward slashes 
   
   my ($y, $m, $d) = split(/\//o, $_, -1);
   # we won't touch the year to force user to enter four digits
   if($y !~ /\d{4}/o) {
      $y = "2000";
      my $text = "You have entered a non four digit year in the date field.\n".
                 "Tkg2 as a matter of strict policy does not want to assume ".
                 "anything about your intent.  However, to keep errors trapped, ".
                 "we are defaulting to $y since it is a nice round number.\n".
                 "Guess we just lied?";
      &Message($::MW,'-generic', "$text");
   }
   $m = "01" if(not defined $m);  # error trapping just in case
   $d = "01" if(not defined $d);  # really stupid value are entered
   $m = sprintf("%2.2d", $m);
   $d = sprintf("%2.2d", $d);
   return "$y/$m/$d";
}

sub _short_cuts_on_time_component_only {
   $_ = $_[0];  # a time component of a date/time field (hh:mm::ss.ffff)
   s/:$//o; # strip any trailing colons 
   
   # Short cuts on the time portion, if null, 0, or whitespace
   # set to 00:00:00 beginning of day.
   return "00:00:00" if(not $_ or m/^\s+$/o); # 0hrs if null, 0, whitespace
   return "12:00:00" if(m/^n/io);      # noon if 'noon' or just 'n'
   return "15:00:00" if(m/^t/io);      # 3pm if 'tea' or just 't'
   return "18:00:00" if(m/^(d|s)/io);  # 6pm if 'dinner','supper' or 'd' or 's'  
   return "22:00:00" if(m/^b/io);      # 10pm if 'bedtime' or just 'b'
   
   my ($h, $m, $s) = split(/:/o, $_, -1);
   $h = ($h) ? sprintf("%2.2d", $h) : "00";
   $m = ($m) ? sprintf("%2.2d", $m) : "00";
   $s = (not $s) ? "00" :
        (int($s) eq $s) ? sprintf("%2.2d", $s) : "$s";
         # all this to preserve fractional seconds
   return "$h:$m:$s"
}

1;
