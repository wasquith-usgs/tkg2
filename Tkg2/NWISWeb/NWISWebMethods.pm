package Tkg2::NWISWeb::NWISWebMethods;

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
# $Date: 2004/06/09 18:25:39 $
# $Revision: 1.8 $

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
use SelfLoader;

@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw( NWISWebFrontEnd );

use Tkg2::Base qw(Message strip_space isNumber);

print $::SPLASH "=";

1;

__DATA__

sub NWISWebFrontEnd {
   my $type = pop(@_);
   my %dispatch = ( 'daily'   => sub { &NWISEditor(@_,'daily');    },
                    'peaks'   => sub { &NWISEditor(@_,'peaks');    },
                    'monthly' => sub { &NWISEditor(@_,'monthly');  },
                    'annual'  => sub { &NWISEditor(@_,'annual');   }, );
   if(not exists($dispatch{$type})) {
      warn " Tkg2-NWISFrontEnd  Invalid sub call\n";
      return;
   }
   &{ $dispatch{$type} };
}


sub getADMvalues {
   my ($plot, $template, $canv, $type) = ( shift, shift, shift, shift);
   return unless($type eq 'annual' or $type eq 'daily' or $type eq 'monthly');
   return unless(@_);
   my @request = @_;
   my $retrievaltype = ($type eq 'annual') ? 'annual'             :
                                               ($type eq 'monthly') ? 'monthly' : 'discharge';
   $canv->Busy;
   foreach (@request) {
      my ($station, $t1, $t2) = split(/:/, $_);
      $t1 = &strip_space($t1);
      $t2 = &strip_space($t2);
      my ($m1, $d1, $y1) = split(/\s+/, $t1, -1);
      my ($m2, $d2, $y2) = split(/\s+/, $t2, -1);
      my $getwholeperiod = (defined($m1) and defined($d1) and defined($y1) and
                            defined($m2) and defined($d2) and defined($y2) ) ? 0 : 1;
      print " Tkg2-NWISMethods::getADMvalues data for USGS $station\n" if($::TKG2_CONFIG{-DEBUG});
      if(not $getwholeperiod) {
         print "                  Begin date is $m1/$d1/$y1\n" if($::TKG2_CONFIG{-DEBUG});
         print "                  End   date is $m2/$d2/$y2\n" if($::TKG2_CONFIG{-DEBUG});
      }
      my $path = "http://water.usgs.gov/nwis-bin/$retrievaltype/";
      my $command;
      my $getfile = ($getwholeperiod) ? "nwisget-$station-$retrievaltype.rdb" :
                                        "nwisget-$station-$retrievaltype-$m1$d1$y1-$m2$d2$y1.rdb";
      unlink($getfile) if(-e $getfile);
      COMMAND: {
         if($getwholeperiod) {
            $command = "GET '$path?site_id=$station".
                       "&format=rdb".
                       "&compression=gz' | gzcat | ";
         }
         else {
            $command = "GET '$path?site_id=$station".
                       "&begin_date=$m1%2F$m1%2F$y1".
                       "&end_date=$m2%2F$d2%2F$y2".
                       "&format=rdb".
                       "&compression=gz' | gzcat |";  
         }
         last COMMAND;
      }
      print "COMMAND = $command\n" if($::TKG2_CONFIG{-DEBUG});
      my $numfilelines = 0;
      my $numdatalines = 0;
      open(GETFH, ">$getfile") or die "$!\n";
         open(PIPE, "$command")  or die "$!\n";
            if($retrievaltype eq 'monthly') {
               my @line;
               while(<PIPE>) {
                  $numfilelines++;
                  if(/^#/) { print GETFH; next; }
                  chomp($_);
                  @line = split("\t", $_, -1);
                  print GETFH "$line[0]\t$line[1]$line[2]\t$line[3]\n";
                  $_ = <PIPE>; # remove the format line
                  chomp($_);
                  @line = split("\t", $_, -1);
                  print GETFH "$line[0]\t$line[1]$line[2]\t$line[3]\n";
                  last;
               }
               while(<PIPE>) {
                  $numdatalines++;
                  chomp($_);
                  @line = split("\t", $_ ,-1);
                  $line[2] = "" if(not defined($line[2]));
                  print GETFH "$line[0]\t$line[2]/15/$line[1]\t$line[3]\n";
               }
            }
            elsif($retrievaltype eq 'annual') {
               my @line;
               while(<PIPE>) {
                  $numfilelines++;
                  if(/^#/) { print GETFH; next; }
                  print GETFH;
                  $_ = <PIPE>; # remove the format line
                  print GETFH;
                  last;
               }
               while(<PIPE>) {
                  $numdatalines++;
                  chomp($_);
                  @line = split("\t", $_ ,-1);
                  $line[2] = "" if(not defined($line[2]));
                  print GETFH "$line[0]\t6/15/$line[1]\t$line[2]\n";
               }
            }
            else {
               while(<PIPE>) {
                  $numfilelines++;
                  if(/^#/) { print GETFH; next;}
                  print GETFH;
                  $_ = <PIPE>; # remove the format line
                  print GETFH;
                  last;
               }
               while(<PIPE>) {
                  $numdatalines++;
                  print GETFH;
               }
            }
         close(GETFH) or
              do { my $mess = "Could not close the preprocessed NWIS retrieval\n";
                   &Message($::MW, '-generic', $mess);
                   return; };
      close(PIPE) or
            do { my $mess = "Could not close the pipe on the NWIS retrieval\n";
                 &Message($::MW, '-generic', $mess);
                 return; };
             
      if((not -e $getfile) or ($numdatalines == 0) or ($numfilelines == 0) ) {
         my $mess =" Tkg2-NWISWeb::NWISWebMethods::getADMvalues GET did not return a file";
         &Message($::MW, '-generic', $mess);
         $canv->Unbusy;
         return;
      }
      
      # system("cat $getfile");
      print " Tkg2-NWISMethods::getADMvalues Loading into plot\n" if($::TKG2_CONFIG{-DEBUG});
      my %para = ( -fullfilename  => "$getfile",
                   -fileisRDB     => 1,
                   -numskiplines  => 0,
                   -missingval    => "",
                   -filedelimiter =>  '\t',
                   -numlabellines => 0,
                   -skiplineonmatch => "^#",
                   -sortdoit      => 0,
                   -sorttype      => 'numeric',
                   -sortdir       => 'ascend');
      my %plotpara = ( -plotaxes  => 'Bottom and Left',           
                       -plotstyle => 'X-Y Line'); 
      my ($header, $data, $linecount) =  $plot->{-dataclass}->ReadRDBFile($canv, $plot, $template, \%para, 0);
      $plot->{-dataclass}->LoadDataIntoPlot($canv, $plot, $template,
                                            $header, $data, \%para, \%plotpara, $linecount);
      unlink($getfile) unless($::TKG2_CONFIG{-DEBUG});
   }   
   $canv->Unbusy;
}
        
        
        
sub getPeaks {
   my ($plot, $template, $canv) = ( shift, shift, shift);
   return unless(@_);
   my @request = @_;
   $canv->Busy;
   foreach (@request) {
      my ($station, $y1, $y2) = split(/:/, $_);
      my $getwholeperiod = (defined($y1) and defined($y2)) ? 0 : 1;
      print " Tkg2-NWISMethods::getPeaks for USGS $station\n" if($::TKG2_CONFIG{-DEBUG});
      if(not $getwholeperiod) {
         print "                  Beginning water year is $y1\n" if($::TKG2_CONFIG{-DEBUG});
         print "                     Ending water year is $y2\n" if($::TKG2_CONFIG{-DEBUG});
      }
      my $path = 'http://water.usgs.gov/nwis-bin/peak/';
      my $command;
      my $getfile = ($getwholeperiod) ? "nwisget-$station.rdb" :
                                        "nwisget-$station-$y1-$y2.rdb";
      unlink($getfile) if(-e $getfile);
      COMMAND: {
         if($getwholeperiod) {
            $command = "GET '$path?site_id=$station".
                       "&format=rdb".
                       "&compression=gz' | gzcat > $getfile";
         }
         else {
            $command = "GET '$path?site_id=$station".
                       "&begin_date=$y1".
                       "&end_date=$y2".
                       "&format=rdb".
                       "&compression=gz' | gzcat > $getfile";  
         }
         last COMMAND;
      }
      print "COMMAND = $command\n";  
      #system($command);
      next;
      if(not -e $getfile) {
         print " Tkg2-NWISMethods::getPeaks  GET command did not return a file\n";
      }
      # system("cat $getfile");
      print " Tkg2-NWISMethods::getPeaks  Loading into plot\n" if($::TKG2_CONFIG{-DEBUG});
      my %para = ( -fullfilename  => "$getfile",
                   -fileisRDB     => 1,
                   -numskiplines  => 0,
                   -missingval    => "",
                   -filedelimiter =>  '\t',
                   -numlabellines => 0,
                   -skiplineonmatch => "^#",
                   -sortdoit      => 0,
                   -sorttype      => 'numeric',
                   -sortdir       => 'ascend');
      my %plotpara = ( -plotaxes  => 'Bottom and Left',           
                       -plotstyle => 'Scatter'); 
      my ($header, $data, $linecount) =  $plot->{-dataclass}->ReadRDBFile($canv, $plot, $template, \%para, 0);
      $plot->{-dataclass}->LoadDataIntoPlot($canv, $plot, $template,
                                            $header, $data, \%para, \%plotpara, $linecount);
      unlink($getfile) unless($::TKG2_CONFIG{-DEBUG});
   }   
   $canv->Unbusy;
}

sub NWISEditor {
   my ($plot, $template, $canv, $type) = ( shift, shift, shift, shift);
   if(Tk::Exists($::DIALOG{-NWISEDITOR})) { $::DIALOG{-NWISEDITOR}->destroy; }
   my $tw = $canv->parent;
   my $title = uc("NWIS get $type data");
   my $pe = $tw->Toplevel(-title => "$title");
   my ( $station, $end_date, $begin_date, $finishsub);
   my ($px, $py) = (1, 1);
   my $lb;

   my $f_1  =  $pe->Frame->pack(-side => 'top',  -fill => 'x');
   my $f_11 = $f_1->Frame->pack(-side => 'left', -fill => 'x');
   my $f_12 = $f_1->Frame->pack(-side => 'left', -fill => 'x');
 
   my $f_sta = $f_11->Frame->pack(-side => 'top', -fill => 'x');        
   $f_sta->Label(-text => "USGS station number ")
        ->pack(-side => 'left', -anchor => 'w');
   $f_sta->Entry(-textvariable => \$station,
                 -bg => 'white', -width => 15  )
        ->pack(-side => 'left', -fill => 'x');
    
   my (@begin_date, @end_date);   
   my $f_beg = $f_11->Frame->pack(-side => 'top', -fill => 'x');        
      $f_beg->Label(-text => "Begin Date (m,d,yyyy)")
            ->pack(-side => 'left', -anchor => 'w');
   foreach (0..2) {
      $begin_date[$_] = "";
      $f_beg->Entry(-textvariable => \$begin_date[$_],
                    -bg => 'white', -width => 5  )
            ->pack(-side => 'left');        
   }  
   my $f_end = $f_11->Frame->pack(-side => 'top', -fill => 'x');                
      $f_end->Label(-text => "  End Date (m,d,yyyy)")
            ->pack(-side => 'left', -anchor => 'w'); 
   foreach (0..2) {    
      $end_date[$_] = "";
      $f_end->Entry(-textvariable => \$end_date[$_],
                    -bg => 'white', -width => 5  )
            ->pack(-side => 'left');
   }      
   
   $f_12->Button(-text => ' Add Entry  ',
         -command => sub { return unless($station =~ m/\d{8}/);
                           foreach (@begin_date, @end_date) {
                              $_ = "", return unless(&isNumber($_) || $_ eq ""); 
                           }
                           $lb->insert('end',"$station:@begin_date:@end_date" );
                           $station = undef;
                           foreach (@begin_date, @end_date) { $_ = ""; }
                         } )
        ->pack(-fill => 'x', -padx => 3);
   $f_12->Button(-text => 'Delete Entry',
                 -command => sub { $lb->delete($lb->curselection); } )
        ->pack(-fill => 'x', -padx => 3);
        
   
   my $f_2 = $pe->Frame->pack(-side => 'top', -fill => 'x');
   $lb = $f_2->Scrolled("Listbox", -scrollbars => 'e',
                        -selectmode => 'single',
                        -bg => 'linen', -width => 40)
                ->pack(-side => 'top', -fill => 'x');    
   
   my $f_3  =  $pe->Frame->pack(-side => 'bottom', -fill => 'x');             
   my $font = "Helvetica 10 bold";   
   my $f_b = $f_3->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-fill => 'x');
   my $b_ok = $f_b->Button(-text => 'GET',
                           -font => $font, -borderwidth => 3,
                           -highlightthickness => 2,
          -command => sub {  SWITCH: { 
                               &getPeaks(    $plot, $template, $canv, $type, $lb->get(0,'end')), last SWITCH if($type eq 'peaks');
                               &getADMvalues($plot, $template, $canv, $type, $lb->get(0,'end')), last SWITCH if($type eq 'annual');
                               &getADMvalues($plot, $template, $canv, $type, $lb->get(0,'end')), last SWITCH if($type eq 'daily');
                               &getADMvalues($plot, $template, $canv, $type, $lb->get(0,'end')), last SWITCH if($type eq 'monthly');
                               warn " Tkg2::NWISEditor Could not route the plot type\n"; return;
                             }
                             $pe->destroy;
                           } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  
   $b_ok->focus;
   my $b_cancel = $f_b->Button(-text    => "Cancel", 
                               -font    => $font,
                               -command => sub { $pe->destroy; })
                      ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   my $b_help = $f_b->Button(-text    => "Help",
                             -font    => $font,
                             -padx    => 4, -pady => 4,
                             -command => sub { return; } )
                    ->pack(-side => 'left', -padx => $px, -pady => $py,);
       
}

1;


