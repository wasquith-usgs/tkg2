package Tkg2::Base;

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
# $Revision: 1.93 $

use strict;
use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK $benchit $columns $LASTSHOWNSUB @BaseDate);
@ISA   = qw(Exporter SelfLoader);

use Tk;
use Cwd;
use Text::Wrap qw($columns &wrap);
use File::Spec;
use Storable qw(dclone);
use Benchmark;

             
@EXPORT_OK = qw( strip_space
                 strip_commas
                 centerWidget
                 commify
                 isNumber
                 isInteger
                 randarray
                 arrayhasNumbers
                 arrayhasNoUndefs
                 pixel_to_inch
                 inch_to_pixel
                 canvas_all_coords 
                 Message
                 log10
                 DeepClone
                 relative_path
                 stackWidget
                 isDISPLAYset
                 Show_Me_Internals
                 Begin_Log_File
                 routeVERBOSE
                 routeBUG
                 routeMetaPost
                 ResolutionHandler
                 getDashList
                 $benchit
                 @BaseDate
                 adjustCursorBindings
                 getShortenedFileName
                 OSisMSWindows
                 repackit
                 deleteFontCache
               );
                
# using the bench marking module, wha has determined that this is the
# fastest construction for log10 calculations. 
use constant logof10 => log(10);
sub log10 {
   my $n = shift;
      $n = "$n"; # PERL5.8 CORRECTION (other comments for research)
   #$_ = ($n <= 0.00) ? 'less than zero' : 'greater than zero';
   #print $::MESSAGE "Tkg2::Base::log10 $n is <= zero\n" if(/less/);
   #print STDERR "Tkg2::Base::log10 $n is <= zero\n" if(/less/);
   #$n = sprintf("%0.16f",$n);
   #$_ = ($n <= 0.00) ? 'less than zero' : 'greater than zero';
   #print $::MESSAGE "Tkg2::Base::log10 $n is <= zero\n" if(/less/);
   #print STDERR "Tkg2::Base::log10 $n is <= zero\n" if(/less/);
   ($n <= 0) ? undef : log($n)/logof10;
}

# PERL5.8 CORRECTION, TO FORCE A POTENTIAL "STRING" TO A NUMBER
# Although wrapping double quotes around a variable also gets rid of
# the float/integer confusion.
sub repackit { return unpack("d",pack("d",shift)); }

# Simple subroutine to test whether a value is an integer or not.
sub isInteger { my $n = shift;  return (int($n) == $n) ? 1 : 0; }

use constant S2    => scalar   2;
use constant S10   => scalar  10; 
use constant S72   => scalar  72; 
use constant S100  => scalar 100;
use constant S150  => scalar 150; 
 
@BaseDate = (1900, 01, 01); 
 
$LASTSHOWNSUB = "none";
 
# The benchit suite of subroutines provide a handy
# ability to perform benchmarking time stamps in
# any other package.  The following line is actually
# executed as part of module compilation.
# For example: print &$benchit; ..other code..; print &$benchit;
$benchit = &reallybenchit();
# $benchit becomes a subroutine reference and $t remains visible
sub reallybenchit {
   my $t = 0;
   return sub {
       return (not $t) ?
           ("\nStart Benchmark\n",$t = new Benchmark)[0]
                       :
          (timestr(timediff($t, new Benchmark))."\n",$t=new Benchmark)[0]
   };
}

sub OSisMSWindows {
  return 1 if ($^O =~ /MSWin/o) ? 1 : 0;
}

sub randarray { $_[0]->[rand @{$_[0]}] }

sub isDISPLAYset {
   my $env = shift;
   return 1 if(&OSisMSWindows());
   return 1 if( defined $env->{-DISPLAY} );
   print STDERR "\n";
   print STDERR "DIED: Your shell variable DISPLAY has not been set and unfortunately\n".
           " Tkg2 requires that it be able to make a connection to an X-server.\n".
           " You are probably trying to run Tkg2 via an rlogin or a telnet session.\n".
           " In that case your DISPLAY is not automatically exported or set when\n".
           " you logged in.\n\n";
   print STDERR " At your regular (not rlogin or telnet) prompt type 'echo \$DISPLAY'\n".
           " You will see something like this 'ws26ast:0.0' or 'ws26ast.cr.usgs.gov:0.0'.\n".
           " echoed back to you.  The above are for my Windows NT machine, yours will be\n".
           " different.  What is echoed back is your display name, you now need to set\n".
           " this display name for each of your rlogin or telnet session(s).  How you do\n".
           " that varies as to which shell you run under.\n\n";
   print STDERR " Try each of these if you do not know which shell you run\n".
           " Bash:    'export DISPLAY=ws26ast:0.0'\n".
           " C-Shell: 'setenv DISPLAY ws26ast:0.0'\n".
           " Test by using 'echo \$DISPLAY' and see if your display name is returned.\n".
           " If the display name is echoed back then you should be able run tkg2.\n\n";
   print STDERR " If you still get this message, then contact you system administrator\n\n";
   exit;
}

