package Tkg2::DeskTop::Printing;

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
# $Date: 2008/09/03 15:17:23 $
# $Revision: 1.52 $

use strict;

use File::Basename;
use File::Spec;
use Tkg2::Base qw(Message Show_Me_Internals strip_space routeMetaPost);
use Tkg2::Help::Help;

use Cwd;

use Exporter;
use SelfLoader;

use vars     qw( @ISA @EXPORT_OK
                 $EDITOR    $EXPORT_EDITOR $LASTSAVEDIR
               );
@ISA       = qw( Exporter SelfLoader );
@EXPORT_OK = qw( Print
                 Tkg2Export Tkg2MetaPost
                 correctTkPostscript
                 Postscript2Printer
                 RenderPostscript
                 RenderMIF
                 RenderPDF
                 RenderPNG
		 RenderMetaPost 
	       );


use Tkg2::DeskTop::Rendering::RenderMIF;
use Tkg2::DeskTop::Rendering::RenderPDF;
use Tkg2::DeskTop::Rendering::RenderPNG;
use Tkg2::DeskTop::Rendering::RenderPS;
use Tkg2::DeskTop::Rendering::RenderMetaPost;

$EDITOR = $EXPORT_EDITOR = $LASTSAVEDIR = "";

print $::SPLASH "=";

1;
#__DATA__

# Print is the sole dialog box for controlling and routing postscript
# print services.  Two types of printers are identified.
# The tkg2rc file identifies each as Tkg2*printers.
# The default printer is the one at the top of the list.
sub Print {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw) = (shift, shift, shift);
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $tw->Toplevel(-title => 'Tkg2 Print');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   
   my $font = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my ($px, $py) = (2, 2);
   
   my @printers    = @{ $::TKG2_CONFIG{-PRINTERS} };   
   
   if(not @printers) {
      # The warning message is placed here and not at the time
      # the tkg2rc files were read in because, I want 99% of tkg2
      # features running and available even if the printers are not
      # specified.  The user does not care about the printers until
      # this point in the code.
      my $mess = "There are no printers identified ".
                 "in the three tkg2rc files\n".
                 "In a tkg2rc file place something like this: \n".
                 "Tkg2*printers:    printer1 printer2\n".
                 "    Consult the documentation.";
      &Message($pe,'-generic', $mess);
   }
   
   my ($asps, $asmif) = (0, 0); # default settings
   my $additional_options = "";
   
   if($::TKG2_CONFIG{-QUEUE_OPTIONS} ne "") {
      $additional_options = $::TKG2_CONFIG{-QUEUE_OPTIONS};
   }
   
   my @p = qw(-side top -fill both);
   my $lb = $pe->Scrolled("Listbox", -scrollbars => 'e',
                                     -selectmode => 'single',
                                     -background => 'white',
                                     -font       => $font,
                                     -width      => 10)->pack(@p);
   $lb->insert('end', @printers); # load up the list
   $lb->selectionSet(0); # select the first value in list
   
   
   my $f_opts = $pe->Frame(-borderwidth => 3,-relief => 'groove',)
                   ->pack(-fill => 'x', -expand => 1, -pady => 3);
   $f_opts->Label(-text    => "Additional printer command\n".
                              "line options (e.g. -o11x17).",
                  -font    => $font,
                  -anchor  => 'w',
                  -justify => 'left')
          ->pack(-side => 'top', -anchor => 'w', -fill => 'x');
   $f_opts->Entry(-textvariable => \$additional_options,
                  -font         => $font,
                  -background   => 'white')
          ->pack(-side => 'left', -fill => 'x', -expand => 1);
   
   my $postref = $template->{-postscript};
   @p = qw(-side top -anchor w);
   $pe->Checkbutton(-text     => 'Rotate 90 degees',
                    -variable => \$postref->{-rotate},
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font)->pack(@p);

   my $set_zoom_to_one = ($::TKG2_CONFIG{-NOZOOM2UNITY}) ? 0 : 1;
   $pe->Checkbutton(-text     => "Rescale fonts (--zoom=1)",
                    -variable => \$set_zoom_to_one,
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font)->pack(@p);   
   $pe->Checkbutton(-text     => 'Bypass tkpsfix.pl script',
                    -variable => \$::TKG2_ENV{-UTILITIES}->{-BYPASS_PSFIX},                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font)->pack(@p);

                 
   my $colormode = $postref->{-colormode};
   my $f_1 = $pe->Frame()->pack(-fill => 'x');  
   $f_1->Radiobutton(-text     => 'Color',
                     -variable => \$colormode,
                     -value    => 'color',
                     -font     => $font)->pack(-side => 'left');
   $f_1->Radiobutton(-text     => 'Mono',
                     -variable => \$colormode,
                     -value    => 'mono',
                     -font     => $font)->pack(-side => 'left');
   
   @p = (-side => 'left', -padx => $px, -pady => $py);                     
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)->pack(-fill => 'x');
   my $b_ok = $f_b->Button(-text               => 'OK',
                           -font               => $font,
                           -borderwidth        => 3,
                           -highlightthickness => 2,
       -command => sub { $canv->Busy;
                         my $printer = $lb->get($lb->curselection);
                         $pe->destroy;
                         
                         if($set_zoom_to_one and
                            $::TKG2_CONFIG{-ZOOM} != 1) {
                            # If the user wants to reset the zoom to one
                            # for the postscript rendering and the current
                            # zoom is not already one, then set zoom to one
                            # update the canvas and proceed with drawing
                            local $::TKG2_CONFIG{-ZOOM} = 1;
                            $template->UpdateCanvas($canv);
                         }
                         else {
                            # the toggle is set to zero so that we can 
                            # trigger the final UpdateCanvas to restore
                            # the canvas to the original --zoom setting.
                            $set_zoom_to_one = 0;
                         }
                         
                         if(  not $::TKG2_CONFIG{-REDRAWDATA} ) {
                            local $::TKG2_CONFIG{-REDRAWDATA} = 1;
                            $template->UpdateCanvas($canv);
                         }
                         
                         $postref->{-colormode} = $colormode;
                         my $options;
                         $options->{-destination} = $printer;
                         $additional_options = &strip_space($additional_options);
                         $options->{-additional_command_options} =
                                    $additional_options;
                         &Postscript2Printer($template, $canv, $options);
                         
                         $template->UpdateCanvas($canv) if($set_zoom_to_one);
                         $canv->Unbusy; } )->pack(@p);
                                           
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $font,
                -command => sub { $pe->destroy; })->pack(@p);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $font,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )->pack(@p);
}



