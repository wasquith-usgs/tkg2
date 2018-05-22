package Tkg2::DeskTop::Exit;

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
# $Date: 2002/08/07 18:39:29 $
# $Revision: 1.18 $

use strict;
use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK);

use Cwd;
use File::Basename;

use Tk;
use Tkg2::Base qw(Show_Me_Internals);
use Tkg2::DataMethods::Class::MegaCommand qw(DeleteMegaCommandFiles);
use Tkg2::Time::TimeMethods qw(SaveTimeCache);  

@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(Exit TotalExit);

print $::SPLASH "=";

1;

__DATA__

sub TotalExit { 
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $font = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my ($px, $py) = (14, 4);
   my $tw = $::MW->Toplevel(-title => 'Tkg2 Confirmation');
   $tw->resizable(0,0);
   $tw->geometry("-0+80");
   my $t = $tw->Frame(-background => 'light grey', -relief => 'groove')
                ->pack(-fill => 'x');
   my $lab = $t->Label(-text => "EXIT TKG2 ENTIRELY?\n".
                                "There is no further saving\nand no turning back",
                       -background => 'light grey',
                       -font       => $font)
                 ->pack;
                 
   my $f = $tw->Frame(-background => 'light grey')->pack(-fill => 'x');
   $f->Button(-text               => 'OK',
              -height             => 2,
              -font               => $font,
              -borderwidth        => 3,
              -highlightthickness => 2,
              -background         => 'light grey',
              -command => sub {
                                $tw->idletasks;
                                $tw->destroy;
                                &SaveTimeCache();
                                &DeleteMegaCommandFiles();
                                $::MW->destroy;
                              } )
     ->pack(-side => 'left', -padx => $px, -pady => $py);
   $f->Button(-text       => "Cancel",
              -height     => 2,
              -font       => $font,
              -background => 'light grey',
              -command => sub { $tw->idletasks;
                                $tw->destroy; })
     ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f->Button(-text       => "Help",
              -height     => 2,
              -font       => $font,
              -background => 'light grey',
              -padx       => 4,
              -pady       => 4,
              -command => sub { return; } )
     ->pack(-side => 'left', -padx => $px, -pady => $py,);
}

sub Exit { 
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw, $exit_without_message) = @_;
   my $needsave = $template->NeedSaving;
   
   my $file = $template->{-tkg2filename};
   my $dir;
   if(defined $file) {
      my $SAFE = '-SAFE_KEEPING_FOR_TKG2_FILE_HEADINGS';
      # now delete the filename from the safe keeping hash.
      delete( $::TKG2_ENV{$SAFE}->{$file} );
   }
   
   my $oldcwd = &cwd;
   if(not defined $file ) {
      $dir = $oldcwd;
   }
   else {
      $dir = &dirname($file);
   }
   print $::VERBOSE "Exit: directory of file is: $dir\n";
   if($exit_without_message) {
      $template->RemoveUndo;
      $tw->destroy if(Tk::Exists($tw)); # just a safety check on existance
      return 1;
   }

   my $message = ($needsave) ? "WARNING: Not saved" : "Exit already saved template?";
   
   my $font = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my ($px, $py) = (14, 4);
   my $pe = $tw->Toplevel(-title => 'Tkg2 Confirmation');
   $pe->resizable(0,0);
   $pe->geometry("-0+80");
   my $t = $pe->Frame(-background => 'light grey',
                      -relief     => 'groove')
              ->pack(-fill => 'x');
   my $lab = $t->Label(-textvariable => \$message,
                       -font         => $font,
                       -background   => 'light grey')
               ->pack;
                 
   my $f = $pe->Frame(-background => 'light grey')->pack(-fill => 'x');
   if($needsave) {
      $f->Button(-text               => 'SAVE',
                 -height             => 2,
                 -font               => $font,
                 -borderwidth        => 3,
                 -highlightthickness => 2,
                 -background         => 'light grey',
                 -command => sub { $tw->idletasks;
                                   $template->Save($canv, $tw) } )
        ->pack(-side => 'left', -padx => $px, -pady => $py);
      $f->Button(-text               => 'DO NOT SAVE',
                 -height             => 2,
                 -font               => $font,
                 -borderwidth        => 3,
                 -highlightthickness => 2,
                 -background         => 'light grey',
                 -command => sub { $template->RemoveUndo;
                                   $tw->idletasks;
                                   $tw->destroy; } )
        ->pack(-side => 'left', -padx => $px, -pady => $py);
   }
   else {
      $f->Button(-text               => 'OK',
                 -height             => 2,
                 -font               => $font,
                 -borderwidth        => 3,
                 -highlightthickness => 2,
                 -background         => 'light grey',
                 -command            => sub { $tw->destroy; } )
        ->pack(-side => 'left', -padx => $px, -pady => $py);
   }
   
   
   $f->Button(-text       => "Cancel",
              -height     => 2,
              -font       => $font,
              -background => 'light grey',
              -command    => sub { $pe->destroy; })
      ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f->Button(-text       => "Help",
              -height     => 2,
              -font       => $font,
              -background => 'light grey',
              -padx       => 4,
              -pady       => 4,
              -command    => sub { return; } )
     ->pack(-side => 'left', -padx => $px, -pady => $py,);
}

1;