# getShortenedFileName is a subroutine that quickly
# parses any $file name /home/wasquith/junk/morejunk/tkg2/junk.tkg2
# into a string of directory length set by the $dirs2show argument
# print getShortenedFileName(/home/wasquith/junk/morejunk/tkg2/junk.tkg2,
#                            3);
# yields: /home/.../morejunk/tkg2/junk.tkg2
# This subroutine's intent is to provide a central mechanism for 
# shortening file names in dialog boxes.
sub getShortenedFileName {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($file,$dirs2show) = @_;
   return $file if(&OSisMSWindows());
   my (undef, $directories, $shortfile) = File::Spec->splitpath($file);
   
   return $shortfile if(not defined $directories);
   
   my @dirs   = File::Spec->splitdir($directories);
   shift(@dirs);      pop(@dirs);
   # leading / and trailing / are counted as ""
   # so we need shift and pop

   my $nd     = scalar(@dirs);
   $dirs2show = $nd if(not defined $dirs2show);
   
   if($nd == 0) {
      return $shortfile;
   }
   elsif($dirs2show >= $nd) {
      return $file;
   }
   elsif($nd > $dirs2show) {
      my $le = $#dirs;
      my @list2get = (($le-$dirs2show+2)..$le);
      my $remain =
          File::Spec->catfile(@dirs[@list2get],$shortfile);
      $shortfile = "/$dirs[0]"."/.../".$remain;
   }
   else {
      return $file;
   }
}


sub Begin_Log_File {   
   my ($opts, $argv) = @_;
   my %opts = %$opts;
   my @argv = @$argv;
   my $os   = $::TKG2_ENV{-OSNAME};
   
   return 0 unless($os eq 'solaris' or $os eq 'linux');
   
   my $logfile = $::TKG2_ENV{-LOGFILE};
   my $need_to_chmod = (-e $logfile) ? 0 : 1;
   local *LOGFH;
   open(LOGFH, ">>$logfile") or
      do {
        print STDERR "Tkg2 could not append '$logfile' because $!\n";
        return 0;
      };
      my $lock = 1;
      while(not flock(LOGFH,2)) { 
         warn "Tkg2 could not exclusive lock '$logfile' == try number $lock\n";
         warn "   Waiting 2 seconds and the lock should clear. Cntrl-C to break\n";
         sleep(2);
         $lock++;
         if($lock == 4) {
            close(LOGFH);
            warn "   Giving up on lock, consult wasquith\@usgs.gov, continuing\n";
            return 0;
         } 
      }    
      my $message;
      exists $opts{'message'} && ($message = $opts{'message'}) && delete $opts{'message'};  
         @argv = (@argv) ? @argv : ('**no_files**');
      my @opts = (%opts) ? ( map { if(ref($opts{$_}) eq 'ARRAY') {
                                     "$_=@{$opts{$_}}";
                                   }
                                   else {
                                     "$_=$opts{$_}";
                                   }
                                 } keys %opts ) : ('**no_opts**');
      
      my $time = localtime;
      my $user = getpwuid($<);
      my $string  = "%"; #"
         $string .= join("|", ( $0, $::VERSION, $time, $user) )."|@opts|@argv";
         $string .= "|# $message" if($message);
      print LOGFH  $string,"\n";
      print $::BUG $string,"\n";
   close(LOGFH) or
       warn("Tkg2 could not close '$logfile' because $!\n"), return 0; 
   chmod(0666, $logfile) if($need_to_chmod);       
   return 1; 
}       



