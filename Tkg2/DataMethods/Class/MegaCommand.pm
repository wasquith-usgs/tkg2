package Tkg2::DataMethods::Class::MegaCommand;

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
# $Date: 2002/08/26 19:48:29 $
# $Revision: 1.11 $

use strict;
use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(MegaCommand DeleteMegaCommandFiles);

use Tkg2::Base qw(Show_Me_Internals OSisMSWindows);

# MegaCommand provides the external hook to the system for running
# arbitrarily complicated commands, programs, or pipelines and 
# collecting their standard output.  The standard output is collected
# into files called megacommand files.  Because the user might want to
# run multiple megacommands, we increment the megacommand file name
# by one each time this subroutine is run.
sub MegaCommand {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   return if(&OSisMSWindows());
       
   my $para = shift;
   return if not $para->{-megacommand};
   
   my $file     = $::TKG2_ENV{-MEGACMD_BASENAME};
   my $megcount = scalar @{$::TKG2_ENV{-MEGACMD_FILES}};
         $file .= $megcount; # add the mega file count number
   $file = File::Spec->catfile($::TKG2_ENV{-HOME},$file);
   push(@{$::TKG2_ENV{-MEGACMD_FILES}}, $file);
   
   my $moreargs = (defined $::CMDLINEOPTS{'megacmd_args'}) ?
                           $::CMDLINEOPTS{'megacmd_args'}  : "";
      $moreargs =~ s/_/ /g; # remove all underscores and replace with spaces
      
   my $text = "\n        MEGA: %% $para->{-megacommand} $moreargs %%\n".
                "        MEGA: Results of STDOUT directed to \n";
   if($::CMDLINEOPTS{'megacmd_show'}) {
      print STDOUT $text;
   }
   else {
      print $::VERBOSE $text;
   }
      
            
   if($para->{-megacommand} =~ m/^\s*pipe:\s*(.+)\s*/o or
      $para->{-megacommand} =~ m/^\s*filter:\s*(.+)\s*/o) {
      system("cat $para->{-fullfilename} | $1 $moreargs > $file");
      rename("$file", "$para->{-fullfilename}") or
            print STDERR " Tkg2--Megacommand: Could not rename '$file'",
                         " to '$para->{-fullfilename}'\n";
   }
   else {
      system("$para->{-megacommand} $moreargs > $file");
      $para->{-fullfilename}    = $file;
      $para->{-userelativepath} = 0; # should already be done, but do again
                                  # to absolutely make sure.
                                  # All Megacommand stuff will use absolute
   }
   
   if($::CMDLINEOPTS{'megacmd_show'}) {
      print STDOUT "        MEGA: $file\n",
                   "        MEGA: which had ";
   }
   else {
      print $::VERBOSE "        MEGA: $file\n",
                       "        MEGA: which had ";
   }
   
   if($::CMDLINEOPTS{'megacmd_show'}) {
      print STDOUT "\n# MEGA: STDOUT contents of the megacommand.\n";
      system("cat $file");
      print STDOUT "# MEGA: STDOUT contents of the megacommand.\n";
   }
}

sub DeleteMegaCommandFiles {
   return if($::CMDLINEOPTS{'megacmd_keep'});
   return if(&OSisMSWindows());
   unless( $$::CMDLINEOPTS{'megacmd_keep'} ) {
      foreach my $megacmd_file (@{$::TKG2_ENV{-MEGACMD_FILES}}) {
         next unless(-e $megacmd_file);
         print $::VERBOSE "Tkg2-Unlinking megacommand file $megacmd_file\n";
         unlink($megacmd_file) or 
               print STDERR "Tkg2--warning: Could not unlink $megacmd_file\n";
      }
      print STDERR "\n";
   }
}

1;
