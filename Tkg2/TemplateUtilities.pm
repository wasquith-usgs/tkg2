package Tkg2::TemplateUtilities;

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
# $Revision: 1.48 $

use strict;

use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK $EDITOR);
@ISA = qw(Exporter SelfLoader);
@EXPORT_OK = qw(StartTemplate
                DataOnTheFly
                UpdateCanvas
                NeedSaving
                AddPlot
                AddAnno
                snap_to_grid
                Dump
                Dump2Stdout);

use Data::Dumper;

use File::Basename;
use Tk; # need the pesky Ev commands
use Tkg2::Base qw(Message Show_Me_Internals stackWidget OSisMSWindows isInteger);

print $::SPLASH "=";

# StartTemplate is the main entrance into the tkg2 object model.
# This methods builds the main editing canvas/template and performs
# other initializations.
sub StartTemplate {
   use vars qw($statbar);
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $template = shift;
   my $tw = $::MW->Toplevel(-title => "Canvas");
 
   if($::CMDLINEOPTS{'justdisplayone'} or
      $::CMDLINEOPTS{'nomw'}           or
      $::CMDLINEOPTS{'withdrawmw'} ) {
      my $mess = "WARNING: Tkg2 is operating in a mode in which the MainWindow is\n".
                 "not visible to the user.  You just pressed the window destroy\n".
		 "button on the window decoration.  This only destroys (or\n".
		 "would only destroy) a child of the MainWindow--thus, this\n".
		 "action WILL NOT TERMINATE the Tkg2 process.  You must use the\n".
		 "Exit from the FILE menu or TKG2 DISPLAYER menu.\n".
		 "The operation modes that trigger this behavior are:\n\n".
		 "   --nomw, --withdrawmw, and --justdisplayone\n".
		 "   **NOTE that --justdisplay is not included because a\n".
		 "   **MainWindow is visible to the user with that mode.\n\n";
      $tw->protocol(["WM_DELETE_WINDOW"], sub { print STDERR $mess;  } );
   }       
   
   $tw->withdraw if($::CMDLINEOPTS{'withdraw'});
   
   $tw->overrideredirect(1) if($::CMDLINEOPTS{'nodec'});
   
   # stackWidget calls Tk->geometry and sets position of the tkg2 window
   # stackWidget places first window along right hand side of display
   # and any following windows are each shifted 60 pixels to the left.
   # The @::UNDO array is a means to track the number of tkg2 files that
   # are open 
   if($::CMDLINEOPTS{'presenter'}) {
      &stackWidget($tw,1*60,0);
   }
   elsif($::TKG2_CONFIG{-GEOMETRY}) {
      $tw->geometry($::TKG2_CONFIG{-GEOMETRY});
   }
   else {
      &stackWidget($tw,scalar(@::UNDO)*60,0);
   } 
   
   my $canvxbm = (&OSisMSWindows()) ? 
                 "Bitmaps/tkg2canvas.xbm" : 
                 "$::TKG2_ENV{-TKG2HOME}/Tkg2/Bitmaps/tkg2canvas.xbm";
   if(-e $canvxbm) {
      $tw->iconbitmap("@".$canvxbm); #"
   }
   else {
      print STDERR "Tkg2-warning: could not find the tkg2canvas bitmap\n";
   }
   
   
   &_backwardsTemplateLevelCompatability($template);
      
   # if the command line option to affect the rotation was given
   if(defined $::CMDLINEOPTS{'exportrotate'}) {
      if($::CMDLINEOPTS{'exportrotate'} eq '90' ) {
        $template->{-postscript}->{-rotate} = 1;
      }
      elsif($::CMDLINEOPTS{'exportrotate'} eq '0') {
        $template->{-postscript}->{-rotate} = 0;
      }
      else {
         print STDERR "Tkg2-warning: Whoops command line option ",
                      "--exportrotate is not 0 or 90.  Leaving template ",
                      "as is.\n";
      }
   }
   
   # Rescaling of the Template is necessary if one *.tkg2 file was created
   # on a monitor having a different resolution than the current session.
   # This is just the way that Tk works, I guess?  
   $template->rescaleTemplate($::MW->scaling);
   
   $template->{-undonum} = scalar(@::UNDO); # forever in this session,
                                            # this is the template
                                            # number in the UNDO array
   $::UNDO[$template->{-undonum}] = [ ];    # create the anonymous UNDO array
   
   if( defined $template->{-tkg2filename} ) {
      my $basename = &basename($template->{-tkg2filename});
      $tw->configure(-title => "Tkg2 showing $basename");
      $tw->iconname("$basename");
   }

   my $f = $tw->Frame(-relief      => 'ridge',
                      -borderwidth =>  2,
                      -background  => $::TKG2_CONFIG{-BACKCOLOR} ) 
               ->pack(-side   => 'top',
                      -anchor => 'n',
                      -fill   => 'x' );
   
   my ($oldheight,$oldwidth);
   # the abs() on the CMDLINEOPTS is for simple protection against
   # the mistaken leading negative on a width or height.  The program
   # actually does not crash when a negative is present, but the canvas
   # certainly does not look right
   if($::CMDLINEOPTS{'width'} or $::TKG2_CONFIG{-FORCE_PAGE_WIDTH} ) {
      # the following conditional sets up the width if it was set from
      # a tkg2rc file, but not if a command line option is present
      $::CMDLINEOPTS{'width'} =  $::TKG2_CONFIG{-FORCE_PAGE_WIDTH}
         if (     $::TKG2_CONFIG{-FORCE_PAGE_WIDTH} and
              not $::CMDLINEOPTS{'width'} );

      $oldwidth = $template->{-width};
      $template->{-width} = abs($::CMDLINEOPTS{'width'});
   }   
   
   if($::CMDLINEOPTS{'height'} or $::TKG2_CONFIG{-FORCE_PAGE_HEIGHT}) {
      # the following conditional sets up the width if it was set from
      # a tkg2rc file, but not if a command line option is present
      $::CMDLINEOPTS{'height'} =  $::TKG2_CONFIG{-FORCE_PAGE_HEIGHT}
      if (     $::TKG2_CONFIG{-FORCE_PAGE_HEIGHT} and
              not $::CMDLINEOPTS{'height'} );
              
      $oldheight = $template->{-height};
      $template->{-height} = abs($::CMDLINEOPTS{'height'});
   }
   
   # Check the we have valid width and height limits before proceeding.
   my $message = "A known cause of this is the --mktemp option without ".
                 "a argument, but being following by another option. ".
                 "Please check your command line options.\n";
   if(not defined $template->{-width}) {
      &Message($::MW,-generic,
          "Template width is somehow undefined--setting to 8.5i. "."$message");
      $template->{-width}  = '8.5';
   }
   if(not defined $template->{-height}) {
      &Message($::MW,-generic,
          "Template height is somehow undefined--setting to 11i. "."$message");
      $template->{-height} = '11';
   }
   # End of the check on valid width and height limits
   
   # set up the height, width, and offsets for the potential rulers 
   my $scale  = 1;
   my $width  = $template->{-width};
      $width  = $tw->fpixels("$width"."i" );
   my $height = $template->{-height};
      $height = $tw->fpixels("$height"."i");
   my $vedge  = $tw->fpixels("0.21i" );
   my $hedge  = $tw->fpixels("0.15i");

   # frame to hold scrollbars and the drawing canvas
   my $fcanv = $tw->Frame->pack(-fill => 'both', -expand => 1);                

   # must build scrollbars before the canvas is placed, but configure
   # after the canvas is built.
   my @to_configureSB =
      $template->buildScrollBars($fcanv,$hedge,$vedge,$width,$height)
      if(not $::CMDLINEOPTS{'batch'});            
   my $canv = $fcanv->Canvas(-scrollregion => [ 0, 0, $width, $height ],
                             -takefocus    => 1,
                             -relief       => 'sunken',
                             -width        => $width*$scale,
                             -height       => $height*$scale,
                             -background   => $template->{-color} )
                    ->pack(-expand => 1, -fill => 'both');               
   
   if($::CMDLINEOPTS{'batch'}) {
      # do nothing, no need to add any more bells and whistles
   }
   elsif($::CMDLINEOPTS{'justdisplay'}    or
         $::CMDLINEOPTS{'justdisplayone'} or
         $::CMDLINEOPTS{'presenter'} ) {
      $template->configureScrollBars($canv,@to_configureSB);
      
      $template->TemplateDisplayMenus($f,$tw,$canv)
                                    unless($::CMDLINEOPTS{'nomenus'});
      
      $template->Rulers($canv, $to_configureSB[2], $to_configureSB[3],
                        $hedge, $vedge, $::CMDLINEOPTS{'norulers'});
   }
   else { # regular user session
      $template->configureScrollBars($canv,@to_configureSB);
      $template->TemplateFullMenus($f,$tw,$canv);
      $template->Rulers($canv, $to_configureSB[2], $to_configureSB[3],
                        $hedge, $vedge, $::CMDLINEOPTS{'norulers'});
   }
   
   my ($oldcanvwidth, $oldcanvheight);
   foreach my $plot ( @{$template->{-plots}} ) {
      $plot->{-scaling} = $template->{-scaling};  # necessary so that the
      # getPlotMargins method call can work because of the need for the
      # pixel_to_inch conversion
      
      # we have redundent lookups on the -canvwidth and -canvheight since
      # all plots in a given template (single file) have the same value
      # of these fields.  The my declaration is made above this scope
      # because oldcanv* values are needed for annotation adjustments
      $oldcanvwidth        = $plot->{-canvwidth};
      $oldcanvheight       = $plot->{-canvheight};
      $plot->{-canvwidth}  = $canv->cget(-width);
      $plot->{-canvheight} = $canv->cget(-height);
      
      # Redefine the margins and the coordinates of the explanation for
      # the potentially different height and width values
      $plot->CanvHeightWidth_have_changed($oldcanvwidth, $oldcanvheight)
          if($::CMDLINEOPTS{'height'} or $::CMDLINEOPTS{'width'});
      
      $plot->configwidth; # always required when the scaling could have changed
   }

   # if the command line had --height=X.X or --width=X.X, we need to
   # take care of redefining the origins or coordinates of every annotation
   # conveniently, each annotation type has a CanvHeigthWidth_have_changed
   # method that knows how to modify the particular annotation object type
   if($::CMDLINEOPTS{'height'} or $::CMDLINEOPTS{'width'}) {
      my $newcanvwidth  = $canv->cget(-width);
      my $newcanvheight = $canv->cget(-height);
      foreach my $anno ( @{$template->{-annotext}  },
                         @{$template->{-annosymbol}},
                         @{$template->{-annoline}  } ) {
         $anno->CanvHeightWidth_have_changed($newcanvwidth, $newcanvheight,
                                             $oldcanvwidth, $oldcanvheight);
      }
   }

   if( $::CMDLINEOPTS{'instb4data'} ) {
      $template->Instructions;        # Instructions before the Data
      $template->DataOnTheFly($canv); # for the 0.72 and greater releases.
   }
   else {
      $template->DataOnTheFly($canv); # load any data that is dynamically needed
                                      # and take care of any special configuration
   
      # INSTRUCTIONS FOR RUNTIME CONTROL CONFIGURATION
      $template->Instructions; # cleanly returns if no plot control done
   }
   
   # FINAL ADJUSTMENTS
   # At this point, it is highly advisable that we run through
   # whatever consistency checks are necessary.
   # such checks include unit conversions or conversions into
   # internal tkg2 representations
   foreach my $plot ( @{$template->{-plots}} ) {
      
      $plot->convertUnitsToPixels;
      
      # This provides a quick check on the min and max fields for each axis
      # if a min or max field checks out as a valid tkg2 time, then the time
      # is converted to a integer for the user.  This allows the user to
      # modify the min and max fields for a time series plot using dates and time
      # and have tkg2 do the conversion to integer.fracdays since that is how
      # tkg2 works with time -- feature suggested by Willard Gibbons, Austin, Texas
      # This is an very subtle feature.
      $plot->convertAxisMinMaxtoIntegerifTime;
   }
   
   # the -datajustloaded is a toggle to tell the update to ignore
   # a reloading of data (when the --redodata option was present)
   # because the data for this template was just loaded.
   $template->UpdateCanvas($canv,-datajustloaded); # the final drawing call
  
   return ($canv, $tw);                 
}

