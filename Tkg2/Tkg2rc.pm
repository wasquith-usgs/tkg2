package Tkg2::Tkg2rc;

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
# $Date: 2016/02/29 17:13:00 $
# $Revision: 1.43 $

use strict;
use Exporter;

use Tk;
use Tk::Dialog;
use Cwd;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
           
@EXPORT_OK = qw(Read_tkg2rc_file Read_tkg2rc_file_for_ShortCuts);
use Benchmark;

use Tkg2::Base qw(OSisMSWindows);


# READING THE X-STYLE RESOURCE FILES             
sub Read_tkg2rc_file {
   
   # Read the rc file that comes with the distribution
   my $tkg2rc = (&OSisMSWindows()) ? "tkg2rc" :
                "$::TKG2_ENV{-TKG2HOME}/Tkg2/tkg2rc";
   $::TKG2_ENV{-RC_FILES}->{-DISTRIBUTION} = $tkg2rc
                    if(&_really_read_tkg2rc($tkg2rc));
   
   # Read the rc file that root could place in the usual place for application default files
   # Path to the usual place for application defaults
   my $systemrc =
      ($^O =~ /solaris/o) ? "/usr/openwin/lib/app-defaults/tkg2.rc"   :
      ($^O =~ /linux/o  ) ? "/usr/X11R6/lib/X11/app-defaults/tkg2.rc" :
                            undef;
   # there seems to be some debate whether the tkg2.rc on linux systems
   # goes in the app-defaults of X or in /usr/etc or /usr/local/etc.  In
   # the spirit of staying parallel to solaris, I choose app-defaults.
                           
   if(defined $systemrc and -e $systemrc) {
      # Set value to the path name so we can track installation
      # problems or issues easier by seeing which file was read in.
      $::TKG2_ENV{-RC_FILES}->{-SYSTEM} = $systemrc
                 if(&_really_read_tkg2rc($systemrc));
   }
 
   # Read the rc file that might exist in the user's directory
   my $userrc = $::TKG2_ENV{-HOME}."/.tkg2rc";
   if(-e $userrc) { 
      $::TKG2_ENV{-RC_FILES}->{-USER} = $userrc
                 if(&_really_read_tkg2rc($userrc));
   }

   # Tk methods crash if unavailable color names are used
   # thus we need to explicitly test for them, this is not fool proof
   # as the client can have different colors than the server
   &_verifyColors();  

   # Now reverse the printer lists so that the last ones read in 
   # in the user's tkg2rc, which is the last rc file read, end
   # up a the top of the list.
   @{$::TKG2_CONFIG{-PRINTERS}  } = reverse( @{$::TKG2_CONFIG{-PRINTERS} } );
   
   # Now just ignore everything about the printers, if running under Solaris
   # or Linux.
   # This is so that all the system administrators will not have to
   # build up the rc files themselves.  I suppose that reading printers
   # from the rc files is still needed on non Solaris or Linux platforms.
   if( not @{$::TKG2_CONFIG{-PRINTERS}} and
       ( $::TKG2_ENV{-OSNAME} eq 'solaris' or
         $::TKG2_ENV{-OSNAME} eq 'linux'   or
         $::TKG2_ENV{-OSNAME} eq 'darwin') ) {
      # get list of all available printers
      my @printers = map { m/\w+\s+\w+\s+(.+):.+/o } ( split(/\n/o, `lpstat -v`) );
      if(not @printers) {
         print STDERR "Warning: Could not identify printers using ",
                      "'lpstat -v'\n  Tkg2 will be using the word ",
                      "'printer' as a place filler.\n";
         @printers = ('printer');
      }
      # get the default printer
      my ($default_printer)  = (defined $::TKG2_ENV{-DEFAULT_PRINTER} )  ? 
                                        $::TKG2_ENV{-DEFAULT_PRINTER}    :
                                            `lpstat -d` =~ m/:\s+(.+)/o  ;
                                    
      $default_printer = 'no default printer'
           if(not defined $default_printer);
      
      # now use a hash to find the duplicate and remove it.
      # the duplicate exists because lpstat -d was previously identified
      # by lpstat -v
      my %unique_printers;
      map { $unique_printers{$_}++ } ($default_printer, @printers);
      delete $unique_printers{$default_printer};
      
      @printers = sort keys %unique_printers;
      
      $::TKG2_CONFIG{-PRINTERS} =
          ($default_printer eq 'no default printer') ?
          [ @printers ]  :  [ $default_printer, @printers ];
   }
   
   # finally place the none color and the custom delimiter
   unshift( @{$::TKG2_CONFIG{-COLORS    }}, 'none'   );
   push(    @{$::TKG2_CONFIG{-DELIMITERS}}, 'custom' );

   &_check_TKG2_CONFIG_for_duplicates(\%::TKG2_CONFIG);
   &_increment_dialog_fonts();
}