# ResolutionHandler is a very important subroutine that is invoked
# before any graphics are ever done.  This subroutine is intended to 
# provide 'nice' settings for Tk on a per monitor basis. 
sub ResolutionHandler {
   my ($cmdlineopts, $config, $env) = @_;
   
   my $xres     = $env->{-XRESOLUTION};
   my $yres     = $env->{-YRESOLUTION};
   my $oldscale = $env->{-SCALING};
   
   my $text      = " %% Tkg2-message:"; # leading message text
   print $::MESSAGE
         "$text Screen resolution = $xres x $yres pixels.\n";
   my ($monwidth, $monheight, $size) =
            &_computeMonitorSize($xres,$yres,$oldscale);
   $config->{-MONITORSIZE} = $size;
   
   print $::MESSAGE
         "$text Monitor size ~= $size inches.\n",
         "=== Note that these are monitor dimensions calculated by \n",
         "===  environment variables reported by Tk and might be\n",
         "===  somewhat different than the actual monitor.\n";
   #SIZEprint $::MESSAGE "$text Tkg2 thinks monitor diagonal is about $size inches.\n"; 
   print $::MESSAGE "$text Initial scaling (pxl/pt) = $oldscale.\n";
   
   
   # Set the environmental scaling multiplier (not the actual scaling
   # value) from the various sources.  Then use the _scalingMW subroutine
   # to apply the multiplier and internally set the true scaling into
   # the env hash.
   my $htbuff = (defined $cmdlineopts->{'scaling'}) ?
                         $cmdlineopts->{'scaling'}  :
                (defined $config->{-RC_SCALING})    ?
                         $config->{-RC_SCALING}     : "use table";
   if($htbuff eq "use table") {
      # A height buffer of 1.25 works in most situation, but a little
      # tweaking is nice too.
      # If the vertical resolution is huge > 1024 lower buffer to 1.15
      # If the vertical resolution is 600 pixels or greater use   1.25
      # If the vertical resolution is 500 pixels or greater use   1.5
      # If the vertical resolution is 400 pixels or greater use   1.75
      # If for some reason a these conditionals break down, use 1.25.
      $htbuff = ($yres > 1024) ? 1.15 :
                ($yres >  600) ? 1.25 :
                ($yres >  500) ? 1.5  :
                ($yres >  400) ? 1.75 : 1.25;
      print $::MESSAGE
            "$text Height buffer ~= $htbuff inches.\n",
            "=== Note that height buffer value came from automatic rules.\n";
   }
   else {
      print $::MESSAGE
            "$text Height buffer ~= $htbuff inches.\n",
            "=== Note that the height buffer value came from ";
      if(defined $cmdlineopts->{'scaling'}) {
         print $::MESSAGE "command line.\n";
      }
      elsif(defined $config->{-RC_SCALING}) {
         print $::MESSAGE "configuration file.\n";      
      }
      else {
         print $::MESSAGE "no where.\n";
      }   
   }
   
   my $scaling_multiplier = &_computeScalingMultiplier($monheight,$htbuff);
   # set the true scaling factor for this session with the scaling multiplier
   my ($newscale, $ratio) = &_scalingMW($env,$scaling_multiplier);

   print $::MESSAGE "$text   Final scaling (pxl/pt)  = $newscale.\n";
   print $::MESSAGE "$text   Final / Initial scaling = ",
                                         $newscale/$oldscale,".\n\n";

   # Modify the dialog fonts for a better visual size
   &_rescaleDialogFonts($env,$config) unless($cmdlineopts->{'nodialogrescale'});
}

# _computeScalingMultiplier is a simple subroutine that performs the 
# algebraic transformation on the scaling ratio in such a way that an
# 11 inch tall canvas with the addition height of menus and rulers will
# fit on the monitor without having to use the scroll bars.  The subroutine
# returns the ratio that needs to be multiplied to the default or startup
# scaling value of Tk.
sub _computeScalingMultiplier {
   my ($monitor_height, $height_buffer) = @_;
   my $ratio;
   
   # The MESSAGE filehandle has already been opened in a BEGIN block in
   # package main.
   
   # if the height buffer is a number then apply the transformation
   # the height buffer is just an offset down from the top of the screen
   # that permits users and the tkg2 developers to fine tune the setting.
   if(&isNumber($height_buffer)) {
      $ratio = (($monitor_height - $height_buffer ) / 11);
   }
   else {
      $ratio = 1;
      print $::MESSAGE
            "!!! The height buffer was not a number.  The ratio multiplier\n",
            "!!! has been set to 1 to return to default Tk settings.\n";
   }
   if(not defined $ratio or $ratio <= 0) { 
      $ratio = 1;
      print $::MESSAGE
            "!!! Ratio multiplier has been set to 1 because height buffer \n",
            "!!!   is greater than the monitor height as calculated by \n",
            "!!!   environment settings as reported by Tk.\n";
   }
   return $ratio;
}

