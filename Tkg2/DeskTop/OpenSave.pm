package Tkg2::DeskTop::OpenSave;

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
# $Date: 2006/09/17 22:36:34 $
# $Revision: 1.45 $

use strict;

use Storable qw(nstore_fd retrieve_fd);
use Data::Dumper;

use Tkg2::Base qw(Message Show_Me_Internals);
use File::Basename;
use Cwd;
use File::Spec;

use Exporter;
use vars qw(@ISA @EXPORT_OK $LASTOPENDIR $LASTSAVEDIR);
@ISA = qw(Exporter);
@EXPORT_OK = qw(Open Save SaveAs Open_em Batch_open);
# Open_em is exportable so that files can be opened without having to pass
# through the getOpenFile dialog

print $::SPLASH "=";

my $SAFE = '-SAFE_KEEPING_FOR_TKG2_FILE_HEADINGS';

$LASTOPENDIR = "";
$LASTSAVEDIR = "";

# Open provides the opening frontend to open any and all templates
# If Open is called with a second argument, which hopefully is a file
# name, then that file is opened, the header read and saved away, and the tkg2
# title line is read.  The title line contains the format the the remainder
# of the file is saved in.  If Open is called without a second argument, then
# a GUI is launched and the user is to specify a file name.
sub Open {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $tw = shift;  # the parent toplevel widget
   my ($fsel, $file);
   
   # Use the last open directory if it appears possible, otherwise
   # go and test the user's home (actually the directory that tkg2
   # was launched from if it appears possible, otherwise go and
   # test the true user's home (/home/wasquith) if it appears possible
   # otherwise open to /tmp in which we should be pretty darn sure 
   # is viable.
   my $dir2open =
        (   $LASTOPENDIR and
         -d $LASTOPENDIR )           ? $LASTOPENDIR           :
        (   $::TKG2_ENV{-USERHOME} and
         -d $::TKG2_ENV{-USERHOME} ) ? $::TKG2_ENV{-USERHOME} :
        (   $::TKG2_ENV{-HOME} and
         -d $::TKG2_ENV{-HOME} )     ? $::TKG2_ENV{-HOME}     : "/tmp" ;

   print $::BUG "Tkg2-Open: About to try getOpenFile on '$dir2open'\n";
   
   OPENFILE: {
      $file = (@_) ? shift :
          $tw->getOpenFile(-title      => "Open a Tkg2 File",
                           -initialdir => $dir2open,
                           -filetypes  => [ [ 'Tkg2 Files', [ '.tkg2' ] ],
                                            [ 'All Files',  [ '*'     ] ]
                                          ] );
   }
   $LASTOPENDIR = "", return if(not defined $file or $file eq "");
  
   # Open up the file, cat the heading together and save it away
   my $heading  = "";
   my $fh       = &_fh4reading($file);
   $LASTOPENDIR = "", return unless($fh);
   
   # logic to work out whether we should remember the directory
   # Right now we do not remember the directory because some scripts
   # that drive tkg2 sessions crater with threaded library exceptions
   # that appear unrelated directly to Perl or Tk.  Seems to be a C-shell
   # issue.
   #PERLBUG my $dirname  = &dirname($file);
   #PERLBUG print $::BUG "just called dirname\n";
   #PERLBUG my $cwd      = &cwd;  # gives use a full path name without the '.'
   #PERLBUG print $::BUG "just called cwd\n";
   #PERLBUG $LASTOPENDIR = ($dirname eq '.') ? $cwd : $dirname;
   # Check to make sure that the directory does exist before we
   # allow the directory to be remembered
   
   # Occassionally, cwd returns undef.  Thus, to trap an error within
   # Tkg2 it is necessary to check for definedness first before checking
   # whether the directory exists.
   $LASTOPENDIR = "" unless(defined $LASTOPENDIR and -d $LASTOPENDIR);
   
   
   my $mess = "The next read on $file will be an end-of-file. ".
              "This generally means that you are trying to read ".
              "either a non Tkg2 file, a file without a __DATA__ ".
              "token, an empty file, or the input record separator ".
              "within tkg2 is messed up.  Tkg2 is quietly giving up ".
              "processing this file.";

   local $/ = $::TKG2_ENV{-INPUT_RECORD_SEPARATOR};
   while(<$fh>) {
      last if(m/^__DATA__/o); # the beginning caret is critical
      $heading .= $_; 
      if(eof($fh)) {
         &Message($tw, '-generic',$mess);          
         $LASTOPENDIR = "";
         return;
      }
   }
   if(eof($fh)) {
      &Message($tw, '-generic',$mess);          
      $LASTOPENDIR = "";
      return;
   }
   chomp($_ = <$fh>);  # grab the tkg2 title line
   
   # Ok, finally go an read the rest of the file
   my $template = &Open_em($fh,$file,$_);
   # delete $::CMDLINEOPTS{'showme'};  # looking for the Fortran-Perl bug
   close($fh) or
      do {
           &Message($tw, '-fileerror', $!);
           $LASTOPENDIR = "";
           return;
         };

   if(not $template or not ref $template) {
      &Message($tw, '-invalidtkg2file',"\nFile=$file");
      return;
   }

   # Store away the cat of all the lines read in until the __DATA__ was
   # found.  The saving routines will peak here for a heading to write out
   $file = $template->{-tkg2filename}; # get the absolute file name
   if( exists( $::TKG2_ENV{$SAFE}->{$file} )   and
       defined $::TKG2_ENV{$SAFE}->{$file}     and
           not $::CMDLINEOPTS{'presenter'}     and
           not $::CMDLINEOPTS{'test'}  ) {
      # Basically, the basename of the file is used to identify things
      # about that file.  Tkg2 will potentially get confused if two
      # or more files of the same name are openned.
      # This is NOT an issue UNLESS the user is trying to capitalize on
      # Tkg2's ability to 'see' special instructions at the top of a 
      # tkg2 file.
      
      # I have turned with error off by testing for whether the presenter
      # is in operation.  With the presenter the user is likely to switch
      # back and forth between files.  At the present time, this error would
      # then pop up.  I assume that everything will be ok with the header
      # storage in this case. 
      print $::BUG "BUG--WARNING: $::TKG2_ENV{$SAFE}->{$file}\n";
      my $mess = "ADVANCED USER WARNING!!\n".
                 "Tkg2 keeps track of any special headers in the opened ".
                 "tkg2 files by the global hash \%TKG2_ENV.  The tkg2 file ".
                 "name is used as the key to this hash.  When you see this ".
                 "message then tkg2 will potentially overwrite the ".
                 "instructions for the earlier file.  In other words two ".
                 "more files are open with the same name!  The last opened ".
                 "file of the files having the same name will contain the ".
                 "heading written to the other files if and when they are ".
                 "saved.";

      &Message($tw, '-generic', $mess);   
   }
   $::TKG2_ENV{$SAFE}->{$file} = $heading; # saving the heading away   

   my ($canv, $tl) = $template->StartTemplate;
   
   # return the canvas, which TopLevel contains the template and the template
   # The TopLevel reference is used by Presenter.pm for destroying
   return ($canv, $tl, $template);

}