sub _increment_dialog_fonts {
  my $fontset   = \$::TKG2_CONFIG{-DIALOG_FONTS};
  
  my $idf       = \$::TKG2_CONFIG{-INCREMENT_DIALOG_FONTS};
  my $increment = (defined $$idf) ? $$idf : 0;
                           
  foreach my $font (keys %{$$fontset} ) {
     my ($fam, $size, $type) = split(/\s+/o, $$fontset->{$font});
     $size += $increment;
     $$fontset->{$font} = "$fam $size $type";
  }
}



sub Read_tkg2fc_file_for_ShortCuts {
   my $requested_short_cut = shift;
   my $userrc = $::TKG2_ENV{-HOME}."/.tkg2rc";
   my %shortcuts = ();
   unless(-e $userrc) {
      print STDERR "Warning: The requested short cut can not be ",
                   "processed because\n",
                   "         there is no .tkg2rc in the user's home ",
                   "directory\n",
                   "   Ignoring the short cut request\n";
      return 0;
   }
   open(FH, "<$userrc") or die "Could not open $userrc file because $!\n";
   while(<FH>) {
      next if(m/^\#|^\!/o);
      chomp;
      next if(m/^\s+$/o);
       $shortcuts{$1} = $2 if(/Tkg2\*SHORTCUT=(.+):\s+(.*)$/o);
   }
   close(FH);
   if(not exists($shortcuts{$requested_short_cut})) {
      print STDERR "Warning: The requested short cut does not exists in\n",
                   "         the .tkg2rc file in the user's home directory\n",
                   "   Ignoring the short cut request\n";
      return 0;
   }
   return $shortcuts{$requested_short_cut};  # return the short cut name
}

sub _check_TKG2_CONFIG_for_duplicates {
   my $config = shift;
   foreach (keys %$config ) { 
      next if( ref $config->{$_} ne 'ARRAY'); 
      $config->{$_} = &__checkem($config,$_);
   }
   %::TKG2_CONFIG = %$config;
}


sub __checkem {
   my ($config,$key) = (shift,shift);
   my @array = @{ $config->{$key} };
   my @newarray = ();
   my %checker;
   foreach (@array) {
      if(exists $checker{$_} ) {
         next if($key eq 'PRINTERS' );
         # ignore warning about duplicate printers
         # 4/11/2000, wha does not remember why this was in here
         
         print STDERR "Minor Warning: A duplicate element exists in ",
                      ".tkg2rc file(s)\n      The key is $key and ",
                      "the element is $_\n";
      }
      else {
         push(@newarray, $_);
      }
      $checker{$_}++;
   }
   return [ @newarray ];
}      


# _really_read_tkg2 actually reads the tkg2rc files specified by 
# the call in Read_tkg2rc_file
sub _really_read_tkg2rc {
   my $file = shift;
   local *FH;
   open(FH, "<$file") or
      do {
           print STDERR "Tkg2-Warning: could not open '$file' file because $!\n";
           return 0;
         };
   
   while(<FH>) {
      next if(m/^\#|^\!/o);
      next if(m/SHORTCUT/o);  # Short cuts are parsed on another read.
      chomp;
      
      push(@{$::TKG2_CONFIG{-PRINTERS}},      split(/\s+/o, $1) ),
           next if(/Tkg2\*printers:\s+(.*)$/o);
      push(@{$::TKG2_CONFIG{-COLORS}},        split(/\s+/o, $1) ),
           next if(/Tkg2\*colors:\s+(.*)$/o);
      push(@{$::TKG2_CONFIG{-FONTS}},         split(/\s+/o, $1) ),
           next if(/Tkg2\*fonts:\s+(.*)$/o);
      push(@{$::TKG2_CONFIG{-LINETHICKNESS}}, split(/\s+/o, $1) ),
           next if(/Tkg2\*linethicks:\s+(.*)$/o);
      push(@{$::TKG2_CONFIG{-DELIMITERS}},    split(/\s+/o, $1) ),
           next if(/Tkg2\*delimiters:\s+(.*)$/o);
      
      ($::TKG2_CONFIG{-FILEFORMAT})         = split(/\s+/o, $1),
           next if(/Tkg2\*fileformat:\s+(.*)$/o);
      ($::TKG2_CONFIG{-DEBUG})              = split(/\s+/o, $1),
           next if(/Tkg2\*debug:\s+(.*)$/o);   
      ($::TKG2_CONFIG{-SPLASH})             = split(/\s+/o, $1),
           next if(/Tkg2\*splash:\s+(.*)$/o);
      ($::TKG2_CONFIG{-REDRAWDATA})         = split(/\s+/o, $1),
           next if(/Tkg2\*redrawdata:\s+(.*)$/o);
      ($::TKG2_CONFIG{-DELETE_LOADED_DATA}) = split(/\s+/o, $1),
           next if(/Tkg2\*delete_loaded_data:\s+(.*)$/o);
      ($::TKG2_CONFIG{-VERBOSE})            = split(/\s+/o, $1),
           next if(/Tkg2\*verbose:\s+(.*)$/o);
      ($::TKG2_CONFIG{-PLOTTING_POSITION_COEFFICIENT}) = split(/\s+/o, $1),
           next if(/Tkg2\*plotting_position_coe:\s+(.*)$/o);
      ($::TKG2_CONFIG{-GEOMETRY})           = split(/\s+/o, $1),
           next if(/Tkg2\*geometry:\s+(.*)$/o);
      ($::TKG2_CONFIG{-QUEUE_OPTIONS})      = split(/\s+/o, $1),
           next if(/Tkg2\*queue_options:\s+(.*)$/o);
      ($::TKG2_CONFIG{-WM_OVERRIDE_POD_GEOMETRY}) = split(/\s+/o, $1),
           next if(/Tkg2\*wm_override_pod_geometry:\s+(.*)$/o);
      ($::TKG2_CONFIG{-RC_SCALING})         = split(/\s+/o, $1),
           next if(/Tkg2\*scaling:\s+(.*)$/o);
      ($::TKG2_CONFIG{-FORCE_PAGE_WIDTH})   = split(/\s+/o, $1),
           next if(/Tkg2\*width:\s+(.*)$/o);
      ($::TKG2_CONFIG{-FORCE_PAGE_HEIGHT})  = split(/\s+/o, $1),
           next if(/Tkg2\*height:\s+(.*)$/o);
      ($::TKG2_CONFIG{-ZOOM})  = split(/\s+/o, $1),
           next if(/Tkg2\*zoom:\s+(.*)$/o);
      ($::TKG2_CONFIG{-NOZOOM2UNITY})  = split(/\s+/o, $1),
           next if(/Tkg2\*nozoom2unity:\s+(.*)$/o);	   
      ($::TKG2_CONFIG{-INCREMENT_DIALOG_FONTS}) = split(/\s+/o, $1),
           next if(/Tkg2\*increment_dialog_fonts:\s+(.*)$/o);
      ($::TKG2_CONFIG{-SHOWME}) = split(/\s+/o, $1),
           next if(/Tkg2\*showme:\s+(.*)$/o);
   }
   close(FH);
   return 1;
}   


# _verifyColors only verifies whether the colors listed in the tkg2rc file(s)
# are also listed in the rgb.txt file.  If a user is running on the Sun through 
# another Unix box and possibly(?) and NT, some colors might not be available.
# % tkg2 --checkcolors  will actually try Tk and each color. 
sub _verifyColors {
   my $os = $::TKG2_ENV{-OSNAME};
   return if(&OSisMSWindows());
   my $rgb="";
   if($os eq 'solaris') {
      $rgb = "/usr/openwin/lib/X11/rgb.txt";
      if(! -e $rgb) {
         $rgb = "/usr/X11R6/lib/X11/rgb.txt";
      }
   } elsif($os eq 'linux') {
      $rgb = "/usr/share/X11/rgb.txt";
      if(! -e $rgb) {
         $rgb = "/usr/X11R6/lib/X11/rgb.txt";
      }
   } elsif($os eq 'darwin') {
      $rgb = "/usr/X11/share/X11/rgb.txt";
      $rgb = "/opt/X11/share/X11/rgb.txt"; # 2016/02/27
   }
   open(FH,"<$rgb") or
      do {
            print STDERR "$rgb not opened for color ",
                         "verification because $!\n";
            return;
         };
   local $/ = undef;    # getting ready to slurp whole file in
   my $rgbtext = <FH>;  # slurp it
   close(FH);
   my @testedcolors = ();
   foreach my $color (@{$::TKG2_CONFIG{-COLORS}}) {
     if( $rgbtext !~ /$color/io ) {
        print STDERR "  Bad Color: '$color' is not valid on X-Client\n",
                     "      Remove '$color' from the .tkg2rc file\n",
                     "             '$color' has been removed for this session\n";
        next;
     }
     push(@testedcolors, $color);
   }
   @{$::TKG2_CONFIG{-COLORS}} = @testedcolors;
   return 1;
}
 
1;
