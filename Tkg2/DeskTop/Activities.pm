package Tkg2::DeskTop::Activities;

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
# $Date: 2008/05/05 14:44:50 $
# $Revision: 1.61 $

use strict;
use Benchmark;

use Tkg2::DataMethods::Class::MegaCommand qw(DeleteMegaCommandFiles);

use Tkg2::DeskTop::Printing         qw(Print Tkg2Export Tkg2MetaPost);
use Tkg2::DeskTop::OpenSave         qw(Open Save SaveAs);
use Tkg2::DeskTop::Batch            qw(Batch DeleteLoadedData);
use Tkg2::DeskTop::Exit             qw(Exit TotalExit);
use Tkg2::DeskTop::CreateTemplate   qw(CreateTemplate CreateTemplateOnTheFly);
use Tkg2::DeskTop::Undo             qw(StoreUndo Undo RemoveUndo);
use Tkg2::DeskTop::Presenter        qw(Presenter);
use Tkg2::DeskTop::SelectScales     qw(SelectPlotScale);

use Tkg2::Help::Help;
use Tkg2::Help::CmdLineHelp qw(commandLineHelp);

use Tkg2::Time::TimeMethods         qw(OpenTimeCache SaveTimeCache);

use File::Basename;
use Cwd;
use File::Find;

use Exporter;
use SelfLoader;
use vars     qw( @ISA @EXPORT_OK );
@ISA       = qw( Exporter SelfLoader);
@EXPORT_OK = qw( Batch
                 CreateTemplate
                 DeleteLoadedData
                 Exit
                 Open
                 Print
                 ProcessOptions
                 Save
                 SaveAs
                 SelectPlotScale
                 StoreUndo
                 TotalExit
                 Tkg2Export Tkg2MetaPost
                 Undo
                 RemoveUndo
               );
 
print $::SPLASH "=";
             
