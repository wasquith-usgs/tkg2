package Tkg2::DeskTop::Presenter;

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
# $Date: 2005/05/02 11:50:14 $
# $Revision: 1.15 $

use strict;

use Exporter;
use SelfLoader;

use vars     qw(@ISA @EXPORT_OK $PRESENTER);
@ISA       = qw(Exporter SelfLoader);
@EXPORT_OK = qw(Presenter);

use Tkg2::DeskTop::OpenSave qw(Open);
use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";


$PRESENTER = "";

1;
__DATA__
# Presenter is a really cool feature in Tkg2
# A GUI can be launched that allows the users to dynamically query which of
# one or more tkg2 files are to be shown in the display only mode.
sub Presenter {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   
   # figure out whether potentially tkg2 file names are going to be made
   # available.
   my $tkg2files = shift;  # ref of list of tkg2 files to open
   return unless(ref($tkg2files) eq 'ARRAY'); # rough error trap
   my @tkg2files = @$tkg2files; # deref 
   if(not @tkg2files) { # hey no tkg2 files available, show a warning
      print STDERR "Tkg2 Presenter requires one or more tkg2 files to operate\n",
                   "  Usage:  tkg2 --presenter file1.tkg2 file2.tkg2\n",
                   "  Usage:  tkg2 --presenter -presentersort file1.tkg2 file2.tkg2\n",
                   "  Usage:  tkg2 --presenter -presentersort -presentercolumns=2 file1.tkg2 file2.tkg2\n",
      exit;
   }
   
   # start up the presenter widget
   $PRESENTER->destroy if( Tk::Exists($PRESENTER) );
   my $title = ($::CMDLINEOPTS{'message'}) ?
                $::CMDLINEOPTS{'message'} : 'Tkg2 PRESENTER';
   my $pe = $::MW->Toplevel(-title => $title);
   
   my $mess = "WARNING: Tkg2 is operating in --presenter mode in which the\n".
              "MainWindow is not visible to the user.  You just pressed the\n".
	      "window destroy button on the window decoration.  This only\n".
	      "destroys (or would only destroy) a child of the MainWindow--\n".
	      "thus, this action WILL NOT TERMINATE the Tkg2 process.  You must\n".
	      "use the EXIT button or the Exit from the TKG2 DISPLAYER menu.\n\n";
   $pe->protocol(["WM_DELETE_WINDOW"], sub { print STDERR $mess;  } );

   
   
   $PRESENTER = $pe;
   $pe->geometry("+20+0");  # upper left corner
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   
   my $n = scalar(@tkg2files);
   $pe->Label(-text => " Select one of $n Tkg2 files ",
              -font => $fontbig)
      ->pack(-fill => 'x', -side => 'top');
      
      
   my ( $file2show, $fileshowing );
 
   # subroutine for the Radiobutton call backs
   my $radiosub = sub { # remove the current displaying file if it exists
                        $fileshowing->destroy if(Tk::Exists($fileshowing));
                        
                        # idletasks makes sure that the user isn't making a 
                        # bunch of presses to get something to work when
                        # things are running slow
                        $pe->idletasks; # thanks Dane on a slow X-term
                        
                        # the way is cleared, open the file up!
                        (undef, $fileshowing) = &Open($::MW, $file2show);
                      };
   
   my %filemap;
   if($::CMDLINEOPTS{'presenterlabels'}) {
      my @labels = split(/:/o,
                         $::CMDLINEOPTS{'presenterlabels'},
                         scalar(@tkg2files));
      foreach my $label (@labels) {
         $label = "no label provided" if(not defined $label       or
                                                     $label eq "" or
                                                     $label =~ /:+/o);
            # the test for labels having : in them is done in case an extra
            # colon is included on the string, such as
            # --presenterlabels=::: but @tkg2files is only 3 fields
            # This hack keeps a : from showing up in the presenter
            # frame.
         $label =~ s/_/ /go;
      }
      @filemap{@tkg2files} = @labels;
   }
   else {
      @filemap{@tkg2files} = @tkg2files;
   }

   @tkg2files = sort @tkg2files if($::CMDLINEOPTS{'presentersort'});

   my $cols = ($::CMDLINEOPTS{'presentercolumns'}) ?
               $::CMDLINEOPTS{'presentercolumns'} : 1; # ask or default to 1
   my $fileno        = 0;
   my $filecount     = scalar(@tkg2files);
   my $filespercol   = int($filecount / $cols);
   my $fullcolcount  = $filespercol * $cols;
   my $fileremainder = $filecount - $fullcolcount;
   print $::VERBOSE "Tkg2::Presenter: $filecount files, $filespercol files per column, ",
                    "$fileremainder remaining files\n";
   my $frames        = [ ]; # references to the frames to pack with radiobuttons
   foreach my $no (1..$cols) {
      $frames->[$no] = $pe->Frame(-relief      => 'groove',
                                  -borderwidth => 2)
                          ->pack(-side => "left", -fill => 'y', -expand => 1);
      # write a bunch of radio buttons.
      my $remainder = ($no == 1 and $fileremainder) ? $fileremainder : 0;           
      foreach my $i (1..$filespercol+$remainder) {
         my $file = $tkg2files[$fileno];
         $frames->[$no]->Radiobutton(-text     =>  $filemap{$file},
                                     -variable => \$file2show,
                                     -value    =>  $file,
                                     -font     =>  $fontb,
                                     -anchor   => 'w',
                                     -command  =>  $radiosub )
                       ->pack(-side => 'top', -fill => 'both', -expand => 1);
         if($remainder == 0 and $i == $filespercol and $fileremainder) {
            foreach my $j (1..$fileremainder) {
            $frames->[$no]->Label(-text     =>  " ",
                                  -font     =>  $fontb,
                                  -anchor   => 'w' )
                          ->pack(-side => 'top', -fill => 'both', -expand => 1);
            }
         }
         $fileno++;
      }
   }
   print STDERR "PRESENTER Warning: files to present = $filecount, but packed only ",
                "$fileno files\n" if($fileno != $filecount);


   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-fill => 'x');
   $f_b->Button(-text        => 'EXIT',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { $::MW->destroy; } )
       ->pack(-side => 'left', -padx => 2, -pady => 2);                    
}

1;
