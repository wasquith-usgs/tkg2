#!/usr/bin/perl -w
use strict;
use Tk 804.026;
use Getopt::Long qw(:config no_ignore_case);

=head1 NAME

tkg2.pl - The ultimate 2-D charting application.

=head1 LICENSE

 This Tkg2 program is authored by the enigmatic William H. Asquith.
     
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

## CVS STAMPS are present in every module and look like the following
# $Author: wasquith $
# $Date: 2011/04/11 17:18:41 $
# $Revision: 1.194 $

######## BEGIN BLOCK 1 ########
# The first begin block is used largely to get an immediate time stamp
# and to get the location of the distribution on the @INC.
BEGIN {
   # Die if the real/effective or user/group ids are zero . . .
   die "Tkg2: Should not be run by root because ",
        "of security concerns involving the necessary",
        "but few uses of the 'eval' function.\n"
        if((not $< or not $>) and $^O !~ /MSWin/o);
   select((select(STDOUT),$|=0)[0]); # turn autobuffering off
   use vars qw($TIME0 $TIME1);
   use Benchmark;
   $TIME0 = new Benchmark;

   # tkg2 permits the display to be set immediately, if and only if
   # the -display is the first argument.  The other commandline options
   # require processing AFTER the MainWindow is created, which can NOT
   # be done without a valid display.
   if(@ARGV and $ARGV[0] =~ m/^-?-DISPLAY=(.+)$/io ) {
      my $display = $1;
      # the following is to make the typical display values optional
      $display .= ":0.0" if($display !~ m/:\d\.\d$/o);
      shift(@ARGV);  # remove it from the argument list for
      # later processing
      $ENV{DISPLAY} = $display;
   }


   use vars qw(%TKG2_ENV);

   # The global tkg2 environmental settings
   %TKG2_ENV = ( -XRESOLUTION    => undef,
                 -YRESOLUTION    => undef,
                 -TKG2HOME       => undef,
                 -USERHOME       => undef,
                 -MEGACMD_FILES    => [ ],
                 -MEGACMD_BASENAME => "tkg2_megacommand_file_",
                 -INPUT_RECORD_SEPARATOR => "\n",
                 -LOGFILE        => '/tmp/tkg2.log',
                 -BUGFILE        => '/tmp/tkg2.bugs',
                 -HOME           => $ENV{HOME},
                 -DISPLAY        => $ENV{DISPLAY},
                 -PAGER          => $ENV{PAGER},
                 -SCALING        => 1,
                 -ORIGINAL_SCALING => 1,
                 -EXECUTABLE     => $0,
                 -OSNAME         => $^O,
                 -PRINTER_QUEUE  => 0,
                 -COMMANDLINE    => [ @ARGV ],
                 -SAFE_KEEPING_FOR_TKG2_FILE_HEADINGS => { },
                 -RC_FILES       => { -DISTRIBUTION => "not read",
                                      -SYSTEM       => "not read",
                                      -USER         => "not read" },
                 -UTILITIES => {
                      -TKPSFIX_EXEC   => undef,
                      -PS2PNG_EXEC    => undef,
                      -PSTOEDIT_EXEC  => undef,
                      -PDFVIEWER_EXEC => undef,
                      -PNGVIEWER_EXEC => undef,
                      -PSVIEWER_EXEC  => undef,
                      -TKMIFFIX_EXEC  => undef,
                      -BYPASS_PSFIX   => 0,
                      -BYPASS_MIFFIX  => 0, }
               );
   
   $::TKG2_ENV{-DEFAULT_PRINTER} = (defined $ENV{LPDEST} ) ? $ENV{LPDEST}  :
                                   (defined $ENV{PRINTER}) ? $ENV{PRINTER} :
                                     undef;
   $::TKG2_ENV{-PRINTER_QUEUE}   = (defined $ENV{PRINTER_QUEUE}) ?
                                            $ENV{PRINTER_QUEUE} : 0;
   
   
   use Sys::Hostname;
   $::TKG2_ENV{-HOST} = &hostname;
                           
   use Cwd;  # need the &cwd to determine which user directory tkg2 was launched
   $::TKG2_ENV{-USERHOME} = &cwd;
   use File::Basename;  # need the &dirname function
   
   #### FIND THE PATH TO THE TKG2 DISTRIBUTION ####
   
   # The following two commented operations on TKG2HOME are for Asquith only
   # on his home machines in Austin--just ignore
   # for non rpm installation just remove the comment on the following line
   # you will have to create your own soft link
   # The development root installation looks like this:
   # /usr/opt/Asqplot/Tkg2/
   # /usr/opt/bin/asqplot -> /usr/opt/Asqplot/Tkg2/tkg2.asqplot
   # to install along root PATH
   # REMOVE COMMENT FOR DEVELOPMENT INSTALLATION $::TKG2_ENV{-TKG2HOME} = '/usr/opt/Asqplot';  
   # REMOVE COMMENT FOR BLEEDING EDGE INSTALLATION $::TKG2_ENV{-TKG2HOME} = '/usr/opt/G2';

   # The following line is for the official RPM version, although the distribution
   # location can still be overriden by the TKG2LIB environment variable.
   # to install along root PATH 
   # The following is THE PREFERED PATH FOR site installation
   # REMOVE COMMENT FOR DAVID BOLDT RPM $::TKG2_ENV{-TKG2HOME} = '/usr/local';
       
   # If the home is still unknown, then try the TKG2LIB environment variable
   if(not defined $::TKG2_ENV{-TKG2HOME} ) {
      # The default is usually '.' from &dirname, but not always
      $::TKG2_ENV{-TKG2HOME} =
         ( defined $ENV{TKG2LIB} ) ? $ENV{TKG2LIB} : &dirname($0); 
   }
   
   # unshift whatever the Tkg2 location onto the @INC array
   pop(@INC); # REMOVE DEFAULT '.' FROM THE PATH
   unshift(@INC, $::TKG2_ENV{-TKG2HOME});
   unshift(@INC, 'H:\tkg2') if($^O =~ /MSWin/o); # EXPERIMENTAL FOR WINDOWS
  
   # Now that the @INC array likely is pointing to a path containing the
   # Tkg2 distribution, lets see if we can use one of the module
   # Tkg2::TestLoading is a completely empty module that is just used
   # to see whether the eval will work.
   unless(eval "require Tkg2::TestLoading") {
      print STDERR "Tkg2-Fatal Error:\n",
                      "Tkg2 can not find its libraries along the paths in \@INC.\n";
      map { print STDERR "    $_\n" } @INC;
      print STDERR "  DO NOT BE TOO CONCERNED, THIS IS AN EASY FIX.\n",
                   "  Please contact wasquith\@usgs.gov\n";
      exit;
   }

   # External Utilities
   # Now that the HOME is determined for tkg2, lets set the executable path
   # for the utilities.
   if($::TKG2_ENV{-OSNAME} eq 'solaris' or
      $::TKG2_ENV{-OSNAME} eq 'linux'   or
      $::TKG2_ENV{-OSNAME} eq 'darwin' ) {
      my $util = \$::TKG2_ENV{-UTILITIES};
      $$util->{-TKPSFIX_EXEC}   =       "$::TKG2_ENV{-TKG2HOME}/Tkg2/Util/tkpsfix.pl"
                                  if(-x "$::TKG2_ENV{-TKG2HOME}/Tkg2/Util/tkpsfix.pl");
      
      $$util->{-TKMIFFIX_EXEC}  =       "$::TKG2_ENV{-TKG2HOME}/Tkg2/Util/tkmiffix.pl"
                                  if(-x "$::TKG2_ENV{-TKG2HOME}/Tkg2/Util/tkmiffix.pl");

      # Try to find the executables along /usr/local/bin first as this seems to be
      # a more common unix convention, certainly Linux, but some solaris installations
      # seem to just have /usr/opt/bin and do no link /usr/local/bin to /usr/opt/bin
      # or maybe the -x test fails on a link to an executable?
      $$util->{-PSTOEDIT_EXEC}  = (-x "/usr/local/bin/pstoedit") ?
                                      "/usr/local/bin/pstoedit"  :
                                  (-x "/usr/opt/bin/pstoedit")   ?
                                      "/usr/opt/bin/pstoedit"    : "pstoedit";
                                  
      $$util->{-PNGVIEWER_EXEC} = (-x "/usr/local/bin/rpng")     ?
                                      "/usr/local/bin/rpng"      :
                                  (-x "/usr/opt/bin/rpng")       ?
                                      "/usr/opt/bin/rpng"        : "rpng";
                                  
      $$util->{-PDFVIEWER_EXEC} = (-x "/usr/local/bin/acroread") ?
                                      "/usr/local/bin/acroread"  :
                                  (-x "/usr/opt/bin/acroread")   ?
                                      "/usr/opt/bin/acroread"    : "xpdf";   
                                  
      $$util->{-PSVIEWER_EXEC}  = (-x "/usr/bin/gs")      ?
                                      "/usr/bin/gs"       :
                                  (-x "/usr/opt/bin/gs")  ? 
                                      "/usr/opt/bin/gs"   : "gs";
                                  
   }
   # End of the External Utilities
}
######## END BLOCK 1 ########