sub ProcessOptions {
   my $options = shift;     # hash reference containing the commandline opts
   my @args = @{ shift() }; # basically tkg2 file names
     
   my %options = %$options; # dereference the command line opts hash

   system("clear") if($options{'clear'});

   $::TKG2_CONFIG{-DEBUG}      = $options{'debug'}
                                    if( defined $options{'debug'} );
   $::TKG2_CONFIG{-REDRAWDATA} = $options{'drawdata'}
                                    if( defined $options{'drawdata'} );
   $::TKG2_CONFIG{-DELETE_LOADED_DATA} = not $options{'importdata'}
                                    if( defined $options{'importdata'});
  
   # lumped options when --optimize
   $::CMDLINEOPTS{'nofieldcheck'} = 
   $::CMDLINEOPTS{'norulers'}     =
   $::CMDLINEOPTS{'noundo'}       = 1 if($options{'optimize'});

   # lumped options when --nomenus
   $::CMDLINEOPTS{'noundo'} =
   $::CMDLINEOPTS{'nobind'} = 1 if($options{'nomenus'});

   # if the binds have been shut off, lets default to --presenter
   # if none of the display only modes are toggled
   if(    $::CMDLINEOPTS{'nobind'}      and
      not $::CMDLINEOPTS{'justdisplay'} and
      not $::CMDLINEOPTS{'justdisplayone'}  ) {
      $options{'presenter'} = $::CMDLINEOPTS{'presenter'} = 1;
   }

   # if the --presenterlabels option has been provided and the 
   # --presenter option left off, lets toggle it on
   $options{'presenter'} = $::CMDLINEOPTS{'presenter'} = 1
                                  if($::CMDLINEOPTS{'presenterlabels'});

   # COMMAND_LINE_OPTION_ROUTER
   my %option_router   = (
      -help            =>
         sub { &commandLineHelp(\@args) },
      -checkcolors     =>
         sub { &_reallyCheckColorsWithTk($::MW) },
      -viewconfig      =>
         sub { &_showConfiguration(\%::TKG2_ENV, \%::TKG2_CONFIG) },
      -echocommandline =>
         sub { &_showCommandLine(\%::TKG2_ENV) },
      -version         =>
         sub { &_showVersion(\%::TKG2_CONFIG) },
      -presenter       =>
         sub { &Presenter(\@args) },
      -home            =>
         sub { &_changeHomeDir($options{'home'}) },
      -geometry        =>
         sub { &_setGeometry($options{'geometry'}, \%::TKG2_CONFIG) },
      -glob            =>
         sub { &_globFiles($options{'glob'},\@args) },
      -recursiveglob   =>
         sub { &_recursiveGlob($options{'walkatree'}, $options{'glob'}, \@args) },
      );
   
   # Time Caching routing, see OpenTimeCache in Tkg2::Time::TimeMethods for more details
   my @method = (exists $options{'time_cache_delete'} ) ? ('delete') :
                (exists $options{'time_cache_ignore'} ) ? ('ignore') :
                (exists $options{'time_cache_view'  } ) ? ('retrieve','view') :
                'retrieve';
   my $cacherr = &OpenTimeCache(@method);
   print STDERR "Tkg2--Warn: $cacherr\n" if($cacherr);
   
   # Glob and Walkatree take optional string arguments, if no string supplied
   # the set default pattern matching behavior or default directory.  Walkatree
   # can be specified by itself and if so then glob is set to the default behavior
   $options{'glob'}      = '.tkg2$' if( exists($options{'glob'})  and
                                               $options{'glob'} eq "");
   if( exists($options{'walkatree'}) and $options{'walkatree'} eq "" ) {
      $options{'walkatree'} = '.';
      $options{'glob'}   = '.tkg2$' unless($options{'glob'});
   }
   
   &{ $option_router{-help}        }     if( $options{'help'}            );
   &{ $option_router{-echocommandline} } if( $options{'echocommandline'} );
   &{ $option_router{-viewconfig}  }     if( $options{'viewconfig'}      );
   &{ $option_router{-checkcolors} }     if( $options{'checkcolors'}     );
   &{ $option_router{-version}     }     if( $options{'version'} or
                                             $options{'v'} or $options{'V'}
                                           );   
   &{ $option_router{-home}        }     if( $options{'home'}            );
   &{ $option_router{-geometry}    }     if( $options{'geometry'}        );

   if( $options{'glob'} and not exists( $options{'walkatree'} ) ) { 
       @args = &{ $option_router{-glob} };
   }
   if( $options{'walkatree'} ) { @args = &{ $option_router{-recursiveglob} }; }
   
   if( $options{'presenter'} ) {
     &{ $option_router{-presenter} };
     return;
   }
   
   # the test command line option is just a switch that sets up
   # the looping based on --cycle and performs an autoexit
   if( $options{'test'} ) { 
      my $loops = ( $options{'cycle'} ) ? $options{'cycle'} : 1;
      foreach (1..$loops) {
         foreach my $tkg2 (@args) {
            my ($canv, $tw, $template) = &Open($::MW, $tkg2);
            sleep($options{'test'});
            $template->Exit($canv, $tw, 'exit without message');
         }
      }
      exit;
   }
                 
   # Set up the color mode for error free operation              
   my $colormode = 'use_colormode_for_template'; # default
      $colormode = $options{'colormode'} if( defined $options{'colormode'} );
      $colormode = 'color' unless($colormode eq 'mono'  or
                                  $colormode eq 'grey');
                                  
   # make sure that the batch mode is turned on if a destination is explicitly shown on 
   # the command line
   if( $options{'destination'} or $options{'format'} or $options{'exportfile'} ) {
      $options{'batch'} = 1; # turn batch on for this subroutine
      # Because --format TRUE will trigger autoexit operations, we need to
      # also toggle the true --batch TRUE through the dereferencing mechanism
      # here, this prevents tons of memory dealloc errors along standard error.
      # FIX: WHA 05/05/2008 
      $options->{'batch'} = 1 if($options{'format'});
   }
   
   my $printer = ( defined $options{'destination'} ) ? $options{'destination'}        :
                                                       $::TKG2_CONFIG{-PRINTERS}->[0] ;  
   $printer = 0 if(not defined $printer);
   
   # since --exportview take and optional integer arguement, we must
   # explicitly set is to truth if the option existed on the command line
   $options{'exportview'} = 1 if( (exists $options{'exportview'}  and
                                     not  $options{'exportview'}) or
                                          $options{'exportfilev'} );
   
   # get the properly dual options on when exportfilev-iew is specified
   if($options{'exportfilev'}) {
      $options{'exportview'} = 1;
      $options{'exportfile'} = $options{'exportfilev'};
   }
   
   # Check the export file extensions and set up the export format if
   # an export file was given
   if($options{'exportfile'}) {
      # An export filename was specified.
      my ($name, $path, $suffix) = &fileparse($options{'exportfile'},'\.g2','\.tkg2');
      $options{'exportfile'} = ($suffix eq '.tkg2' or $suffix eq '.g2') ? $name : $name."$suffix";
      $options{'format'} = 'ps' if(not $options{'format'}); # hey set default on format
   }
   
   
   if($options{'format'}) {   # make sure that format will have a valid value
      my $found = 0;
      map { $found = $_ if($options{'format'} =~ /^$_/i) }
                                                       qw(mif png pdf ps mp);
      if(not $found) {
         warn " The command-line option --format was not equal to either ".
              "'mif', 'mp', 'pdf', 'png', or 'ps'\n";
         warn " --format has been changed to postscript\n";
         $options{'format'} = 'ps';
      }
   }
   
   # BUILD TEMPLATE ON THE FLY
   if($options{'mktemp'}) {
      &CreateTemplateOnTheFly($options{'mktemp'},$options{'mkplot'});
   }
   
   # ACTUALLY BEGIN WORKING ON THE OPTIONAL *.tkg2 FILENAMES
   my ($canv, $tw, $template);
   print $::VERBOSE "\n";
   if(@args) { # hey, there were additional command line arguments--hopefully *.tkg2 files
      my $newfile;
      foreach my $tkg2 (@args) {  # loop across each of the passed tkg2 filenames
         print $::VERBOSE "Tkg2 processing $tkg2\n";
         # BEHAVIOR NO. 1
         # TKG2 launched as tkg2 --batch <otheroptions> tkg2filename(s)
         if($options{'batch'}) {
            # Other options --exportfile=somefile
            # The format is postscript unless specified by the --format option
            if($options{'exportfile'}) {
               ($canv, $tw, $template) = 
                  &Batch($tkg2, -exportfile => $options{'exportfile'},
                                -exportview => $options{'exportview'},
                                -format     => $options{'format'},
                                -colormode  => $colormode ); 
            }
            # --format given, but no export filename given, then add the format extension
            # to the tkg2 file
            elsif(not $options{'exportfile'} and $options{'format'}) {
               my $name = &basename($tkg2,'.tkg2');
               ($canv, $tw, $template) =
                  &Batch($tkg2, -exportfile => $name.".$options{format}",
                                -exportview => $options{'exportview'},
                                -format     => $options{'format'},
                                -colormode  => $colormode );
            }
            else {
               if($printer) {
                  ($canv, $tw, $template) = 
                     &Batch($tkg2, -destination => $printer,
                                   -format      => 'ps',
                                   -colormode   => $colormode ); 
               }
               else {
                  my $name = &basename($tkg2,'.tkg2');
                  my $exportfile = $name.".ps";
                  
                  print STDERR "Tkg2-Warning: Batch processing '$tkg2' to ",
                               "apparently unknown printer.\n",
                               "  Changing --batch to ",
                               "--exportfile=$exportfile\n";
                  ($canv, $tw, $template) = 
                     &Batch($tkg2, -exportfile => $exportfile,
                                   -exportview => $options{'exportview'},
                                   -format     => "ps",
                                   -colormode  => $colormode );
               }
            }
         }
         # BEHAVIOR NO. 2
         else {
            ($canv, $tw, $template) = &Open($::MW, $tkg2);
         }
         
         if($::CMDLINEOPTS{'batchsave'}) {
            print $::VERBOSE "Tkg2--Batch Saving '$tkg2'\n";
            $template->Save($canv, $tw);
         }
         
         sleep($options{'pause'}) if($options{'pause'});
      }
   }
   
   # The following is the sole hook for reading tkg2 files along STDIN
   # Notice that this is after all other potential tkg2 files along
   # the command line have been read and displayed or batch processed.
   ($canv, $tw, $template) = &Open($::MW, "stdin") if($::CMDLINEOPTS{'stdin'});  
   
   # The following is the sole hook for dumping the first tkg2 file
   # read and displayed back out along STDOUT
   $template->Save($canv, $tw) if($::CMDLINEOPTS{'stdout'} and $template);
   
   # We must explicitly test for whether the megacommand files should be deleted
   # because if we call the subroutine and the --megacmd_keep is toggled, then
   # megacommand files might be deleted prematurely.  Although, the plots at this
   # point have already been plotted, hence the megacommand files have already been
   # read into memory.
   &DeleteMegaCommandFiles() if( exists $options{'autoexit'} or $options{'batch'} );
   
   $::TIME1 = new Benchmark;
   my $timediff = timediff($::TIME0, $::TIME1);
   print $::VERBOSE "Tkg2: Start up took ",timestr($timediff),"\n";
   
   sleep($options{'autoexit'}) if(  $options{'autoexit'} );
   &SaveTimeCache(), exit if(       $options{ 'batch'  } or
                             exists($options{'autoexit'} ) );
   # Do not hang around when operating in batch mode or explicit autoexit
}

