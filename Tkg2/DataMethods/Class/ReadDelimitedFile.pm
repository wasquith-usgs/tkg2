package Tkg2::DataMethods::Class::ReadDelimitedFile;

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
# $Date: 2008/01/28 17:58:59 $
# $Revision: 1.36 $

use strict;
use Tkg2::Base qw(Message strip_space isNumber
                  Show_Me_Internals arrayhasNoUndefs getShortenedFileName);
use Tkg2::DataMethods::Class::MegaCommand qw(MegaCommand);
use Tkg2::Time::TimeMethods;

use File::Basename;
use File::Spec;
use Cwd;

use Tk;
use Exporter;

use vars qw(@ISA @EXPORT_OK %USER_COL_MAP);
@ISA = qw(Exporter);

@EXPORT_OK = qw(ReadDelimitedFile);

print $::SPLASH "=";

%USER_COL_MAP = ( t => 'calctime',
                  d => 'time',
                  n => 'number',
                  s => 'string');  
  

# ReadDelimitedFile
# The sole method to read in generic ASCII files with trememdous flexibility in
# headings, labelings, missing lines, comment lines, and data fields
sub ReadDelimitedFile {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  
   my ($self, $canv, $plot, $template, $para, $showLineTrack) = @_;
             
   my $FIELDCHECK = ($::CMDLINEOPTS{'nofieldcheck'}) ? 0 : 1;
   # turn field checking on?
   
   my %data;
   
   my $file;
   my $oldcwd = &cwd;
   if(not defined $oldcwd) {
      print STDERR "Tkg2-Serious Warning: Perl could NOT determined the ",
                   "current working directory with the Cwd module and method.\n";
      return;
   }
   
   &MegaCommand($para);

   my %para = %$para;
   if($para{-userelativepath}) {
      my $dir;
      if(not defined $template->{-tkg2filename} ) {
         $dir = $oldcwd;
      }
      else {
         $dir = &dirname( $template->{-tkg2filename} );
      }
      chdir($dir) or
         do { 
              print STDERR "Tkg2-Error: ReadDelimitedFile, could not ".
                           "chdir to $dir because $!\n";
              return (undef, undef, $!);
            };
      $file = File::Spec->catfile($dir,$para{-relativefilename});
      if( not -e $file) {
         my $mess = "Tkg2-Error: ReadDelimitedFile.  The file ($file) ".
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

   my ($pe, $line_track) = &_trackingBox($canv,$file) if($showLineTrack);
    
   my (@user_col_types, @type);
   if( $para{-columntypes} ne 'auto' and
       $para{-columntypes} ne 'in file' ) {
      @user_col_types = split(//o,$para{-columntypes});
      @type = map { $USER_COL_MAP{$_} } @user_col_types;                                      
   }
   
   
   # ERROR MESSAGES
   my $_error1 =
      sub { my $file = shift;
            my $mess = "ERROR1: End-Of-File reached on\n".
                       "$file, but still skipping header.";
            &Message($::MW, -generic, $mess);
          };
                     
   my $_error2 =
      sub { my $file = shift;
            my $mess = "ERROR2: End-Of-File reached on\n".
                       "$file, but still loading label lines.";
            &Message($::MW,'-generic',$mess);
          };
                     
   my $_laberror1 =
      sub { my ($file, $ncol, $userwidth)  = @_;
            my $mess = "LABERROR1: ReadDelimitedFile, the number of columns in ".
                       "$file label ($ncol) is not equal to the number of ".
                       "column types specified ($userwidth): @user_col_types";
            &Message($::MW,'-generic',$mess);
          };
          
   my $_laberror2 =
      sub { my ($file, $ncol, $j, $n ) = @_;
            my $mess = "LABERROR2: ReadDelimitedFile, the number of columns in ".
                       "$file is not constant for the labels. ".
                       "First label line was $ncol columns wide. ".
                       "The $j th label line is $n columns wide.";
            &Message($::MW,'-generic',$mess);
          }; 
   my $_error_bad_format1 =
      sub { my ($file, @user_col_types) = @_;
            my $mess = "ERROR BAD FORMAT1 in $file: One or more ".
                       "of the column types do not match either ".
                       "D or d (date or time), N or n  (number), ".
                       "S or s (string), or T or t (calctime).  ".
                       "Here are the formats: ".
                       "'@user_col_types'\nTkg2 is giving up.";
            &Message($::MW, '-generic', $mess);
            return;
          };       
   my $_error_bad_format2 =
         sub { my ($file, @user_col_types) = @_;
               my $mess = "ERROR BAD FORMAT2 in $file: Tkg2 could ".
                          "not map your format line into simple dnst ".
                          "Here are the formats: ".
                          "'@user_col_types'\nTkg2 is giving up.";
               &Message($::MW, '-generic', $mess);
               return;
             };      
   # END OF ERROR MESSAGES
 
 
   # OPEN UP THE FILE AND BEGIN READING                
   # Any file error on opening is returned up to the caller.
   local *FH;      
   local $/ = $::TKG2_ENV{-INPUT_RECORD_SEPARATOR};
   open(FH, "<$file") or return (undef, undef, "$!, zero");
   
   my ($skip, @line, @header, @datatype, $ncol);
   
   # SKIP THE HEADER
   # FIRST SKIP DESIGNATED NUMBER OF LINES
   if($para{-numskiplines} > 0 ) {
      foreach my $skip (1..$para{-numskiplines}) {
         $_ = <FH>;
         &$_error1($file), return if(eof(FH));
      }
   }
   
   my $delimiter           = $para{-filedelimiter};
   my $skipline            = $para{-skiplineonmatch};
   my $invertskipline      = $para{-invertskipline};
   my $skipline_afterlabel = $para{-numskiplines_afterlabel};
   my $linestoread         = $para{-numlinestoread};
   my $thresholds          = $para{-thresholds};
   my $missingval          = $para{-missingval};
   my $labellines          = $para{-numlabellines};
   # READ IN THE LABEL LINES
   LAB_LINE: foreach my $j (1..$labellines) {
      $_ = <FH>;
      &$_error2($file), return if(eof(FH));
      
      # Skip the header
      if(defined $skipline) { # a skip line is defined so do something
         if($invertskipline) { # invert the sense of the regex?
            redo if(not m/$skipline/);
         }
         else {
            redo if(m/$skipline/);
         }
      }
  
      chomp;
      $_ =~ s/^\s+//o;
      $_ =~ s/\s+$//o;
      @line = ($delimiter eq "|") ?
               split(/\|/, $_,-1) :
               split(/$delimiter/, $_,-1);
      
      if($j == 1) {
         $ncol = scalar(@line);
         
         # the user has set the column types already, check the number
         # the number of columns
         if(@user_col_types and @user_col_types ne $ncol) {
           &$_laberror1($file,$ncol,scalar(@user_col_types));
           return;
         }
      }
      elsif($ncol != @line) {
         &$_laberror2($file,$ncol,$j,scalar(@line));
         return;
      }
      
      foreach my $val (@line) {
         $_ =~ s/^\s+//o;
         $_ =~ s/\s+$//o;
      }
      
      # concate the labels together for each column
      foreach my $i (0..$#line) {
         $header[$i] = ($j == 1) ? $line[$i] : $header[$i]."-$line[$i]";
      }
   }  # END LAB_LINE:
   
   # Initialize the column types when something in the label line was read and
   # if and only if it hasn't already been defined by the user above
   # the test on the existance of the type was not added until July 2001 when
   # Pat Murry detected ancillary problems reading in data files.
   @type = map { 'number' } (0..($ncol-1)) if($ncol and not @type);
   
   
   # READ IN THE FORMAT CASTING LINE
   # if and only if the columntypes key has a value of 1
   if( $para{-columntypes} eq 'in file' ) {
     chomp($_ = <FH>);
     s/^\s+//o; # no unquoted whitespace is allowed for proper splitting.
     @user_col_types = ($delimiter eq "|") ? 
                        split(/\|/, $_,-1) :
                        split(/$delimiter/, $_,-1);
     foreach my $val (@user_col_types) { # Boiling the format line down too tdns
       $val =~ s/(\d+)?([TtDdNnSs])(\d+)?/$2/o; # strip the numbers out
       # numbers are stripped out so that RDB files can be read by this
       # ReadDelimitedFile subroutine.
       $val = lc($val); # lower case the characters, just to be paranoid.
       &$_error_bad_format1($file,@user_col_types), return if($val !~ m/[tdns]/io);
     }
     @type = map { $USER_COL_MAP{$_} } @user_col_types; # initialize
     
     # The following trap was made on 2001/09/06 as a users had a file with
     # the numbers FOLLOWING the format and not before.  For example, n4 s6
     # instead of 4n 6s.
     # Since Tkg2 does not use the numbers, I have decided to strip
     # the numbers from the left and right sides of the format type.
     &$_error_bad_format2($file, @user_col_types),
                          return unless(&arrayhasNoUndefs(@type));
   }
   

     
   my %junk; # a temporary trash variable that checks whether
             # repeated column headings are seen
   foreach (@header) {
      if(not exists $junk{$_} ) {
         $junk{$_} = 1;
      }
      else {
         $junk{$_}++;
         $junk{"$_"."$junk{$_}"} = 1;
         $_ = "$_"."$junk{$_}";
      }
   }
  
   # ERROR MESSAGES FOR READING DATA
   my $_dataerror1 =
      sub { my ( $file, $ncol) = ( shift, shift );
            my @line = @_;
            my $n = scalar(@line);
            my $mess = "DATAERROR1: ReadDelimitedFile, number of columns in ".
                       "$file is not constant while reading in data.  ".
                       "The number of columns in header is $ncol, ".
                       "but Tkg2 sees $n in the file.  ".
                       "The line read in is '@line'\n";
            &Message($::MW,'-generic',$mess);
          };
   
   my $_dataerror2 =
      sub { my ($i, $val, $linecount) = @_;
            my $mess = "DATAERROR2: Tkg2 is looking for a number ".
                       "in column $i but $val (no. $linecount) ".
                       "is not a number.  Tkg2 is confused, exiting.";
            &Message($::MW,'-generic',$mess);
          };
   my $_dataerror3 =
      sub { my ($i, $val, $linecount) = @_;
            my $mess = "DATAERROR3: Tkg2 is looking for a date or time ".
                       "in column $i but $val (no. $linecount) ".
                       "does not parse as a date.  Tkg2 is confused, ".
                       "exiting.";
            &Message($::MW,'-generic',$mess);
          };       
    my $_dataerror4 =
      sub { my ($i, $val, $linecount) = @_;
            my $mess = "DATAERROR4: Tkg2 is looking for a precomputed ".
                       "date/time in column $i but $val (no. $linecount) ".
                       "does not parse as a number.  Tkg2 is confused, ".
                       "exiting.";
            &Message($::MW,'-generic',$mess);
          };       

   # ERROR MESSAGES
   
   
   # FINALLY, BEGIN READING AND TESTING THE DATA
   my $linecount = 0;

   # PATH BREAKING WHA: 1/28/2008
   my $path_breaking_linecount = 0; # for massive length files so that
   # we can cut paths (continueous line segments to a smaller size to
   # avoid apparent device limitations of PDF, Ghostscript, and MetaPost
   # See the $...ReadFiles::PATH_BREAKING_THRESHOLD


   while(<FH>) {
     last if (/^__END__/o);  # added for Carolina District
     
     # Skip certain lines if desired
     if(defined $skipline) {
        if($invertskipline) {
           next if(not m/$skipline/); 
        }
        else {
           next if(m/$skipline/);
        }
     }
     
     $linecount++;
     $path_breaking_linecount++; # PATH BREAKING
     next unless($linecount > $skipline_afterlabel);
     last if(    $linestoread ne ""
             and $linecount >  ( $linestoread + 
                                 $skipline_afterlabel
                               )
            );
     # update the tracking box when it is available
     if($showLineTrack) {
        if($linecount == 4000) { $pe->deiconify; } # show the tracking widget
        if($linecount >= 4000 and $linecount =~ m/[0]{3,}$/o) {
           $line_track->configure(-text => "$linecount");
           $pe->update;
        }
     }


     # PATH BREAKING WHA: 1/28/2008
     # If the path threshold is exceeded, reset counter, and foreach
     # column of data, set the value to "".
     if($path_breaking_linecount >
        $Tkg2::DataMethods::Class::ReadFiles::PATH_BREAKING_THRESHOLD) {
       $path_breaking_linecount = 0;
       #print STDERR "PATH BREAKING to ",
       #     $Tkg2::DataMethods::Class::ReadFiles::PATH_BREAKING_THRESHOLD,
       #     " values at line $linecount of the file\n";
       foreach my $i (0..$#line) {
         push(@{$data{$header[$i]}}, ""); 
       }
     }
     # PATH BREAKING WHA: 1/28/2008


     
     chomp($_);
     s/^\s+//o; # no unquoted whitespace is allowed for be the 
     # first characters in a line so that we get expected splitting when
     # plain whitespace is the delimiter.  Trailing whitespace is removed later.
     next unless($_);   # blank lines are skipped entirely
     @line = ($delimiter eq "|") ? 
              split(/\|/, $_,-1) :
              split(/$delimiter/, $_,-1); 
     
     # now check to see that the number of columns remains consistent
     if(not defined $ncol) { # the number of label lines was zero and the 
                             # while loop above this one was never executed
        $ncol = scalar(@line);  # set the num of columns in label line
                                # equal to the num of columns in first data
                                # line
        map { $header[$_] = "v".($_+1) } (0..($ncol-1)); 
        # initialize the column types
        @type = map { 'number' } (0..($ncol-1)); # initialization not previously done                                      
     }
     
     # Error if the number of columns in the label lines is not equal to the data line
     if($ncol ne @line ) {
        &$_dataerror1($file,$ncol,@line);
        return;
     } 
     
     # foreach column in current line, do the field checking
     foreach my $i (0..$#line) { 
        my $val = $line[$i];
           $val =~ s/^\s+//o;
           $val =~ s/\s+$//o;
        
        # Are we going to do something about thresholds?
        if( $thresholds ne 'ignore' ) {
           $val = "", last if( $thresholds eq 'make missing' );
           if($thresholds eq 'substitute') {
              $val =~ s/^>//o;
              $val =~ s/^<//o;
           }
        } 
        
        # BEGIN FIELD CHECKING WITH CAST TYPES
        if($FIELDCHECK and @user_col_types ) { 
           # The @user_col_types means that the user has pre-specified
           # the nature of the column as a date(time), number, or string
           if(not defined $val or $val eq $missingval or $val eq "" ) {
              1;   # Do not test for field type if undef, missing, or null ("")
           }
           elsif( $USER_COL_MAP{$user_col_types[$i]} eq 'number' and
                  not &isNumber($val) ) {
              &$_dataerror2($i,$val,$linecount);  # User is looking for a number
              return;
           }
           elsif( $USER_COL_MAP{$user_col_types[$i]} eq 'time'
                  and not &isTkg2Date($val) ) {
              &$_dataerror3($i,$val,$linecount);
              return;
           }
           elsif( $USER_COL_MAP{$user_col_types[$i]} eq 'calctime' and
                  not &isNumber($val) ) {
              &$_dataerror4($i,$val,$linecount);
              return;
           }
           else {
              # do nothing;
           }
        } # END OF FORMAT CHECKING
        # BEGIN DYNAMIC FIELD DETERMINATION
        elsif($FIELDCHECK) {
           if(not defined $val or $val eq $missingval or $val eq "" ) {
              1;  # Do not test for field type if undef, missing, or null ("")
           }
           else {
              $type[$i] = (&isNumber($val)  ) ? 'number' :
                          (&isTkg2Date($val)) ? 'time'   : 'string'; 
           }
        } # END OF DYNAMIC FIELD DETERMINATION
        else {
          # do nothing
        }
       # load raw data after type checking, time is converted later
       
       push(@{$data{$header[$i]}}, $val);   
         
      $datatype[$i] = $type[$i] if(not defined $datatype[$i] or
                                               $datatype[$i] ne 'string');
      
     }    
     # FINISHED ITERATING THROUGH THE DATA LINE
   }
   # FINISHED READING DATA
   
   close(FH) or do {
                     &Message($::MW, '-fileerror', $!);
                     return (undef, undef, $!);
                   };
   
   $pe->destroy if( Tk::Exists($pe) );                
   
   foreach my $i (0..$#line) {
      $data{"$header[$i]:$datatype[$i]"} = $data{$header[$i]};
      delete($data{$header[$i]});
      $header[$i] .= ":$datatype[$i]";
   }
   
   if(not defined $header[0] or not defined $data{$header[0]}) {
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

     return (\@header, \%data, $linecount);
   }
   
   if(not @{$data{$header[0]}}) {
     my $mess = "Error:  It appears as though no data was actually ".
                "read in.  Please check file reading or megacommand ".
                "settings and try again.";
     print $::BUG $mess;
     
     return (\@header, \%data, $linecount);      
   }   
    
   
   # change back to original directory, not a problem at this point
   # if chdir is unsuccessful, let errors cascade later
   # It is critical earlier that chdir is successful though
   # (see top of subroutine)
   chdir($oldcwd) or
      do { 
           print STDERR "Tkg2-Warn: ReadDelimitedFile, could not chdir ",
                        "to $oldcwd because $!\n";
           return (undef, undef, $!);
         };
         
   # &showME_Data(\%data); # Uncomment the following line to look at all the data

   return (\@header, \%data, $linecount);
}


# This subroutine is duplicated in ReadRDBFile.pm too.
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
   my $pe    = $pw->Toplevel(-title => 'ReadDelimitedFile'); 
   $pe->withdraw;         
   $pe->Label(-text => "Reading large delimited file\n$shortfile",
              -font => $fontb)
      ->pack(-side => 'top', -fill => 'x');
   $pe->Label(-text => 'Passing line: ',
              -font => $fontb)->pack(-side => 'left');
   my $line_track = $pe->Label(-text => "",
                               -font => $font)
                       ->pack(-side => 'left', -fill => 'x');
   return ($pe, $line_track);
}    




# This subroutine is duplicated in ReadRDBFile.pm too.
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