# _computeMonitorSize does just that.  Computes the width and height of
# the monitor based on the default scaling value (pixels / point) from Tk.
# and the resolution as reported to Tk from the X server.
sub _computeMonitorSize {
   my ($xres, $yres, $scalingfactor) = @_;   
   my $convert   = $scalingfactor * S72;
   my $monwidth  = int( ( $xres / $convert) * S100) / S100;
   my $monheight = int( ( $yres / $convert) * S100) / S100;
   return $monwidth, $monheight, "$monwidth x $monheight";
}

sub _rescaleDialogFonts {
   my ($env,$config) = @_;
   my $fonts = $config->{-DIALOG_FONTS};
   foreach (keys %$fonts) {
      my ($f, $s, $t) = split(/\s+/o, $fonts->{$_});
      # print STDOUT "Old Size $s\n";
      my $newsize     = int($s/$env->{-SCALING});
      # print STDOUT "New size $newsize\n";
      $fonts->{$_}    = join(" ", $f, $newsize, $t);
   }
}

# _scalingMW alters the scale in pts per inch that the canvas and any other
# Tk widgets will be drawn at.  The user sets on the command line by
# specifying a percentage of original scale.  So -scaling=0.9 would reduce
# the startup scale by 10 percent.
sub _scalingMW {
   my ($env,$ratio) = @_;
   $ratio = 1 unless(defined $ratio and $ratio >= 0);

   my $startup_scale = $::MW->scaling;
   my $newscale      = $ratio*$startup_scale;
   $::MW->scaling($newscale);  # pixels per point (point = 1/72 inch)
   # the scaling method call makes some small changes? to either the scale
   # when store or when retrieved, by calling the scaling method for
   # retrieval instead of using $newscale consistency is insured.
   $env->{-SCALING} = $::MW->scaling();
   
   return ($env->{-SCALING}, $ratio);
}

# startup the VERBOSE filehandle that will be accessible from package main
sub routeVERBOSE {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   $::TKG2_CONFIG{-VERBOSE} = 0 if( exists  $::CMDLINEOPTS{'verbose'}
                                    and not $::CMDLINEOPTS{'verbose'} );
   
   my $stdoutON = shift;
   # turn the verbose filehandle one if configured that way
   my $null   = ">/dev/null";
   my $stdout = ">&STDOUT";#">/dev/stdout";
   my $file   = ($stdoutON or $::TKG2_CONFIG{-VERBOSE}) ? $stdout : $null;
   local *VERBOSE;
   open(VERBOSE, $file) or
      do {
          print STDERR "Tkg2 Error--VERBOSE not opened ",
                      "as $file because $!\n";
          return;
         };
   return *VERBOSE;  
}

# startup the BUG filehandle that will be accessible from package main
sub routeBUG {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($ONbyCMDLINE, $ONbyCONFIG) = @_;
      
   # If the command line is true, then use it as
   # either truth or 'file', otherwise use the configuration
   my $bugsON  = ($ONbyCMDLINE) ? $ONbyCMDLINE : $ONbyCONFIG;
   # The same stamp as the log file is made to the bug file
   # The bug file is not appended too like in the log file
   # case so that exact reporting for a single tkg2 session
   # is made.  Note that a lock is not made on this file.
   my $bugfile = ">$::TKG2_ENV{-BUGFILE}";
   my $null    = ">/dev/null";
   my $stdout  = ">&STDOUT";#">/dev/stdout";
   my $file    = ($bugsON eq 'file'  ) ? $bugfile :
                 ($bugsON eq 'stdout') ? $stdout  : $null;
   
   local *BUG;
   open(BUG, $file) or
      do {
          print STDERR "Tkg2 Error--BUG not opened ",
                      "as $file because $!\n";
          return;
         };
   return *BUG;  
}