1;

__DATA__

# _reallyCheckColorsWithTk performs a bit more sophisticated color check
# because users are likely to be running tkg2 from a server and the colors
# on their client might be different, we need to have tkg2 try to use those
# colors from the tkg2rc files.
sub _reallyCheckColorsWithTk {
   my $tw = shift;
   $tw->deiconify;
   my $geo = "-200+200";
   $tw->geometry($geo);
   print STDERR "Tkg2 is checking whether it has valid colors ",
                "specified in the tkg2rc files.\n";
   my $font = "Helvetica 16 bold";
   my @con = qw(-text color -foreground black
                -relief sunken padx 5 pady 5
                -width 50);
   my $b = $tw->Label(@con, -font => $font)->pack;
   my @colors = @{$::TKG2_CONFIG{-COLORS}};
   @{$::TKG2_CONFIG{-COLORS}} = ();
   my $found_at_least_one_bad_color = 0;
   print STDERR "  Tkg2--Color Test: ";
   foreach (@colors) {
      next if(/none/o);
      print STDERR  "$_  ";
      eval { $b->configure(-text => $_, -foreground => $_) };
      if($@) {
         print STDERR "\n  Bad Color: '$_' is not valid on X-Client\n".
               "      Remove '$_' from the tkg2rc file\n".
               "      '$_' has been removed for this session.\n";
         $found_at_least_one_bad_color = 1;
      }
      else {
         $b->update;
         $tw->geometry($geo);  # Some window managers are moving the 
                               # dialog off the screen and too the right
                               # We'll blow the clock cycles to keep
                               # in check.  I think that this might be a
                               # bug in the 'after(200)' call--but don't
                               # know.  WHA 8/16/2001.
         $tw->after(200);
         push(@{$::TKG2_CONFIG{-COLORS}}, $_);
      }
   }
   if($found_at_least_one_bad_color) {
      print STDERR "\n Tkg2--Color Test: At least one invalid color was found.\n";
   }
   else {
      print STDERR "\n Tkg2--Color Test: No invalid colors were found.\n";
   }
   $b->packForget;
   unshift(@{$::TKG2_CONFIG{-COLORS}}, 'none');
}


