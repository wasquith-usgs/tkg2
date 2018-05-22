package Tkg2::Help::CmdLineHelp;

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
# $Date: 2002/08/26 19:48:59 $
# $Revision: 1.13 $

use strict;
use Exporter;
use SelfLoader;

use Tkg2::Base qw(Message Show_Me_Internals OSisMSWindows);
use Tkg2::Help::Help;

use vars  qw(@ISA @EXPORT_OK);
   @ISA = qw(Exporter SelfLoader);
   
@EXPORT_OK = qw(commandLineHelp);


print $::SPLASH "=";

1;
__DATA__

# commandLineHelp is the single interface to show the command line options
# of tkg2.
sub commandLineHelp {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my $args = shift; # list of values not parsed as command line options
                     # or just file names, hopefully pod.
   
   if(not @$args) {   
      local $/ = undef;
      local *FH;
      my $file = (&OSisMSWindows()) ?
                  File::Spec->catfile("Help","CmdLine.pod") :
                  "$::TKG2_ENV{-TKG2HOME}/Tkg2/Help/CmdLine.pod";
      open(FH, "<$file") or die "Could not open $file because $!\n";
      my $help = <FH>;
      close(FH) or die "Could not close FH for $file\n";
      
      my $pager = (defined $::TKG2_ENV{-PAGER}) ? $::TKG2_ENV{-PAGER} : 'more';
      open(FH,"| $pager") or
             die "Could open FH piped to '$pager' for commandLineHelp\n";
         print FH $help;
      close(FH) or die "Could not close FH for commandLineHelp\n";
      exit;
   }
   
   my @clearly_tkg2_files = ();
   $Tkg2::Help::Help::DESTROYHELPER = 0;
   foreach my $podfile (@$args) {
      push(@clearly_tkg2_files, $podfile), next if($podfile =~ m/\.tkg2/io);
      print $::VERBOSE " Help POD from command line: '$podfile'\n";
      &Help($::MW, $podfile);
   }
   # place just the tkg2 files back onto the command line @ARGV
   @$args = @clearly_tkg2_files;
}

1;
