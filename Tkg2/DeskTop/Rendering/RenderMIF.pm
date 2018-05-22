package Tkg2::DeskTop::Rendering::RenderMIF;

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
# $Date: 2005/02/23 17:57:47 $
# $Revision: 1.14 $

use strict;

use File::Basename;
use Cwd;
use Tkg2::Base qw(Show_Me_Internals);
use Tkg2::DeskTop::Rendering::RenderPS;
use Exporter;
use SelfLoader;

use vars  qw( @ISA @EXPORT $PSTOEDITX $TKMIFFIX $LASTSAVEDIR);
@ISA    = qw( Exporter SelfLoader );
@EXPORT = qw( RenderMIF );

print $::SPLASH "=";

$LASTSAVEDIR = "";
$PSTOEDITX   = $::TKG2_ENV{-UTILITIES}->{-PSTOEDIT_EXEC};
$TKMIFFIX    = $::TKG2_ENV{-UTILITIES}->{-TKMIFFIX_EXEC};
print STDERR "Tkg2-warning, RenderMIF: pstoedit utility path is undefined.\n"
             if(not $PSTOEDITX);
print STDERR "Tkg2-warning, RenderMIF: tkmiffix utility path is undefined.\n"
             if(not $TKMIFFIX);
1;
__DATA__

sub RenderMIF {
   &Show_Me_Internals(@_) if($::CMDLINEOPTS{'showme'});

   # do not remove shifts
   my ($template, $canv, $options ) = (shift, shift, shift);
   my $tmpps = "xxxxxxxtkg2tmpps";  # temporary postscript file name
   my $filetypes = [ [ 'MIF',        [ '.mif'  ] ],
                     [ 'Tkg2 Files', [ '.tkg2' ] ],
                     [ 'All Files',  [ '*'     ] ]
                   ];
   my $file;
   my $tw = $canv->parent;
   
   my $dir2save = ($LASTSAVEDIR) ? $LASTSAVEDIR : $::TKG2_ENV{-USERHOME};
   my $nextarg = shift; # see if the export file name is provided
   if($nextarg and $nextarg ne "") {
      $file = $nextarg;
   }
   elsif($template->{-tkg2filename}) {
      my $canvasname = $template->{-tkg2filename};
      $file = $tw->getSaveFile(-title      => "Save $canvasname as MIF",
                               -initialdir => $dir2save,
                               -filetypes  => $filetypes );
   }
   else {
      $file = $tw->getSaveFile(-title      => "Save Canvas as MIF",
                               -initialdir => $dir2save,
                               -filetypes  => $filetypes );
   }
   $LASTSAVEDIR = "", return if(not defined $file or $file eq "");
   
   # logic to work out whether we should remember the directory
   my $dirname = &dirname($file);
   my $cwd     = &cwd;  # gives use a full path name without the '.'
   $LASTSAVEDIR = ($dirname eq '.') ? $cwd : $dirname;
   # Check to make sure that the directory does exist before we
   # allow the directory to be remembered
   $LASTSAVEDIR = "" unless(-d $LASTSAVEDIR);
   # make sure .mif extension tagged on
   $file .= ".mif" if($file !~ m/.+\.mif$/o); 
   # need to change the rotation scheme so that FrameMaker treats
   # the incoming MIF in a more reasonable fashion--this is the
   # author's preference for operating Frame
   my $oldrotate = $template->{-postscript}->{-rotate}; # save old setting
   $template->{-postscript}->{-rotate} = 0;
   &RenderPostscript($template, $canv, $tmpps);
   $template->{-postscript}->{-rotate} = $oldrotate;  # restore old setting
   
   &correctTkPostscript($tmpps);
   
   print $::VERBOSE " Tkg2-Spawning $PSTOEDITX ",
                    "-f mif $tmpps $file > /dev/null 2>&1\n";
   
   system("$PSTOEDITX -f mif $tmpps $file > /dev/null 2>&1");
   
   # Route the mif file through a post processing filter
   print $::VERBOSE " Tkg2-Routing MIF file: $TKMIFFIX $file\n";
   
   
   if( $::TKG2_ENV{-UTILITIES}->{-BYPASS_MIFFIX} ) {
      print STDERR "%% Tkg2 has bypassed the tkmiffix.pl script\n",
                   "%%  The MIF is raw from the postscript to mif conversion.\n";
   }
   else {
      system("$TKMIFFIX $file");
   }
   
   
   unlink($tmpps);
   if(not -e $file) {
      print STDERR " Tkg2 could not build a mif file, check ",
                   "that pstoedit is available\n";
      return 0;
   }
   return $file;
}

1;