# _showConfiguration prints along standard output the
# the environment and configuration settings of tkg2 after
# the .tkg2rc files have been read
sub _showConfiguration {
   my ($env, $config,) = (shift, shift);
   my %env    = %$env;
   my %config = %$config;
   print STDERR "\nTkg2 Environment, \%TKG2_ENV, is\n";
   foreach (sort keys %env)    {
      if(ref($env{$_}) eq 'ARRAY') {
         my @array = (defined $env{$_}) ? (@{ $env{$_} }) : ('undefined');
         print STDERR "  $_ => @array\n";
      }
      elsif($_ eq "-INPUT_RECORD_SEPARATOR") {
         my $val = (defined $env{$_}) ? ord($env{$_}) : 'undefined';
         print STDERR "  $_ => $val (ascii character number--'man ascii' to ",
                      "view the character for the number shown)\n";   
      }
      else {
         my $val = (defined $env{$_}) ? $env{$_} : 'undefined';
         print STDERR "  $_ => $val\n";
      }
   }
   print STDERR "\nTkg2 Configuration, \%TKG2_CONFIG, is \n";
   foreach (sort keys %config) {
      if(ref($config{$_}) eq 'ARRAY') {
         my @array = (defined $config{$_}) ? (@{ $config{$_} }) : ('undefined');
         print STDERR "  $_ => @array\n";
      }
      else {
         my $val = (defined $config{$_}) ? $config{$_} : 'undefined';
         print STDERR "  $_ => $val\n";
      }
   }
   print STDERR "\n";
   exit;
}   