# Save is a wrapper around the SaveAS and Save_em subroutines
sub Save {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw) = (shift, shift, shift);
   
   if(not $::TKG2_CONFIG{-REDRAWDATA}) {
      # localize the global to make sure that UpdateCanvas is called
      # with redraw as true so that the data will certainly be drawn
      # onto the canvas.
      local $::TKG2_CONFIG{-REDRAWDATA} = 1;
      $template->UpdateCanvas($canv);
   }   
   $canv->delete('selectedplot','selectedanno','rectexplan');
   $canv->bell;  # make the computer respond with a simple beep.
   $::DIALOG{-SELECTEDPLOT} = ""; 
   
   if( ( not defined $template->{-tkg2filename} or
         not -e      $template->{-tkg2filename} ) ) {
      # no previous file name
      &SaveAs($template, $canv, $tw); # use getSaveFile to get a filename
   }
   else {
      &Save_em($template);
   }
   $template->NeedSaving(0);
}

# SaveAs is a wrapper around the getSaveFile Tk methods and calls
# the Save_em subroutine when a file name become available.
sub SaveAs {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $tw) = (shift, shift, shift);
   
   if(not $::TKG2_CONFIG{-REDRAWDATA}) {
      # localize the global to make sure that UpdateCanvas is called
      # with redraw as true so that the data will certainly be drawn
      # onto the canvas.
      local $::TKG2_CONFIG{-REDRAWDATA} = 1;
      $template->UpdateCanvas($canv);
   }
   
   $canv->delete('selectedplot','selectedanno','rectexplan');
   $::DIALOG{-SELECTEDPLOT} = "";  # make sure that there is not a selected plot
   
   my $file;
   SAVEFILE: {
        # Use the last save directory if it appears possible, otherwise
        # go and test the user's home (actually the directory that tkg2
        # was launched from if it appears possible, otherwise go and
        # test the true user's home (/home/wasquith) if it appears possible
        # otherwise save to /tmp in which we should be pretty darn sure 
        # is viable.
        my $dir2save =
        (   $LASTSAVEDIR and
         -d $LASTSAVEDIR )           ? $LASTSAVEDIR           :
        (   $::TKG2_ENV{-USERHOME} and
         -d $::TKG2_ENV{-USERHOME} ) ? $::TKG2_ENV{-USERHOME} :
        (   $::TKG2_ENV{-HOME} and
         -d $::TKG2_ENV{-HOME} )     ? $::TKG2_ENV{-HOME}     : "/tmp" ;

      print $::BUG "Tkg2-Save: About to try getSaveFile on '$dir2save'\n";
      
      if(defined $template->{-tkg2filename} ) {
         my $curfile = $template->{-tkg2filename};
         my $home    = &dirname($curfile);
            $curfile = &basename($curfile);
         $file = $tw->getSaveFile(-title => "Save $curfile as a different Tkg2 File",
                                  -initialdir => $dir2save,
                                  -filetypes  => [ [ 'Tkg2 Files', [ '.tkg2' ] ],
                                                   [ 'All Files',  [ '*'     ] ] ]);
      }
      else {
         $file = $tw->getSaveFile(-title => "Save Canvas as a Tkg2 File",
                                  -initialdir => $dir2save,
                                  -filetypes  => [ [ 'Tkg2 Files', [ '.tkg2' ] ],
                                                   [ 'All Files',  [ '*'     ] ] ]);   
      }
   }
   
   if(not defined $file or $file eq "") {
      $LASTSAVEDIR = "";
      &Message($tw, '-nofilename');
      return;
   }
   
   my $dirname = &dirname($file);
   my $cwd     = &cwd;
   $LASTSAVEDIR = ($dirname eq '.') ? $cwd : $dirname;
   $LASTSAVEDIR = "" unless(-d $LASTSAVEDIR);
   
   $file .= ".tkg2" unless($file =~ m/[.]tkg2$/o);
   $template->{-tkg2filename} = "$file";
   &Save_em($template);
   $tw->configure(-title => "Tkg2 showing $template->{-tkg2filename}");
   $template->NeedSaving(0);
}



