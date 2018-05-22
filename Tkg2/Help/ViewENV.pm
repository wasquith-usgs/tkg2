package Tkg2::Help::ViewENV;

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
# $Date: 2006/09/05 01:36:22 $
# $Revision: 1.9 $

use strict;
use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK $EDITOR);

@ISA = qw(Exporter SelfLoader);
@EXPORT_OK = qw(ViewENV);

use Data::Dumper;

use Tkg2::Base qw(Message Show_Me_Internals);
use Tkg2::Help::Help;

print $::SPLASH "=\n";

1;

__DATA__

sub ViewENV {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $pw = shift;  # normally the MainWindow

   # Standard dialog behavior throughout Tkg2 core
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'View Tkg2 ENV Settings');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   # Dumped Tkg2 environmental settings   
   my $dumpedEnv    = Data::Dumper->Dump([\%::TKG2_ENV],
                                         [qw(TKG2_ENV)]);
   # Dumped Tkg2 configuration settings
   my $dumpedConfig = Data::Dumper->Dump([\%::TKG2_CONFIG],
                                         [qw(TKG2_CONFIG)]);
   
   $pe->Label(-text => 'Tkg2 Environment Hash',
              -font => $fontb)->pack();

   my $text1 = $pe->Scrolled("Text",
                  -wrap       => 'none',
                  -background => 'white',
                  -height     => 20,
                  -width      => 60 )->pack();
   $text1->insert('end', $dumpedEnv);
   $text1->configure(-state => "disabled");

   $pe->Label(-text => 'Tkg2 Configuration Hash',
              -font => $fontb)->pack();

   my $text2 = $pe->Scrolled("Text",
                  -wrap       => 'none',
                  -background => 'white',
                  -height     => 20,
                  -width      => 60)->pack();
   $text2->insert('end', $dumpedConfig);
   $text2->configure(-state => "disabled");

      
   my ($px, $py) = (2, 2);
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   
   $f_b->Button(-text    => "Leave", 
                -font    => $fontb,
                -command => sub { $pe->destroy;
                                } )
                ->pack(-side => 'left', -padx => $px, -pady => $py);
   $f_b->Button(-text    => 'Dump to File',
                -font    => $fontb,
                -foreground => $::TKG2_CONFIG{-BACKCOLOR},
                -command => [\&dumpViewEnv, $pe, $dumpedEnv, $dumpedConfig] )
                ->pack(-side => 'left', -padx => $px, -pady => $py,);
   $f_b->Button(-text    => "Log File\nSummary", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -foreground => $::TKG2_CONFIG{-BACKCOLOR},
                -command =>
                sub { &Tkg2LogFileSummary($pe,'summary'); } )
                ->pack(-side => 'left', -padx => $px, -pady => $py,);
   $f_b->Button(-text    => "Dump Log File\nSummary to File", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -foreground => $::TKG2_CONFIG{-BACKCOLOR},
                -command =>
                sub { &Tkg2LogFileSummary($pe,'dump'); } )
                ->pack(-side => 'left', -padx => $px, -pady => $py,);
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { &Help($pe,'Environment.pod'); } )
                ->pack(-side => 'left', -padx => $px, -pady => $py,);

}

sub dumpViewEnv {
   my ($pe, $dumpedEnv, $dumpedConfig) = @_;
   
   $pe->Busy;
   
   local *FH;
   
   my $file = "$::TKG2_ENV{-HOME}/__dumped_tkg2_settings__";
   open(FH,">$file") or
        do { print STDERR "Tkg2 Warning: Could not open",
                          "'$file' for writing because $!\n";
             return;
           };
   print FH "### Dumped Tkg2 ENV and Config Hashes ###\n",
            '%::Tkg2_ENV =',   "\n", $dumpedEnv,   "\n",
            '%::Tkg2_Config =',"\n", $dumpedConfig,"\n",
            "### End ###\n";
   
   print $::VERBOSE " $file has been written\n";
   close(FH) or
         do { print STDERR
                    "Tkg2 Warning: Could not close '$file' because $!\n";
              return;
            };
   my $text = "The current tkg2 session environmental and ".
              "configuration settings have been dumped to ".
              "a file called $file.\n";
   &Message($pe,'-generic',$text);
   
   $pe->Unbusy;
}


sub Tkg2LogFileSummary {
   my ($pe,$doIdump) = @_;
   
   $pe->Busy;
   
   my $sum = `$::TKG2_ENV{-TKG2HOME}/Tkg2/Util/sumtkg2log.pl`;
   
   if($doIdump eq 'dump') {
      local *FH;
   
      my $file = "$::TKG2_ENV{-HOME}/__tkg2_log_file_summary__";
      open(FH,">$file") or
         do { print STDERR "Tkg2 Warning: Could not open",
                            "'$file' for writing because $!\n";
               return;
            };
   
      print FH $sum;
   
      print $::VERBOSE " $file has been written\n";
   
      close(FH) or
            do { print STDERR
                       "Tkg2 Warning: Could not close '$file' because $!\n";
                 return;
               };
      my $text = "The tkg2 log file in /tmp/tkg2.log been summarized into ".
                 "a file called $file.\n";
      &Message($pe,'-generic',$text);
   }
   else {
      &Message($pe,'-generic',$sum);
   }
   $pe->Unbusy;
}


1;
