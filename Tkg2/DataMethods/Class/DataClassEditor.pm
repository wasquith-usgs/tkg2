package Tkg2::DataMethods::Class::DataClassEditor;

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
# $Date: 2004/06/09 18:50:17 $
# $Revision: 1.17 $

use strict;
use Tkg2::Base qw(Message Show_Me_Internals);
use Tkg2::Help::Help;

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK $EDITOR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(DataClassEditor);

$EDITOR = "";

print $::SPLASH "=";

1;
__DATA__

sub DataClassEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($dataclass, $canv, $plot, $template) = @_;
   
   $EDITOR->destroy if( Tk::Exists($EDITOR) ) ;
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
      
   my $pw = $canv->parent;
   my $pe = $pw->Toplevel(-title => 'Data Class (File) Editor');
   $EDITOR = $pe;
   $pe->resizable(0,0);
  
   my $f = $pe->Frame->pack;
   my $f_1 = $f->Frame->pack(-fill   => 'y',
                             -side   => 'left',
                             -expand => 1);
   my $f_2 = $f->Frame->pack(-fill   => 'y',
                             -side   => 'right',
                             -expand => 1);
   
   $f_1->Label(-text => 'Data Files or Sets in the Plot',
               -font => $fontbig)
       ->pack(-side => 'top');
   my $lb = $f_1->Scrolled("Listbox",
                           -font       => $font,
                           -scrollbars => 'se',
                           -selectmode => 'single',
                           -background => 'white',
                           -width      => 30)
                ->pack(-side => 'top', -fill => 'both');
                   
   my $updatelb = sub { my %hash;
                        foreach my $set ( @{$dataclass} ) {
                           my $name = $set->{-setname};
                           $hash{$name}++;
                           $name .= ":$hash{$name}";
                           $lb->insert('end', $name);
                        } };
                        
   my $db = $f_1->Button(
                -text    => 'Delete All',
                -font    => $fontb,
                -command => sub { $dataclass->dropall;
                                  $lb->delete(0,'end');
                                  $template->UpdateCanvas($canv);
                                } )
                ->pack(-side => 'top');
   
   my $text1 = "  Select a data set\n".
               "  from the list and\n".
               "  perform the following\n".
               "  operations on it.";
   $f_2->Label(-text    => $text1,
               -font    => $fontb,
               -justify => 'left',
               -anchor  => 'w')
       ->pack(-side => 'top');
   $f_2->Button(-text    => 'Raise',
                -width   => 17,
                -font    => $fontb,
                -command => sub { my $index = $lb->index($lb->curselection);
                                  if( not defined $index ) {
                                     $index = $lb->size;
                                     $index--;
                                  }
                                  $dataclass->raise($index);
                                  $lb->delete(0,'end');
                                  &$updatelb();
                                  $template->UpdateCanvas($canv);
                                } )
       ->pack;
   $f_2->Button(-text    => 'Lower',
                -width   => 17,
                -font    => $fontb,
                -command => sub { my $index = $lb->index($lb->curselection);
                                  $index = 0 unless( defined $index );
                                  $dataclass->lower($index);
                                  $lb->delete(0,'end');
                                  &$updatelb();
                                  $template->UpdateCanvas($canv);
                                } )
       ->pack;
   $f_2->Button(-text    => 'Delete One',
                -width   => 17,
                -font    => $fontb,
                -command => sub { my $index = $lb->index($lb->curselection);
                                  &Message($pe,'-selfromlist'),
                                           return unless( defined $index );
                                  $dataclass->dropone($index);
                                  $lb->delete($index);
                                  $template->UpdateCanvas($canv);
                                } )->pack;                               
                                
   $f_2->Label(-text => " ")->pack;
   $f_2->Button(
       -text    => 'Edit Data Set',
       -width   => 17,
       -font    => $fontb,
       -command => sub { my $index = $lb->index($lb->curselection);
                         $index = 0 unless( defined $index );
                         my $dataset = $dataclass->getone($index);
                         my $name = $lb->get($index);
                         if(    defined $dataset
                            and defined $name ) {
                            my @args = ($canv, $plot, $template, $name);
                            $dataset->DataSetEditor(@args);
                         }
                         else {
                            &Message($pe,'-selfromlist');
                            return;
                         } } )->pack;
                         
   $f_2->Label(-text => "(launch Data Set Editor)\n",
               -font => $fontb)
       ->pack;
   my $text2 = "Sets are plotted in the\n".
               "order shown in the list box.";
   $f_2->Label(-text    => $text2,
               -font    => $fontb,
               -justify => 'left')
       ->pack;
#   $f_2->Button(-text => '*Change Data in Data Set*',
#                -font => $fontb)
#       ->pack;
#   $f_2->Label(-text => "(replace data with new data)",
#               -font => $fontb)
#       ->pack;
   
#   $f_2->Label(-text => " ")->pack;
#   $f_2->Button(
#       -text       => "Compute Statistics",
#       -width      => 17,
#       -font       => $fontb,
#       -foreground => 'red',
#       -activeforeground => 'red',
#       -command    => sub {  my $index = $lb->index($lb->curselection);
#                             $index = 0 unless( defined $index );
#                             my $dataset = $dataclass->getone($index);
#                             my $name = $lb->get($index);
#                             if( ref($dataset) ) {
#                                my @args = ($canv, $plot, $template, $name);
#                                $dataset->StatisticsEditor(@args);
#                             }
#                             else {
#                                 my $mess = "Warning: No data sets are ".
#                                            "available so statistics ".
#                                            "can not be calculated anyway.";
#                                 &Message($pe,'-generic',$mess);
#                                 return;
#                             } } )->pack;                        
   
   &$updatelb();
   
   my ($px, $py) = (2, 2);   
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   
   my @p = ( -side => 'left', -padx => $px, -pady => $py);               
   $f_b->Button(-text        => 'OK',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command     => sub { $pe->destroy;
                                      $template->UpdateCanvas($canv);
                                    } )
       ->pack(@p);  

   $f_b->Button(-text    => "Cancel",
                -font    => $fontb,
                -command => sub { $pe->destroy; } )
       ->pack(@p);
                        
   $f_b->Button(-text => "Help",
                -font => $fontb,
                -padx => 4,
                -pady => 4,
                -command => sub { &Help($pe,'DataClassEditor.pod');} )
       ->pack(@p);
}

1;
