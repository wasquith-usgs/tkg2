package Tkg2::DeskTop::Batch;

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
# $Date: 2008/05/05 14:53:59 $
# $Revision: 1.35 $

use strict;

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK $PSVIEWER $PDFVIEWER $PNGVIEWER);
@ISA = qw(Exporter SelfLoader);
@EXPORT_OK = qw(Batch DeleteLoadedData);

use Tkg2::DeskTop::Printing qw(RenderPostscript
                               correctTkPostscript
                               Postscript2Printer
                               RenderMIF
                               RenderPDF
                               RenderPNG
                               RenderMetaPost);
                               
use Tkg2::DeskTop::OpenSave qw(Batch_open);

use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";

$PSVIEWER  = $::TKG2_ENV{-UTILITIES}->{-PSVIEWER_EXEC};
$PDFVIEWER = $::TKG2_ENV{-UTILITIES}->{-PDFVIEWER_EXEC};
$PNGVIEWER = $::TKG2_ENV{-UTILITIES}->{-PNGVIEWER_EXEC};

print STDERR "! Tkg2-Batch, warning: Postscript viewer is undefined.\n"
   if(not defined $PSVIEWER);
print STDERR "! Tkg2-Batch, warning: PDF viewer is undefined.\n"
   if(not defined $PDFVIEWER);
print STDERR "! Tkg2-Batch, warning: PNG viewer is undefined.\n"
   if(not defined $PNGVIEWER);
   
1;

__DATA__

