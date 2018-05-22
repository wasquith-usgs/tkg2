package Tkg2::DataMethods::Class::RouteData2Script;

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
# $Date: 2003/10/03 13:53:18 $
# $Revision: 1.12 $

use strict;

use Tkg2::Base qw(centerWidget Message Show_Me_Internals);
use Data::Dumper;

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK @EXPORT $EDITOR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(RouteData2Script RouteData2Script_Actually_Perform);
$EDITOR = "";


print $::SPLASH "=";

1;

__DATA__

sub RouteData2Script {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $para) = @_;
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Route data through external program');
   $EDITOR = $pe;
   
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};   
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};   
   
   $pe->resizable(0,0);
   &centerWidget($pe);   
   
   my $href = $para->{-transform_data};
   
   my $dir = $::TKG2_ENV{-TKG2HOME}."/Tkg2/Scripts/";
   my @contents;
   opendir(DIR, $dir) or return $!;
     @contents = readdir(DIR); 
   closedir(DIR);
   my @scripts;
   map { push(@scripts, $_) unless($_ eq '.' or $_ eq '..') } @contents; 
   
   my @p = qw(-side top -anchor w);
   $pe->Checkbutton(-text     => 'Do Transformation',
                    -font     => $fontb,
                    -variable => \$href->{-doit},
                    -onvalue  => 1,
                    -offvalue => 0)->pack(@p);
   
   my $entry;
   my $text = "Select a standard tkg2 transform program from the\n".
              "following list available in ~Tkg2/Scripts/";
   $pe->Label(-text    => $text,
              -font    => $fontb,
              -justify => 'left')
      ->pack(-side => 'top');
   
   my $f_1 = $pe->Frame->pack(-side => 'top', -fill => 'both');
   
   my $lb = $f_1->Scrolled("Listbox",
                           -font       => $font,
                           -scrollbars => 'e',
                           -selectmode => 'single',
                           -background => 'white',
                           -width      => 30)
                ->pack(-side => 'left', -fill => 'x');
   $f_1->Button(-text    => "Select",
                -font    => $fontb,
                -command => sub { my $index = $lb->curselection;
                                  unless( defined($index) ) {
                                     &Message($pe,'-selfromlist');
                                     return;
                                  }
                                  my $entrytext = $lb->get($index);
                                  $entrytext = $dir.$entrytext;
                                  $entry->delete('0.0','end');
                                  $entry->insert('end',$entrytext);})
       ->pack(-side => 'left');
                
   $lb->insert('end',@scripts);           
   $lb->selectionSet(0);
   
   @p = qw(-side left -fill x);
   my $f_script = $pe->Frame->pack(-side => 'top', -fill => 'x');        
   $f_script->Label(-text   => "Enter the command to run",
                    -font   => $fontb,
                    -anchor => 'w')
            ->pack(-side => 'top', -fill => 'x');
   $entry = $f_script->Entry(
                     -textvariable => \$href->{-script},
                     -font         => $font,
                     -background   => 'white',
                     -width        => 50 )
                     ->pack(@p);
        
   my $f_command = $pe->Frame->pack(-side => 'top', -fill => 'x');             
   $f_command->Label(-text   => "Enter the needed command line arguments",
                     -font   => $fontb,
                     -anchor => 'w')
             ->pack(-side => 'top', -fill => 'x'); 
   $f_command->Entry(-textvariable => \$href->{-command_line_args},
                     -font         => $font,
                     -background   => 'white',
                     -width        => 50 )->pack(@p);  
   
   
   my $finishsub = sub { if(not -e $href->{-script}) {
                           my $mess = "$href->{-script} does not exist\n";
                           &Message($pe, '-generic', $mess);
                           return;
                         }
                         $pe->destroy; return; };
   
   
   my ($px, $py) = (2, 2);   

   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
                     
   $f_b->Button(-text        => 'OK',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command     => $finishsub )
       ->pack(-side => 'left', -padx => $px, -pady => $py); 
   
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; return; } )
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(-side => 'left', -padx => $px, -pady => $py,);  
}
  
  
  
  
  
  
  
  
sub RouteData2Script_Actually_Perform {
   my ($para, $data, $abscissa, $ordinates) = ( shift, shift, shift, shift);

   # STEP 1: BUILDUP THE COMMAND
   my $transfile   = "tkg2R2S.tmp";
   my $ref         = $para->{-transform_data};
   my $script      = $ref->{-script};
   my $cmdlineargs = $ref->{-command_line_args};
   my $command = "$script $cmdlineargs $transfile";
   
   print $::VERBOSE "      Routing data through: $script\n";
   
   # STEP 2:  REMOVED UNNEEDED KEYS FROM THE DATA HASH
   my @allkeys   = keys %$data;
   my @ordinates = @$ordinates;
   ALLKEYS: foreach my $key (@allkeys) {
      next if($key eq $abscissa);
      foreach my $ord (@ordinates) { next ALLKEYS if($key eq $ord) }
      delete($data->{$key});
   }
   
   # STEP 3:  BUILD UP HEADER FOR TRANSFER FILE
   my $header = <<HEADER;
# Tkg2 RouteData2Script Hash Transfer File
#
# X key and Y key(s)
X=$abscissa
HEADER

   # writeout the Y key(s)
   map { $header .= "Y=$_\n" } @ordinates;
  
   $header .= "Data Dumper Hash\n";
   
   
   # STEP 4:  DUMP THE HEADER AND HASH OUT TO $transfile
   $Data::Dumper::Indent = 1;
   local *FH;
   open(FH, ">$transfile") or
            do { &Message($::MW, '-generic', "Open for write on $transfile because $!"); return; };
      print FH $header;
      my $stuff = Data::Dumper->Dump([$data], [ qw(data) ]);
      print FH $stuff;
   close(FH) or do { &Message($::MW, '-fileerror', $!); return; };
   
   print $::VERBOSE "      Data dumped into '$transfile'\n";

   
   # STEP 5: CALL THE EXTERNAL PROGRAM
   # Try to compile the program first
   my $compile = `perl -c tkg2 2>&1`;
   unless($compile =~ m/tkg2 syntax OK/) {
      return "Could not compile $command\n $compile";
   }
   
   print $::VERBOSE "      Forking to external program\n";
   my $stdout_from_external_program = `$command`;
   # check program return value
   if($stdout_from_external_program !~ 'External Program OK') {
      return "STDOUT from external program is not equal to 'External Program OK'.\n";
   }
   if(not -e $transfile) {
      return "The transferfile $transfile from the external program does not exist\n";
   }
  
   # STEP 5: READ THE EXTERNAL PROGRAM OUTPUT (BACK INTO $transfile)
   $data = undef;
   open(FH, "<$transfile") or
          do { &Message($::MW, '-generic', "Open for read on $transfile because $!"); return; };
      local $/ = undef;
      $data = <FH>;
   close(FH) or do { &Message($::MW, '-fileerror', $!); return; };
   return "Empty file returned from external program" if(not defined($data));
   eval { eval $data; };
   return "The eval did not work because $@\n" if($@);
   if(not exists($data->{$abscissa})) {
      return "The abscissa $abscissa does not exists in eval'ed data\n";
   }
   
   foreach my $ord (@ordinates) {
      if(not exists($data->{$ord}) ) { 
         return "The ordinate $ord does not exists in eval'ed data\n";
      } 
   }
   unlink($transfile);
   print $::VERBOSE "      Transformed data has been thawed back into core tkg2\n";
  
   return ('OK', $data);
}  
   
1;


__END__

See the ~Tkg2/Scripts/DoNoTransform_JustTest.pl for a complete in-out
operation of the external transformation of the data.  When that script
is run the data is not changed.  That script is an example of the type of
(preferred) wrapper that the developer needs to build for their script
to talk properly with tkg2.