# Tkg2Export is the sole dialog box controlling and routing avenue to
# export tkg2 graphics into various graphic files.
sub Tkg2Export {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw) = (shift, shift, shift);
   $EXPORT_EDITOR->destroy if( Tk::Exists($EXPORT_EDITOR) );
   my $pe = $tw->Toplevel(-title => 'Tkg2 Export');
   $EXPORT_EDITOR = $pe;
   $pe->resizable(0,0);
   
   my $font1 = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $font2 = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   my ($px, $py) = (2, 2);
   my $rendertype = 'pdf';
   my @p = qw(-side top -anchor w);

   $pe->Label(-text => 'Select an export format:',
              -font => $font2)
      ->pack(@p);
   unless($::TKG2_ENV{-OSNAME} eq 'darwin') {         
      $pe->Radiobutton(-text     => 'FrameMaker Interchange Format (MIF)',
                       -variable => \$rendertype,
                       -value    => 'mif',
                       -font     => $font1)->pack(@p);
   }                 
   $pe->Radiobutton(-text     => 'Portable Document Format (PDF)',
                    -variable => \$rendertype,
                    -value    => 'pdf',
                    -font     => $font1)->pack(@p);
   
   $pe->Radiobutton(-text     => 'Portable Network Graphics (PNG)',
                    -variable => \$rendertype,
                    -value    => 'png',
                    -font     => $font1)->pack(@p);                             
                    
   $pe->Radiobutton(-text     => 'Postscript (PS)',
                    -variable => \$rendertype,
                    -value    => 'postscript',
                    -font     => $font1)->pack(@p);
   
   
   $pe->Label(-text => "\nFurther export settings:",
              -font => $font2)
      ->pack(@p);
   $pe->Checkbutton(-text     => 'Rotate 90 degrees',
                    -variable => \$template->{-postscript}->{-rotate},
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
		    
   my $set_zoom_to_one = ($::TKG2_CONFIG{-NOZOOM2UNITY}) ? 0 : 1;
   $pe->Checkbutton(-text     => "Rescale fonts (--zoom=1)",
                    -variable => \$set_zoom_to_one,
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $pe->Checkbutton(-text     => 'Bypass tkmpsfix.pl script',
                    -variable => \$::TKG2_ENV{-UTILITIES}->{-BYPASS_PSFIX},                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $pe->Checkbutton(-text     => 'Bypass tkmiffix.pl script (if mif)',
                    -variable => \$::TKG2_ENV{-UTILITIES}->{-BYPASS_MIFFIX},                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
                   
                    
                    
   my $colormode = $template->{-postscript}->{-colormode};
   my $f_1 = $pe->Frame()->pack(-fill => 'x');  
   $f_1->Radiobutton(-text     => 'Color',
                     -variable => \$colormode,
                     -value    => 'color',
                     -font     => $font1)->pack(-side => 'left');
   $f_1->Radiobutton(-text     => 'Mono',
                     -variable => \$colormode,
                     -value    => 'mono',
                     -font     => $font1)->pack(-side => 'left');
   
   my $resolution = "";
   my $restext = "\nPixel resolution of output format\n".
                   "(if applicable: PNG only for now)";
   my $f_res = $pe->Frame->pack(-fill => 'x');
   $f_res->Label(-text    => $restext,
                 -font    => $font1,
                 -anchor  => 'w',
                 -justify => 'left')
         ->pack(-side => 'top', -anchor => 'w');
   $f_res->Entry(-textvariable => \$resolution,
                 -font         => $font1,
                 -background   => 'white',
                 -width        => 10  )
         ->pack(-side => 'left', -fill => 'x');
   
   my $pdfzoom = "1";
   my $pdftext = "\nZoom factor on PDF generation";
   my $f_pdf = $pe->Frame->pack(-fill => 'x');
   $f_pdf->Label(-text    => $pdftext,
                 -font    => $font1,
                 -anchor  => 'w',
                 -justify => 'left')
         ->pack(-side => 'top', -anchor => 'w');
   $f_pdf->Entry(-textvariable => \$pdfzoom,
                 -font         => $font1,
                 -background   => 'white',
                 -width        => 10  )
         ->pack(-side => 'left', -fill => 'x');
   
   @p = (-side => 'left', -padx => $px, -pady => $py);                     
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)->pack(-fill => 'x');
   my $b_ok = $f_b->Button(
       -text               => 'OK',
       -font               => $font1,
       -borderwidth        => 3,
       -highlightthickness => 2,
       -command =>
          sub { $canv->Busy;
                $pe->destroy;
                
                if($set_zoom_to_one and $::TKG2_CONFIG{-ZOOM} != 1) {
                   # If the user wants to reset the zoom to one
                   # for the postscript rendering and the current
                   # zoom is not already one, then set zoom to one
                   # update the canvas and proceed with drawing
                   local $::TKG2_CONFIG{-ZOOM} = 1;
                   $template->UpdateCanvas($canv);
                }
                else {
                   # the toggle is set to zero so that we can 
                   # trigger the final UpdateCanvas to restore
                   # the canvas to the original --zoom setting.
                   $set_zoom_to_one = 0;
                }
                
                if(  not $::TKG2_CONFIG{-REDRAWDATA} ) {
                   local $::TKG2_CONFIG{-REDRAWDATA} = 1;
                   $template->UpdateCanvas($canv);
                }
                $template->{-postscript}->{-colormode} = $colormode;
                                
                my %options = ( -resolution    => $resolution,
                                -zoom          => $pdfzoom );
                ROUTER: {
                 &RenderMIF($template, $canv, \%options), last ROUTER
                                               if($rendertype eq 'mif');
                 &RenderPDF($template, $canv, \%options), last ROUTER
                                               if($rendertype eq 'pdf');
                 &RenderPNG($template, $canv, \%options), last ROUTER
                                               if($rendertype eq 'png');
                 &_PostscriptasFile($template, $canv, \%options), last ROUTER
                                               if($rendertype eq 'postscript');
                }
                $template->UpdateCanvas($canv) if($set_zoom_to_one);
                $canv->Unbusy;
             } )->pack(@p);                  
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $font1,
                -command => sub { $pe->destroy; })->pack(@p);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $font1,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )->pack(@p);
}