sub Batch {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $tkg2file = shift;
   return 0 if(not -e $tkg2file);
   my %options = @_;  # command line options
   
   my $template = &Batch_open($tkg2file);
   return 0 unless($template);
   
   # insure that drawing of data is 1 for UpdateCanvas unless
   # overridden by the --nozoom2unity command line switch or through
   # the tkg2rc file(s).
   local $::TKG2_CONFIG{-REDRAWDATA} = 1;
   # Do not apply the font zooming, just render the fonts in their 
   # true specified sizes.
   local $::TKG2_CONFIG{-ZOOM} = 1 unless($::TKG2_CONFIG{-NOZOOM2UNITY});
   
   my ($canv, $notneededhere) = $template->StartTemplate;
   
   my $tref = $template->{-postscript};
   my $colormode = ( $options{-colormode} eq
                     'use_colormode_for_template') ? $tref->{-colormode}  :
                                                     $options{-colormode} ;    
   
   my $destination = $options{-destination};
   # The export file name needs to remain separate from the other options
   my $exportfile  = $options{-exportfile};
   unless( $destination ) {
      if(not defined $exportfile or $exportfile eq "") {
         print STDERR "Tkg2-Warning: Premature exit from Batch subroutine ",
               "as exportfile is not defined before attempted extension ",
               "removal from tkg2 file.\n";
         return 0;   
      }
      # remove any extensions that the user might provide on the command line
      # we are going to force the rendering subroutines to appended their own
      # extensions (.ps, .png, .pdf, .mif, etc).
      $exportfile =~ s/\..*$//;
   
      # error trapping
      if(not defined $exportfile or $exportfile eq "") {
         print STDERR "Tkg2-Warning: Premature exit from Batch subroutine ",
               "as exportfile is not defined after attempted extension ",
               "removal from tkg2 file.\n";
         return 0;
      } 
   }
   
   # Parse the --format
   my ($format, @parsed_format) = split(/:/o, $options{-format}, -1);
   $exportfile = "" if(defined $parsed_format[0] and
                               $parsed_format[0] eq "ask"); # png, pdf, mif
   my $viewer;
   my $command;
   my @args = ($template, $canv);
   if( $destination ) {
      # spool file to printer since one was specified
      &Postscript2Printer(@args, \%options );
   }
   elsif( $format =~ /^ps/io )  {
      if($exportfile eq "") { # we prompt here, because RenderPostscript has a different
         my $filetypes = [ [ 'PS',         [ '.ps'  ] ],
                           [ 'Tkg2 Files', [ '.tkg2' ] ],
                           [ 'All Files',  [ '*'     ] ]
                         ];
         my $dir2save = $::TKG2_ENV{-USERHOME};
         $exportfile = $canv->getSaveFile(-title      => "Save $options{-exportfile} as PS",
                                          -initialdir => $dir2save,
                                          -filetypes  => $filetypes );
         if(not defined $exportfile) {
            print STDERR "WARNING: Export file name prompted for but left undefined.\n";
            $::MW->exit 
         }
         $exportfile =~ s/\..*$//; # remove the *.ps or other if the user provided--likely
      }
      &RenderPostscript(@args, $exportfile );
      my $width  = $template->{-width};
      my $height = $template->{-height};
      my $page   = $width."x".$height;
      &correctTkPostscript($exportfile);
      rename($exportfile,$exportfile.".ps");
      $exportfile .= ".ps";
      my $res = ($options{-exportview} and
                 $options{-exportview} > 1) ?
                 $options{-exportview} : 50;
      my $pxlwidth  = $width*$res;
      my $pxlheight = $height*$res;
      my $gcom  = ($template->{-postscript}->{-rotate}) ?
                         $pxlheight."x".$pxlwidth :
                         $pxlwidth."x".$pxlheight;
      $viewer   = $PSVIEWER;
      $viewer ||= "";   # used to surpress Unintialized value warning
      $command  = "$viewer -q -g$gcom -r$res $exportfile";
      if($options{-exportview} and $viewer) {
         print $::VERBOSE " EXTERNAL_COMMAND: $command <== EXPORT FILE NAME\n";
         system($command); 
      }
   }
   elsif( $format =~ /^mif/io ) {  
      $exportfile = &RenderMIF( @args, \%options, $exportfile );
      if($options{-exportview}) {
         print $::VERBOSE
            " EXTERNAL_COMMAND: Mif not easily viewed with utility\n";
      }
   }
   elsif( $format =~ /^pdf/io ) {
      $options{-zoom} = $parsed_format[1];
      $exportfile = &RenderPDF( @args, \%options, $exportfile );
      if(not defined $exportfile) {
         print STDERR "WARNING: Export file name prompted for but left undefined.\n";
         $::MW->exit 
      }
      $viewer   = $PDFVIEWER;
      $viewer ||= "";  # used to surpress Unintialized value warning
      $command  = "$viewer $exportfile";
      if($options{-exportview} and $viewer) {
         print $::VERBOSE " EXTERNAL_COMMAND: $command <== EXPORT FILE NAME\n";
         system($command); 
      }
   }
   elsif( $format =~ /^png/io ) {
      $options{-resolution} = $parsed_format[1];
      $exportfile = &RenderPNG( @args, \%options, $exportfile );
      if(not defined $exportfile) {
         print STDERR "WARNING: Export file name prompted for but left undefined.\n";
         $::MW->exit 
      }
      $viewer     = $PNGVIEWER;
      $viewer   ||= "";  # used to surpress Unintialized value warning
      $command    = "$viewer $exportfile";
      if($options{-exportview} and $viewer) {
         print $::VERBOSE " EXTERNAL_COMMAND: $command <== EXPORT FILE NAME\n";
         system($command); 
      }
   }
   elsif( $format =~ /^mp/io ) {
      &RenderMetaPost( @args, \%options);
   }
   else {
      return 0;
   }
   return ($canv, $::MW, $template); 
}   



# In order to save space and to not confuse the user, when a tkg2 file
# is closed, we delete all the nonimported data from the data storage
# model.
sub DeleteLoadedData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my $canDEL = $::TKG2_CONFIG{-DELETE_LOADED_DATA};
   
   my $template = shift;
   PLOT: foreach my $plot ( @{ $template->{-plots} } ) {
      my $dataclass = $plot->{-dataclass};
      
      DATA: foreach my $dataset (@{$dataclass}) {
          
         # Always remove the parsed data cache
         map { delete( $_->{-parseData} ) } @{$dataset->{-DATA}};
         
         my ($ordnum, @ordinates);
         if(not $dataset->{-file}->{-dataimported}) {
            # now, if it is intended that the data is to actually
            # be retained in the file after it was loaded then
            # turn the dataimported on and go on to the next dataset
            $dataset->{-file}->{-dataimported} = 1, next DATA unless($canDEL);
            
            # moving on an deleting the data
            @ordinates = ();
            foreach my $subset ( @{$dataset->{-DATA}} ) {
               push(@ordinates, $subset->{-origordinate});
            }
            foreach my $ordnum (0..$#ordinates) {
               my $cleardata = $dataset->clearjustdata($ordnum);
            }
         }
      }
   }
   return $template;
}

1;
