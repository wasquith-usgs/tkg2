package Tkg2::DataMethods::Class::DataViewer;

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
# $Date: 2002/08/07 18:41:26 $
# $Revision: 1.14 $

use strict;
use Tkg2::Base qw(Message Show_Me_Internals);

use Exporter;
use SelfLoader;
use File::Basename;
use Cwd;

use vars qw(@ISA @EXPORT_OK $VIEWER $LASTOPENDIR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(DataViewer);

$VIEWER = "";


print $::SPLASH "=";
$LASTOPENDIR = "";

1;

__DATA__

# DataViewer
# This is a nifty dialog that is accessed through the button for viewing the
# data file in the AddDataToPlot dialog and module.  This is such a simple
# module here that WHA has elected to always have it loaded via SelfLoader.
# The basic need for this dialog is that often during the set up of parameters
# to read in a data file, the user OFTEN forgets what their data file(s) look
# like.  This allows them to peek at the file from within Tkg2 and modify their
# reading parameters accordingly.  WHA absolutely insists that the user only
# be allowed to view data files from within Tkg2 and NOT edit them.  If editing
# is needed it is best that the user slow down and be forced to use an external
# editor.  Plus external editors are much better at editing files that I want
# to spend the time writing here.
sub DataViewer {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my $pw = shift;
   
   # Do the global dialog book keeping
   $VIEWER->destroy if( Tk::Exists($VIEWER) );
   my $pe = $pw->Toplevel(-title => 'Data Viewer');
   $VIEWER = $pe;
   
   # insert a scrolled text widget that is 35 columns high and 80 columns widt
   my $text = $pe->Scrolled('Text',
                 -scrollbars => 'se',
                 -font       => $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium},
                 -spacing1   => 2,
                 -background => 'linen',
                 -wrap       => 'none',
                 -height     => 35,
                 -width      => 80 )
                 ->pack;
   $text->configure(-state => 'disabled');  # will be inabled when file is read
                                 
   my ($px, $py) = (2, 2);   
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 1);
                                                                                    
   $f_b->Button(-text    => "Close", 
                -font    => $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB},
                -command => sub { $pe->destroy; } )
       ->pack(-side => 'left', -expand => 1); 
                      
   my @types = qw( .asc .dat .out .prn .rdb .tmp .txt );
   my $dir2open = ($LASTOPENDIR) ? $LASTOPENDIR : $::TKG2_ENV{-USERHOME};                    
   my $file = $pe->getOpenFile(-title      => "Open a Data File",
                               -initialdir => $dir2open,
                               -filetypes  => [ [ 'All Files', 
                                                 [ '*' ]
                                                ],
                                                [ 'Typical Text',
                                                  [ @types ]
                                                ],
                                              ] );
   if(not defined $file or not -e $file) {
      $LASTOPENDIR = "";
      &Message($pe,'-nofilename');
      $pe->destroy;
      return; 
   }
   
   # logic to work out whether we should remember the directory
   my $dirname = &dirname($file);
   my $cwd     = &cwd;  # gives a full path name without the '.'
   $LASTOPENDIR = ($dirname eq '.') ? $cwd : $dirname;
   # Check to make sure that the directory does exist before we
   # allow the directory to be remembered
   $LASTOPENDIR = "" unless(-d $LASTOPENDIR);
   
   # Change the title on the window
   $pe->configure(-title => "Viewing $file");
   local *FH;
   open(FH,"<$file") or do {
                             &Message($pe, '-fileerror', $!);
                             $pe->destroy;
                           };
      local $/ = undef; # about the slurp the whole file in
      $text->configure(-state => 'normal');
      my $contents = <FH>;
      $text->insert('end',$contents);
   close(FH) or do {
                     &Message($pe, '-fileerror', $!);
                     $pe->destroy;
                   };
                   
   $text->configure(-state => 'disabled');
}

1;