# MetaPost filehandle that will be accessible from package main
# and defaults to NULL
sub routeMetaPost {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $output = shift;
   my $null    = ">/dev/null";

   my $file = ($output and $output ne "") ? $output : $null;
      
   local *MP;
   open(MP, ">$file") or
      do {
          print STDERR "Tkg2 Error--MP filehandle not opened ",
                      "as $file because $!\n";
          return;
         };
   return *MP;  
}


sub stackWidget {
   my $widget = shift;       
   my $morexoff = (@_) ? shift() : 0;
   my $moreyoff = (@_) ? shift() : 0; 
   $widget->geometry("-$morexoff-$moreyoff");
}

# isNumber is another handy utility that tests whether the argument
# is a number or not.  This might not be the fastest or the most
# logical method by which to test whether a string is a number or
# not, but hey, it works and provides a constant interface throughout
# the program.  This is an area in which someone could do some really
# important research in terms of speeding up the read in the data
# process.
sub isNumber {
  my $v = shift;
  if(not defined $v ) {
     my @call = caller(1);
     map { $call[$_] = "" if(not defined $call[$_]) } (0..$#call);
     print STDERR "Tkg2::Base::isNumber(undef) as @call\n";
     return 0;
  }
  $v =~ /^[+-]?\d+\.?\d*$/o                 || 
    $v =~ /^[+-]?\.\d+$/o                   ||
      $v =~ /^[+-]?\d+\.?\d*[eE][+-]?\d+$/o || 
        $v =~ /^[+-]?\.\d+[eE][+-]?\d+$/o;
}

# pixel_to_inch and inch_to_pizel are two important methods to convert back
# and for between the screen and real world units.  wha really wishes that
# Tk provided these two methods.  Keep an eye on Tk progress, perhaps these
# will be added eventually.  wha has asked the Tk community to provide, but
# has not really pressed the issue.
sub pixel_to_inch {
   my ($self, $pxls) = @_;
   return $pxls unless(&isNumber($pxls));
   # scale is the pixels per point a point is 1/72 of an inch
   return sprintf("%0.3f"."i", (($pxls)/($self->{-scaling}))/S72);
}

sub inch_to_pixel {
   my ($self, $inch) = @_;
   $inch =~ s/([0-9.]+).+/$1i/;
}

# Tk::Canvas provides the coords method, which produces coords
# of the lowest item with the tag.  This method will get all
# coordinates of all items tagged with $tag, and return as
# array of array references.
sub canvas_all_coords {
   my ($canv, $tag) = (@_);
   my @ids = $canv->find('withtag',$tag);
   my @all_coords;
   foreach my $id (@ids) {
      my @coords = $canv->coords($id);
      push(@all_coords, [ @coords ] );
   }
   return @all_coords;
}

# arrayhasNumbers  In several dialog boxes (actually entry fields), it
# is necessary to check whether or not an array is full of numbers
sub arrayhasNumbers {
   map { return 0 if( not &isNumber($_) ) } @_;
   return 1; # the array has numbers
}


# arrayhasNoUndefs
sub arrayhasNoUndefs {
   my $null_found;
   map { return 0 unless $_ } @_;
   return 1;
}


# adjust the cursor as is enters and leaves a tagged object
sub adjustCursorBindings {
   my ($canv, $tag) = @_;
   my $e_cursor = 'hand2';
   my $l_cursor = 'top_left_arrow';
   my $_cursor  = sub { my ($c,$r) = @_;
                        $c->configure(-cursor => $r);
                        $c->update;
                      };
   # Recall that $canv becomes the first argument into 
   # the _cursor callback with the below notation
   $canv->bind($tag, "<Enter>", [ $_cursor, $e_cursor] );
   $canv->bind($tag, "<Leave>", [ $_cursor, $l_cursor] );
}

# this function is a late arrival in tkg2 with migration to Perl5.8.3 and
# Tk804.026 there are reports of core dumps associated with a font cache
# that is not getting cleaned up before a 'fontCreate' is called throughout
# the text rendering portions of tkg2.  This global method scans the entire
# cache and wipes everything clean.  Note that this call SHOULD NOT BE
# needed, but there seems to be some Perl/Tk garbage collection problems.
# The specific_fonts_to_delete is important because we have an embedded subroutine
# within the drawExplanation in which another font is needed before an earlier
# font is finished being used.  The message is handy feature.
# WHA  06/22/2004
sub deleteFontCache {
   my ($specific_fonts_to_delete, $message) = @_; # array ref and message
   $message = "no message" if(not defined $message);
   my ($file, $line, $sub) = ( caller(1) )[1,2,3];
   my @fonts = (ref $specific_fonts_to_delete) ?
                   @{$specific_fonts_to_delete} : 
                   $::MW->fontNames;
   foreach (@fonts) {
     print $::BUG "Tkg2::Base::deleteFontCache--$_ is being deleted with $message\n",
                  "                             called from ($file, $line, $sub)\n";
     eval { $::MW->fontDelete($_); };
     print $::BUG "$_ could not be deleted: $@\n" if($@);
   }
}

1;

__DATA__
              
# commify is a handy utility that adds comma's to integer and real
# numbers, commify is used throughout the program's modules to add
# the final production ready touches to numbering                 
sub commify {
  my $in  = reverse $_[0];
  my $sym = $_[1] ? $_[1] : ',';
  $in =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$sym/g;
  return scalar reverse $in;
}   

sub strip_commas {
   $_ = $_[0];
   s/,\s+?/ /og;
   return $_;
}

# strip_space is a convenient wrapper on the two standard regex which
# removes leading spaces and then removes trailing spaces
# for massively repeated operations of space stripping the substitutions
# are explicitly performed with this subroutine because of the 
# time expense of calling &strip_space thousands to tens of thousands of
# time
sub strip_space { $_[0] =~ s/^\s+//o;  $_[0] =~ s/\s+$//o;  return $_[0]; }

sub centerWidget {
   my $widget = shift;       
   my $morexoff = (@_) ? shift() : 0;
   my $moreyoff = (@_) ? shift() : 0; 
   # Still working out how to center a widget without it knowing
   # how big it is.  The -150 shift is arbitrary but seems to look nice
   my $geo = $widget->geometry;
   my @geo = $geo =~ m/^ (\d+)x(\d+)  ([+-]\d+)  ([+-]\d+) $/xo;
   #print "geometry @geo\n";
   my $xres = $::TKG2_ENV{-XRESOLUTION};
   my $yres = $::TKG2_ENV{-YRESOLUTION};
   my $x = int( ($xres - $geo[0])/S2 - S150 + $morexoff);
   my $y = int( ($yres - $geo[1])/S2 - S150 + $moreyoff);
   $widget->geometry("+$x+$y");
}


sub DeepClone {
   # $template->DeepClone;                # for Undo
   my $template = shift;
   # The Storable modules does not support the annoymous subroutines,
   # since the rulers are draw via annoymous subs, they must first be
   # removed.
   my $clone = &_clonetemplate($template);
   delete($clone->{-markrulerEv});
   delete($clone->{-markrulerXY});
   $clone->{-x_grid} = [ ];
   $clone->{-y_grid} = [ ];
   $clone = &dclone($clone);
 
   return $clone;
}
      
sub _clonetemplate {
   my $cp = shift;
   return bless( {%$cp}, ref($cp));
}
   

sub relative_path {
   my $file = shift;  # full absolute path name to file
   my $dir  = &cwd;
   if(not defined $dir) {
      print STDERR "Tkg2-Serious Warning: Perl could NOT determined the ",
                   "current working directory with the Cwd module and method.\n";
      return;
   }  
   my $os   = $::TKG2_ENV{-OSNAME};
   if($os ne 'MSWin32') { # for unix type systems
      $file =~ s|$dir/||;
   }
   else { 
      $file =~ s|$dir\\||;
   }
   return $file;
}


# Message is the main message reporting method for all of tkg2.
# The first argument is a toplevel widget such as $::MW (MainWindow)
# or TopLevel children of MainWindow
sub Message {
   my ($tw, $which) = ( shift, shift); # do not remove these shifts
   $! = "unknown" if(not defined $!);
   my %messages = ( -selplot       => 'Need to select a plot first.',
                    -selfromlist   => 'Please select an element from the listbox.',
                    -noclipboard   => 'Clipboard is empty.',
                    -nofilename    => 'No filename was specified or the file does not exist.',
                    -invalidtkg2file => "File is not recognizable as a tkg2 ".
                                        "file, or the file does not exist, or the file ".
                                        "is empty.",
                    -confirmdelete => 'Are you sure you want to delete?',
                    -generic       => 'Generic error called.',
                    -notnumber     => 'One or more entries are not numbers!',
                    -fileerror     => "File Error: $!");
   # exit if key isn't found
   unless( exists $messages{$which} ) {
      warn "Message $which does not exist";
      return;
   };

   my $text;
   if($which eq '-generic') {
      $text  = (@_) ? shift() : $messages{$which};
   }
   else {
      $text  = $messages{$which};
      $text .= " ".shift() if(@_);  # cat the next thing passed in
   }
   
   
   # This is to provide message reporting on the command line
   # when tkg2 is being run in withdraw mode or batch and
   # no mainwindow or other toplevels exist
   unless(Tk::Exists($tw)) {
      print STDERR "Tkg2 Message: $text";
      return;
   }
   
   &_MessageDialog($tw, $text);
}

sub _MessageDialog {
   my ($pw, $text) = @_;
   
   $columns = 60;  # columns is actually a global variable for 
                   # the wrap module.  They did not use capital
                   # letters.

   my $MessageTopLevel = $pw->Toplevel(-title => 'Tkg2 Messaging System');

   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-large};
   
   my $tkg2color = $::TKG2_CONFIG{-BACKCOLOR};
   
   my $e = $MessageTopLevel->Scrolled('Text',
                         -scrollbars => 'se',
                         -font   => $font,
                         -width  => $columns,
                         -height => 10)
              ->pack(-side => 'top', -fill => 'x');
   
   # Indent each paragraph by 3 spaces, using no spaces for susequent lines
   # and wrap the line at $columns without splitting any words.
   map { $e->insert('end', &wrap("   ","",$_)."\n") } split(/\n/, $text);

   $e->configure(-state => 'disabled');
   
   my $f_b = $MessageTopLevel->Frame(-relief      => 'sunken',
                        -background  => $tkg2color,
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   my $b = $f_b->Button(-relief      => 'raise',
                        -borderwidth => 5,
                        -highlightcolor => 'red',
                        -highlightthickness => 3,
                        -bitmap      => 'error',
                        -foreground  => 'red',
                        -activeforeground => 'red',
                        -width       => 100,
                        -command     => sub { $MessageTopLevel->destroy; } )
               ->pack(-side => 'bottom', -pady => 2);           
   $b->focus;
}


sub Show_Me_Internals {
   my $seconds = ( $::CMDLINEOPTS{'showme'} ) ?
                   $::CMDLINEOPTS{'showme'}   : 1;
   my ($file, $line, $sub) = ( caller(1) )[1,2,3];

   my @font_names = $::MW->fontNames;
   #print STDERR "Show_Me_Internals::FONTBUG: List of Font Names in Cache: @font_names\n";
   
   if($::CMDLINEOPTS{'showmesubs'}) {
      print STDERR "$sub   FROM $file ($line)\n";
      return;
   }
   
   my $text = "## $sub\n".
              "##   from $file\n".
              "##   on line $line\n";
   if(@_) {
      my @args = map { (defined $_) ? $_ : 'undef' } @_;
      $text .= "##-".scalar(@args)."-args    @args\n\n";
   }
   else {
      $text .= "##    no arguments\n";
   }
   print STDERR $text;
   print STDERR "#### Benchmark: $LASTSHOWNSUB to beginning of \n".
                "####            $sub took:\n",
                "#### ",&$benchit(),"\n";
   sleep( $seconds / S10 );
   $LASTSHOWNSUB = $sub;
}

sub getDashList {
   my ($dash_loc, $font) = @_;
   # $dash_loc is a reference to the dash storage location
   # \$linerev->{-dashstyle}
   return ( [ 'command' => 'Solid',
              -font     => $font,
              -command  => sub { $$dash_loc = 'Solid'} ],
      
            [ 'command' => '--',
              -font     => $font,
              -command  => sub { $$dash_loc =    '--'} ],
            
            [ 'command' => '- -',
              -font     => $font,
              -command  => sub { $$dash_loc =    '- - '} ],
            
            [ 'command' => '-  -',
              -font     => $font,
              -command  => sub { $$dash_loc =    '-  -  '} ],
            
            [ 'command' => '-  --',
              -font     => $font,
              -command  => sub { $$dash_loc =    '-  --  '} ],
            
            [ 'command' => '-.-.',
              -font     => $font,
              -command  => sub { $$dash_loc =    '-.-.'} ],
            
            [ 'command' => '.',
              -font     => $font,
              -command  => sub { $$dash_loc =    '.'} ] );
}

1;