sub Postscript2Printer {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $options) = @_;
   my $printer = $options->{-destination};
   
   # Additional options for the printer queue are guaranteed to be defined
   # from the dialog box but are left undefined during batch spooling to 
   # the printer.  If and only if these options are not defined or are
   # equal to nothing ("") then consider using the QUEUE_OPTIONS from the
   # tkg2rc files. 
   my $additional_options = $options->{-additional_command_options};
      $additional_options = $::TKG2_CONFIG{-QUEUE_OPTIONS}
              if((not defined $additional_options or $additional_options eq "")
                                                 and
                                  defined $::TKG2_CONFIG{-QUEUE_OPTIONS});
   $additional_options = "" if(not defined $additional_options); # insurance

   my $file = File::Spec->catfile($::TKG2_ENV{-HOME},"xxxxxxxtkg2printfile");
   
   &RenderPostscript($template, $canv, $file);
   &correctTkPostscript($file);
      
   # determine an appropriate queue to print from
   # the lp -c (lp with copy) is available on most unixes
   # but linux has moved to lpr that I haven't tested yet.
   # The environment variable -PRINTER_QUEUE can be used
   # to force which printer queue will be used.
   my $queue = ($::TKG2_ENV{-PRINTER_QUEUE}) ?
                $::TKG2_ENV{-PRINTER_QUEUE} : 'lp -c';
   
   # build the whole spool command into a single variable
   # to make echoing to the user easier if needed
   my $fullqueue = "$queue -d $printer $additional_options $file 2>&1";

   print $::VERBOSE " Tkg2-Postscript2Printer\n",
                    "        Queue = $fullqueue\n";
   
   my $mess = `$fullqueue`; # put stderr into stdout too
   
   if($mess =~ /unknown printer/io or
      $mess =~ /error/io) {
     &Message($::MW,'-generic',"Printing error--$mess.  ".
                               "Queue was $fullqueue");
   }
   else {
     # The usual message seen is echoed here.
     print $::VERBOSE " Tkg2-Postscript2Printer: successful spool\n";
   }
   unlink($file);
}



