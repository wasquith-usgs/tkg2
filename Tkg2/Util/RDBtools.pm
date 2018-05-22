package Tkg2::Util::RDBtools;

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith
 with major contributions by David K. Yancey.
     
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
# $Date: 2002/08/07 18:26:57 $
# $Revision: 1.9 $

use strict;
use vars qw(@ISA @EXPORT_OK $benchit);

use Benchmark;
use Date::Calc qw(Delta_Days);
# Delta_Days
# $Dd = &Delta_Days($year1,$month1,$day1, $year2,$month2,$day2);

use Exporter;
use SelfLoader;
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw($benchit
                parseRDBheader
                optime_fixformRDB
                convert_to_tkg2_time
                spliceDATE_TIME_inRDB
                spliceYEAR_MONTH_DAY_optionalTIME_inRDB);

use constant S24 => scalar 24; 
use constant S60 => scalar 60;

$benchit = &reallybenchit();
# $benchit becomes a subroutine reference and $t remains visible
sub reallybenchit {
   my $t = 0;
   return sub { return (not $t) ?
       ("\nStart Benchmark\n",$t = new Benchmark)[0]       :
       (timestr(timediff($t, new Benchmark))."\n",$t=0)[0] };
}

1;

__DATA__


sub parseRDBheader {
   my %ARGS = @_;
   my %HDR;
   local *RDB; # for safety
   
   my $infile = $ARGS{-file}; 
      $infile = '/dev/stdin' if(not defined $infile or
                                $infile =~ m/stdin/io);
   open(RDB, "<$infile") or return "$infile: $!";
   select((select(RDB),$|=1)[0]);  # autobuffering off
   
   my ($i,$j);
   my ($Identifier, $inkey, $inquote, $Keyword, $Value);
   my (@CHARS, @Ident, @Val, @Key);
   
   while(<RDB>) {
      last unless(/^#/o);
      chomp && s|\# //||; # strip the '# //' characters from line
   
      @CHARS = split(//,$_);
      $i = 0; # reset the index counter to zero because on new line

      # identifier is first string delimited by whitespace
      $Ident[$i] = $CHARS[$i], $i++ until($CHARS[$i] eq " ");
      
      $Identifier = join('', @Ident);
      @Ident = ();
   
      # seach for keyword=value fields until EOL
      $inkey   = 1;
      $inquote = $j = 0;
      $i++;
      until($i > $#CHARS) {
         ($inkey) ? $Key[$j]=$CHARS[$i] :
                    $Val[$j]=$CHARS[$i] ;
   
         $i++; $j++;

         # get keyword on left of =
         if( $CHARS[$i] eq "=" ) {
            $Keyword = join('', @Key);
            @Key   = ();
            $inkey = $j = 0;
            $i++;
            $inquote = 1 if $CHARS[$i] eq '"';
         }

         # get value on right of =
         # if value not quoted and encountered a space or end of line
         elsif( not $inkey and not $inquote
                           and
               ( $CHARS[$i] eq " " or $i == $#CHARS ) ) {
            $Value = join('', @Val);
            $HDR{$Identifier}->{$Keyword} = $Value;
            @Val   = ();
            $inkey = 1;
            $j     = 0;
	         $i++;
         }
         # if value quoted and encountered the closing quote
         elsif( $inquote and $CHARS[$i] eq '"' ) {
            # we have complete quoted value; add ending quote
            $Value   = join('', @Val,'"');
            $HDR{$Identifier}->{$Keyword} = $Value;
            @Val     = ();
            $inkey   = 1;
            $inquote = $j = 0;
            $i += 2;		# ending quote is followed by space
         }
         else {
            # do nothing
         }
         
      } # end until($i > $#CHARS) loop
   
   } # end of the while loop
   close(RDB);
   
   my $trim = $ARGS{-trim};
   if(defined $trim and $trim) {
      foreach my $id (sort keys %HDR) {
         map { $HDR{$id}->{$_} =~ s/^"//;
               $HDR{$id}->{$_} =~ s/"$//;
               $HDR{$id}->{$_} =~ s/^\s+//;
               $HDR{$id}->{$_} =~ s/\s+$//;
             } sort keys %{$HDR{$id}};
      }
   }
   
   my $debug = $ARGS{-debug};
   if(defined $debug and $debug) {
      print STDERR "parseRDBheader====================BEGIN\n";
      foreach my $id (sort keys %HDR) {
         map { print STDERR "$id$_ => $HDR{$id}->{$_}\n" }
               sort keys %{$HDR{$id}};
      }
      print STDERR "parseRDBheader======================END\n";
   }
   
   return (wantarray) ? %HDR : { %HDR };
}

# takes an rdb input file and combines the DATA and TIME columns
# if and only if they both exist.  The file is duplicated if they
# are not
sub spliceDATE_TIME_inRDB {
   my %ARGS = @_;
 
   my $infile = $ARGS{-input}; 
      $infile = '/dev/stdin' if(not defined $infile   or
                                $infile =~ m/stdin/io or
                                not -e $infile);
   
   
   my $outfile = $ARGS{-output};
      $outfile = '/dev/stdout' if(not defined $outfile or
                                  $outfile =~ m/stdout/io);
   
   local *INFH; local *OUTFH;
   open(INFH, "<$infile" ) or return  "'$infile' not opened because $!";
   open(OUTFH,">$outfile") or return "'$outfile' not opened because $!";
   select((select(STDOUT),$|=1)[0]);  # autobuffering off
   
   my (@COLUMNS, @FORMAT, @LINE, @COLUMNS2, @FORMAT2, %DATA);
   my $there_is_a_minute_column = 0;
   while(<INFH>) {
      if(/^#/o) {
         print OUTFH;
         next;
      }
      chomp;
      @COLUMNS = split(/\t/o,$_,-1);
      foreach my $col (@COLUMNS) {
        ($col,$there_is_a_minute_column) = ('TIME',1) if($col eq 'MINUTE');
      }
      chomp($_=<INFH>);
      @FORMAT  = split(/\t/o,$_,-1);
      last;
   }   
   
   my $there_is_a_DATE_field = 0;
   my $there_is_a_TIME_field = 0;
   my $there_is_a_DATE_and_a_TIME_field = 0;
   foreach my $column (@COLUMNS) {
      $there_is_a_DATE_field = 1 if($column eq 'DATE');
      $there_is_a_TIME_field = 1 if($column eq 'TIME');
   }
   if($there_is_a_DATE_field and $there_is_a_TIME_field) {
      $there_is_a_DATE_and_a_TIME_field = 1;
      my $i = 0;
      foreach my $col (@COLUMNS) {
         $i++, next if($col eq 'TIME');
         push(@COLUMNS2, ($col eq 'DATE') ? 'DATE_TIME' : $col );
         push(@FORMAT2,  ($col eq 'DATE') ? 'd' : $FORMAT[$i] );
         $i++;
      }
      print OUTFH
        "#\n",
        "# This file has been modified.  Originally there were separate\n",
        "# DATE and TIME columns.  These columns have been combined into\n",
        "# a single column titled DATE_TIME.  There is a single space\n",
        "# between the date and time strings.\n#\n";
   }
   else {
      @COLUMNS2 = @COLUMNS;
       @FORMAT2 =  @FORMAT;
   }

   print OUTFH join("\t",@COLUMNS2),"\n";
   print OUTFH join("\t", @FORMAT2),"\n";

   while(<INFH>) {
      %DATA = ();
      chomp;
      if($_ !~ /\t/) {
        print "$_\n";
        next;
      }
      @LINE = split(/\t/o,$_,-1);
      @DATA{@COLUMNS} = @LINE;
      if($there_is_a_DATE_and_a_TIME_field) {
         # Some programs produce a time component in hhmm or hhmmss
         # format.  The data parsing algorithm in Date::Manip will
         # not handle something like this: 2001/10/02 1345,
         # but will handle something like this: 2001/10/02 13:45
         # The colons are pretty important, so this conditional insures
         # that things work.
         if($DATA{TIME} !~ /:/o) {
            if($there_is_a_minute_column) {
              $DATA{TIME} = &minutes2hhmmss($DATA{TIME});
            }
            else {
               my ($h, $m, $s) = $DATA{TIME} =~ /(\d{2})(\d{2})?(\d{2})?/;
               $DATA{TIME} = ($h eq "") ? join(":", ('00','00','00') ) :
                             ($m eq "") ? join(":", ($h  ,'00','00') ) :
                             ($s eq "") ? join(":", ($h  ,  $m,'00') ) :
                                          join(":", ($h  ,  $m,  $s) ) ;
            }
         }
         $DATA{DATE_TIME} = "$DATA{DATE} $DATA{TIME}";
         delete $DATA{DATE};
         delete $DATA{TIME};
      }
      @LINE = @DATA{@COLUMNS2};
      print OUTFH join("\t",@LINE),"\n";
   }
   close(INFH); close(OUTFH);
}

# takes an rdb input file and combines the YEAR, MONTH, DAY, and
# optional TIME columns if and only if they all exist.
# The file is duplicated if they are not.
# Note the Day is optional and assumed to be 01 if not.
sub spliceYEAR_MONTH_DAY_optionalTIME_inRDB {
   my %ARGS = @_;
 
   my $infile = $ARGS{-input}; 
      $infile = '/dev/stdin' if(not defined $infile   or
                                $infile =~ m/stdin/io or
                                not -e $infile);
   
   
   my $outfile = $ARGS{-output};
      $outfile = '/dev/stdout' if(not defined $outfile or
                                  $outfile =~ m/stdout/io);
   
   local *INFH; local *OUTFH;
   open(INFH, "<$infile" ) or return  "'$infile' not opened because $!";
   open(OUTFH,">$outfile") or return "'$outfile' not opened because $!";
   select((select(STDOUT),$|=1)[0]);  # autobuffering off
   
   my (@COLUMNS, @FORMAT, @LINE, @COLUMNS2, @FORMAT2, %DATA);
   my $there_is_a_minute_column = 0;
   while(<INFH>) {
      if(/^#/o) {
         print OUTFH;
         next;
      }
      chomp;
      @COLUMNS = split(/\t/o,$_,-1);
      foreach my $col (@COLUMNS) {
        ($col,$there_is_a_minute_column) = ('TIME',1) if($col eq 'MINUTE');
      }
      chomp($_=<INFH>);
      @FORMAT  = split(/\t/o,$_,-1);
      last;
   }   
   
   my $there_is_a_YEAR_field  = 0;
   my $there_is_a_MONTH_field = 0;
   my $there_is_a_DAY_field   = 0;
   my $there_is_a_TIME_field  = 0;
   my $there_are_YMD_fields   = 0;
   my $there_is_a_TIME_field  = 0;
   foreach my $column (@COLUMNS) {
      $there_is_a_YEAR_field  = 1 if($column eq 'YEAR');
      $there_is_a_MONTH_field = 1 if($column eq 'MONTH');
      $there_is_a_DAY_field   = 1 if($column eq 'DAY');
      $there_is_a_TIME_field  = 1 if($column eq 'TIME');
   }
   if(    $there_is_a_YEAR_field  and
          $there_is_a_MONTH_field ) {
      $there_are_YMD_fields = 1;
      
      if( not $there_is_a_TIME_field ) {
         if( not $there_is_a_DAY_field) {
           print OUTFH
             "#\n",
             "# This file has been modified.  Originally there were separate\n",
             "# YEAR and MONTH.  Day of 01 has been assumed at 000000 hours.\n",
             "# These columns have  been combined into a single column\n",
             "# titled DATE_TIME.  There is a single space between the date\n",
             "# and time strings.\n#\n";
         }
         else {
           print OUTFH
             "#\n",
             "# This file has been modified.  Originally there were separate\n",
             "# YEAR, MONTH, DAY and no TIME columns.  These columns have\n",
             "# been combined into a single column titled DATE_TIME.  There\n",
             "# is a single space between the date and time strings.\n#\n";
         }
      }
      else {
         $there_is_a_TIME_field = 1;
         print OUTFH
           "#\n",
           "# This file has been modified.  Originally there were separate\n",
           "# YEAR, MONTH, DAY and TIME columns.  These columns have\n",
           "# been combined into a single column titled DATE_TIME.  There\n",
           "# is a single space between the date and time strings.\n#\n";
      }
      my $i = 0;
      foreach my $col (@COLUMNS) {
         $i++, next if($col eq 'MONTH' or
                       $col eq 'DAY'   or
                       $col eq 'TIME' );
         push(@COLUMNS2, ($col eq 'YEAR') ? 'DATE_TIME' : $col );
         push(@FORMAT2,  ($col eq 'YEAR') ? 'd' : $FORMAT[$i] );
         $i++;
      }
   }
   else {
      @COLUMNS2 = @COLUMNS;
       @FORMAT2 =  @FORMAT;
   }

   print OUTFH join("\t",@COLUMNS2),"\n";
   print OUTFH join("\t", @FORMAT2),"\n";

   while(<INFH>) {
      %DATA = ();
      chomp;
      @LINE = split(/\t/o,$_,-1);
      @DATA{@COLUMNS} = @LINE;
      if($there_are_YMD_fields) {
         my $d = ($there_is_a_DAY_field) ? &show2digits($DATA{DAY}) : "01";
         my $m = &show2digits($DATA{MONTH});
         if($there_is_a_TIME_field and $DATA{TIME} !~ /:/o) {
            if($there_is_a_minute_column) {
              $DATA{TIME} = &minutes2hhmmss($DATA{TIME});
            }
            else {
              my ($h, $m, $s) = $DATA{TIME} =~ /(\d{2})(\d{2})?(\d{2})?/;
              $DATA{TIME} = ($h eq "") ? join(":", ('00','00','00') ) :
                            ($m eq "") ? join(":", ($h  ,'00','00') ) :
                            ($s eq "") ? join(":", ($h  ,  $m,'00') ) :
                                         join(":", ($h  ,  $m,  $s) ) ;
            }
         }
         $DATA{DATE_TIME} = ($there_is_a_TIME_field) ?
                            "$m/$d/$DATA{YEAR} $DATA{TIME}" :
                            "$m/$d/$DATA{YEAR}";
         delete $DATA{MONTH};
         delete $DATA{DAY};
         delete $DATA{YEAR};
         delete $DATA{TIME};
      }
      @LINE = @DATA{@COLUMNS2};
      print OUTFH join("\t",@LINE),"\n";
   }
   close(INFH); close(OUTFH);
}


sub show2digits { return sprintf("%2.2d",$_[0]) }


sub optime_fixformRDB {
   my %ARGS = @_;
 
   my $infile = $ARGS{-input}; 
      $infile = '/dev/stdin' if(not defined $infile   or
                                $infile =~ m/stdin/io or
                                not -e $infile);
   
   
   my $outfile = $ARGS{-output};
      $outfile = '/dev/stdout' if(not defined $outfile or
                                  $outfile =~ m/stdout/io);
   
   my $format = uc($ARGS{-format});
      $format = "A4 A2 A2" unless(defined $format);
   my $yrin   = 0;
   # the default format is YYYYMMDD  
   
   my %Table = (
      'YYYY/MM/DD'         => ['A4  x A2 x A2', 0],
      'YYYY.MM.DD'         => ['A4  x A2 x A2', 0],
      'YYYYMMDD'           => ['A4 A2 A2',      0],
      
      'YYYYMMDDHH:MM:SS'   => ['A4 A2 A2   A2 x A2 x A2', 0],
      'YYYYMMDD\@HH:MM:SS' => ['A4 A2 A2 x A2 x A2 x A2', 0],
      'YYYYMMDD HH:MM:SS'  => ['A4 A2 A2 x A2 x A2 x A2', 0],
      
      'YYYYMMDDHH:MM'      => ['A4 A2 A2   A2 x A2', 0],
      'YYYYMMDD@HH:MM'     => ['A4 A2 A2 x A2 x A2', 0],
      'YYYYMMDD HH:MM'     => ['A4 A2 A2 x A2 x A2', 0],
      
      'YYYYMMDDHH'         => ['A4 A2 A2   A2', 0],
      'YYYYMMDD@HH'        => ['A4 A2 A2 x A2', 0],
      'YYYYMMDD HH'        => ['A4 A2 A2 x A2', 0],
      
      'MMDDYYYY'           => ['A2    A2   A4', 2],
      'MM/DD/YYYY'         => ['A2  x A2 x A4', 2],
      'MM.DD.YYYY'         => ['A2  x A2 x A4', 2],
      
      'MM/DD/YYYY@HH:MM:SS' => ['A2 x A2 x A4 x A2 x A2 x A2', 2],
      'MM.DD.YYYY@HH:MM:SS' => ['A2 x A2 x A4 x A2 x A2 x A2', 2],
      'MM/DD/YYYY HH:MM:SS' => ['A2 x A2 x A4 x A2 x A2 x A2', 2],
      'MM.DD.YYYY HH:MM:SS' => ['A2 x A2 x A4 x A2 x A2 x A2', 2],
   );
   
   ($format, $yrin) = @{$Table{$format}} if( $format =~ m/Y/o
                                                  and
                                            exists $Table{$format} );
   
   local *INFH; local *OUTFH;
   open(INFH, "<$infile" ) or return  "'$infile' not opened because $!";
   open(OUTFH,">$outfile") or return "'$outfile' not opened because $!";
   select((select(STDOUT),$|=1)[0]);  # autobuffering off
   
   my (@COLUMNS, @FORMAT, @LINE, @dfields);
   while(<INFH>) {
      print OUTFH;
      next if(/^#/o);
      chomp;
      @COLUMNS = split(/\t/,$_,-1);
      chomp($_=<INFH>);
      s/d/t/g; s/D/T/g;
      @FORMAT  = split(/\t/,$_,-1);
      print OUTFH "$_\n";
      last;
   }   
   
   map { push(@dfields,$_) if($FORMAT[$_] =~ m/t/io) } (0..$#FORMAT);
   
   while(<INFH>) {
      chomp;
      @LINE = split(/\t/,$_,-1);
      foreach my $i (@dfields) {
         my @vals = unpack($format, $LINE[$i]);
         $LINE[$i] = &convert_to_tkg2_time(splice(@vals,$yrin,1),@vals);
      }
      print OUTFH join("\t",@LINE),"\n";
   }
   close(INFH); close(OUTFH);
}


sub convert_to_tkg2_time {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = @_;
   return undef if(not defined $yyyy or
                   not defined $mm   or
                   not defined $dd );
   # use foreach's aliasing feature to make sure that undefined
   # fields take on a zero value
   map { $_ = 0 if not defined } ($hh, $min, $ss);
   
   return &_dayhhmmss2days(
          &Delta_Days( 1900, 1, 1, $yyyy, $mm, $dd ),
                                   $hh,  $min, $ss ); 
}            


# _dayhhmmss2days:
# convert a list of (days, hours, minutes, seconds) to 
# a real number days.frac
sub _dayhhmmss2days {
   return ($_[0]+($_[1]+(($_[2]+($_[3]/S60))/S60))/S24);
}


sub minutes2hhmmss {
   my $min = $_[0];  # incoming minutes into day
   $min /= 60; # convert to hours and fractional hours
   my ($hh, $frh) = split(/\./o,$min,2);
   $hh = &show2digits($hh);
   return "$hh:00:00" unless($frh);
   
   $frh = ".$frh";
   $frh *=60;  # convert to minutes and fractional minutes
   my ($mm, $frm) = split(/\./o,$frh,2);
   $mm = &show2digits($mm);
   return "$hh:$mm:00" unless($frm);
   
   $frm  = ".$frm";
   $frm *= 60; # convert to seconds and fractional seconds
   my ($ss, $frs) = split(/\./o,$frm,2);
   $ss = &show2digits($ss);
   return "$hh:$mm:$ss";
   
   # follow is not run as we are fully tested on fractional seconds
   #return "$hh:$mm:$ss" unless($frs);
   
   #$frs = ".$frs";
   #$ss += $frs;
   #return "$hh:$mm:$ss";
}

1;