######## BEGIN BLOCK 2 ########
# Set up the tkg2 configuration, check that DISPLAY is set, and build
# the MainWindow in which all other Tkg2 graphics will be children of.
BEGIN {   
   # Global variables to hold command line options, user tkg2 configuration
   # and references to dialog boxes.  %DIALOG is used to determine whether
   # a particular dialog box is open, if so then each subroutine controlling
   # that dialog box destroys it first before recreating.  Thus, only one
   # dialog box of a certain type can be open at the same time.
   # Also, %DIALOG holds stuff the user selects on the canvas such as plots, 
   # and annotation objects.
   use vars qw(%CMDLINEOPTS %TKG2_CONFIG %DIALOG);
   use vars qw($MESSAGE $VERBOSE $BUG $SPLASH $MP); # FILEHANDLES
   use vars qw($VERSION);
               $VERSION = '1.5-1';
               
   # The last of the Global variables
   use vars qw($MW @UNDO);
   # M_ain W_indow and the UNDO array holding arrays for each template
   
   # The CONFIG hash holds various configuration parameters and constants
   # Often tkg2 looks at this hash for default behaviors.  The comments below
   # the __END__ token in this module provides description of each key.
   # These parameters will all eventually by controlled by the tkg2rc file,
   # but at the present time (12/9/99) the Tkg2rc.pm module only reads
   # a few of them.
   %TKG2_CONFIG = ( -COLORS             => [],
                    -LINETHICKNESS      => [],
                    -PRINTERS           => [],
                    -DELIMITERS         => [],
                    -FILEFORMAT         => 'DataDumper',
                    -FONTS              => [],
                    -DIALOG_FONTS       => { -smallB  => "Fixed  9 normal",
                                             -mediumB => "Fixed 10 normal",
                                             -largeB  => "Fixed 11 normal",
                                             -small   => "Fixed  9 normal",
                                             -medium  => "Fixed 10 normal",
                                             -large   => "Fixed 11 normal" },
                    -VERSION            => $::VERSION,
                    -BUILDDATE          => 'INSERT LOCALTIME RESULT',
                    -OWNER              => 'William H. Asquith',
                    -DEBUG              => 0,
                    -SPLASH             => 1,
                    -DELETE_LOADED_DATA => 1,
                    -EXTENDED_WARNINGS  => 0,
                    -DATA_DUMPER_INDENT => 1,
                    -REDRAWDATA         => 1,
                    -SHOWME             => 0,
                    -VERBOSE            => 0,
                    -INCREMENT_DIALOG_FONTS => 0,
                    -ZOOM               => 1,
		    -NOZOOM2UNITY       => 0,
                    -WM_OVERRIDE_POD_GEOMETRY => 0,
                    -GEOMETRY           => undef,
                    -MONITORSIZE        => undef,
                    
                    -RC_SCALING         => undef,
                    
                    -FORCE_PAGE_WIDTH   => undef,
                    -FORCE_PAGE_HEIGHT  => undef,
                    
                    -QUEUE_OPTIONS      => "",
                    
                    -BACKCOLOR          => "#007B71",
                    -FORECOLOR          => "white",
                    
                    -PLOTTING_POSITION_COEFFICIENT => 0.40,
                    
                    -LOG_BASE_MAJOR_TICKS  => [ qw(1 2 3 4 5 6 7 8 9) ],
                    
                    -LOG_BASE_MAJOR_LABEL  => [ qw(1 2 3 4 5 6 8) ],
                    
                    -LOG_BASE_MINOR_TICKS  => [ qw(1.1 1.2 1.3 1.4 1.5
                                                   1.6 1.7 1.8 1.9
                                                   2.2 2.4 2.6 2.8
                                                   3.2 3.4 3.6 3.8
                                                   4.2 4.4 4.6 4.8
                                                   5.5 6.5 7.5 8.5) ],
                                                   
                    
                    -PROB_BASE_MAJOR_TICKS => [ qw(.001 .005 .01 .02 .05
                                                   .10  .15  .20 .30 .40
                                                   .50  .60  .70 .80 .85
                                                   .90  .95  .98 .99 .995
                                                   .999) ],
                    -PROB_BASE_MAJOR_LABEL => [ qw(.001 .005 .01 .02 .05
                                                   .10  .15  .20 .30 .40
                                                   .50  .60  .70 .80 .85
                                                   .90  .95  .98 .99 .995
                                                   .999) ],
                                                   
                    -PROB_BASE_MINOR_TICKS => [ qw( ) ],
                    
                    -DEFAULT_BOXPLOT_MOMENT_CALC_METHOD    => 'product',  
                    -DEFAULT_BOXPLOT_TRANSFORMATION_METHOD => 'linear');
                 
                 
   # %::DIALOG is the storage facility for references to dialog box
   # Tk Toplevels, the tkg2 clip board.  By tracking each dialog box
   # using a global variable in this fashion ensures that there is only one
   # copy of a dialog box open at a time even if there are more than one
   # template open.
   map { $::DIALOG{$_} = ""; } ( qw(-SELECTEDPLOT
                                    -SELECTEDEXPLANATION
                                    -CLIPBOARDPLOT
                                    -SELECTEDANNO
                                    -NWISEDITOR
                                    -ROUTEDATA2SCRIPT
                                    -SOURCECODEVIEWER ) );

   #   use Tk::Event;      # needed for Tk800.015? on NT
   #   use Tk::DialogBox;  # needed for Tk800.015? on NT

   # These two uses on Tkg2::** are done because, we need
   # the Read_tkg2rc_file and the isDISPLAYset methods
   # immediately.  The remain Tkg2::** packages are 
   # read after the command line options are loaded

 
   # Working on building %TKG2_CONFIG
   use Tkg2::Tkg2rc  qw(Read_tkg2rc_file);
   &Read_tkg2rc_file();  # READ IN SYSTEM SPECIFIC PARAMETERS 
   
   use Tkg2::Base qw(isDISPLAYset 
                     ResolutionHandler);
   &isDISPLAYset(\%TKG2_ENV); # check that the tkg2 display is set
   
   my $title = "Tkg2 $::TKG2_CONFIG{-VERSION}, ".
               "$::TKG2_ENV{-HOST} as $$";  # the title to show in MW
   
   # By wrapping an eval{} around the MainWindow construction, we trap
   # for exceptions thrown in case a connection to and X server could
   # not be made, although the display (tested just above) could
   # have been set.
   eval {
      $MW = MainWindow->new(-title => $title);
   };
   if($@) {
      print STDERR "#########################################\n".
                   "Tkg2: X-server Connection Error\n   $@\n".
                   "  % xhost +'your server name'\n".
                   "on your client will likely fix things\n".
                   "#########################################\n";
      exit;
   }
  
   # Developer warning: A segmentation fault occurs if the Bitmaps can not be
   # found or are invalid.  Extremely hard to debug, but fortunately, easy
   # to fix.
   my $tkg2xbm = ($::TKG2_ENV{-OSNAME} =~ /MSWin/o) ?
                 "Bitmaps/tkg2.xbm" : 
                 "$::TKG2_ENV{-TKG2HOME}/Tkg2/Bitmaps/tkg2.xbm";
   if(-e $tkg2xbm) {
      $::MW->iconbitmap("@".$tkg2xbm); #" load icon bitmap
   }
   else {
      print STDERR "Tkg2-warning: could not find the tkg2.xbm bitmap\n";
   }
   
   $::MW->withdraw;           # hide it for now
   $::MW->geometry("-20+0");  # upper right corner
   
   $::TKG2_ENV{-XRESOLUTION}      = $::MW->screenwidth;
   $::TKG2_ENV{-YRESOLUTION}      = $::MW->screenheight;
   $::TKG2_ENV{-ORIGINAL_SCALING} = $::MW->scaling;
   $::TKG2_ENV{-SCALING} = $::TKG2_ENV{-ORIGINAL_SCALING};
  
   # Currently turned on command line options
   # Here is an array showing what the symbols mean
   # ! Options does not take an argument and can be negated by
   # prefixing no.  For example, --nobatch sets batch to false.
   # =s Mandatory string argument
   # :s Optional string argument
   # =f Mandatory real argument
   # :f Optional real argument
   # =i Mandatory integer argument
   # :i Optional integer argument
   my @options = qw ( autoexit:i
   
                      batch!
                      batchsave
                      
                      checkcolors
                      clear
                      colormode=s
                      cycle=i
                      
                      debug=s
                      destination=s
                      
                      drawdata!
                      
                      dumpboxes
                      
                      echocommandline
                      exportfile=s
                      exportfilev=s
                      exportrotate=s
                      exportview:i
                      
                      format=s
                      
                      geometry=s
                      glob:s
                      
                      height=f
                      help!
                      home=s
                      
                      importdata!
                      
                      inst=s@
                      instv=s@
                      instb4data
                      
                      justdisplay
                      justdisplayone
                      
                      mkplot=s@
                      mktemp=s
                      megacmd_args=s
                      megacmd_show
                      megacmd_keep
                      message=s
                      
                      nobind
                      nodec
                      nodialogrescale
                      noexport
                      nofieldcheck
                      nomenus
                      nomw
                      noprint
                      norulers
                      nosave
                      noundo
                      nozoom2unity
		      
                      optimize
                      
                      pause=i
                      presenter
                      presenterlabels=s
                      presentercolumns=i
                      presentersort
                      printer_queue=s
                      
                      readonly
                      redoinst
                      redodata
                      
                      scaling=s
                      showme=f
                      showmesubs
                      splash!
                      stdin
                      stdout
                      
                      test=i
                      time_cache_delete
                      time_cache_ignore
                      time_cache_nosave
                      time_cache_view 
                      
                      verbose!
                      version
                      v
                      V
                      
                      viewconfig
                      
                      walkatree:s
                      width=f
                      withdraw
                      withdrawmw
                      
                      zoom=f
                    ); # these are the valid command line options
   &GetOptions(\%::CMDLINEOPTS, @options); # parse the command line options
      
   # Turn the verbose on if the verbose instructions are requested
   # This is meant to shorten the length of the command line somewhat.
   $::CMDLINEOPTS{'verbose'} = 1 if($::CMDLINEOPTS{'instv'});
   
   # Perform a substitution on the underline symbol with a space when
   # present in the message string.  This permits easier shell and perl
   # handling on the command line as spaces are the usual option delimiters
   $::CMDLINEOPTS{'message'} =~ s/_/ /og if($::CMDLINEOPTS{'message'});
   
   # Set the zoom configuration--mainly for font control on very large
   # or very small rescaling/resizing of page sizes
   $::TKG2_CONFIG{-ZOOM} = $::CMDLINEOPTS{'zoom'} if($::CMDLINEOPTS{'zoom'});
   $::TKG2_CONFIG{-NOZOOM2UNITY} = $::CMDLINEOPTS{'nozoom2unity'}
                                   if($::CMDLINEOPTS{'nozoom2unity'}); 
   
   # If --readonly is present, turn on each of the 'output' oriented
   # features: --noexport, --onprint, and --nosave
   $::CMDLINEOPTS{'noexport'} =
   $::CMDLINEOPTS{'noprint'}  =
   $::CMDLINEOPTS{'nosave'}   = 1 if($::CMDLINEOPTS{'readonly'});
   
   # If the -SHOWME configuration is true, set the command line option
   # to trigger the show me internals subroutine
   # it would be better if the configuration would trigger the showme
   # instead of the command line options.  Perhaps I will fix this 
   # some time
   $::CMDLINEOPTS{'showme'} = $::TKG2_CONFIG{-SHOWME}
                           if($::TKG2_CONFIG{-SHOWME});
   
   # Reset the -PRINTER_QUEUE environment if specified on the command line
   $::TKG2_ENV{-PRINTER_QUEUE} =
      $::CMDLINEOPTS{'printer_queue'} if($::CMDLINEOPTS{'printer_queue'} );

   # MESSAGE is a guaranteed filehandle opened to .tkg2message in the user
   # home space
   $MESSAGE = &routeMESSAGE();
   
   # Adjust the scaling factor for different screen resolutions
   # a feature that was far to long in coming given how easy
   # it was
   &ResolutionHandler(\%::CMDLINEOPTS,\%TKG2_CONFIG,\%TKG2_ENV);
   
   # Show the growing trail of '=' along STDERR
   $::TKG2_CONFIG{-SPLASH} = $::CMDLINEOPTS{'splash'}
                 if( defined $::CMDLINEOPTS{'splash'});
   $::SPLASH = &routeSPLASH($::TKG2_CONFIG{-SPLASH});
   
  
   sub routeMESSAGE {
      my $file   = $::TKG2_ENV{-HOME}."/.tkg2message";
      local *MESSAGE;
      
      # Open the file, but if for whatever reason you can't
      # then throw the message away.  This is a safety feature
      # in that tkg2 will stop executing is MESSAGE remains
      # undefined.
      open(MESSAGE, ">$file") or open(MESSAGE, ">/dev/null");
      
      # set up and write the header
      my $time = scalar(localtime);
      print MESSAGE "Tkg2 Version $::TKG2_CONFIG{-VERSION} ",
                        "built on $::TKG2_CONFIG{-BUILDDATE}\n";
      print MESSAGE "Tkg2 launched on $time.\n\n";
      return *MESSAGE;  
   }


   sub routeSPLASH {
      my $splashON = shift;
      
      my $null      = ">/dev/null";
      my $stdout    = ">&STDERR";#">/dev/stderr";
      my $file = ($splashON) ? $stdout  : $null;
   
      local *SPLASH;
      open(SPLASH, $file) or
         do {
             print STDERR "Tkg2 Error--SPLASH not opened ",
                          "as $file because $!\n";
             return;
            };
      # yes, the dubious quest for compact code continues
      select((select(SPLASH), $| = 1)[0]); # turn autobuffering off
      return *SPLASH;  
   }
}
######## END BEGIN BLOCK 2 ########
   
   
   
   
######## AND AWAY WE GO   
   use Tkg2::Base qw(pixel_to_inch
                     inch_to_pixel
                     Message
                     DeepClone
                     Show_Me_Internals
                     Begin_Log_File
                     routeVERBOSE
                     routeBUG
                     routeMetaPost);


   use Tkg2::TemplateUtilities qw(StartTemplate
                                  DataOnTheFly
                                  UpdateCanvas
                                  NeedSaving
                                  AddPlot
                                  AddAnno
                                  snap_to_grid
                                  Dump
                                  Dump2Stdout);
                                  
   use Tkg2::RescaleTemplate   qw(rescaleTemplate);
   
   use Tkg2::MenusRulersScrolls::Loader qw(TemplateFullMenus
                                           TemplateDisplayMenus
                                           Rulers
                                           buildScrollBars
                                           configureScrollBars);
   
   use Tkg2::Plot::Plot2D;
   use Tkg2::Plot::Movements::DraggingPlot;
   
   use Tkg2::DeskTop::Activities qw(Batch
                                    Open
                                    Print
                                    Tkg2Export Tkg2MetaPost
                                    Save
                                    SaveAs
                                    ProcessOptions
                                    DeleteLoadedData
                                    Exit
                                    TotalExit
                                    CreateTemplate
                                    StoreUndo
                                    Undo
                                    RemoveUndo
                                    SelectPlotScale );
   use Tkg2::DeskTop::Instructions;
    
   
   use Tkg2::Anno::Text;
   use Tkg2::Anno::Box;
   use Tkg2::Anno::Line;
   use Tkg2::Anno::Symbol;
   use Tkg2::Anno::QQLine;
   use Tkg2::Anno::ReferenceLines;
   use Tkg2::Anno::SelectAnno qw(SelectAnno);
   
   use Tkg2::Help::Help;
   use Tkg2::Help::ViewENV qw(ViewENV);
   

   # VERBOSE is a single file handle that is either directed to
   # /dev/stdout or /dev/null depending on the value of verbose
   $VERBOSE = &routeVERBOSE( $::CMDLINEOPTS{verbose} );
   
   # BUG is a single file handle that is either directed to 
   # /dev/stdout or /dev/null or /tmp/tkg2.bugs
   $BUG = &routeBUG( $::CMDLINEOPTS{'debug'}, $::TKG2_CONFIG{-DEBUG} );

   $MP = &routeMetaPost(); # MetaPost--opening filehandle to NULL
   
   &Begin_Log_File( \%::CMDLINEOPTS, \@::ARGV );  
   
   # process the command line options            
   &ProcessOptions( \%::CMDLINEOPTS, \@::ARGV ); 
   
   &MainDialog($::MW);     # build the classic first dialog of an application
   $::MW->resizable(0,0);  # disable resizing of mainwindow
   # Hide the mainwindow dialog if either of these command line options
   # is given.  Cool idea that did not get added until surprizing late (09/2001)
   $::MW->withdraw if( $::CMDLINEOPTS{'withdrawmw'} or $::CMDLINEOPTS{'nomw'});
   
   &MainLoop;  # LAUNCH THE TK EVENT LISTENER, AMONG MANY OTHER THINGS
   
