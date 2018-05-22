#!/usr/bin/perl -w
=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith
 with major contributions by David K. Yancey and special thanks
 to Willard Gibbons.
     
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
# $Date: 2000/10/06 14:05:10 $
# $Revision: 1.14 $

use strict;
use vars qw(%CMDS);

use Data::Dumper;

my $Version  = 0.90;
my %PageSize = ( '8.5x11'   => { -x => 0,
                                 -y => 0 },
                 '11x8.5'   => { -x =>  100,
                                 -y => -100 },
                                 
                 '11x17'    => { -x => 92,
                                 -y => 215 },
                 '17x11'    => { -x => 97,
                                 -y => 214 },
                                 
                 '11x14'    => { -x => 94,
                                 -y => 95 },
                 '14x11'    => { -x => 94,
                                 -y => 95 },
                                 
                 '8.5x14'   => { -x => 0,
                                 -y => 100 },
                 '14x8.5'   => { -x => 0,
                                 -y => 100 },
                                 
                 '24x32'    => { -x => 1000,
                                 -y => 2000 },
                                 
                 '22x34'    => { -x => 791, 
                                 -y => 1612 },
                 '34x22'    => { -x => 791, 
                                 -y => 1612 },
                                 
                 '16.75x22' => { -x => 606, 
                                 -y => 1085 },
                                 
                 '17x28.5'  => { -x => 612,
                                 -y => 1360 }
               );

# PROCESS COMMAND LINE OPTIONS
use Getopt::Long;   # imports the &GetOptions subroutine
my @options = qw ( h
                   help
                   
                   pagehash
                   pagesize=s
                   
                   x=i
                   y=i
                   
                   file=s
                   
                   lp
                   d=s
                   
                   v
                   version
                   
                   clean); # these are the valid command line options
&GetOptions(\%CMDS, @options); # parse the command line options
# END COMMAND LINE OPTIONS

if($CMDS{version} or $CMDS{v}) {
  print " tkps2ps.pl: $Version\n",
        "    by William H. Asquith <wasquith\@usgs.gov>\n";
  exit;
}

if($CMDS{h} or $CMDS{help}) {
   print <<HERE;
 tkps2ps.pl $Version -- A tool to filter Perl/Tk postscript output
   Usage:  tkps2ps.pl <options> <postscript files>
       Options:
          -clean            Unlink the -file=filename file when
                              finished.
                              
          -d=printer        Set the printer destination for the lp
                              command.  The presence of --d will
                              turn -lp on.
                              
          -file=filename    Create new postscript file as
                              filename.              
          
          -h | -help        This help.
          
          -lp               Spool the new postscript to lp command,
                              if and only if an output file name
                              has been provided.
          
          -pagehash         The \%PageSize hash of translation
                              instructions is dumped to standard out.
                              
          -pagesize=WWxHH   Translate WWxHH according to
                              the \%PageSize hash.
                              
          -x=i              Translate x position by i pixels.
          -y=i              Translate y position by i pixels.

       Notes:
         If no <postscript files> are given, then tkps2ps.pl 
         expects postscript to be coming from standard input.
         
         If no -file is provided, then the modified postscript
         if dumped to standard output.
         
         Expect odd behavior to result if multiple postscript
         files are provided standard input or multiple postscript
         files are written to standard output.
                      
   Examples of the command line
   % tkps2ps.pl --x=100 --y=250  11x17.ps
      Translate the x and y position by 100 and 250 pixels for
      the 11x17.ps file.
      
   % tkps2ps.pl --x=100 --lp --d=afucolor  11x17.ps
      Translate the x position by 100 pixels and spool the 11x17.ps
      file to the afucolor printer.
      
   % tkps2ps.pl -file=tempps -clean -lp -d=afucolor \
                -pagesize=8.5x14 8.5x14.ps
      Spool the 8.5x14.ps file as tempps to the afucolor printer
      using the translation values in the \%PageSize hash.  The
      -clean option deletes tempps when finished.
      
   % tkps2ps.pl --file=newfile -pagesize=8.5x14 8.5x14.ps
      Generate a new postscript file called newfile from the 8.5x14.ps
      file using the translation values in the \%PageSize hash.
      
   % tkps2ps.pl -pagesize=8.5x14 8.5x14.ps | lp -d opus
      Dumped the translated postcript of 8.5x14.ps to stdout out
      using the translation values in the \%PageSize hash.  Pipe the
      stdout directly to the opus printer.
      
HERE
   
   exit;
}

if($CMDS{pagehash}) {
   my $dumpedHash = Data::Dumper->Dump([\%PageSize], [ qw(PageSize) ] );
   
   print <<HERE;
 tkps2ps.pl $Version -- A tool to filter Perl/Tk postscript output
   PageSize Hash:  WWxHH => direction => pixels to translate
     $dumpedHash

HERE
   
   exit;

}


# Enforce consistency checks
die "Died: --pagesize can not be used with --x and/or --y or vis versa.\n"
   if(exists $CMDS{pagesize} and (exists $CMDS{x} or exists $CMDS{y}) );
   
die "Died: Can not -lp with optional -d if an output -file is not provided.\n"
   if((exists $CMDS{lp} or $CMDS{d}) and not exists $CMDS{file});
# End of consistency checks

# What is the input postscript source and other parameters?
my $infile      = (@ARGV)       ? shift(@ARGV) : "/dev/stdin";
my $outfile     = ($CMDS{file}) ? $CMDS{file}  : "/dev/stdout";
my $printer     =  $CMDS{d};
my $youCanSpool = ($CMDS{lp} or $printer) ? 1 : 0;
my $pagesize    =  $CMDS{pagesize};

my ($Xadjust, $Yadjust);
if($CMDS{pagesize} and exists $PageSize{$pagesize}) {
   $Xadjust = $PageSize{ $pagesize }->{-x};
   $Yadjust = $PageSize{ $pagesize }->{-y};
}
elsif($CMDS{pagesize} and not exists $PageSize{$pagesize}) {
   die "Died: --pagesize=$pagesize does not exist in the \%PageSize hash\n";
}
else {
   $Xadjust = ($CMDS{x}) ? $CMDS{x} : 0;
   $Yadjust = ($CMDS{y}) ? $CMDS{y} : 0;
}
# End of program setup

# Begin the core operations on the postscript files
open(INFH,"<$infile")   or
     die "$infile not opened because $!\n";
     
open(OUTFH,">$outfile") or
     die "$outfile not opened because $!\n";

my $found_page = 0;
while(<INFH>) { # reads each line into $_
   if(not $found_page and $_ =~ m/^%%Page: 1 1/o) {
      $found_page = 1;
      print OUTFH $_;
      $_ = <INFH>;
      print OUTFH $_;
      $_ = <INFH>;
      chomp($_);
      my ($X, $Y, $REST) = split(/\s+/o, $_);
      $X += $Xadjust;
      $Y += $Yadjust;
      print OUTFH join(" ", $X, $Y, $REST),"\n";
      next;
   }
   print OUTFH $_;
}
close(INFH);
close(OUTFH);
# End of the postscript file operations

# Handle printing operations
print(($printer) ? `lp -c -d $printer $outfile` :
                   `lp -c $outfile`)
    if($youCanSpool and $outfile !~ m/stdout/o );

# Remove the output file if the output file isn't wanted permanently
unlink($outfile) if(-e $outfile and $CMDS{clean});

exit;