sub _PostscriptasFile {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $options) = (shift, shift, shift);
   my $tw = $canv->parent;
   my $file = $template->{-tkg2filename};
   my $psfile;
   my $filetypes = [ [ 'Postscript', [ '.ps', '.eps', '.epsi'] ],
                     [ 'Tkg2 Files', [ '.tkg2' ] ],
                     [ 'All Files',  [ '*'     ] ]
                   ];
   my $dir2save = ($LASTSAVEDIR) ? $LASTSAVEDIR : $::TKG2_ENV{-USERHOME};               
   if(defined $file ) {
      $psfile = $tw->getSaveFile(-title      => "Save $file as Postscript",
                                 -initialdir => $dir2save,
                                 -filetypes  => $filetypes );
   }
   else {
      $psfile = $tw->getSaveFile(-title      => "Save Canvas as Postscript",
                                 -initialdir => $dir2save,
                                 -filetypes  => $filetypes );
   }
   $LASTSAVEDIR = "", return if(not defined $psfile or $psfile eq "");
   
   # logic to work out whether we should remember the directory
   my $dirname = &dirname($psfile);
   my $cwd     = &cwd;  # gives use a full path name without the '.'
   $LASTSAVEDIR = ($dirname eq '.') ? $cwd : $dirname;
   # Check to make sure that the directory does exist before we
   # allow the directory to be remembered
   $LASTSAVEDIR = "" unless(-d $LASTSAVEDIR);

   $psfile .= ".ps" if($psfile !~ m/.+\.ps/o);
   my $tmpps = "xxxxxxxtkg2tmpps";  # temporary postscript file name
   &RenderPostscript($template, $canv, $tmpps);
   rename("$tmpps","$psfile");
   &correctTkPostscript($psfile);
   return $psfile;
}


