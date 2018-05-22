package Tkg2::Help::Help;

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
# $Date: 2003/02/14 15:52:58 $
# $Revision: 1.67 $

use strict;
use Exporter;
use SelfLoader;
use vars  qw(@ISA @EXPORT @EXPORT_OK);
   @ISA = qw(Exporter SelfLoader);

use File::Spec;
use File::Basename;
use Tk::Pod::Text;

BEGIN {
  if(eval "use Tk::JPEG") {
     print STDERR "Tkg2-Compile Warning:\n".
                  "  Tk::JPEG module is not installed.\n".
                  "  Screen shot viewing not possible.\n".
                  "  All other aspects of tkg2 in operation.\n";
  }
}

use Tkg2::Base qw(Message Show_Me_Internals OSisMSWindows);

@EXPORT    = qw(Help ScreenShot SpoolCmdLine);

use vars qw($INFOTOPLEVEL $PODHELPER $DESTROYHELPER $SCREENSHOT);

$PODHELPER       = "";
$INFOTOPLEVEL    = "";
$SCREENSHOT      = "";
$DESTROYHELPER   = 1;

print $::SPLASH "=";

1;

__DATA__

sub SpoolCmdLine {
   my ($tw) = @_;
   
   my $file = (&OSisMSWindows()) ?
               File::Spec->catfile("Help","CmdLine.pod") : 
               File::Spec->catfile($::TKG2_ENV{-TKG2HOME}, 
                                  "Tkg2/Help","CmdLine.pod");
                                  
   # determine an appropriate queue to print from
   # the lp -c (lp with copy) is available on most unixes
   # but linux has moved to lpr that I haven't tested yet.
   # The environment variable -PRINTER_QUEUE can be used
   # to force which printer queue will be used.
   my $queue = ($::TKG2_ENV{-PRINTER_QUEUE}) ?
                $::TKG2_ENV{-PRINTER_QUEUE} : 'lp -c';
   
   # build the whole spool command into a single variable
   # to make echoing to the user easier if needed
   my $fullqueue = "$queue $file 2>&1";
   
   print $::VERBOSE " Tkg2-SpoolCmdLine\n",
                    "        Queue = $fullqueue\n";
   
   my $mess = `$fullqueue`; # put stderr into stdout too
   
   if($mess =~ /unknown printer/io or
      $mess =~ /error/io) {
     &Message($::tw,'-generic',"Printing error--$mess.  ".
                               "Queue was $fullqueue");
   }
   else {
     # The usual message seen is echoed here.
     print $::VERBOSE " Tkg2-SpoolCmdLine: successful spool\n";
   }  
}

sub ScreenShot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($tw,$screen)  = @_;
   
   my $dir = (&OSisMSWindows()) ? "Help/ScreenShots/" :
             "$::TKG2_ENV{-TKG2HOME}/Tkg2/Help/ScreenShots/";
   
   my $bgcolor = $::TKG2_CONFIG{-BACKCOLOR};
   
   
   $SCREENSHOT->destroy if( Tk::Exists($SCREENSHOT) and $DESTROYHELPER );

   my $pe = $tw->Toplevel;
   $SCREENSHOT = $pe if($DESTROYHELPER);
   
   my $file = "$dir"."$screen";

   my $finishsub = sub { $SCREENSHOT = "" if($DESTROYHELPER);
                         $pe->destroy; };

   my $f_b1 = $pe->Frame->pack(-side => 'top', -fill => 'x');
      $f_b1->Button(-text    => 'Exit',
                    -command => $finishsub )
           ->pack(-side => 'left');
      $f_b1->Label(-text => " This image is located at: $file")
           ->pack(-side => 'left');

   my $f_photo = $pe->Frame(-background => $bgcolor)
                    ->pack(-fill   => 'both');
   if(-e $file) {
      my $image;
      eval {
        $image = $pe->Photo(-format => 'jpeg',
                            -file   => $file);
      };
      if(not $@) {
         $f_photo->Button(-image  => $image,
                          -relief => 'flat'
                          )
                 ->pack(-padx   => 5,
                        -pady   => 5);
      }
      else {
         $f_photo->Button(-text => "IMAGE GENERATION PROBLEM.\n".
                                   "(Tk::JPEG not installed?)\n\n$@",
                          -relief => 'flat')
                 ->pack();
      }
   }
   else {
      $f_photo->Button(-text   => "$file not found",
                       -relief => 'flat')
              ->pack();
   }
   my $f_b2 = $pe->Frame
                 ->pack(-side   => 'bottom',
                        -fill   => 'x',
                        -expand => 1);
      $f_b2->Button(-text    => 'Exit',
                    -command => $finishsub )
           ->pack(-fill => 'x', -expand => 1);
}


sub Help {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $dir = (&OSisMSWindows()) ? "Help/" :
               "$::TKG2_ENV{-TKG2HOME}/Tkg2/Help/";
   my $tw  = shift;
   my $file;
   $file = (@_) ? shift :
                  $tw->getOpenFile(
                     -title      => "Open POD File",
                     -initialdir => $dir,
                     -filetypes  => [ [ 'Pod Files', [ '.pod' ] ],
                                      [ 'All Files', [ '*'    ] ] ] );
   if(not defined $file or $file eq "") {
      &Message($tw, '-generic',
                  "A POD file was not specified");
      return;
   }
   else {
      $file  = &basename($file);
      $file  = "$dir"."$file";
      $file .= '.pod' if($file !~ m/\.pod/io);
   }
   if(not -e $file) {
      &Message($tw, '-generic',
                  "Pod helper file\n$file\ndoes not exist, ".
                  "Yet!\nFeel free to bug the author about ".
                  "getting this done: wasquith\@usgs.gov");
      return;
   }
   
   $PODHELPER->destroy if( Tk::Exists($PODHELPER) and $DESTROYHELPER );

   my $pe = $tw->Toplevel;
   $PODHELPER = $pe if($DESTROYHELPER);
   $pe->geometry("+0-0")
            unless($::TKG2_CONFIG{-WM_OVERRIDE_POD_GEOMETRY});
   $pe->withdraw;

   my $finishsub = sub { $PODHELPER = "" if($DESTROYHELPER);
                         $pe->destroy; };

   my $f_b1 = $pe->Frame->pack(-side => 'top', -fill => 'x');
      $f_b1->Button(-text    => 'Exit',
                    -command => $finishsub )
           ->pack(-side => 'left');
      $f_b1->Label(-text => " This file is located at: $file")
           ->pack(-side => 'left');

   my $f_pod = $pe->Frame->pack;
   my $pod = $f_pod->PodText(-file       => $file,
                             -scrollbars => 'w'
                            )->pack;

   my $f_b2 = $pe->Frame
                 ->pack(-side   => 'bottom',
                        -fill   => 'x',
                        -expand => 1);
      $f_b2->Button(-text    => 'Exit',
                    -command => $finishsub )
           ->pack(-fill => 'x', -expand => 1);
   $pe->deiconify;
}


1;