# Save_em is a router to dispatch to the saving file formats.
# Save_em is called in two locations, one by Save and the other
# by SaveAs.
sub Save_em {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $template = shift;  
   my $form = $template->{-fileformat};    
   if($form =~ m/DataDumper/o) {
      &_useDataDumper('save', 'fh', $template);
   }
   else {
      return 0;
   }
   chmod(0755, $template->{-tkg2filename}) if(-e $template->{-tkg2filename});
}


# Batch_open is the tkg2 file opening frontend to the Batch method
# This method ends up calling Open_em.  The main purpose of the Batch_open
# is to provide a slightly different error trapping mechanism along STDERR
# instead of the Tkg2 Message board.
sub Batch_open {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $file = shift;
   my $fh   = &_fh4reading($file);
   return 0 unless($fh);
   
   local $/ = $::TKG2_ENV{-INPUT_RECORD_SEPARATOR};
   while(<$fh>) {
      last if(m/^__DATA__/o); # the beginning caret is critical
      if(eof($fh)) {
         my $mess = "The next read on $file will be a end-of-file.\n".
                    "Tkg2 is quietly giving up processing this file.\n";
         print STDERR "Tkg2-Batch Error: $mess";          
         return 0;
      }
   }
   if(eof($fh)) {
      my $mess = "The next read on $file will be a end-of-file.\n".
                 "Tkg2 is quietly giving up processing this file.\n";
      print STDERR "Tkg2-Batch Error: $mess";          
      return 0;
   }
   chomp($_ = <$fh>);
   my $template = &Open_em($fh,$file,$_); 
   unless($template) {
      print STDERR "Tkg2-Batch Error: $file is not recognized as a tkg2 file\n";
      return 0;
   }
   close($fh) or do {
                     print STDERR "Tkg2-Batch Error: No close on $file because $!\n";
                     return 0;
                   };
   return $template;
}