# when the Main Window is destroyed, the the MainLoop is exited and any code following
# MainLoop starts processing.  In this case we exit.  A segmentation fault develops if an exit is
# called outside package main and the Main Window Tk::Exists, unless a use Tk;
# in the exit'ing package is done because Tk overloads the usual perl exit 
# function.

## END OF THE MAIN PROGRAM







## BEGIN THE SUBROUTINES

sub MainDialog {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my $tw = shift;
   
   # Do not show main dialog if justdisplayone or presenter options are set
   # the TemplateDisplayMenu provides the exit method
   return 0 if($::CMDLINEOPTS{'justdisplayone'} or
               $::CMDLINEOPTS{'presenter'}      or
               $::CMDLINEOPTS{'withdraw'} );

   my @p = ( -side   => 'left',
             -expand => 1,
             -padx   => 1,
             -pady   => 1);
             
   my @b = ( -height     => 2,
             -font       => $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB},
             -background => $::TKG2_CONFIG{-BACKCOLOR},
             -foreground => $::TKG2_CONFIG{-FORECOLOR});
   
   $tw->deiconify;  # The button was withdrawn just after creation
   
   # Only a show an exit button
   if($::CMDLINEOPTS{'justdisplay'}) { 
      $tw->OnDestroy( sub { exit; } );
      $tw->Button(-text    => 'Total Exit from Tkg2 Displayer',
                  -width   => 50,
                  -command => sub { $tw->destroy }, @b )
         ->pack(@p);
   }
   else { # Regular startup
      $tw->OnDestroy( sub { exit; } );
      $tw->Button(-text    => 'New', @b,
                  -command => [ \&CreateTemplate ])
         ->pack(@p);
      
      $tw->Button(-text    => "Open\nTkg2 File", @b,
                  -command => [ \&Open, $tw ])
         ->pack(@p);
                         
      $tw->Button(-text    => "View\nENV", @b,
                  -command => [ \&ViewENV, $tw ])
         ->pack(@p);
              
      $tw->Button(-text    => 'Exit', @b,
                  -command => [ \&TotalExit ])
         ->pack(@p);

      $tw->Button(-text    => "Intro", @b,
                  -command => [ \&Help, $tw, 'main.pod' ])
         ->pack(@p);

      $tw->Button(-text    => "New for\n$::TKG2_CONFIG{-VERSION}", @b,
                  -command => [ \&Help, $tw, 'NewFor.pod' ])
         ->pack(@p);

   }
   return 1;                     
}  

