package Tkg2::DataMethods::Class::ReadRDBFile;

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
# $Date: 2008/01/28 17:59:00 $
# $Revision: 1.38 $

use strict;
use Tkg2::Base qw(Message strip_space isNumber
                  Show_Me_Internals arrayhasNoUndefs getShortenedFileName);
use Tkg2::Time::TimeMethods;
use Tkg2::DataMethods::Class::MegaCommand qw(MegaCommand);

use File::Basename;
use File::Spec;
use Cwd;

use Tk;
use Exporter;

use vars qw(@ISA @EXPORT_OK %RDB_COL_MAP);
@ISA = qw(Exporter);

@EXPORT_OK = qw(ReadRDBFile);

print $::SPLASH "=";

%RDB_COL_MAP = ( t => 'calctime',
                 d => 'time',
                 n => 'number',
                 s => 'string');

# READ IN AN RDB FILE
# RDB is a simple yet extremely flexible ASCII flat file data base structure.
# The basic RDB file of interest to the following ReadRDBFile method
# is as follows:
#
# #This file contains published daily mean streamflow data.
# #
# # This information includes the following fields:
# #
# # site_id  (not included if only one site is shown)
# # datetime    date of measurement
# # value      discharge, in cubic-feet per-second
# #
# #
# datetime	value	code
# 10d	12n	3s
# 06/01/1939@24:00:00	36	
# 19390602	32 
# ....... and so on .........
# RDB Rules that Tkg2 uses
# 1. Lines in the header begin with # and are skipped over
# 2. There is one label line separated by tabs and it is the first line
#      following the last # line
# 3. There is one format line separated by tabs and it is the line following
#      the label line
# 4a. The recognized formats are simply d or D for a date, n or N for a number
#      and s or S for a string.  Tkg2 ignores the integers in the format line
#      as Perl's treatment of anything as a string is capitalized on.
#      The D, N, or S act as a casting mechanism so that Tkg2 will know how
#      to handle the input fields.
# 4b. The integers in RDB as supposed to come before the type as in 8N, but
#      some people create tab delimited files with format as N8 and call
#      them RDB.  Since tkg2 does not use the number anyway, we strip
#      numbers from both sides of the format type.
# 5. Data can be commented out by prepending a # in from of the data lines.
# 6. Constant number of columns.
#        Several error traps are conducted during the reading process, such as
#        checking that the number of columns 'split(/\t/,' remains constant.
# 7. Tkg2 requires that column label NOT be duplicated.  If they are you must
#        load the file as a delimited file: label lines = 1, delimiter = \t,
#        and column types = f (for file).
sub ReadRDBFile {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $plot, $template, $para, $showLineTrack) = @_;

   my $FIELDCHECK = ($::CMDLINEOPTS{'nofieldcheck'}) ? 0 : 1;
   # turn field checking on?
      
   # Set up some constants and declare some variables   

   my $file;
   my $oldcwd = &cwd;
   if(not defined $oldcwd) {
      print STDERR "Tkg2-Serious Warning: Perl could NOT determined the ",
                   "current working directory with the Cwd module and method.\n";
      return;
   }
   
   &MegaCommand($para);
   
   my %para = %$para;  # deref for speed
   if($para{-userelativepath}) {
      my $dir;
      if(not defined($template->{-tkg2filename}) ) {
         $dir = $oldcwd;
      }
      else {
         $dir = &dirname( $template->{-tkg2filename} );
      }
      chdir($dir) or
         do { 
             print STDERR "Tkg2-Error: ReadRDBFile, could not ".
                          "chdir to $dir because $!\n";
             return (undef, undef, $!);
         };
      $file = File::Spec->catfile($dir,$para{-relativefilename});
      if( not -e $file) {
         my $mess = "Tkg2-Error: ReadRDBFile.  The file ($file) ".
                    "does not exist.  **Look very closely at the path ".
                    "construction**\n\nSince you have requested that ".
                    "tkg2 use relative path to find the selected data ".
                    "file, it is possible that you had to go up from ".
                    "the directory that tkg2 is running from ".
                    "or the directory that the tkg2 file is in.  If ".
                    "this is the case, you likely want to AddDataToPlot with ".
                    "relative path usage turned off (see Advanced tab). ".
                    "The relative path feature expects data files to reside ".
                    "in the current directory or below where tkg2 is running. ".
                    "This is considered a feature because it makes batch ".
                    "processing easier and portability of tkg2 based ".
                    "applications more logical.  Your author is open to your ".
                    "comments.\n".
                    "Relative path: $para{-relativefilename}\n".
                    "Directory:     $dir\n";
         &Message($::MW, -generic, $mess);
         return (undef, undef, "No such file, zero");
      }          

   }
   else {
      $file = $para{-fullfilename};
   }
  
   my (@rdb_col_types, @titles, @line, @thresholds);
   my $linecount = 0;
   
   # PATH BREAKING WHA: 1/28/2008
   my $path_breaking_linecount = 0; # for massive length files so that
   # we can cut paths (continueous line segments to a smaller size to
   # avoid apparent device limitations of PDF, Ghostscript, and MetaPost
   # See the $...ReadFiles::PATH_BREAKING_THRESHOLD


   # Error messages
   my $_error1 = sub {
                   my ($file, $ncol, $ntypes) = @_;
                   my $mess = "ERROR1: RDB file $file has $ncol column ".
                              "titles and $ntypes of format.  ".
                              "These numbers are not equal. ".
                              "Tkg2 is confused, exiting\n";
                   &Message($::MW,'-generic',$mess);
                 };   
   my $_error2 = sub {
                   my ($file, $ncol, $n) = @_;
                   my $warn  = "ERROR2: ReadRDBFile number of columns\n".
                               "in $file is not constant while reading\n".
                               "in data.  The number of columns in\n".
                               "header is $ncol, but Tkg2 sees $n in\n".
                               "the file.  The line read in is '@line', which ".
                               "is the $linecount line read.";
                   &Message($::MW, '-generic', $warn);
                 };
   
   my $_error_bad_format1 =
         sub { my ($file, @rdb_col_types) = @_;
               my $mess = "ERROR BAD RDB FORMAT1 in $file: One or more ".
                          "of the column types do not match either ".
                          "D or d (date or time), N or n  (number), ".
                          "S or s (string), T or t (calctime).  ".
                          "Here are the formats: ".
                          "'@rdb_col_types'\nTkg2 is giving up.";
               &Message($::MW, '-generic', $mess);
               return;
             };
             
   my $_error_bad_format2 =
         sub { my ($file, @rdb_col_types) = @_;
               my $mess = "ERROR BAD RDB FORMAT2 in $file: Tkg2 could ".
                          "not map your format line into simple dnst ".
                          "Here are the formats: ".
                          "'@rdb_col_types'\nTkg2 is giving up.";
               &Message($::MW, '-generic', $mess);
               return;
             };
             
   # The showLineTrack dialog box is used only when a huge file is
   # being read in for the first time through the user interface.
   my ($pe, $line_track) = &_trackingBox($canv,$file) if($showLineTrack);    
     
   # OPEN THE FILE                                 
   # Any file error on opening is returned up to the caller.
   local *FH;                                      
   open(FH, "<$file") or return (undef, undef, "$!, zero");
   
   # SKIP THE HEADER, LOAD THE LABEL LINE, AND LOAD THE FORMATS
   local $/ = $::TKG2_ENV{-INPUT_RECORD_SEPARATOR};
   LAB_LINE: while(<FH>) {
      next if (/^\#/o);
      chomp($_);
      @titles  = split(/\t/o, $_, -1);  # the -1 makes undef place holders in the array   
      chomp($_ = <FH>);                 # pull the format line off
      @rdb_col_types = split(/\t/o,$_,-1);
      last LAB_LINE;
   }

   # strip any leading and trailing spaces on a column label
   # all spaces internal to the label will be left as is
   map { s/^\s*(.+)\s*$/$1/o } @titles;
   
   # Error checking
   my $ncol = scalar(@titles); # number of column titles
   foreach my $val (@rdb_col_types) { # Boiling the rdb format line down too dns
      # error check
      &$_error_bad_format1($file,@rdb_col_types), return if($val !~ m/[tdns]/io);
      $val =~ s/\s*(\d+)?([TtDdNnSs])(\d+)?\s*/$2/o; # strip the numbers out (and spaces)
      $val = lc($val);             # lower case the characters, just to be paranoid.
   }
   # @type contains the column types in the long string notation
   my @type = map { $RDB_COL_MAP{$_} } @rdb_col_types; # the official format caster
   
   # The following trap was made on 2001/09/06 as a users had an 'rdb' file
   # with the numbers FOLLOWING the format and not before.  For example, n4 s6
   # instead of 4n 6s.  Since Tkg2 is partially RDB compliant as of version
   # 0.61 and does not use the numbers anyway, I have decided to strip the
   # numbers from the left and right sides of the format type.
   &$_error_bad_format2($file, @rdb_col_types),
                        return unless(&arrayhasNoUndefs(@type));
   
   &$_error1($file,$ncol, scalar(@type)), return if($ncol != @type );
  
   
   # DATA ERRORS
   my $_dataerror1 =
      sub { my ($i, $val, $linecount) = @_;
            my $mess = "ERROR: Tkg2 is looking for a number ".
                       "in column $i but '$val' is not a ".
                       "number on line $linecount.\n".
                       "Tkg2 is confused, exiting.";
            &Message($::MW,'-generic',$mess);
          };
   my $_dataerror2 =
      sub { my ($i, $val, $linecount) = @_;
            my $mess = "ERROR: Tkg2 is looking for a date or time ".
                      "in column $i but $val (no. $linecount) ".
                      "does not parse as a date.  Tkg2 is confused, ".
                      "exiting.";
            &Message($::MW,'-generic',$mess);
          };
   
   
   # END DATA ERRORS
  
   # PREALLOCATE MEMORY FOR DATA STORAGE
   my %data;
   keys(%data)  = scalar(@titles);  # preallocating the keys of the hash
   foreach my $key (@titles) {
      $data{$key} = [ ];  # making each an array reference so that 
      # we can cleanly handle the zero data situation properly.
   }
  
  
   # THE LOOP READING IN THE DATA!!!!!!!!!!!!!  
   # Go about the business of reading the data in
   my $datacount = 0;
   LINE: while(<FH>) {  
     next if (/^\#/o);  # embedded comments are allowed
     last if (/^__END__/o);  # added for Carolina District
     $linecount++;      # counting the number of lines read in.
     $path_breaking_linecount++; # as a linecount, but reset on trigger # PATH BREAKING
     next unless($linecount > $para{-numskiplines_afterlabel});
     last if(    $para{-numlinestoread} ne ""
             and $linecount > ( $para{-numlinestoread} +
                                $para{-numskiplines_afterlabel}
                              )
            );
     # update the tracking box when it is available
     if($showLineTrack) {
        $pe->deiconify if($linecount == 4000); # show the tracking widget
        if($linecount >= 4000 and $linecount =~ m/[0]{3,}$/o) {
           $line_track->configure(-text => "$linecount");
           $pe->update;
        }
     }
     
     # PATH BREAKING WHA: 1/28/2008
     # If the path threshold is exceeded, reset counter, and foreach
     # column of data, set the value to "" and make sure to increment
     # datacount because shortly hereafter the true data for this line
     # number will be loaded in.
     if($path_breaking_linecount >
        $Tkg2::DataMethods::Class::ReadFiles::PATH_BREAKING_THRESHOLD) {
       $path_breaking_linecount = 0;
       #print STDERR "PATH BREAKING to ",
       #     $Tkg2::DataMethods::Class::ReadFiles::PATH_BREAKING_THRESHOLD,
       #     " values at line $linecount of the file\n";
       foreach my $i (0..$#line) {
         $data{ $titles[$i] }->[$datacount] = "";
       }
       $datacount++;
     }
     # PATH BREAKING WHA: 1/28/2008


     chomp($_);                    # remove the trailing \n 
     next unless($_);              # null lines are quietly skipped
     @line = split(/\t/o, $_ ,-1);  # split line up, the -1 push undef values onto array 
     my $n = scalar(@line);
     # check whether the number of columns remains consistent
     &$_error2($file, $ncol, $n), return if($ncol != $n );
    
     # for each of the columns
     foreach my $i (0..$#line) {
        my $val   = $line[$i];
        my $typei = $type[$i];
        # remove and leading and trailing whitespace
        $val =~ s/^\s+//o;
        $val =~ s/\s+$//o; 
        
        # Are we going to do something about thresholds?
        if($para{-thresholds} ne 'ignore') {
           $val = "", last if( $para{-thresholds} eq 'make missing' );
           if($para{-thresholds} eq 'substitute') {
              $val =~ s/^>//o;
              $val =~ s/^<//o;
           }
        }
        
        $data{ $titles[$i] }->[$datacount] = $val;
        
        next unless($FIELDCHECK);
        
        # Do not test for field type if undef, missing, or null ("")
        next, if(   not defined $val 
                 or $val eq $para{-missingval}
                 or $val eq "" );  
        
        # Looking for a number, but it isn't one
        &$_dataerror1($i, $val, $linecount),
              return if( $typei eq 'number' and not &isNumber($val) );
        
        # Looking for a date/time, but it isn't one                                              
        &$_dataerror2($i, $val, $linecount),
              return if( ( $typei eq 'time' and not &isTkg2Date($val) )
                                             or
                         ( $typei eq 'calctime' and not &isNumber($val) ) );
        # No need to test for a string        
     } # END OF COLUMN LOOP
     $datacount++;
     
   } # END OF LINE:
   
   close(FH) or do { 
                     &Message($::MW, '-fileerror', $!);
                     return (undef, undef, $!);
                   };

   $pe->destroy if(Tk::Exists($pe));
 
   foreach my $i (0..$#line) {
      $data{"$titles[$i]:$type[$i]"} = $data{$titles[$i]};
      delete($data{$titles[$i]});
      $titles[$i] .= ":$type[$i]";
   } 
   
   if(not defined $titles[0] or not defined $data{$titles[0]}) {
     my $mess = "Error:  It appears as though no data was actually ".
                "read in.  Please check file reading or megacommand ".
                "settings and try again.";
     print $::BUG $mess;
     
     $mess = "Error: On rare occasions, we do not even have a reference".
             "to work with in the next conditional.  This is".
             "known to at least occur when a megacommand is unsuccessful".
             "because the command can not be found.  Maybe a screwed up".
             "path or a name change in a data retrieval script is at fault.\n";
     print $::BUG $mess;
     
     return (\@titles, \%data, $linecount);
   }
   
   if(not @{$data{$titles[0]}}) {
     my $mess = "Error:  It appears as though no data was actually ".
                "read in.  Please check file reading or megacommand ".
                "settings and try again.";
     print $::BUG $mess;
     
     return (\@titles, \%data, $linecount);      
   }   
   
   # change back to original directory, not a problem at this point
   # if chdir is unsuccessful, let errors cascade later
   # It is critical earlier that chir is successful though (see top of subroutine)
   chdir($oldcwd) or
      do { 
           print STDERR "Tkg2-Warn: ReadRDBFile, could not chdir ",
                        "to $oldcwd because $!\n";
         };
         
   
   # &showME_Data(\%data); # Uncomment the following line to look at all the data
   
   return (\@titles, \%data, $linecount);
}


# This subroutine is duplicated in ReadDelimitedFile.pm too.
# _trackingBox is a label only dialog box that reports which
# lines are being passed up as very large files are read.
sub _trackingBox {
   my ($canv, $file) = @_;
   
   my $shortfile = &getShortenedFileName($file,3);
    
   # Set up a nifty widget that will report the line number that 
   # is being read, for very large data files.  
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};   
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};          
   my $pw    = $canv->parent;          
   my $pe    = $pw->Toplevel(-title => 'ReadRDBFile'); 
   $pe->withdraw;         
   $pe->Label(-text => "Reading large RDB file\n$shortfile",
              -font => $fontb)
      ->pack(-side => 'top', -fill => 'x');
   $pe->Label(-text => 'Passing line: ',
              -font => $fontb)->pack(-side => 'left');
   my $line_track = $pe->Label(-text => "",
                               -font => $font)
                       ->pack(-side => 'left', -fill => 'x');
   return ($pe, $line_track);
}    

# This subroutine is duplicated in ReadDelimitedFile.pm too.
# showME_data can be used to echo the read in data hash to
# standard out for debugging purposes.
sub showME_Data {
   my $data = shift;
   my %data = %$data;  
   foreach my $key (sort keys %data) {
      print STDERR "$key\n";
      map { print STDERR "$_ " } @{$data{$key}};
      print STDERR "\n\n";
   }
}


1;

