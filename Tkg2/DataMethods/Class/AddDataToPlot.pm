package Tkg2::DataMethods::Class::AddDataToPlot;

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
# $Date: 2005/05/14 03:27:58 $
# $Revision: 1.72 $

use strict;
use Tkg2::Base qw(centerWidget relative_path Message strip_space
                  Show_Me_Internals isNumber Message arrayhasNumbers);
use Tkg2::Help::Help;

use Exporter;
use SelfLoader;

use Tk::NoteBook;

use Tkg2::DataMethods::Class::DataViewer qw(DataViewer);

use Tkg2::DataMethods::Class::RouteData2Script qw(RouteData2Script);

use Date::Manip 5.39;
use Date::Calc qw(Delta_Days);
use constant S24 => scalar 24;
use constant S60 => scalar 60; 

use File::Basename;
use Cwd;


use vars qw(@ISA @EXPORT_OK $EDITOR
           $LAST_PAGE_VIEWED $LAST_PARA $LAST_PLOTPARA $LASTOPENDIR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(AddDataToPlot);

print $::SPLASH "=";

1;

$LASTOPENDIR = "";
$LAST_PAGE_VIEWED = 'page1';
$EDITOR = "";
$LAST_PARA = { -fileisRDB       => 0,
               -dataimported    => 0,
               -numskiplines    => 0,
               -numlabellines   => 1,
               -numskiplines_afterlabel => 0,
               -numlinestoread  => "",
               -megacommand     => 0,
               -common_datetime => "",
               -datetime_offset => 0,
               -userelativepath => 1,
               -missingval      => '',
               -filedelimiter   => '\s+',
               -skiplineonmatch => '^#',
               -invertskipline  => 0,
               -sortdoit        => 0,
               -sorttype        => 'numeric',
               -sortdir         => 'ascend',
               -columntypes     => "auto",
               -ordinates_as1_column => 0,
               -thresholds      => 0,
               -transform_data  => { -doit   => 0,
                                     -script => "",
                                     -command_line_args => "" } };
$LAST_PLOTPARA = { -plotstyle    => 'Scatter', 
                   -which_y_axis => 1,
                 };

__DATA__

sub AddDataToPlot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $plot, $template, $donot_delete_dialogs) = @_;
   my $pw = $canv->parent;
   unless($donot_delete_dialogs) {
      $EDITOR->destroy if( Tk::Exists($EDITOR) );
      $donot_delete_dialogs = "";
   }
   my $title = "Add Data File to Plot: $donot_delete_dialogs";
   my $pe = $pw->Toplevel( -title => $title);
   $EDITOR = $pe;
   $pe->resizable(0,0);
   &centerWidget($pe);
 
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};   
   my @font  = (-font => $font);
   my @fontb = (-font => $fontb);
   
   my %para = %$LAST_PARA;
 
   my %plotpara          = %$LAST_PLOTPARA;
   $plotpara{-which_y_axis} = 1; # do not remember that the last data was
   
   my $plotstyle         = $plotpara{-plotstyle};  
   my $_plotpara1        = sub { $plotstyle            = shift;
                                 $plotpara{-plotstyle} = $plotstyle; };


   my $_plotpara1_discrete = sub { $plotstyle = shift;
                                   $plotpara{-plotstyle} = $plotstyle;
                                   my $xref = $plot->{-x};
                                   my $yref = $plot->{-y};
                                   if($plotstyle eq 'X-Discrete') {
                                      $xref->{-discrete}->{-doit} = 'stack';
                                      $xref->{-type} = 'linear';
                                   }
                                   elsif($plotstyle eq 'Y-Discrete') {
                                      $yref->{-discrete}->{-doit} = 'stack';
                                      $yref->{-type} = 'linear';
                                   } 
                                   else {
                                      $xref->{-discrete}->{-doit} = 'stack';
                                      $yref->{-discrete}->{-doit} = 'stack';
                                      $xref->{-type} = 'linear';
                                      $yref->{-type} = 'linear';
                                   } };

   my $_plotpara1_box = sub { $plotstyle = shift;
                              # Diabling Box plot capability for the user
                              $plotpara{-plotstyle} = $plotstyle;
                              # $plotpara{-plotstyle} = 'Scatter';
                            }; 

   $para{-megacommand} = 0; # the default megacommand is off
   
   # Modify the axis location pair according to that in the plot
   # this prevents the plot from having to deal with tkg2 changing
   # their settings.
   my $axis = ucfirst($plot->{-x}->{-location}).
                            " and ".
              ucfirst($plot->{-y}->{-location});
   my @axes = ( [ 'command' => 'Bottom and Left', @font,
                  -command  => sub { $axis = 'Bottom and Left'; } ],
                [ 'command' => 'Top and Left   ', @font,
                  -command  => sub { $axis = 'Top and Left'; } ],
                [ 'command' => 'Bottom and Right', @font,
                  -command  => sub { $axis = 'Bottom and Right'; } ],
                [ 'command' => 'Top and Right   ', @font,
                  -command  => sub { $axis = 'Top and Right'; } ] );

   my @plotstyle = ();
   foreach ( 'Scatter'         ,
             'X-Y Line'        ,
             'Text'            ,
             'Y-Accumulation'  ,
             'Y-Accumulation(text)',
             'X-Probability'   ,
             'Y-Probability'   ,
             'Bar'             ,
             'Shade'           ,
             'Shade Between'   ,
             'Shade Between Accumulation',
             'Y-Error Bar'     ,
             'Y-Error Limits'  ,
             'X-Y Error Bar'   ,
             'X-Y Error Limits', ) {
      push(@plotstyle, [ 'command' => "$_", @font,
                         -command  => [ $_plotpara1, $_] ]);  
   } 
   
   push(@plotstyle, "-");
   foreach ( 'X-Discrete'  ,
             'Y-Discrete'  ,
             'XY-Discrete' ) {
      push(@plotstyle, [ 'command' => "$_", @font,
                         -command  => [ $_plotpara1_discrete, $_] ]);
   }
   
   push(@plotstyle, "-");
   foreach ( 'Vertical Box'     ,
             'Horizontal Box'   ,                     
             'VertBox by Group' ,
             'HorzBox by Group' ) {
      push(@plotstyle, [ 'command' => "$_", @font,
                         -command  => [ $_plotpara1_box, $_] ] );
   }
      
   my $sorttype = $para{-sorttype};
   my $_sorttype = sub { $sorttype = shift;
                         $para{-sorttype} = $sorttype; };        
   my @sorttype = ();
   foreach ( qw(numeric alphabetic) ) {
      push(@sorttype,
           [ 'command' => $_, @font,
             -command  => [ $_sorttype, $_] ]);
   }
            
   my $delimiter = $para{-filedelimiter};         
   my $_delimiter = sub { $delimiter = shift;
                          $para{-filedelimiter} = $delimiter; };
   my @delimiters = ();    
   my $customdelimiter = undef;
   foreach (@{$::TKG2_CONFIG{-DELIMITERS}}) {
      push(@delimiters,
           [ 'command' => $_, @font,
             -command  => [ \&$_delimiter, $_ ] ] );
   }              
              
              

              
                  
   my $nb = $pe->NoteBook(-dynamicgeometry => 1, @fontb)->pack;
   my $page1 = $nb->add( 'page1', -label => 'Basic'    );
   my $page2 = $nb->add( 'page2', -label => 'Advanced' );
   my $page3 = $nb->add( 'page3', -label => 'Date-Time');
   
   my $f_a = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_a->Label(-text => 'Position Axes', @fontb)
       ->pack(-side => 'left');
   $f_a->Menubutton(-textvariable => \$axis,
                    -indicator => 1,
                    -tearoff   => 0,
                    -anchor    => 'w',
                    -relief    => 'ridge',
                    -menuitems => [ @axes ], @fontb,
                    -width     => 16 )
         ->pack(-side => 'left'); 
   my $f_p = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_p->Label(-text => '  Plot Type  ', @fontb)
       ->pack(-side => 'left');
   $f_p->Menubutton(-textvariable => \$plotstyle,
                    -indicator    => 1,
                    -tearoff      => 0,
                    -anchor       => 'w',
                    -relief       => 'ridge',
                    -menuitems    => [ @plotstyle ],
                    -width        => 25, @fontb)
       ->pack(-side => 'left'); 
   my $f_p2 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_p2->Checkbutton(
        -text     => 'Data for second y axis?',
        -variable => \$plotpara{-which_y_axis},
        -onvalue  => 2,
        -offvalue => 1, @fontb,
        -command  => sub { my $yref = $plot->{-y};
                           my $linmin = $yref->{-datamin}->{-whenlinear};
                           my $linmax = $yref->{-datamax}->{-whenlinear};
                           if( $plotpara{-which_y_axis} == 2
                                        and
                               (    not defined $linmin
                                 or not defined $linmax ) ) {
                              my $mess = "Warning.  You are about to load ".
                                         "data for the second y axis BEFORE ".
                                         "data has been loaded to the first ".
                                         "y axis.  This is not good practice ".
                                         "and potentially confusing to the ".
                                         "program.  Resetting to first y axis.";
                              &Message($pe,'-generic',$mess);
                              $plotpara{-which_y_axis} = 1;
                           } 
        } )
        ->pack(-side => 'left');             
   my $f_1 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_1->Label(-text => " Num. of Lines to Skip before Labels", @fontb)
       ->pack(-side => 'left', -anchor => 'w');

   # number of lines to skip ABOVE the labels lines
   my $num_skip_e = $f_1->Entry(-textvariable => \$para{-numskiplines},
                                -background   => 'white',
                                -width        => 10, @fontb )
        ->pack(-side => 'left', -fill => 'x');
   
   my $f_4 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_4->Label(-text => "               Number of Label Lines", @fontb)
       ->pack(-side => 'left', -anchor => 'w');
   my $num_label_e = $f_4->Entry(-textvariable => \$para{-numlabellines},
                                 -background   => 'white',
                                 -width        => 10, @fontb)
                         ->pack(-side => 'left', -fill => 'x');
                         
   my $f_11 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_11->Label(-text => "     Num. Lines to Skip after Labels", @fontb)
       ->pack(-side => 'left', -anchor => 'w');
   my $num_skip_after_label =
          $f_11->Entry(-textvariable => \$para{-numskiplines_afterlabel},
                       -background   => 'white',
                       -width        => 10, @fontb )
               ->pack(-side => 'left', -fill => 'x');

   my $f_12 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_12->Label(-text => "             Number of Lines to Read", @fontb)
        ->pack( -side => 'left', -anchor => 'w');
   my $num_read_e = $f_12->Entry(-textvariable => \$para{-numlinestoread},
                                 -background   => 'white',
                                 -width        => 10, @font )
        ->pack(-side => 'left', -fill => 'x');
   
   my $f_2 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_2->Label(-text => "Missing Value Identifier", @fontb)
       ->pack(-side => 'left', -anchor => 'w');        
 
   $f_2->Entry(-textvariable => \$para{-missingval}, @font,
               -background   => 'white',
               -width        => 12)
       ->pack(-side => 'left', -fill => 'x');  

   my $f_31 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_31->Label(-text => "          File Delimiter", @fontb)
        ->pack(-side => 'left', -anchor => 'w');
   my $delim_mb = $f_31->Menubutton(
                       -textvariable => \$delimiter,
                       -indicator => 1,
                       -tearoff   => 0,
                       -relief    => 'ridge',
                       -menuitems => [ @delimiters ],
                       -width     => 9, @fontb)
                       ->pack(-side => 'left'); 
 
   my $f_32 = $page1->Frame->pack(-side => 'top', -fill => 'x');        
   $f_32->Label(-text => "   Custom File Delimiter", @fontb)
        ->pack(-side => 'left', -anchor => 'w');
   my $cust_e = $f_32->Entry(-textvariable => \$customdelimiter,
                             -background   => 'white',
                             -width        => 12, @font)
                     ->pack(-side => 'left', -fill => 'x'); 
                
   my $f_5 = $page1->Frame->pack(-side => 'top', -fill => 'x');                
   $f_5->Label(-text => "    Skip Line Identifier", @fontb)
       ->pack(-side => 'left', -anchor => 'w'); 
   my $skip_e = $f_5->Entry(-textvariable => \$para{-skiplineonmatch},
                            -background   => 'white',
                            -width        => 12, @font )
                    ->pack(-side => 'left', -fill => 'x');
   $f_5->Checkbutton(-text     => 'invert it',
                     -variable => \$para{-invertskipline},
                     -onvalue  => 1,
                     -offvalue => 0, @fontb)
       ->pack(-side => 'left');          
                     
   my $f_6 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_6->Label(-text => " Column types (a|DSNT|f)", @fontb)
       ->pack(-side => 'left', -anchor => 'w');
   my $coltype_e = $f_6->Entry(-textvariable => \$para{-columntypes},
                               -background   => 'white',
                               -width        => 12, @font)
                       ->pack(-side => 'left', -fill => 'x');    

   my $isRDBdelWidgets =
         sub {
            my $isRDB = shift;
            my @wg2chg = ($num_skip_e,  $cust_e,
                          $num_label_e, $skip_e, $coltype_e,
                          $num_skip_after_label, $num_read_e );
            # We need to disable and change the appearance
            # of options that are really not available for
            # true RDB file.  The actually settings for RDB
            # are forced in the &$finishsub called with the
            # OK button.  See how a call back is cleanly
            # used to control that state of multiple widgets
            # in the window.
            if($isRDB) {
               $delimiter = '\t'; # will change the menu
               my @opts = qw(-bg grey75 -state disabled);
               map { $_->configure(@opts) } @wg2chg;
               $delim_mb->configure(-state => 'disabled');
            }
            else {
               my @opts = qw(-bg white -state normal);
               # Only change the delimit to one or more space
               # if it is a tab.  This way the 'memory' of
               # LAST_PARA remains functional.
               $delimiter = '\s+' if($delimiter eq "\t");
               map { $_->configure(@opts) } @wg2chg;
               $delim_mb->configure(-state => 'normal');
            }
          };           
   # now run the RDB widget reconfiguration to express the 
   # current value of -fileisRDB so that if the last time the
   # dialog box was handled and RDB file was choosen, then the
   # next dialog box will show this.
   &$isRDBdelWidgets($para{-fileisRDB});
    
   my $f_r2 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_r2->Checkbutton(
        -text     => 'File is RDB (quasi compliant, d|D for dates)', @fontb,
        -variable => \$para{-fileisRDB},
        -onvalue  => 1,
        -offvalue => 0,
        -command  => sub { &$isRDBdelWidgets($para{-fileisRDB});
                           $para{-delimiter}       = "\t";
                           $para{-skiplineonmatch} = "^#";
                         } )
        ->pack(-side => 'left');
   my $f_r22 = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_r22->Checkbutton(-text     => 'Import data (no dynamic loading)',
                      -variable => \$para{-dataimported},
                      -onvalue  => 1,
                      -offvalue => 0, @fontb)
        ->pack(-side => 'left');
   
   ### All of the following so that we can bypass the mandatory
   # autoconfiguration of the axis when the first data is loaded
   # into the plot.  We don't deal with the second y axis here.
   # The mandatory call is not applied for the second y axis because
   # there is no way prior to loading of data that the user could
   # have tweaked the second y axis limits, settings etc.
   # If the button is pressed then the default autoconfiguration settings
   # are turned off.  The user will have to manually turn them back on
   # in the PlotEditor or the AxisEditor.  The button is not shown
   # if data has already been loaded.
   if(scalar(@$self) == 0) {
      my $f_r3 = $page1->Frame->pack(-side => 'top', -fill => 'x');   
      $f_r3->Checkbutton(-text     => 'Skip handy x-y axis config. on 1st data loaded.',
                         -variable => \$plot->{-skip_axis_config_on_1st_data},
                         -onvalue  => 1,
                         -offvalue => 0, @fontb,
                         -command  =>
                         sub { my ($xref, $yref) = ($plot->{-x}, $plot->{-y});
                               if($plot->{-skip_axis_config_on_1st_data}) {
                                  # turn off the settings
                                  $xref->{ -autominlimit} =
                                  $xref->{ -automaxlimit} = 0;
                                  $yref->{ -autominlimit} =
                                  $yref->{ -automaxlimit} = 0;
                               }
                               else {
                                  # restore the default settings
                                  $xref->{ -autominlimit} = 1;
                                  $xref->{ -automaxlimit} = 1;
                                  $yref->{ -autominlimit} = 1;
                                  $yref->{ -automaxlimit} = 1;
                               }
                              } )
        ->pack(-side => 'left');        
   }
   ### end of the configuration bypass
   
   
   my $f_rel = $page1->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_rel->Checkbutton(-text     => "Use relative path for file name",
                       -variable => \$para{-userelativepath},
                       -onvalue  => 1,
                       -offvalue => 0, @fontb)
         ->pack(-side => 'left');             
   
   my $f_op = $page1->Frame->pack(-side => 'top', -fill => 'x');
   $f_op->Checkbutton(-text     => 'Do not verify/test field types (fast reading)',
                      -variable => \$::CMDLINEOPTS{'nofieldcheck'},
                      -onvalue  => 1,
                      -offvalue => 0, @fontb)
        ->pack(-side => 'left');       
   
   

   my $f_tra = $page2->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_tra->Checkbutton(-text     => "Convert ordinates (Y's) to a single column",
                       -variable => \$para{-ordinates_as1_column},
                       -onvalue  => 1,
                       -offvalue => 0, @fontb,
                       -command => sub {
                        my $mess = "This will move each ordinate into a single ".
                                   "column and duplicate the abscissa to retain ".
                                   "a fully defined retangular matrix.\n".
                                   "Is this really what you want?";
                        &Message($pe,'-generic',$mess)
                                     } )->pack(-side => 'left');
                                     
                                     
   my $f_thr = $page2->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_thr->Label(-text   => "Thresholds", @fontb,
                 -anchor => 'w')
         ->pack(-side => 'left');
   $f_thr->Radiobutton(-text     => "Ignore",
                       -variable => \$para{-thresholds},
                       -value    => 'ignore', @fontb)
         ->pack(-side => 'left');
   $f_thr->Radiobutton(-text     => "Substit",
                       -variable => \$para{-thresholds},
                       -value    => 'substitute', @fontb)
         ->pack(-side => 'left');
   $f_thr->Radiobutton(-text     => "Make missing",
                       -variable => \$para{-thresholds},
                       -value    => 'make missing', @fontb)
         ->pack(-side => 'left');                                  
                                          
                                          
   # Route data 2 script actually provides the GUI to interface and
   # edit the -transform_data hash.  The astute reader of this
   # module with see that the three sub keys in the -transform_data
   # hash are not altered.  RouteData2Script is a phenominally powerful
   # feature because it provides a means to dump parts of Perl's memory
   # to disk and then perform adjustments and place that back into
   # memory.  Really cool for providing all sorts of advanced 
   # preprocessing that otherwise is too arcane for direct implementation
   # into Tkg2.
   my $f_ctra = $page2->Frame->pack(-side => 'top', -fill => 'x'); 
   $f_ctra->Label(-text => "")->pack;
   $f_ctra->Button(-text    => "Route data through external program",
                   -command => [\&RouteData2Script, $pe, \%para ],
                   @fontb)
          ->pack(-side => 'left');
   
   my $t_megacommand;
   my $f_mega = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_mega->Label(-text => "\nUse a 'megacommand' in lieu of a file\n".
                           "(0 or null for none).", @fontb,
                  -justify => 'left',
                  -anchor  => 'w')
          ->pack(-side => 'top', -fill => 'x');
   $f_mega->Entry(-textvariable => \$para{-megacommand},
                  -width        => 40,
                  -background   => 'white', @fontb)
          ->pack(-side => 'top', -fill => 'x'); 
   
   
          
   my $f_s1 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_s1->Label(-text => 'Sort the abscissa or X column',@fontb)
        ->pack(-side => 'left');
   $f_s1->Menubutton(-textvariable => \$sorttype,
                     -tearoff      => 0,
                     -relief       => 'ridge',
                     -anchor       => 'e',
                     -menuitems    => [ @sorttype ],
                     -width        => 10, @fontb)
        ->pack(-side => 'left');
   $f_s1->Label(-text => 'ly.',@fontb)->pack(-side => 'left');
   my $f_s2 = $page2->Frame->pack(-side => 'top', -fill => 'x');
   $f_s2->Checkbutton(-text     => 'Doit in',
                      -variable => \$para{-sortdoit},
                      -onvalue  => 1,
                      -offvalue => 0, @fontb)
       ->pack(-side => 'left');
   $f_s2->Radiobutton(-text     => 'ascending or',
                      -variable => \$para{-sortdir},
                      -value    => 'ascend', @fontb)
        ->pack(-side => 'left');
   $f_s2->Radiobutton(-text     => 'descending order.',
                      -variable => \$para{-sortdir},
                      -value    => 'descend', @fontb )
        ->pack(-side => 'left');

   #----------------- PAGE 3 ----------------------------------------------
   my $f_ct = $page3->Frame(-borderwidth => 3, -relief => 'groove')
                    ->pack(-side => 'top', -fill => 'x');
   $f_ct->Label(-text    => "COMMON DATE-TIME", @fontb,
                -justify => 'left',
                -anchor  => 'w')
          ->pack(-side => 'top', -fill => 'x');
   my $mess = "Convert date-time to a common base.  yr, yr:mn\n".
              "yr:mn:dy:hr, etc. '-' to leave a field alone.";
   $f_ct->Label(-text    => $mess, @fontb,
                -justify => 'left',
                -anchor  => 'w')
          ->pack(-side => 'top', -fill => 'x');
   $f_ct->Entry(-textvariable => \$para{-common_datetime},
                -width        => 40,
                -background   => 'white', @fontb)
          ->pack(-side => 'top', -fill => 'x');
   $mess = "CPU intensive--but no preprocessing needed.\n".
           "e.g. 1996:10 changes dates to 10/-/1996 -:-:-\n".
           "This is an extremely neat feature for annual\n".
           "or diurnal variation time series plots.";        
   $f_ct->Label(-text    => $mess, @fontb,
                -justify => 'left',
                -anchor  => 'w')
        ->pack(-side => 'top', -fill => 'x');
   my $f_ct2  = $f_ct->Frame(-borderwidth => 2, -relief => 'groove')
                     ->pack(-side => 'top', -fill => 'x');
   my $f_ct2a = $f_ct2->Frame->pack(-side => 'left',
                                    -fill => 'y');
   my $f_ct2b = $f_ct2->Frame->pack(-side   => 'right',
                                    -expand => 1,
                                    -fill   => 'x');
   
   $f_ct2a->Button(-text    => "Use noon", @fontb,
                   -command =>
                      sub { $para{-common_datetime} = "-:-:-:12:00:00" })
          ->pack(-side => 'top');
   $f_ct2a->Button(-text    => "As WatYr", @fontb,
                   -command =>
              sub { if($para{-common_datetime} eq "" or
                       $para{-common_datetime} =~ m/^-/o ) {
                       $para{-common_datetime} =
                         "wyYYYY, 'wy' is prepended for a".
                         " common water year";
                    }
                    else {
                       if($para{-common_datetime} !~ m/^wy/io) {
                           $para{-common_datetime} =
                              "wy$para{-common_datetime}"};
                       }
                    })
          ->pack(-side => 'top');
   $f_ct2a->Button(-text => "Default", @fontb,
                   -command => 
                      sub { $para{-common_datetime} =  "" })
          ->pack(-side => 'bottom', -fill => 'x');
   $mess = "Dates without a time component\n".
           "(e.g. 07/20/1969) by default are\n".
           "plotted at 00:00:00.  Use the\n".
           "'Use noon' button to change\n".
           "time to 12:00:00 so the above\n".
           "field will be -:-:-:12:00:00.";
   $f_ct2b->Label(-text    => $mess, @fontb,
                  -justify => 'left',
                  -anchor  => 'w')
          ->pack(-side => 'left', -fill => 'x');
   $f_ct2->Label(-text    => "\n", @fontb)
         ->pack(-side => 'bottom');
   
   my $f_to = $page3->Frame(-borderwidth => 3, -relief => 'groove')
                    ->pack(-side => 'top', -fill => 'x');
   $f_to->Label(-text    => "DATE-TIME OFFSET", @fontb,
                -justify => 'left',
                -anchor  => 'w')
          ->pack(-side => 'top', -fill => 'x');
   $mess = "Offset any and all date-time values by the\n".
           "following floating point in days (positive\n".
           "or negative)--see days calculator below.";
   $f_to->Label(-text    => $mess, @fontb,
                -justify => 'left',
                -anchor  => 'w')
          ->pack(-side => 'top', -fill => 'x');
   $f_to->Entry(-textvariable => \$para{-datetime_offset},
                -width        => 40,
                -background   => 'white', @fontb)
          ->pack(-side => 'top', -fill => 'x');       
   $f_to->Label(-text => "The offset is neat for plotting hydrographs.",
                @fontb,
                -justify => 'left',
                -anchor  => 'w')
        ->pack(-side => 'top', -fill => 'x');
   my ($date1, $date2, $days) = ("","",'none calculated');
   my $f_dc = $f_to->Frame->pack(-fill => 'x');
   $f_dc->Label(-text => "Days Calculator:", @fontb,
                -anchor => 'w')
        ->pack(-side => 'left', -fill => 'x');
   $f_dc->Button(-text => "Load days to offset", @fontb,
                 -command =>
                 sub { $para{-datetime_offset} = $days if(&isNumber($days));
                     })
        ->pack(-side => 'right');
   my $f_cc3 = $f_to->Frame->pack(-side => 'bottom', -fill   => 'x');       
   my $f_cc1 = $f_to->Frame->pack(-side => 'left',   -fill   => 'y');
   my $f_cc2 = $f_to->Frame->pack(-side => 'right',  -expand => 1,
                                                     -fill   => 'both');
   
   $f_cc1->Label(-text   => " First date", @fontb,
                 -anchor => 'e')
         ->pack(-fill => 'x');
   $f_cc1->Label(-text   => " Second date", @fontb,
                 -anchor => 'e')
         ->pack(-fill => 'x');
   $f_cc2->Entry(-textvariable => \$date1,
                 -background   => 'white', @fontb)
         ->pack(-fill => 'x', -expand => 1); 
   $f_cc2->Entry(-textvariable => \$date2,
                 -background   => 'white', @fontb)
         ->pack(-fill => 'x', -expand => 1);
   
   my $day_label;
   $f_cc3->Button(-text    => "Compute date2 - date1", @fontb,
                  -anchor => 'w',
                  -command =>
                  sub { my ($c1, $c2) = (&DateandTime_to_Days($date1),
                                         &DateandTime_to_Days($date2));
                        my $message = "";
                        
                        # check second date first so that if both
                        # are bad, an error for the first will be shown
                        $message = "date2 is not valid" if(not $c2);
                        $message = "date1 is not valid" if(not $c1);
                        
                        $days = ($message) ? $message : ($c2 - $c1);
                        $day_label->configure(-text => "$days");
                      })
          ->pack(-side => 'left', -anchor => 'w');
   $f_cc3->Label(-text => "-->", @fontb)
         ->pack(-side => 'left', -fill => 'x');
   $f_cc3->Label(-text => "days", @fontb)
         ->pack(-side => 'right', -fill => 'x');
   $day_label = $f_cc3->Label(-text   => "$days", @fontb,
                              -relief => 'sunken',
                              -anchor => 'w')
                      ->pack(-side => 'left', -expand => 1, -fill => 'x');
   
   #-----------------------------------------------------------------------
 
   my $finishsub = sub {
          # set the locations of the axes
          my @locations = split(/\sand\s/,$axis);
          @locations = map { lc($_) } @locations; # make sure lower case
          $plot->{-x}->{-location} = $locations[0];
          $plot->{-y}->{-location} = $locations[1];
          
          if($para{-fileisRDB}) {
             # The ReadRDBFile module takes over command of these values,
             # but we will set them here to insure consistency with the
             # file format.
             $para{-delimiter}       = "\t";
             $para{-skiplineonmatch} = "^#";
             $para{-invertskipline}  = 0;
             $para{-numskiplines}    = 0;
             $para{-numlabellines}   = 1;
             $para{-columntypes}     = 'f';
             $para{-numskiplines_afterlabel} = 0;
          }
          
          if($delimiter eq 'custom') { 
             if(not defined($customdelimiter) ) {
               my $mess = "A custom delimiter has been selected, ".
                          "but no custom delimiter was entered in the field.";
               &Message($pe, '-generic', $mess);
               return;
             }
             $para{-filedelimiter} = $customdelimiter;
          }           
          
          if($para{-columntypes}) { # if something has been entered in field
             $para{-columntypes} = &strip_space( $para{-columntypes} );
             if($para{-columntypes} =~ m/f/o) {
               $para{-columntypes} = 'in file';
             }
             elsif($para{-columntypes} =~ m/a/o) {
               $para{-columntypes} = 'auto';
             }
             else {
               $para{-columntypes} = lc($para{-columntypes} );
               my @types = split(//,$para{-columntypes});
               foreach my $type (@types) {
                 if($type !~ m/[dns]/) {
                   my $mess = "One or more of the column types do not ".
                              "match either D or d (date or time), N or n ".
                              "(number), or S or s (string).  Please revise".
                              "the optional column type entry field.";
                   &Message($pe, '-generic', $mess);
                   return;
                 }
               }
             }
          }
          else {
             $para{-columntypes} = 'auto';
          }
          
          # Verify the number of lines to be read
          # "" means grab an entire file or at least until an optional __END__
          if( &isNumber($para{-numlinestoread}) ) {
             if($para{-numlinestoread} < 1) {
                my $mess = "The number of lines to read is a number ".
                           "but it is less than 1 which does not make sense.";
                &Message($pe, '-generic', $mess);
                return;
             }
          }
          else {
             $para{-numlinestoread} = "";
          }
          
          # Verify numbers in the -common_datetime field
          if($para{-common_datetime}) {
             my $mess = "The colon delimited common date time ".
                        "component entry does not contain only numbers. ".
                        "Or the year is not a four digit number or ".
                        "one of the other components is not a two digit ".
                        "number.";
             my @components = split(/:/o, $para{-common_datetime});
             foreach my $component (@components) {
                $component = "-" if(not defined $component or $component eq "");
             }
             my $goodcomponents = 1;
             for(my $i=0; $i<=$#components;$i++) {
                my $component = $components[$i];
                next if($component eq '-');
                if($i == 0 and &isNumber($component)
                           and $component !~ /^\d{4}$/) {
                   $goodcomponents = 0;
                   last;
                }
                else {
                   next;
                }
                next if(&isNumber($component) and $component =~ /^\d{2}$/);
                $goodcomponents = 0;
             }
             if(not $goodcomponents) {
                map { $mess .= "\n$_"; } (@components);
                &Message($pe, '-generic', $mess);
                $para{-common_datetime} = "";
                return;
             }
             
             $para{-common_datetime} = join(":",@components);
          }
          
          if(not &isNumber($para{-datetime_offset})) {
             $para{-datetime_offset} = 0;
             my $mess = "The date-time offset is not a number.\n".
                        "Tkg2 is resetting it to zero.\n";
             &Message($pe, '-generic', $mess);
             return;
          }
          
          # if the second y axis is to be the scale, then we have to
          # toggle the plot to start looking for things concerning 
          # a double y axis, which includes NOT plotting the ticks for
          # the first y axis on the double one.  go see the drawing algorithms
          if($plotpara{-which_y_axis} == 2) {
             $plot->{-y2}->{-turned_on} = 1 # DOUBLE Y:
          }
          
          my ($fsel, $file);
          if(not $para{-megacommand} or
                 $para{-megacommand} =~ m/^\s*pipe:/o or
                 $para{-megacommand} =~ m/^\s*filter:/o ) {
            OPENFILE: {
                my $dir2open = ($LASTOPENDIR) ? $LASTOPENDIR :
                                                $::TKG2_ENV{-USERHOME};
                my @types = ( '.txt', '.out', '.dat', '.csv',
                              '.rdb', '.RDB', '.asc', '.tmp', '.prn' );
                $file = $pw->getOpenFile(-title => "Open a Data File",
                                         -initialdir => $dir2open,
                                         -filetypes => [ [ 'Typical Text',
                                                         [ @types ] ],
                                                         [ 'All Files',  [ '*' ] ] ]);
             }
             if(not defined($file) or not -e $file) { 
                $LASTOPENDIR = "";
                &Message($pe,'-nofilename');
                return;
             }
          
             # logic to work out whether we should remember the directory
             my $dirname = &dirname($file);
             my $cwd     = &cwd;  # gives use a full path name without the '.'
             $LASTOPENDIR = ($dirname eq '.') ? $cwd : $dirname;
             # Check to make sure that the directory does exist before we
             # allow the directory to be remembered
             $LASTOPENDIR = "" unless(-d $LASTOPENDIR);

             # Very important note, -fullfilename will always contain the
             # original data file path, if -userelativepath then -relativefilename
             # could point to differing data files.  &cwd might change between
             # time that getOpenFile is closed and relative_path is
             # called--unlikely
             $para{-fullfilename}     = $file;
             $para{-relativefilename} = &relative_path($file);
          }
          $pe->destroy;
          
          my @c_p_t = ($canv, $plot, $template);
          my ($header, $data, $linecount) = ($para{-fileisRDB})  ?
                                             $self->ReadRDBFile(@c_p_t, \%para, 1) :
                                             $self->ReadDelimitedFile(@c_p_t, \%para, 1);
          if(not $linecount) {
             my $mess = "AddDataToPlot warning.  The read in file was empty.  ".
                        "Can not load data into a plot.  Please find some data for ".
                        "the plot.  At a later time during dynamic data loading at ".
                        "runtime the file is empty then tkg2 will work as expected ".
                        "and simply not show any data.  In other words, you must have ".
                        "data the first time that a plot is built.\n\n".
                        "It is possible that Tkg2 simply can not parse your data file, ".
                        "and an additional dialog box with the errors should be visible.";
             &Message($pw, -generic, $mess);
             return;
          }
          $self->LoadDataIntoPlot(@c_p_t, $header, $data, \%para, \%plotpara, $linecount);
                      
          # -transform data is nested into para so we need to clone
          # that hash              
          my $transform_data = { %{ $para{-transform_data} } };
          $LAST_PARA     = { %para };
          $LAST_PARA->{-transform_data} = $transform_data;
          
          $LAST_PLOTPARA = { %plotpara };
          };


   my ($px, $py) = (2, 2);   
   
   
   $page1->Button(-text    => "Show me the data file contents", @fontb,
                  -command => [\&DataViewer, $pe ])
         ->pack(-side => 'bottom', -padx => $px, -pady => $py);

   $page2->Entry(-textvariable => \$plot->{-username}, @font,
                 -width        => 40,
                 -background   => 'white')
         ->pack(-side => 'bottom', -fill => 'x');
   
   $page2->Label(-text => 'Optional plot user name', @fontb)
         ->pack(-side => 'bottom', -fill =>'x');
   
   
   
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
                     
   my $b_ok = $f_b->Button(
                  -text               => 'OK', @fontb,
                  -borderwidth        => 3,
                  -highlightthickness => 2,
                  -command            => $finishsub )
                  ->pack(-side => 'left', -padx => $px, -pady => $py); 
                    
   $b_ok->bind("<Return>", $finishsub);                          
   
   $f_b->Button(-text    => "Cancel", @fontb,
                -command => sub { $pe->destroy; return; })
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text => "Help", @fontb,
                -padx => 4,
                -pady => 4,
                -command => sub { &Help($pe,'AddDataFile.pod'); } )
       ->pack(-side => 'left', -padx => $px, -pady => $py,);
}


sub BadDate {
   my ($date) = @_;
   return "is not valid";
}


sub DateandTime_to_Days {
   my ($field) = @_;
   
   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   # ParseDateString does not handle the '@' sign, so we will
   # strip it out.
   $field =~ s/(.+)@(.+)/$1 $2/ if($field =~ m/@/o);
   $field = &ParseDateString($field);
   return undef unless($field);
   
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack( $format, $field );
   my $day   = &Delta_Days( 1900, 1, 1, $yyyy, $mm, $dd );
   my $days  = &dayhhmmss2days( $day, $hh, $min, $ss );
   return $days;
}

# dayhhmmss2days:
# convert a list of (days, hours, minutes, seconds) to 
# a real number days.frac
sub dayhhmmss2days {
   return ($_[0]+($_[1]+(($_[2]+($_[3]/S60))/S60))/S24);
}

1;