# This is a convenient dumping ground to insure that every template
# has the various parameters defined that were included late in the tkg2
# development cycle.
sub _backwardsTemplateLevelCompatability {
   my $template = shift;
   # Backwards compatability for 0.53 and on
   $template->{-draw_annotation_first} = 0
      if(not defined $template->{-draw_annotation_first});
   $template->{-annoline_plot_order}   = 1
      if(not defined $template->{-annoline_plot_order} );
   $template->{-annosymbol_plot_order} = 2
      if(not defined $template->{-annosymbol_plot_order} );
   $template->{-annotext_plot_order}   = 3
      if(not defined $template->{-annotext_plot_order} );
   $template->{-metapost} = 0
      if(not defined $template->{-metapost} );
   # end of backwards compatability
}



# UpdateCanvas is the sole method providing the updating/redrawing interface 
# into the entire Tkg2 data model.  A call $template->UpdateCanvas($canv) is
# placed throughout the tkg2 code whenever an update is needed such as hitting
# an B_Ok or B_Apply.
sub UpdateCanvas {
   print $::MESSAGE "BEGIN OF CANVAS UPDATE\n";
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS-Begin: @fonts_defined\n";
             
   my ($template, $canv, $datajustloaded, $increment) = @_;
   if($increment) {
      &_by_Increment_UpdateCanvas($template,$canv,$datajustloaded);
      return;
   }
   my $annotation_has_been_drawn = 0;
   
   if($::CMDLINEOPTS{'redodata'} and not $datajustloaded ) {
      $template->DeleteLoadedData;
      $template->DataOnTheFly($canv);
   }
   
   $template->Instructions if($::CMDLINEOPTS{'redoinst'});
   
   $canv->Busy;  # change mouse cursor to a watch
   
   # speed up by turning UNDO off when one of the following is true
   $template->StoreUndo unless($::CMDLINEOPTS{'justdisplay'}    or
                               $::CMDLINEOPTS{'justdisplayone'} or
                               $::CMDLINEOPTS{'presenter'}      or
                               $::CMDLINEOPTS{'batch'} );
   $template->NeedSaving(1);
   
   # The add data without redrawing key is set be the Data Menu
   # This is a feature that if true allows the user to load all 
   # of their data in without the time consuming redrawings
   # This is particularly helpful on slow remote links.
   if($template->{-no_update_on_data_add}) {
      $canv->Unbusy;
      return;
   }
   
   # Ok now actually begin the rendering process
   $canv->delete("all");  # remove everything from canvas - all in automatic tag
   
   # set up the plot order for the annotation
   my @anno_order = (undef, undef, undef);
   $anno_order[ $template->{-annoline_plot_order}   ] = '-annoline';
   $anno_order[ $template->{-annosymbol_plot_order} ] = '-annosymbol';
   $anno_order[ $template->{-annotext_plot_order}   ] = '-annotext';
   # The following shift is necessary as 1, 2, 3 are used to denote the
   # plot order and not 0, 1, 2.  This makes the interface simpler.  Thus,
   # we need to remove the element 0.
   shift(@anno_order); 
   
   # Generate a potentially very large list of the each of the annotation
   # objects that are to be drawn.
   my @annotation = ();
   foreach my $key ( @anno_order ) {
      if(not defined $key) {
         print STDERR
               "Tkg2-warning: One or more of the annotation elements (text, ",
               "symbol, line) have\n",
               "the same drawing order.  Thus, one or more of these elements ",
               "will not be visible\n",
               "on the screen.  Please consider revising your drawing order in the ",
               "ANNOTATION menu.\n";
         next;
      }
      push(@annotation, @{ $template->{$key}   } );
   }
   
   my @args = ( $canv, $template ); # yes switching order from input arguments
   # is stupid, but that is the way the code has matured.
   
   # Potential Annotation drawing
   if($template->{-draw_annotation_first}) {
      map {  my @fonts_defined = $::MW->fontNames();
             print $::BUG "FONTBUG UPDATECANVAS-AnnoDraw(before): @fonts_defined\n";
             $_->draw(@args);
             @fonts_defined = $::MW->fontNames();
             print $::BUG "FONTBUG UPDATECANVAS-AnnoDraw(before): @fonts_defined\n";
       } @annotation;
      $annotation_has_been_drawn = 1;
   }
   
   # Draw the plots and all related graphics
   my $plot_number = 0;
   foreach my $plot ( @{$template->{-plots}}) {
      #if(&isInteger($plot->{-y}->{-logoffset})) { # PERL5.8 CORRECTION RESEARCH
         # print STDERR "BUG: before drawme offset is an integer\n";  
      #}
      #else {
         # print STDERR "BUG: before drawme offset is not an integer\n";  
      #}
      $plot_number++;
      print $::MESSAGE "   BEGIN PLOT $plot_number\n";
      my @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS-PlotDrawMe(before): @fonts_defined\n";
      $plot->DrawMe(@args);
         @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS-PlotDrawMe(end   ): @fonts_defined\n";
   }
   
   # Potential Annotation drawing again, if not done already
   if(not $annotation_has_been_drawn) {   
      map { $_->draw(@args) } @annotation;
   }
   print $::MESSAGE "END OF CANVAS UPDATE\n";
   $canv->Unbusy;   # revert back to default mouse cursor
   foreach my $plot ( @{$template->{-plots}}) {
     #if(&isInteger($plot->{-y}->{-logoffset})) { # PERL5.8 CORRECTION RESEARCH
       #print STDERR "BUG: ending of update canvas offset is an integer\n";
     #}
     #else {
       #print STDERR "BUG: ending of update canvas offset is not an integer\n\n";
     #}
   }
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS-End: @fonts_defined\n";
} 

