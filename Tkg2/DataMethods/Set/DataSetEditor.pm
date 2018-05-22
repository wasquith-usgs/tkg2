package Tkg2::DataMethods::Set::DataSetEditor;

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
# $Date: 2004/06/09 18:51:25 $
# $Revision: 1.15 $

use strict;
use Tkg2::Base qw(Message Show_Me_Internals);
use Tkg2::Help::Help;

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK $EDITOR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(DataSetEditor);

$EDITOR = "";

print $::SPLASH "=";

1;
__DATA__
sub DataSetEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($dataset, $canv, $plot, $template, $name) = @_;
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pw = $canv->parent;
   my $pe = $pw->Toplevel(-title => "Data Set Editor for $name");
   $EDITOR = $pe;
   $pe->resizable(0,0);
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
   
   my ($lb_org, $lb_show, $entrytext, $entry, $modifyindex, $mod_b);
   my $buttontext = 'Modify Name';
   my $updatelb = sub { my ($lb, $org_or_show) = (shift, shift);
                        my $dataord;
                        foreach $dataord ( @{$dataset->{-DATA}} ) {
                           $lb->insert( 'end', $dataord->{$org_or_show} );
                        } };
   
   my $f = $pe->Frame->pack;
   my @pack = (-fill, 'y', -side, 'left', -expand, 1);
   my $f_1 = $f->Frame->pack(@pack);
   my $f_2 = $f->Frame->pack(@pack);
   my $f_s = $f->Frame->pack(@pack);
   my $f_3 = $f->Frame->pack(@pack);
   $f_s->Label(-text => "", -height => 3)->pack;
   my $f_4 = $pe->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   my $f_5 = $pe->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   
   $f_1->Label(-text => "\nAbscissa (X-title)",
               -font => $fontb)
       ->pack(-anchor => 's');
   $f_1->Label(-text => "Ordinates (Y-title)",
               -font => $fontb)
       ->pack(-anchor => 's');
   $f_1->Button(-text    => "Edit Plot Style",
                -width   => 15,
                -font    => $fontb,
                -command => sub { my $index1 = $lb_show->curselection;
                                  my $index2 = $lb_org->curselection;
                                  my $index = undef;
                                  if($index1) {
                                     $index = $lb_show->index($index1);
                                  }
                                  elsif($index2) {
                                     $index = $lb_show->index($index2);
                                  }
                                  else {
                                    &Message($pe,'-selfromlist');
                                     return;
                                  }
                                  $dataset->editone($index, $canv, $template, $plot);
                                })
       ->pack;
                                   
   $f_1->Button(-text    => 'Raise in Set',
                -width   => 15,
                -font    => $fontb,
                -command => sub { my $index1 = $lb_show->curselection;
                                  my $index2 = $lb_org->curselection;
                                  my $index = undef;
                                  if($index1) {
                                     $index = $lb_show->index($index1);
                                  }
                                  elsif($index2) {
                                     $index = $lb_show->index($index2);
                                  }
                                  else {
                                     $index = $lb_org->size;  $index--;
                                  }
                                  $dataset->raise($index);
                                  $lb_org->delete(0,'end');
                                  $lb_show->delete(0,'end');
                                  &$updatelb($lb_org,"-origordinate");
                                  &$updatelb($lb_show,"-showordinate");
                                  $template->UpdateCanvas($canv);
                                } )
       ->pack;

   $f_1->Button(-text    => 'Lower in Set',
                -width   => 15,
                -font    => $fontb,
                -command => sub { my $index1 = $lb_show->curselection;
                                  my $index2 = $lb_org->curselection;
                                  my $index = undef;
                                  if($index1) {
                                     $index = $lb_show->index($index1);
                                  }
                                  elsif($index2) {
                                     $index = $lb_show->index($index2);
                                  }
                                  else {
                                     $index = 0;
                                  }
                                  $dataset->lower($index);
                                  $lb_org->delete(0,'end');
                                  $lb_show->delete(0,'end');
                                  &$updatelb($lb_org,"-origordinate");
                                  &$updatelb($lb_show,"-showordinate");
                                  $template->UpdateCanvas($canv);
                                 } )
       ->pack;
       
   $f_1->Button(-text    => 'Delete from Set',
                -width   => 15,
                -font    => $fontb,
                -command => sub { my $index1 = $lb_show->curselection;
                                  my $index2 = $lb_org->curselection;
                                  my $index = undef;
                                  if($index1) {
                                     $index = $lb_show->index($index1);
                                  }
                                  elsif($index2) {
                                     $index = $lb_show->index($index2);
                                  }
                                  else {
                                     &Message($pe,'-selfromlist');
                                     return;
                                  }
                                  $dataset->dropone($index);
                                  $lb_org->delete(0,'end');
                                  $lb_show->delete(0,'end');
                                  &$updatelb($lb_org,"-origordinate");
                                  &$updatelb($lb_show,"-showordinate");
                                  $template->UpdateCanvas($canv);
                                } )->pack;
   $mod_b = $f_1->Button(
                -textvariable => \$buttontext,
                -width        => 15,
                -font         => $fontb,
                -command      => sub {
                             if($buttontext eq 'Modify Name') {
                                my $index1 = $lb_show->curselection;
                                my $index2 = $lb_org->curselection;
                               if($index1) {
                                 $modifyindex = $lb_show->index($index1);
                               }
                               elsif($index2) {
                                 $modifyindex = $lb_show->index($index2);
                               }
                               else {
                                 &Message($pe,'-selfromlist');
                                 return;
                               }
                               $entrytext = $lb_show->get($modifyindex);
                               $buttontext = 'Submit Name';
                               $entry->configure(-state => 'normal');
                               $entry->insert('end',$entrytext);
                               $mod_b->configure(-foreground       => 'red',
                                                 -activeforeground => 'red');
                               return;
                             }
                             else {
                                $buttontext = 'Modify Name';
                                $mod_b->configure(-foreground       => 'black',
                                                  -activeforeground => 'black');
                                $entrytext = $entry->get('0.0','end');
                                $entry->delete('0.0','end');
                                $entry->configure(-state => 'disabled');
                                $entrytext =~ s/\n$//;
                                chomp($entrytext);
                                $lb_show->delete($modifyindex);
                                $lb_show->insert($modifyindex, $entrytext);
                                $dataset->{-DATA}->
                                   [$modifyindex]->{-showordinate} = $entrytext;
                                $entry->delete(0,'end');
                             } } )
                ->pack;                            
                              
   
   $f_2->Label(-text => "Original",
               -font => $fontb)
       ->pack(-anchor => 's'); 
   $f_2->Entry(-textvariable =>
               \$dataset->{-DATA}->[0]->{-origabscissa},
               -font         => $font,
               -background   => 'linen',
               -width        => 20,
               -state        => 'disabled')
       ->pack;
   $lb_org = $f_2->Listbox(-background => 'linen',
                           -font       => $font,
                           -selectmode => 'single',
                           -width      => 20,
                           -height     => 10)
                 ->pack;
 
   my $yscrollbar = $f_s->Scrollbar(-width => 10)
                        ->pack(-side => 'left', -fill => 'y'); 
   $yscrollbar->configure(
              -command => sub { $lb_org->yview(@_);
                                $lb_show->yview(@_);
                              }); 
   $f_3->Label(-text => "New (show on plot)",
               -font => $fontb)
       ->pack(-anchor => 's'); 
   $f_3->Entry(-textvariable =>
               \$dataset->{-DATA}->[0]->{-showabscissa},
               -font         => $font,
               -background   => 'linen',
               -width        => 70,
               -state        => 'disabled')
       ->pack;
   $lb_show = $f_3->Listbox(-background => 'linen',
                            -font       => $font,
                            -selectmode => 'single', 
                            -width      => 70,
                            -height     => 10)
                  ->pack;
 
   $f_4->Label(-text => "", -width => 19)->pack(-side => 'left');
   my $xscrollbar = $f_4->Scrollbar(-width  => 10,
                                    -orient => 'horizontal')
                        ->pack(-fill   => 'x',
                               -side   => 'left',
                               -expand => 1);  
   
   
   my $f_5l = $f_5->Frame->pack(-side => 'left');
   my $f_5r = $f_5->Frame
                  ->pack(-side => 'right', -expand => 1, -fill => 'x');
   $f_5l->Label(-text => "Modify the selected\nordinate title\n\n",
                -font => $fontb)
        ->pack(-side => 'top');
   $f_5l->Button(-text    => 'Clear Field',
                 -font    => $fontb,
                 -width   => 15,
                 -command => sub { $entry->delete('0.0','end') } )
        ->pack(-side => 'top');
   $entry = $f_5r->Scrolled('Text',
                            -font       => $font,
                            -scrollbars => 'se',
                            -wrap       => 'none',
                            -width      => 60,
                            -height     => 7,
                            -background => 'white',
                            -state      => 'disabled' )
                 ->pack(-fill => 'x');
   
   $xscrollbar->configure( -command => sub { $lb_org->xview(@_);
                                             $lb_show->xview(@_);
                                           }); 
   my $xscroll_lbs = sub { my ($sb, $that2Bscrolled, $lbs) =
                              ( shift, shift, shift);
                           $sb->set(@_);
                           my ($left, $right) = $that2Bscrolled->xview();
                           my $lb;
                           foreach $lb (@$lbs) {
                              $lb->xview("moveto" => $left);
                           } };
 
   my $yscroll_lbs = sub { my ($sb, $that2Bscrolled, $lbs) =
                              ( shift, shift, shift);
                           $sb->set(@_);
                           my ($top, $bottom) = $that2Bscrolled->yview();
                           my $lb;
                           foreach $lb (@$lbs) {
                              $lb->yview("moveto" => $top);
                           } };



   $lb_org->configure(-xscrollcommand =>
              [ $xscroll_lbs, $xscrollbar, $lb_org, [ $lb_org, $lb_show ] ],
                      -yscrollcommand =>
              [ $yscroll_lbs, $yscrollbar, $lb_org, [ $lb_org, $lb_show ] ] );
   $lb_show->configure(-xscrollcommand =>
              [ $xscroll_lbs, $xscrollbar, $lb_show, [ $lb_org, $lb_show ] ],
                       -yscrollcommand =>
              [ $yscroll_lbs, $yscrollbar, $lb_org, [ $lb_org, $lb_show ] ] );
              

   &$updatelb($lb_org,"-origordinate");
   &$updatelb($lb_show,"-showordinate");
               
   my ($px, $py) = (2, 2);   
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
                     
   my $b_ok = $f_b->Button(
                  -text        => "OK and Exit\nDataSet Editor",
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { $pe->destroy;
                                    $template->UpdateCanvas($canv);
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py); 
                  
   $f_b->Button(
       -text        => "OK and Exit\nDataClass Editor",
       -font        => $fontb,   
       -borderwidth => 3,
       -highlightthickness => 2,
       -command =>
       sub { 
          my $ed = \$Tkg2::DataMethods::Class::DataClassEditor::EDITOR;
          $$ed->destroy if( Tk::Exists($$ed) );
          $pe->destroy;
          $template->UpdateCanvas($canv);
       } )
       ->pack(-side => 'left', -padx => $px, -pady => $py); 
                    
                                         
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,       
                -command => sub { $pe->destroy; })
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text => "Help",
                -font => $fontb, 
                -padx => 4,
                -pady => 4,
                -command => sub { &Help($pe,'DataSetEditor.pod'); } )
       ->pack(-side => 'left', -padx => $px, -pady => $py,);  
   
}

1;
