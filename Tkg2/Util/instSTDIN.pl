#!/usr/bin/perl -w

# $Author: wasquith $
# $Date: 2000/10/04 23:02:16 $
# $Revision: 1.2 $

$inst = <<HERE;
TEST PLOT::
   x min = 10
   x max = 30
   y origindoit = 0
   y2 origindoit = 0
   plottitle = HELLO WORLD
HERE


&spawn_Tkg2_InstSTDIN(-exec => 'g2', 
                      -inst => $inst,
                      -call => [ 'junk.tkg2' ]  );

exit;


# spawn_Tkg2_InstSTDIN
# spawn Tkg2 with plot instructions passed into a STDIN pipe
# Here is an example call.  All the keys are mandatory
#  The executing tkg2 parent:   -executor     => 'g2', 
#  The instructions to apply:   -instructions => $inst,
#  The command line options
#        and tkg2 file names:   -optsNfiles   => [ 'junk.tkg2' ] or
#                                                'junk.tkg2'
sub spawn_Tkg2_InstSTDIN {
   use strict;
   my %h = @_;
   
   my $head = "spawn_Tkg2_InstSTDIN,";
   if( not exists  $h{-exec} or
       not defined $h{-exec} ) {
      print STDERR "$head -executor is not defined\n";
      return 0;
   }
   if( not exists  $h{-inst} or
       not defined $h{-inst} ) {
      print STDERR "$head -inst, instructions are not defined\n";
      return 0;
   }
   if( not exists  $h{-call} or
       not defined $h{-call} ) {
      print STDERR "$head -call, command line argument(s) and ",
                   "tkg2 file name(s) are not defined\n";
      return 0;
   }
  
   # set up the call
   my @call    = (ref $h{-call}) ? @{$h{-call}} : $h{-call};
   
   local *FH; # so as to not clobber an already open file handle
   
   my $comm = "| $h{-exec} -inst=- @call";
   
   open( FH, $comm)    or die "DIED: $head pipe '$comm' not opened: $!\n";
      print FH $h{-inst};        # dump everything along STDIN into tkg2 
   close(FH)           or die "DIED: $head pipe '$comm' not closed: $!\n";
   
   return 1;
}