sub _by_Increment_UpdateCanvas {
   print $::MESSAGE "BEGIN INCREMENT CANVAS UPDATE\n";
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($template, $canv, $datajustloaded) = @_;
   my $annotation_has_been_drawn = 0;
   
   if($::CMDLINEOPTS{'redodata'} and not $datajustloaded ) {
      $template->DeleteLoadedData;
      $template->DataOnTheFly($canv);
   }
   
   $template->Instructions if($::CMDLINEOPTS{'redoinst'});
   
   $canv->Busy;  # change mouse cursor to a watch
   
   # speed up by turning UNDO off when one of the following is true
   $template->StoreUndo unless($::CMDLINEOPTS{'justdisplay'}    or
                               $::CMDLINEOPTS{'justdisplayone'} or
                               $::CMDLINEOPTS{'presenter'}      or
                               $::CMDLINEOPTS{'batch'} );
   $template->NeedSaving(1);
   
   # The add data without redrawing key is set be the Data Menu
   # This is a feature that if true allows the user to load all 
   # of their data in without the time consuming redrawings
   # This is particularly helpful on slow remote links.
   if($template->{-no_update_on_data_add}) {
      $canv->Unbusy;
      return;
   }
   
   # Ok now actually begin the rendering process
   $canv->delete("all");  # remove everything from canvas - all in automatic tag
   &_PromptMessage($canv,'Are all items deleted from canvas?');

   # set up the plot order for the annotation
   my @anno_order = (undef, undef, undef);
   $anno_order[ $template->{-annoline_plot_order}   ] = '-annoline';
   $anno_order[ $template->{-annosymbol_plot_order} ] = '-annosymbol';
   $anno_order[ $template->{-annotext_plot_order}   ] = '-annotext';
   # The following shift is necessary as 1, 2, 3 are used to denote the
   # plot order and not 0, 1, 2.  This makes the interface simpler.  Thus,
   # we need to remove the element 0.
   shift(@anno_order); 
   
   # Generate a potentially very large list of the each of the annotation
   # objects that are to be drawn.
   my @annotation = ();
   foreach my $key ( @anno_order ) {
      if(not defined $key) {
         print STDERR
               "Tkg2-warning: One or more of the annotation elements (text, ",
               "symbol, line) have\n",
               "the same drawing order.  Thus, one or more of these elements ",
               "will not be visible\n",
               "on the screen.  Please consider revising your drawing order in the ",
               "ANNOTATION menu.\n";
         next;
      }
      push(@annotation, @{ $template->{$key}   } );
   }
   
   my @args = ( $canv, $template ); # yes switching order from input arguments
   # is stupid, but that is the way the code has matured.
   
   # Potential Annotation drawing
   if($template->{-draw_annotation_first}) {
      map { $_->draw(@args) } @annotation;
      $annotation_has_been_drawn = 1;
   }
   &_PromptMessage($canv,'Has initial annotation been drawn correctly?');

   # Draw the plots and all related graphics
   my $plot_number = 0;
   foreach my $plot ( @{$template->{-plots}}) {
      $plot_number++;
      print $::MESSAGE "   BEGIN PLOT $plot_number\n";
      $plot->DrawMe(@args,'increment');
      &_PromptMessage($canv,"Has plot $plot_number been drawn correctly?");
   }
   
   # Potential Annotation drawing again, if not done already
   if(not $annotation_has_been_drawn) {   
      map { $_->draw(@args) } @annotation;
   }
   &_PromptMessage($canv,"Has final annotation been drawn correctly?");
   print $::MESSAGE "END OF CANVAS UPDATE\n";
   $canv->Unbusy;   # revert back to default mouse cursor
} 