# _changeHomeDir changes the home directory of the tkg2 process
# implemented from the command line.
sub _changeHomeDir {
   my $newhome = shift;
   my $go = chdir $newhome;
   if($go) {
      $::TKG2_ENV{-USERHOME} = &cwd;
      print $::VERBOSE "  Tkg2-User home changed to ",
                       "$::TKG2_ENV{-USERHOME}\n";
   }
   else {
      print STDERR "Tkg2-Warning _changeHomeDir: Could not chdir ",
                   "to $newhome because $!.\n";
   }
}
 
# Display the version number, build date, and the tkg2 owner
# to the screen, and then exit.
sub _showVersion {
   my ($config)  = @_;
   my $version = $config->{-VERSION};
   my $date    = $config->{-BUILDDATE};
   my $own     = $config->{-OWNER};
   print STDERR "\nTkg2-version $version built on $date\n",
                "     by $own\n";
   exit;  # clean exit because the MainLoop has not yet been called 
}


# I don't know why we would want to show the command line, but here
# goes.
sub _showCommandLine {
   my $env  = shift;
   my %env  = %$env;
   my $line = $env{-COMMANDLINE};
   my @line = @$line;
   my $bin  = $env{-EXECUTABLE};
   print STDERR "$bin @line\n";
}

sub _setGeometry {
   my ($geometry, $config) = @_;
   if($geometry =~ m/^(\d+x\d+)?([+-]\d+[+-]\d+)?$/) {
      $config->{-GEOMETRY} = $geometry;
   }
   else {
      print STDERR "Bad --geometry=$geometry specification format\n",
                   "  Format is usual X-windows: wxh[+-]n[+-]\n",
                   "   Examples: 300x450+10-10 or\n",
                   "             450x234-100+20\n";
   }
}

sub _globFiles {
   my ($string,$files) = @_;

   my $dir = $::TKG2_ENV{-USERHOME};
   
   print $::VERBOSE " Tkg2-Globbing by '$string' in '$dir' = ";
   local *DIR;
   opendir(DIR, $dir) or
      do { print STDERR "Could not open $dir for ",
                        "globbing because $!\n";
           return $files;
         };
      my @newfiles = grep { /$string/ } readdir(DIR);  
   closedir(DIR) or
      do { print STDERR "Could not close $dir after ",
                        "globbing because $!\n";
           return $files;
         };  
      
   print $::VERBOSE scalar(@newfiles)." files.\n";
   
   return ( @$files, @newfiles );  
}   


sub _recursiveGlob {
   my ($dir, $pattern, $files) = @_;
     
   print $::VERBOSE " Tkg2-Recursively globbing by ",
                    "'$pattern' starting in '$dir' = ";  
   my @foundfiles;
   my $_findsub = sub { push(@foundfiles, $File::Find::name) if(/$pattern/) };
   
   find $_findsub, $dir;
   
   print $::VERBOSE scalar(@foundfiles)." files.\n";
   return ( @$files, @foundfiles);
}

1;