# Open_em is a router to dispatch to the saving file formats.
# Open_em is called in several locations.  Here in the Open 
# subroutine, which provides a wrapper around the getOpenFile
# Tk method.  Open_em is also exported to the Batch.pm module
# so that tkg2 files can be opened without a dialog box.
sub Open_em {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($fh, $file, $form) = (shift, shift, shift);
   my $template;
   if($form =~ m/Data::Dumper/o) {
      $template = &_useDataDumper('open', $fh, $file);
   }
   else {
      return 0;  # failure returned when the template could not be opened
   }
   

   if(not ref $template) {
      my $text = "Tkg2-Serious Warning:  Tkg2 was able to determine the potential ".
                 "file format of file '$file' as Data::Dumper ".
                 "However, the file could not be eval'd properly.  Something ".
                 "must be wrong with that file.  This error occurred in OpenSave::Open_em.";
      &Message($::MW, '-generic', $text);
      return 0;
   }
   
   my $cwd = &cwd;
   if(not defined $cwd) {
      print STDERR "Tkg2-Serious Warning: Perl could NOT determine the ",
                   "current working directory with the Cwd module and ",
                   "\&cwd method.\n";
      $template->{-tkg2filename} = $file;
      
      return $template;  # even though the we could not determine the 
      # current directory, the template appears to have been read in
      # correctly as it tested as a reference (see above).  We'll return
      # the template just as if the current directory could be determined
   }             
   my $absfile = ( File::Spec->file_name_is_absolute($file) ) ? $file : "$cwd/$file";
   $template->{-tkg2filename} = $absfile;
   return $template;
}

# _useDataDumper, the actual subroutine that performs the saving and opening
# of tkg2 files in an single anonymous hash state--see CPAN-Data/Dumper.
# _useDataDumper is a wrapper around the Dump subroutines of the module.
# This is a highly compact, non-readable, single ASCII string that is
# platfrom independent, but slow to execute.  This is the ONLY format that
# allows the most flexible batch processing activities to be performed as
# this format can easily be edited by scripts and the human hand.
# The is  the default file format.
sub _useDataDumper {
   # &UseDataDumper ('open','filename');
   # &UseDataDumper ('save',$template);
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($type, $fh) = ( shift, shift);
   
   # perform the opening of the files for the eval
   if($type eq 'open') {
      
      my $file = shift;
      return 0 if( ( not defined $file or not -e $file )
                                  and
                          $file !~ /stdin/io );
      
      local $/ = undef;
      my $template = <$fh>;  # Filehandle is already made available from caller
      
      return 0 if(not defined $template ); # return false on an empty file
      eval { eval $template; };
      return 0 if($@);
      return $template if(ref $template);
   }
   else { # perform the saving of the files for the Dump methods
      my $template = shift;
            
      # make a deep and recursize clone of the template and then
      # delete any non permanent loaded data.
      my $dumpable_template = $template->DeepClone;
      $dumpable_template->DeleteLoadedData;
      
      # DUMP FIRST, WRITE SECOND
      my $indent = $::TKG2_CONFIG{-DATA_DUMPER_INDENT};
      $indent = (defined $indent) ? $indent : 1;
      $indent = 1 unless($indent eq 0);  
      $indent = 0 if($::CMDLINEOPTS{'stdout'});
      $Data::Dumper::Indent = $indent;
      # find out which Dump method is available on the currently
      # running installation of Perl, Dumpxs is faster by a lot.
      my $avail_dump = Data::Dumper->can('Dumpxs') || Data::Dumper->can('Dump');
      if(not $avail_dump) {
         warn("Tkg2-Warn: OpenSave.pm: Could not dump\n"), return 0;
      }
      my $stuff = Data::Dumper->$avail_dump([$dumpable_template], [ qw(template) ]);
         
      # Write
      my $file     = $template->{-tkg2filename};
      $fh = &_fh4writing($file);
      return unless($fh);

      &_writeHeader($file,"Data::Dumper",$fh);
      print $fh $stuff;

      close($fh) or do { &Message($::MW, '-fileerror', $!); return; };
      return 1;
   }
}