sub _PromptMessage {
   my ($canv,$message) = @_;
   $canv->update;
   print "INCREMENTAL CANVAS UPDATE: $message (Y/N) ";
   my $tmp = <STDIN>;
   chomp($tmp);
   $tmp = ($tmp =~ /y/io) ? 'YES' : 'NO';
   print $::MESSAGE "  INCREMENTAL CANVAS UPDATE: $message   ($tmp)\n";
}

# DataOnTheFly is the sole method providing and interface into the dynamic
# loading of data.  See how the dat limit keys -when* get undefined so that
# the setdata limits routines are guaranteed to have valid data fields 
# (if applicable) for log and probability axis.  This method is a good
# starting point if one needs to see how the data storage model is implemented
sub DataOnTheFly {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my %para;
   my ($template, $canv) = (shift, shift);
   foreach my $plot ( @{ $template->{-plots} } ) {
      my $plotname = (defined $plot->{-username} and
                              $plot->{-username} ne "") ?
                              $plot->{-username} :
                      "not explicitly named by user";
      print $::VERBOSE "   DataOnTheFly Plot name '$plotname':\n";
      my %href = ( -whenlinear => undef,
                   -whenlog    => undef,
                   -whenprob   => undef ); # all data limits get cleaned out at run-time
                   
      my $xref              = $plot->{-x};
         $xref->{-datamin}  = { %href };
         $xref->{-datamax}  = { %href };
      my $yref              = $plot->{-y};
         $yref->{-datamin}  = { %href };
         $yref->{-datamax}  = { %href };  
      my $y2ref             = $plot->{-y2};  # DOUBLE Y:
         $y2ref->{-datamin} = { %href };     # DOUBLE Y:
         $y2ref->{-datamax} = { %href };     # DOUBLE Y:

      # Just a rough patch to test on discrete
      # Clear out the label hash so that it will be properly built
      # by dynamic loading.  This means that any hard loaded data
      # that is discrete will not work right -- 11/8/1999
      #$xref->{-discrete}->{-labelhash} = {};
      #$yref->{-discrete}->{-labelhash} = {};  
      
      my $dataclass = $plot->{-dataclass};
      foreach my $dataset ( @{ $dataclass } ) {
         my ($header, $data, $linecount);
        
         my %para = %{ $dataset->{-file} };
         my $file;
         if($para{-dataimported}) {
            # need to take a shot at changing the datalimits
            # (datamin and datamax) using the hard loaded data
            $dataset->configureDataLimits($plot);
            next;
         }
         else {
           if($para{-megacommand}) {
              print $::VERBOSE "      A MegaCommand is retrieving the data.";
           }
           else {
              $file = ($para{-userelativepath}) ? $para{-relativefilename} : 
                                                  $para{-fullfilename}     ;
              print $::VERBOSE "      Reading file '$file' ";
           }
           my $mess = "\n      There was an error with the data file.\n".
                        "      ERROR =";
           if($para{-fileisRDB}) { # hey, the file is an RDB file
               ($header, $data, $linecount) =
                      $dataclass->ReadRDBFile($canv,
                                              $plot,
                                              $template,
                                              \%para, 0);  
               # trap the returns from data errors and sometimes
               # linecount is undefined.
               $linecount = "undef lines." if(not defined $linecount);
               
               if(not defined $header) {
                  print $::VERBOSE " $mess $linecount\n";
                  next;
               }
               else {
                  print $::VERBOSE "$linecount lines.\n";
               }
               $dataclass->LoadDataOnTheFly($dataset,$plot, $canv,
                                            $header, $data, \%para);
           }
           else { # the file is not an RDB file
               ($header, $data, $linecount) =
                      $dataclass->ReadDelimitedFile($canv,
                                                    $plot,
                                                    $template,
                                                    \%para, 0);
               # trap the returns from data errors and sometimes
               # linecount is undefined.
               $linecount = "undef lines." if(not defined $linecount);
               
               if(not defined $header) {
                  print $::VERBOSE " $mess $linecount\n";
                  next;
               }
               else {
                  print $::VERBOSE "$linecount lines.\n";
               }
               $dataclass->LoadDataOnTheFly($dataset, $plot, $canv,
                                            $header, $data, \%para);
           }
         }
      } # END of each dataset in dataclass loop 
   }  # END of each plot loop
} # END OF DataOnTheFly