1;

__END__
Further comments on the configuration parameters:
-COLORS            => [],
# array reference of 'valid' color names.  qw(black white etc).  Valid is an
# interesting issue as the system hosting tkg2 could have different color
# names than the client.  I do not see a good work around yet.  The
# --checkcolors command line options should identify any problems.
-LINETHICKNESS     => [],
# array reference of suitable linethicknesses qw(0.05i 0.15i etc) in inches.
# testing has indicated that the postscript driver in tk can only resolve
# certain differences between lines.  I have selected only those thicknesses
# that show up as different on several of my laser printers and decided on using
# a menubutton to hold the suitable line thicknesses
-PRINTERS    => [],
# array reference of printers that are considered local, say in the same office
-DELIMITERS        => [],
# array reference of the built-in file delimiters such as space, tab, comma
-FILEFORMAT        => 'DataDumper',
# the default file format that tkg2 will save files in
-FONTS             => [],
# do not remember
-DIALOG_FONTS      => { -smallB  => "Courier  9 bold",
                        -mediumB => "Courier 10 bold",
                        -largeB  => "Courier 11 bold",
                        -small   => "Courier  9 normal",
                        -medium  => "Courier 10 normal",
                        -large   => "Courier 11 normal" },
# array reference of font that are only used in dialog boxes, courier was
# chosen because of fixed width and availablity on all systems.  Plus, since
# I exclusively use ->pack to display widgets a fix font greatly enhances
# alignment.
-VERSION           => $::VERSION,
# what tkg2 version to advertise
-BUILDDATE         => 'INSERT LOCALTIME RESULT',
# the build data or installation date of the current tkg2
-OWNER             => 'William H. Asquith',
# namespace presevation!
-DEBUG             => 0,
# true/false to turn internal tkg2 debugging on an off
-EXTENDED_WARNINGS => 0,
# true/false to show extended warnings.  Eventually this will be used to 
# provide a warning mechanism when data can not be plotted for reasons such
# as log(<=0) or prob(<=0 or >=1).  The flag will try to handle surprizes to
# some users.
-REDRAWDATA        => 1,
# true/false: with each call of $template->UpdateCanvas is the data going
# to be displayed      
-PLOTTING_POSITION_COEFFICIENT => 0.40,
# the plotting position coe. used in the general plotting position formula
#  qi = i - a / ( n + 1 - 2*a), where a is the coe.  See a stats book                    
-LOG_BASE_MAJOR_TICKS  => [ qw(1 2 3 4 5 6 7 8 9) ],
# the default 'major' cycles to tick, remember log in power of ten
# I have an AxisConfiguration.pm module that will reset these limits to
# try to achieve a better visual balance.                
-LOG_BASE_MAJOR_LABEL  => [ qw(1 2 3 4 5 6 8) ],
# same as above, but these are the ticks to label
-LOG_BASE_MINOR_TICKS  => [ qw(1.1 1.2 1.3 1.4
                               1.6 1.7 1.8 1.9
                               2.2 2.4 2.6 2.8
                               3.2 3.4 3.6 3.8
                               4.2 4.4 4.6 4.8
                               5.5 6.5 7.5 8.5) ],
# which sub cycles are to be ticked                                                   
-PROB_BASE_MAJOR_TICKS => [ qw(.001 .005 .01 .02 .05
                               .10  .15  .20 .30 .40
                               .50  .60  .70 .80 .85
                               .90  .95  .98 .99 .995
                               .999) ],
# basically the same as the log_base_major_label, not how tkg2 has infinite resolutation
# in how it ticks and labels a probability axis!
-PROB_BASE_MAJOR_LABEL => [ qw(.001 .005 .01 .02 .05
                               .10  .15  .20 .30 .40
                               .50  .60  .70 .80 .85
                               .90  .95  .98 .99 .995
                               .999) ],
# again similar to the log scale labeling array    
-PROB_BASE_MINOR_TICKS => [ qw( ) ]