# _writeHeader writes out the header and the __DATA__ token above the 
# rest of the template.  The template of course can be in either of the three
# data formats
# The FH is the output filehandle and is ALREADY open when the subroutine is called.
sub _writeHeader {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($basename, $type, $fh) = (shift, shift, shift);
   
   # set up and write the header
   my $time = scalar(localtime);
   if( exists( $::TKG2_ENV{$SAFE}->{$basename} ) and
      $::TKG2_ENV{$SAFE}->{$basename} ne "" ) {
      print $fh "$::TKG2_ENV{$SAFE}->{$basename}";
   }
   else { # this is the standard and default header
          # this logic is usually run when a tkg2 file is created.

   # /usr/local/bin tkg2 should be the best location.  I was using
   # /usr/opt/bin for solaris, but /usr/local is just a link to 
   # it anyway.  Linux does not use opt as far as I can tell.

      print $fh <<"HERE";
#!/usr/bin/perl -w
# --------------------------------------------------------------
# A Tkg2 file -- by the enigmatic William H. Asquith
# --------------------------------------------------------------
#   The following is the standard header written by tkg2 during
#   a file save.  Tkg2 requires that the __DATA__ token be
#   present as this flag is used to demark the actual material
#   content of the file in.  Users can edit anything you want
#   above the __DATA__ token or even remove all of it entirely.
#   Or users can put calls to data retrieval scripts above the
#   'exec' to get the data files in place before tkg2 and this
#   file is actually launched. However, users must not remove
#   the __DATA__ token (double underscore DATA double underscore)

# Begin the self executing portion
#   @ARGV contains the command line arguments following
#         this file name: e.g. % $0 --presenter.
#   $0 is the name of this file.
exec("/usr/local/bin/tkg2 \@ARGV \$0") or      
print STDERR "The error message above indicates that the ",
"tkg2 executable could not be found along the above path.";

HERE
;
   }
   print $fh "__DATA__\n";  # mandatory token so that open can work properly
   
   # THE ALL IMPORTANT TKG2 TITLE LINE
   print $fh "Tkg2 File Version|$::TKG2_CONFIG{-VERSION}|$type|$time\n";
}


# The two subroutines, _fh4reading and _fh4writing each provide a switching
# mechanism by which either regular files are opened and the file handle
# returned or already open STDIN and STDOUT are returned.  Very convenient
# for building filters with tkg2.
sub _fh4reading {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my $file = shift;
   if($::CMDLINEOPTS{'stdin'}) {
      $::CMDLINEOPTS{'stdin'} = 0; # turn it off because on any other
       # calls, STDIN will be closed!
      return *STDIN;
   }
   else {
      local *FH;
      open(FH, "<$file") or
         do { 
              if($::VERBOSE) {
                 print $::VERBOSE
                    "Tkg2-error: Could not open tkg2 '$file' because = $!.\n";
                 return;
              }
              else {
                 my $mess = "Reason=$!\n"."\nFile=$file";
                 &Message($::MW, '-invalidtkg2file', $mess);
                 return;
              }
            };   
      return *FH;
   }
}


sub _fh4writing {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my $file = shift;
   if($::CMDLINEOPTS{'stdout'}) {
      $::CMDLINEOPTS{'stdout'} = 0;
      return *STDOUT;
   }
   else {
      local *FH;
      open(FH, ">$file") or do { my $mess = "\nReason=$!\n"."File=$file";
                                  &Message($::MW, '-invalidtkg2file', $mess);
                                  return;
                                };
      return *FH;
   }
}

1;