# NeedSaving is just a simple switcher to handle whether a template needs
# to be saved or not.  -needsaving changes to yes with a call to UpdateCanvas
sub NeedSaving {
   my $template = shift;
   if(@_) {
      $template->{-needsaving} = shift;
   }
   else {
      $template->{-needsaving};
   }
}
 
1;

#__DATA__

# Corresponds entirely to the AddPlot menu.  Presently,
# there are two ways to start a plot, one by dragging
# and the other by using the PlotEditor to specify margins
# AddPlot is the natural location to insert the methods
# to support other types off plots that do not fit into the
# X-Y type model.
sub AddPlot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $canv, $which) = (shift, shift, shift);
   my $w = $canv->cget(-width);
   my $h = $canv->cget(-height);
   my $plot = Tkg2::Plot::Plot2D->new($template, $w, $h);
   if($which eq 'editor') {
      $plot->PlotEditor($canv,$template);
   }
   elsif($which eq 'onthefly') {
       # do nothing?
   }
   elsif($which eq 'drag') { # go ahead and assume dragging
      my $drag = Tkg2::Plot::Movements::DraggingPlot->new(
                                    $canv,$template,$plot);
      $drag->bindStart;
   }
   return $plot;
}



   

# Corresponds entirely to the AddAnno menu.  All additions
# of annotation will be routed through here.
sub AddAnno {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $canv, $which) = (shift, shift, shift);
   
   my $_addanno = sub {
          my ($canv, $template, $which, $x, $y) =
                   (shift, shift, shift, shift, shift);
          $x = $canv->canvasx($x);
          $y = $canv->canvasy($y);
          $canv->Tk::bind("<Button-1>", "");
          my $anno;
          if($which eq 'text') {
             $anno = Tkg2::Anno::Text->new($x,$y);
             $anno->AnnoEditor($canv, $template);
             $canv->configure(-cursor => 'top_left_arrow');
          }
          elsif($which eq 'box') {
             $anno = Tkg2::Anno::Box->new($x, $y);
          }
          elsif($which eq 'line') {
             $anno = Tkg2::Anno::Line->new($x, $y);
             my $drag = $anno->newmove($canv, $template);
             $drag->startDrag;
          }
          else {
             $anno = Tkg2::Anno::Symbol->new($x, $y); 
             $anno->AnnoEditor($canv, $template);
             $canv->configure(-cursor => 'top_left_arrow');
          }   
   };
     
   $canv->configure(-cursor => 'crosshair');
   $canv->Tk::bind("<Button-1>", [ $_addanno,
                                   $template,
                                   $which,
                                   Ev('x'), Ev('y')
                                 ] );
}