# Tkg2MetaPost is the sole dialog box controlling and routing avenue to
# export tkg2 graphics into a MetaPost format.
sub Tkg2MetaPost {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw) = (shift, shift, shift);
   $EXPORT_EDITOR->destroy if( Tk::Exists($EXPORT_EDITOR) );
   my $pe = $tw->Toplevel(-title => 'Tkg2 MetaPost');

   my $dolabelsref   = \$Tkg2::DeskTop::Rendering::RenderMetaPost::DOLABELS;
   my $dotlabelsref  = \$Tkg2::DeskTop::Rendering::RenderMetaPost::DOTLABELS;
   my $helloworldref = \$Tkg2::DeskTop::Rendering::RenderMetaPost::HELLOWORLD;
   my $offset_mark   = \$Tkg2::DeskTop::Rendering::RenderMetaPost::OFFSETMARK;
   my $cleantex      = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANTEX;
   my $spawn         = \$Tkg2::DeskTop::Rendering::RenderMetaPost::SPAWN_MPOST;
   my $cleanup       = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANUP;
   my $cleanupmp     = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANUP_THE_MPFILE;

   $EXPORT_EDITOR = $pe;
   $pe->resizable(0,0);

   my $font1 = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $font2 = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   my ($px, $py) = (2, 2);
   my @p = qw(-side top -anchor w);

   $pe->Label(-text => "EXPORTING TKG2 TO METAPOST (Global Options)",
              -font => $font2)
      ->pack(@p);
   $pe->Label(-text => "The export process involves the external commands\n".
                       "'mpost' and 'mptopdf', which means that your TEX environment\n".
                       "variable of the shell needs to be set to 'latex' and NOT 'tex'.\n".
                       "If you are running the bash shell, this is as easy as\n".
                       "'export TEX=latex'. However, special instructions are placed in\n".
                       "the mp file to avoid this issue if you have no idea what this\n".
                       "paragraph means.  ;)",
              -font => $font2)
      ->pack(@p);
   my $f1 = $pe->Frame(-relief => 'groove',
                       -borderwidth => 2)
               ->pack(-side => 'top', -fill => 'x', -pady => 4);
   $f1->Label(-text => "GLOBAL VARIABLES FOR TEXTUAL ELEMENTS\n".
                       "(Variables for RenderingMetaPost.pm)",
              -font => $font2)
      ->pack(-side => 'top');
   $f1->Checkbutton(-text     => 'OUTPUT LABELS (shall all textual elements be rendered?).',
                    -variable => $dolabelsref,
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $f1->Checkbutton(-text     => "DOT LABELS (place a dot at each label's origin, this is a\n".
                                 "helpful feature if you need to refine various offsets).",
                    -variable => $dotlabelsref,
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $f1->Checkbutton(-text     => "CONVERT TEXT to 'HELLO WORLD' (useful for debugging).",
                    -variable => $helloworldref,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $f1->Checkbutton(-text     => 'STRIP (clean out) special LaTeX characters from text values.',
                    -variable => $cleantex,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   my $f2 = $pe->Frame(-relief => 'groove',
                       -borderwidth => 2)
               ->pack(-side => 'top', -fill => 'x', -pady => 4);
   $f2->Label(-text => "EXTRA DECORATIONS (useful for fine tuning layout.",
              -font => $font2)
      ->pack(-side => 'top');
   $f2->Checkbutton(-text     => 'OFFSET MARK [1in, 1in] crossing (usually want off).',
                    -variable => $offset_mark,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   my $f4 = $pe->Frame(-relief => 'groove',
                       -borderwidth => 2)
               ->pack(-side => 'top', -fill => 'x');
   $f4->Label(-text => "GLOBAL VARIABLES RELATED TO METAPOST OPERATION\n".
                       "(Variables for RenderingMetaPost.pm)",
              -font => $font2)
      ->pack(-side => 'top', -fill => 'x', -pady => 4);

   $f4->Checkbutton(-text     => "SPAWN 'mpost' and then 'mptopdf' (the magic happens here).",
                    -variable => $spawn,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $f4->Checkbutton(-text     => "DELETE (cleanup) intermediate (auxillary) MetaPost files.",
                    -variable => $cleanup,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);
   $f4->Checkbutton(-text     => "DELETE (cleanup) the generated *.tkg2.mp file.",
                    -variable => $cleanup,                
                    -onvalue  => 1,
                    -offvalue => 0,
                    -font     => $font1)->pack(@p);

   @p = (-side => 'left', -padx => $px, -pady => $py);                     
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)->pack(-fill => 'x');
   my $b_ok = $f_b->Button(
       -text               => 'OK',
       -font               => $font1,
       -borderwidth        => 3,
       -highlightthickness => 2,
       -command =>
          sub { $canv->Busy;
                $pe->destroy;
                &RenderMetaPost($template,$canv);
		$canv->Unbusy;
             } )->pack(@p);                  
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $font1,
                -command => sub { $pe->destroy; })->pack(@p);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $font1,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )->pack(@p);
}


sub makeMetaPost {
  my ($template, $canv) = @_;

}

1;