# snap_to_grid and its child _get_snap are responsible for providing 
# the snapping of the mouse coordinates to the ruler.  The ruler
# construction in Tkg2/MenusRulersScrolls/Rulers.pm provides the 
# definition on the grid.
sub snap_to_grid {
   my ($template, $x, $y) = @_;
   return ($x, $y) unless($template->{-snap_to_grid});
   $x = &_get_snap( $template->{-x_grid}, $x );
   $y = &_get_snap( $template->{-y_grid}, $y );
   return ($x, $y);
}

sub _get_snap {
   my ($grid, $xORy) = @_;
   my $xORy2;
   my $dif1 = abs($grid->[0] - $xORy);
   foreach (@$grid) {
      my $dif2 = abs($_ - $xORy);
      last if($dif2 > $dif1); # exit early if we've found the minimum
      ($xORy2, $dif1) = ($_, $dif2) if( $dif2 < $dif1 );
   }
   return (defined $xORy2) ? $xORy2 : $xORy;
}

# A subroutine to view the Data::Dumper image of the template at any time. 
# Useful for debugging.
sub Dump {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $pw) = (shift, shift);

   # Standard dialog behavior throughout Tkg2 core
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'View Dumped Template');
   
   if( defined $template->{-tkg2filename} ) {
      my $basename = &basename($template->{-tkg2filename});
      $pe->configure(-title => "Data::Dumper -- Dumped: $basename");
   }
   
   $EDITOR = $pe;
   
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   # Dump the template
   $Data::Dumper::Indent = 1;
   my $dumped = Data::Dumper->Dump( [ $template ], [ qw(template) ] );
   
   my $text1 = $pe->Scrolled("Text",
                  -wrap       => 'none',
                  -background => 'white',
                  -height     => 20,
                  -width      => 100 )->pack();
   $text1->insert('end', $dumped);
   $text1->configure(-state => "disabled");

   my ($px, $py) = (2, 2);
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   
   $f_b->Button(-text    => "Leave", 
                -font    => $fontb,
                -command => sub { $pe->destroy;
                                } )
                ->pack(-side => 'left'); 
}

sub Dump2Stdout {
   my ($template, $grep_string, $label) = @_;
   $label ||= "";
   $Data::Dumper::Indent = 1;
   my $dumped = Data::Dumper->Dump( [ $template ], [ qw(template) ] );
   if($grep_string) {
      print STDERR "$label: Looking for $grep_string\n";
      map  { print STDERR "$_\n" }
         grep { /$grep_string/ }
            split(/\n/, $dumped);
   }
   else {
      print STDERR "%% $dumped %%\n";
   }
}

1;
