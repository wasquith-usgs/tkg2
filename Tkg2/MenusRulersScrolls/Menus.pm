package Tkg2::MenusRulersScrolls::Menus;

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
# $Date: 2007/09/07 18:20:37 $
# $Revision: 1.67 $

use strict;

use Tkg2::Base qw(Message Show_Me_Internals);
use Tkg2::DeskTop::Activities qw(CreateTemplate Open TotalExit);
use Tkg2::EditGlobalVars qw(EditGlobalVariables);
use Tkg2::Draw::DrawPointStuff qw(delOverlapCache);
use Tkg2::Help::Help;

use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(TemplateFullMenus TemplateDisplayMenus);


print $::SPLASH "=";


sub TemplateDisplayMenus {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $f, $tw, $canv) = @_;
  
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   my $_exportsub = sub { $template->Tkg2Export($canv,$tw) };
   my $_metapostsub = sub { $template->Tkg2MetaPost($canv,$tw) };
   my $_printsub  = sub { $template->Print($canv, $tw) };
   my $_savesub   = sub { local $::TKG2_CONFIG{-DELETE_LOADED_DATA} = 0;
                         $template->SaveAs($canv, $tw);
                        };
   my $_exitsub; # defined later
   
   my $menu = $f->Menubutton(-text    => 'TKG2 DISPLAYER',
                             -font    => $fontb,
                             -relief  => 'groove',
                             -tearoff => 0)
                ->pack(-side => 'left',
                       -padx => 1,
                       -pady => 1);
   my $menu2 = $f->Menubutton(-text    => 'Global Variables',
                              -font    => $fontb,
                              -relief  => 'groove',
                              -tearoff => 0)
                 ->pack(-side => 'left',
                        -padx => 1,
                        -pady => 1);
   my @filemenu = ();
   push(@filemenu, ( [ 'command'    => 'Export',
                      -font        => $font,
                      -accelerator => "Cntl-E",
                      -command     => $_exportsub ] )
       ) unless($::CMDLINEOPTS{'noexport'});
   
   push(@filemenu, ( [ 'command'    => 'Export to MetaPost',
                      -font        => $font,
                      -command     => $_metapostsub ] )
       ) unless($::CMDLINEOPTS{'noexport'});
   
   push(@filemenu, ([ 'command'    => 'Print (postscript to printer)',
                      -font        => $font,
                      -accelerator => "Cntl-P",
                      -command     => $_printsub ],
                    "-", )
       ) unless($::CMDLINEOPTS{'noprint'});
       
   push(@filemenu, ([ 'command'    => "Save As (with imported data)",
                      -font        => $font,
                      -accelerator => "Cntl-S",
                      -command     => $_savesub ],
                    "-")
       ) unless($::CMDLINEOPTS{'nosave'});

   if( $::CMDLINEOPTS{'justdisplay'} ) {
      $_exitsub = ($::CMDLINEOPTS{'nomw'}) ?
                       sub { $tw->destroy; $::MW->destroy; } :
                       sub { $tw->destroy };
     
      push(@filemenu, [ 'command'    => 'Exit',
                        -font        => $font,
                        -accelerator => "Cntl-Q",
                        -command     => $_exitsub ] );
   } 
   else {
      $_exitsub = sub { $tw->destroy; $::MW->destroy; };
      push(@filemenu, [ 'command'    => 'Exit',
                        -font        => $font,
                        -accelerator => "Cntl-Q",
                        -command     => $_exitsub ] );
   }
   $menu->AddItems(@filemenu);
   
   my @globalmenu = ();
   push(@globalmenu, ( [ 'command'    => 'Edit some Global Variables',
                          -font        => $font,
                          -command     =>
                          [ \&EditGlobalVariables,
                            $::MW,$template,$canv,
                            'no_edit_of_plotting_position'] ] )
       );
   
   $menu2->AddItems(@globalmenu);
   
   # Set the keyboard bindings on the menu commands
   $tw->bind("<Control-Key-e>", $_exportsub );
   $tw->bind("<Control-Key-E>", $_exportsub );
   $tw->bind("<Control-Key-p>", $_printsub );
   $tw->bind("<Control-Key-P>", $_printsub );
   $tw->bind("<Control-Key-s>", $_savesub );
   $tw->bind("<Control-Key-S>", $_savesub );
   $tw->bind("<Control-Key-q>", $_exitsub );
   $tw->bind("<Control-Key-Q>", $_exitsub );
}


1;
#__DATA__

sub TemplateFullMenus {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $f, $tw, $canv) = ( shift, shift, shift, shift);
   my @menus = ();

   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   if($::CMDLINEOPTS{'redoinst'} or $::CMDLINEOPTS{'redodata'}) { 
      my $color =
         ( $::CMDLINEOPTS{'redoinst'} and
           $::CMDLINEOPTS{'redodata'} ) ? 'red' :
         ( $::CMDLINEOPTS{'redoinst'} ) ? 'lightblue' : 'yellow';
      # The tiny little vertical update button in the upper left corner
      my $variable; # we mess with this so animation is seen during the
      # press, but the button returns to its 0 state when the canvas
      # is finished updating, neat little trick.
      $f->Checkbutton(
        -font             => $font,
        -variable         => \$variable,
        -offvalue         => 0,
        -onvalue          => 1,
        -indicatoron      => 0,
        -selectcolor      => $color,
        -activebackground => $color,
        -background       => $color,
        -command          => sub { $f->idletasks;
                                   $template->UpdateCanvas($canv);
                                   $variable = 0;
                                 } )
        ->pack(-side => 'left');
   }
   
   foreach ( 'FILE',
             'EDIT',
             'PLOT',
             'DATA',
             'ANNOTATION',
             'Global Settings',
             'SCREEN SHOTS',
             'HELP' ) {
      my $tearoff = (m/HELP|SCREEN SHOTS/io) ? 1 : 0;
      push ( @menus, $f->Menubutton(-text    => $_,
                                    -tearoff => $tearoff,
                                    -relief  => 'groove',
                                    -padx    => 4,
                                    -font    => $fontb) );
   }
   $menus[$#menus]->pack(-side => 'right',
                         -padx => 1,
                         -pady => 1 );
   $menus[$#menus-1]->pack(-side => 'right',
                           -padx => 1,
                           -pady => 1 );
   foreach (0..($#menus-2)) { $menus[$_]->pack(-side => 'left',
                                               -padx => 1,
                                               -pady => 1);
   }
   
   
   
   
   my $_copyplot = sub { &Message($tw,'-selplot'),
                               return unless(ref($::DIALOG{-SELECTEDPLOT}));
                         $::DIALOG{-CLIPBOARDPLOT} =
                         $::DIALOG{-SELECTEDPLOT}->clone;
                       };
   
   my $_pasteplot =
      sub { &Message($tw,'-noclipboard'),
                     return unless(ref($::DIALOG{-CLIPBOARDPLOT}));
            my $plot = $::DIALOG{-CLIPBOARDPLOT};
            $::DIALOG{-CLIPBOARDPLOT} = "";
            my $oset = $::MW->fpixels('0.17i');
            $plot->{-xlmargin} += $oset;
            $plot->{-xrmargin} -= $oset;
            $plot->{-yumargin} += $oset;
            $plot->{-ylmargin} -= $oset;
            $plot->configwidth;
            
            $plot->{-explanation}->{-xorigin} += $oset;
            $plot->{-explanation}->{-yorigin} += $oset;
            
            push(@{$template->{-plots}}, $plot);
            $template->UpdateCanvas($canv); };
   
   my $_cutplot =
      sub { &Message($tw,'-selplot'),
                  return unless(ref($::DIALOG{-SELECTEDPLOT}));
            my @plots = ();
            foreach (@{$template->{-plots}}) {
              push(@plots, $_) unless($_ eq $::DIALOG{-SELECTEDPLOT});
            }
            $template->{-plots} = [ @plots ];
            $template->UpdateCanvas($canv);
            $::DIALOG{-CLIPBOARDPLOT} = $::DIALOG{-SELECTEDPLOT}; };
             
   my $_lowerplot =
      sub { &Message($tw,'-selplot'),
                  return unless(ref($::DIALOG{-SELECTEDPLOT}));
            my @plots = ();
            foreach (@{$template->{-plots}}) {
               push(@plots, $_) unless($_ eq $::DIALOG{-SELECTEDPLOT});
            }
            unshift(@plots, $::DIALOG{-SELECTEDPLOT});
            $template->{-plots} = [ @plots ];
            $template->UpdateCanvas($canv);
            $::DIALOG{-SELECTEDPLOT} = ""; };

   my $_raiseplot =
      sub { &Message($tw,'-selplot'),
                  return unless(ref($::DIALOG{-SELECTEDPLOT}));
            my @plots = ();
            foreach (@{$template->{-plots}}) {
               push(@plots, $_) unless($_ eq $::DIALOG{-SELECTEDPLOT});
            }
            push(@plots, $::DIALOG{-SELECTEDPLOT});
            $template->{-plots} = [ @plots ];
            $template->UpdateCanvas($canv);
            $::DIALOG{-SELECTEDPLOT} = ""; };

   my $_cycleplots = sub { $template->SelectPlotScale($canv); };
   my $_ploteditor = sub { &Message($tw,'-selplot'),
                                 return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                           $::DIALOG{-SELECTEDPLOT}->PlotEditor(
                                                          $canv, $template);
                         };
   my $_plotexplan_show =
         sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                   $::DIALOG{-SELECTEDPLOT}->showExplanation('show');
                   $template->UpdateCanvas($canv);
             };
   my $_plotexplan_hide =
         sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                   $::DIALOG{-SELECTEDPLOT}->showExplanation('hide');
                   $template->UpdateCanvas($canv);
             };
   my $_plotautoaxis_on =
         sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                   $::DIALOG{-SELECTEDPLOT}->toggleAxisConfigurations(1);
             };
   my $_plotautoaxis_off =
         sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                   $::DIALOG{-SELECTEDPLOT}->toggleAxisConfigurations(0);
             };
   
   my $_xaxis =
          sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                $::DIALOG{-SELECTEDPLOT}->ContinuousAxisEditor(
                                          $canv,$template,'-x');
              };
   my $_yaxis =
          sub { &Message($tw,'-selplot'),
                   return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                $::DIALOG{-SELECTEDPLOT}->ContinuousAxisEditor(
                                          $canv,$template,'-y');
              };                      
   my $_y2axis =
           sub { &Message($tw,'-selplot'),
                    return unless(ref($::DIALOG{-SELECTEDPLOT}) );
                 $::DIALOG{-SELECTEDPLOT}->ContinuousAxisEditor(
                                           $canv, $template,'-y2');
               };                      

   my @editmenu = ( [ 'command'    => 'Undo 1',
                      -font        => $font,
                      -command     => sub { $template = $template->Undo(1); 
                                            $template->UpdateCanvas($canv);
                                          } ],
                                          
                    [ 'command'    => 'Undo 2',
                      -font        => $font,
                      -command     => sub { $template = $template->Undo(2); 
                                            $template->UpdateCanvas($canv);
                                          } ],
                                                 
                    "-",
                    
                    [ 'command'    => 'Update Canvas',
                      -font        => $font,
                      -command     =>
                         sub { # cache the original value of data drawing
                               my $tmp = $template->{-no_update_on_data_add};
                               # ensure that data will be drawn when 
                               # update canvas is called from this menu
                               $template->{-no_update_on_data_add} = 0;
                               $template->UpdateCanvas($canv);
                               # restore the original value
                               $template->{-no_update_on_data_add} = $tmp;
                             } ],
                    [ 'command'    => 'Step-Wise Update',
                      -font        => $font,
                      -command     =>
                         sub { # cache the original value of data drawing
                               my $tmp = $template->{-no_update_on_data_add};
                               # ensure that data will be drawn when 
                               # update canvas is called from this menu
                               $template->{-no_update_on_data_add} = 0;
                               $template->UpdateCanvas($canv, 0,'increment');
                               # restore the original value
                               $template->{-no_update_on_data_add} = $tmp;
                             } ],
                    "-",
                    
                    [ 'command'    => 'View Dumped Template',
                      -font        => $font,
                      -command     => sub { $template->Dump($::MW); } ],
                      
                    "-",
                    
                    );
                       
  $tw->bind("<Control-Key-h>", $_cycleplots);
  $tw->bind("<Control-Key-j>", $_xaxis);
  $tw->bind("<Control-Key-k>", $_yaxis);
  $tw->bind("<Control-Key-c>", $_copyplot);
  $tw->bind("<Control-Key-v>", $_pasteplot);
  $tw->bind("<Control-Key-x>", $_cutplot);
  $tw->bind("<Control-Key-r>", $_raiseplot);
  $tw->bind("<Control-Key-l>", $_lowerplot);

  $tw->bind("<Control-Key-H>", $_cycleplots);
  $tw->bind("<Control-Key-J>", $_xaxis);
  $tw->bind("<Control-Key-K>", $_yaxis);
  $tw->bind("<Control-Key-C>", $_copyplot);
  $tw->bind("<Control-Key-V>", $_pasteplot);
  $tw->bind("<Control-Key-X>", $_cutplot);
  $tw->bind("<Control-Key-R>", $_raiseplot);
  $tw->bind("<Control-Key-L>", $_lowerplot);


   my @datamenu = (
     [ 'command' => 'Add Data File to Selected Plot',
       -font     => $font,
       -command  => sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));                          
                          my $plot;
                          foreach (@{$template->{-plots}}) {
                             next unless($_ eq $::DIALOG{-SELECTEDPLOT});
                             $plot = $_;
                          }
                          # one last test which traps problem on a selected
                          # plot on a template different than that being
                          # operated on here.  Drawback with a global tracking
                          # of the selected plot.  WHA 08/07/2002
                          &Message($tw,'-selplot'), return unless(ref($plot));
                          $plot->{-dataclass}->AddDataToPlot(
                                                      $canv, $plot, $template);
                          return;
                        } ],
     [ 'checkbutton' => 'Do not update canvas when data added',
       -font         => $font,
       -onvalue      => 1,
       -offvalue     => 0,
       -variable     => \$template->{-no_update_on_data_add} ],
                    "-",
     [ 'command' => 'Edit Data or Do Statistics',
       -font     => $font,
       -command  =>  sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));
                          my $plot = $::DIALOG{-SELECTEDPLOT};
                          my $data = $::DIALOG{-SELECTEDPLOT}->{-dataclass};
                          $data->DataClassEditor($canv, $plot,  $template); } ],
     [ 'command'    => 'View Internal Data (unavail)',
       -font        => $font,
       -command     => [ \&ViewInternalData, $template, $tw ] ],
                    "-",
     
     [ 'command' => 'Edit Y1 Reference Lines',
       -font     => $font,
       -command  => sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));
                          my $plot = $::DIALOG{-SELECTEDPLOT};
                          $plot->{-RefLines}->ReferenceLineEditor(
                                              $plot, $canv, $template, '-y');
                         } ],
     [ 'command' => 'Edit Y2 Reference Lines',
       -font     => $font,
       -command  => sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));
                          my $plot = $::DIALOG{-SELECTEDPLOT};
                          $plot->{-RefLines}->ReferenceLineEditor(
                                              $plot, $canv, $template, '-y2');
                         } ],
                    "-",
     [ 'command' => 'Edit Y1 Quantile-Quantile Lines',
       -font     => $font,
       -command  => sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));
                          my $plot = $::DIALOG{-SELECTEDPLOT};
                          $plot->{-QQLines}->QQLineEditor(
                                            $plot, $canv, $template, '-y');
                         } ],
     [ 'command' => 'Edit Y2 Quantile-Quantile Lines',
       -font     => $font,
       -command  => sub { &Message($tw,'-selplot'),
                                return unless(ref($::DIALOG{-SELECTEDPLOT}));
                          my $plot = $::DIALOG{-SELECTEDPLOT};
                          $plot->{-QQLines}->QQLineEditor(
                                          $plot, $canv, $template, '-y2');
                         } ],
     "-",
     [ 'command' => 'Show explanations for all plots',
       -font     => $font,
       -command  => sub { 
            map { $_->showExplanation('show') } (@{$template->{-plots}});
            $template->UpdateCanvas($canv);
                        } ],
     [ 'command' => 'Hide explanations for all plots',
       -font     => $font,
       -command  => sub { 
            map { $_->showExplanation('hide') } (@{$template->{-plots}});
            $template->UpdateCanvas($canv);
                        } ],
     [ 'command' => 'Auto axis config. ON for all plots',
       -font     => $font,
       -command  => sub { 
            map { $_->toggleAxisConfigurations(1) } (@{$template->{-plots}});
                } ],
     [ 'command' => 'Auto axis config. OFF for all plots',
       -font     => $font,
       -command  => sub { 
            map { $_->toggleAxisConfigurations(0) } (@{$template->{-plots}});
                } ],
     ); 
                      
   my @plotmenu = ( [ 'command' => 'Add Plot by Dragging',
                     -font     => $font,
                     -command  => sub { $template->AddPlot($canv,'drag'); } ],
                   [ 'command' => 'Add Plot by Editor',
                     -font     => $font,
                     -command  => sub { $template->AddPlot($canv,'editor'); } ],
                   "-",
                   [ 'command'     => 'Select Plot',
                      -font        => $font,
                      -accelerator => "Ctrl-H",
                      -command     => $_cycleplots ],
                    
                    [ 'command'    => 'Plot Editor',
                      -font        => $font,
                      -command     => $_ploteditor ],
                      
                    [ 'command'    => 'X-Axis Editor',
                      -font        => $font,
                      -accelerator => "Ctrl-J",
                      -command     => $_xaxis ],
                      
                    [ 'command'    => 'Y-Axis Editor',
                      -font        => $font,
                      -accelerator => "Ctrl-K",
                      -command     => $_yaxis ],
                    [ 'command'    => 'Y2-Axis Editor',
                      -font        => $font,
                      -command     => $_y2axis ],
                    "-",
                    [ 'command'    => 'Copy Plot', 
                    
                      -font        => $font,
                      -accelerator => "Cntl-C",
                      -command     => $_copyplot  ],
                      
                    [ 'command'    => 'Cut Plot',
                      -font        => $font,
                      -accelerator => "Cntl-X",
                      -command     => $_cutplot   ],
                      
                    [ 'command'    => 'Paste Plot',
                      -font        => $font,
                      -accelerator => "Cntl-V",
                      -command     => $_pasteplot ],
                      
                    [ 'command'    => 'Delete Plot',
                       -font        => $font,
                       -command =>
                       sub { &Message($tw,'-selplot'),
                                   return unless(ref($::DIALOG{-SELECTEDPLOT}));
                             my @plots = ();
                             foreach (@{$template->{-plots}}) {
                                push(@plots, $_)
                                   unless($_ eq $::DIALOG{-SELECTEDPLOT});
                             }
                             $template->{-plots} = [ @plots ];
                             $template->UpdateCanvas($canv);
                             $::DIALOG{-SELECTEDPLOT} = "";
                           } ],   
                    "-",
                    
                    [ 'command'    => 'Raise Plot',
                      -font        => $font,
                      -accelerator => "Ctrl-R",
                      -command     => $_raiseplot ],
                      
                    [ 'command'    => 'Lower Plot',
                      -font        => $font,
                      -accelerator => "Ctrl-L",
                      -command     => $_lowerplot ],
                    "-",
                    [ 'command'    => 'Show explanation',
                      -font        => $font,
                      -command     => $_plotexplan_show ],
                    [ 'command'    => 'Hide explanation',
                      -font        => $font,
                      -command     => $_plotexplan_hide ],
                    [ 'command'    => 'Auto axis configuration ON',
                      -font        => $font,
                      -command     => $_plotautoaxis_on ],
                    [ 'command'    => 'Auto axis configuration OFF',
                      -font        => $font,
                      -command     => $_plotautoaxis_off ],
                 ); 
   
   my @annomenu = (    [ 'command' => 'Text',
                         -font     => $font,
                         -command  =>
                          sub { $template->AddAnno($canv, 'text')   } ],
                       [ 'command' => 'Symbol',
                         -font     => $font,
                         -command  =>
                          sub { $template->AddAnno($canv, 'symbol') } ],
                       [ 'command' => 'Line',
                         -font     => $font,
                         -command  =>
                          sub { $template->AddAnno($canv, 'line')   } ],
                       
                       '-',
                       [ 'command' => 'Select Text',
                         -font     => $font,
                         -command  =>
                          sub { $template->SelectAnno($canv, '-annotext')   } ],
                       [ 'command' => 'Select Symbol',
                         -font     => $font,
                         -command  =>
                          sub { $template->SelectAnno($canv, '-annosymbol') } ],
                       [ 'command' => 'Select Line',
                         -font     => $font,
                         -command  =>
                          sub { $template->SelectAnno($canv, '-annoline')   } ],
                       
                       '-',
                       [ 'checkbutton'  => ' draw Anno first',
                         -font          => $font,
                         -onvalue       => 1,
                         -offvalue      => 0,
                         -variable      =>
                                 \$template->{-draw_annotation_first},
                         -command       =>
                          sub { $template->UpdateCanvas($canv); }  ],
                       '-',
                       
                       [ 'radiobutton' => '   draw Text first',
                          -font        => $font,
                          -variable    => \$template->{-annotext_plot_order},
                          -value       => 1,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '            second',
                          -font        => $font,
                          -variable    => \$template->{-annotext_plot_order},
                          -value       => 2,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '             third',
                          -font        => $font,
                          -variable    => \$template->{-annotext_plot_order},
                          -value       => 3,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       
                       [ 'radiobutton' => ' draw Symbol first',
                          -font        => $font,
                          -variable    => \$template->{-annosymbol_plot_order},
                          -value       => 1,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '            second',
                          -font        => $font,
                          -variable    => \$template->{-annosymbol_plot_order},
                          -value       => 2,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '             third',
                          -font        => $font,
                          -variable    => \$template->{-annosymbol_plot_order},
                          -value       => 3,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       
                       [ 'radiobutton' => '   draw Line first',
                          -font        => $font,
                          -variable    => \$template->{-annoline_plot_order},
                          -value       => 1,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '            second',
                          -font        => $font,
                          -variable    => \$template->{-annoline_plot_order},
                          -value       => 2,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],
                       [ 'radiobutton' => '             third',
                          -font        => $font,
                          -variable    => \$template->{-annoline_plot_order},
                          -value       => 3,
                          -command     =>
                           sub { $template->UpdateCanvas($canv); } ],             
                      );
   
   my @settingsmenu = ( [ 'checkbutton' => 'Draw Data on Canvas Update',
                              -font     => $font,
                              -variable => \$::TKG2_CONFIG{-REDRAWDATA},
                              -onvalue  => 1,
                              -offvalue => 0 ], 
                        [ 'checkbutton' => 'Snap to grid',
                              -font     => $font,
                              -variable => \$template->{-snap_to_grid},
                              -onvalue  => 1,
                              -offvalue => 0 ],
                        [ 'command' => 'Flush leaderline overlap cache',
                           -font    => $font,
                           -command => sub { &delOverlapCache();
                                             $template->UpdateCanvas($canv); } ],
                        "-",
                        [ 'command'    => 'Edit some Global Variables',
                          -font        => $font,
                          -command     =>
                          [ \&EditGlobalVariables, $::MW,$template,$canv] ],
                      );
   
   my @filemenu;
   push(@filemenu, ( [ 'command'    => 'New',
                      -font        => $font,
                      -command     =>   \&CreateTemplate,
                      -accelerator => "Ctrl-N" ], )
       ) unless($::CMDLINEOPTS{'nosave'});
                      
   push(@filemenu, ( [ 'command'    => 'Open',
                      -font        => $font,
                      -command     => [ \&Open, $tw ],
                      -accelerator => "Ctrl-O" ],
                      
                    "-", ) );
                  
   push(@filemenu, ([ 'command'    => 'Save',
                      -font        => $font,
                      -command     => sub { $template->Save($canv, $tw) },
                      -accelerator => "Ctrl-S" ],
                      
                    [ 'command'    => 'Save As (filename requested)',
                      -font        => $font,
                      -command     => sub { $template->SaveAs($canv, $tw) } ],
                    
                    [ 'command'    => "Save As (with imported data)",
                      -font        => $font,
                      -command     =>
                          sub { local $::TKG2_CONFIG{-DELETE_LOADED_DATA} = 0;
                                $template->SaveAs($canv, $tw);
                              } ],
                    [ 'radiobutton' => ' HASH Format (preferred)',
                       -font        => $font,
                       -variable    => \$template->{-fileformat},
                       -value       => 'DataDumper' ],
                   
                    [ 'checkbutton' => '         Compact the Hash',
                          -font     => $font,
                          -variable => \$::TKG2_CONFIG{-DATA_DUMPER_INDENT},
                          -onvalue  => 0,
                          -offvalue => 1 ],
                    
                    [ 'command' => 'Revert to Saved',
                      -font     => $font,
                      -command  =>
                      sub { my $tkg2file = $template->{-tkg2filename};
                            $template->Exit($canv, $tw, 'exit without message');
                            &Open($::MW, $tkg2file);
                            print $::VERBOSE
                                  "Tkg2-message: You have reverted to ",
                                  "saved version of '$tkg2file'.\n";
                          } ],
                       
                    "-", )
       ) unless($::CMDLINEOPTS{'nosave'});  
                     
    push(@filemenu, ([ 'command'    => 'Export',
                      -font        => $font,
                      -command     => sub { $template->Tkg2Export($canv, $tw) } ],
                      
                    "-", )
        ) unless($::CMDLINEOPTS{'noexport'}); 
   
    push(@filemenu, ( [ 'command'    => 'Export to MetaPost',
                       -font        => $font,
                       -command     => sub { $template->Tkg2MetaPost($canv,$tw) } ],

                    "-", )
       ) unless($::CMDLINEOPTS{'noexport'});

                 
    push(@filemenu, ([ 'command'    => 'Print (postscript)',
                      -font        => $font,
                      -command     => sub { $template->Print($canv, $tw) },
                      -accelerator => "Ctrl-P" ],
                      
                    [ 'command'    => 'Print and Exit',
                      -font        => $font,
                      -command     => sub { $template->Print($canv, $tw); 
                                            &TotalExit } ],
                    "-", )
        ) unless($::CMDLINEOPTS{'noprint'});
   
   # The Exit method does not do an explicit MW destroy, plus why would
   # you want multiple exits when the Main Dialog box is not present.
   unless($::CMDLINEOPTS{'nomw'}) {                
      push(@filemenu, ( [ 'command'    => 'Close',
                          -font        => $font,
                          -command     => sub { $template->Exit($canv, $tw) },
                          -accelerator => "Ctrl-W" ] ) );
   }                  
                      
   push(@filemenu,( [ 'command'    => 'Exit Tkg2',
                      -font        => $font,
                      -command     =>  \&TotalExit,
                      -accelerator => "Ctrl-E" ] ) );
   my @screenmenu =
          ( [ 'command'   => 'Tkg2 Main Dialog',
              -font       => $font,
              -command    => [ \&ScreenShot, $tw, 'maindialog.jpg' ] ],
            [ 'command'   => 'Tkg2 Canvas (in action)',
              -font       => $font,
              -command    => [ \&ScreenShot, $tw, 'canvas.jpg' ] ],  
            [ "cascade" => "Plot Editor",
              -font     => $font ],
            [ "cascade" => "Axis Editors",
              -font     => $font  ],
            [ "cascade" => "Data Editors",
              -font     => $font  ],
            [ "cascade" => "Draw Data Editors",
              -font     => $font  ],
            [ "cascade" => "Annotation Editors",
              -font     => $font   ],
                    "-",
            [ 'command'    => 'Exporting Files',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'export.jpg' ] ],
            [ 'command'    => 'Printing Files',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'print.jpg' ] ],
         );
         
   my $plotsubmenu = [
            [ 'command'    => 'Plot Editor (Plot)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'ploteditor_plot.jpg' ] ],
            [ 'command'    => 'Plot Editor (Plot Title)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'ploteditor_title.jpg' ] ],
            [ 'command'    => 'Plot Editor (Explanation)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'ploteditor_explan.jpg' ] ],
            [ 'command'    => 'Plot Editor (Explanation-Show/Hide Entries)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw,
                                'ploteditor_explan_showhide.jpg' ] ]
                     ];
                                
   my $axissubmenu = [
            "Continuous Axis Editing",
            [ 'command'    => 'Linear Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_linear.jpg' ] ],
            [ 'command'    => 'Log Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_log.jpg' ] ],
            [ 'command'    => 'Probability Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_prob.jpg' ] ],
            [ 'command'    => 'Gumbel Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_gumbel.jpg' ] ],
            [ 'command'    => 'Time Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_time.jpg' ] ],
            [ 'command'    => 'Continuous Axis Editor (Title, Labels, and Ticks)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_tlt.jpg' ] ],
            [ 'command'    => 'Continuous Axis Editor (Grid and Origin)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_gridorigin.jpg' ] ],
            "Discrete Axis Editing",
            [ 'command'    => 'Discrete Axis Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_discrete.jpg' ] ],
            [ 'command'    => 'Discrete Axis Editor (Title and Labels)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_discrete_titlelabel.jpg' ] ],
            [ 'command'    => 'Discrete Axis Editor (Ticks and Grid)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'axiseditor_discrete_tickgrid.jpg' ] ],          
                     ];
                        
   my $datasubmenu = [
            [ 'command'    => 'Add Data File to Plot (Basic)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'adddatatoplot_basic.jpg' ] ],
            [ 'command'    => 'Add Data File to Plot (Advanced)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'adddatatoplot_advanced.jpg' ] ],
            [ 'command'    => 'Add Data File to Plot (Date-Time)',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'adddatatoplot_datetime.jpg' ] ],
            [ 'command'    => 'Data Class (File) Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'dataeditor_class.jpg' ] ],
            [ 'command'    => 'Data Set Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'dataeditor_set.jpg' ] ],
                     ];
                     
   my $drawsubmenu = [
            [ 'command'    => 'Points tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_points.jpg' ] ],
            [ 'command'    => 'Lines tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_lines.jpg' ] ],
            [ 'command'    => 'Text tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_text.jpg' ] ],
            [ 'command'    => 'Shading tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_shading.jpg' ] ],
            [ 'command'    => 'Bars tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_bars.jpg' ] ],
            [ 'command'    => 'Error Lines tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_errorlines.jpg' ] ],
            "-",
            [ 'command'    => 'Box Plot Location tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_location.jpg' ] ],
            [ 'command'    => "Box Plot 'ciles tab",
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_ciles.jpg' ] ],
            [ 'command'    => 'Box Plot Tails tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_tails.jpg' ] ],
            [ 'command'    => 'Box Plot Outliers tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_outliers.jpg' ] ],
            [ 'command'    => "Box Plot Sample Size tab",
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_sample.jpg' ] ],
            [ 'command'    => 'Box Plot Detection Limits tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_limits.jpg' ] ],
            [ 'command'    => 'Box Plot Show Data tab',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_data.jpg' ] ],
            [ 'command'    => "Box Plot Statistics Tab",
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'drawdataeditor_boxplot_stats.jpg' ] ],
                    ];
                    
   my $annosubmenu = [
            [ 'command'    => 'Text Annotation Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'textannoeditor.jpg' ] ],
            [ 'command'    => 'Line Annotation Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'lineannoeditor.jpg' ] ],
            [ 'command'    => 'Symbol Annotation Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'symbolannoeditor.jpg' ] ],
                    "-",
            [ 'command'    => 'Reference Line Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'reflineeditor.jpg' ] ],
            [ 'command'    => 'Quantile-Quantile Line Editor',
              -font        => $font,
              -command     => [ \&ScreenShot, $tw, 'qqlineeditor.jpg' ] ],
                     ];
   
   # not create submenu objects which are placed onto the menu after the first
   # layer of entries is added at the end of this subroutine.
   my %sc_subs;
   my $sc = \$menus[6];
   $sc_subs{'Plot Editor'}        = $$sc->menu->Menu(-menuitems => $plotsubmenu);
   $sc_subs{'Axis Editors'}       = $$sc->menu->Menu(-menuitems => $axissubmenu);
   $sc_subs{'Data Editors'}       = $$sc->menu->Menu(-menuitems => $datasubmenu);
   $sc_subs{'Draw Data Editors'}  = $$sc->menu->Menu(-menuitems => $drawsubmenu);
   $sc_subs{'Annotation Editors'} = $$sc->menu->Menu(-menuitems => $annosubmenu);
                                  
   my @helpmenu = ( [ 'command'    => 'Help Index (unavail)',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'HelpIndex.pod' ] ],
                    [ 'command'    => 'FAQs',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'faqs.pod' ] ],
                    "-",
                    [ 'command'    => 'Command Line',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'CmdLine.pod'] ],
                    [ 'command'    => '  Spool CmdLine Help',
                      -font        => $font,
                      -command     => [ \&SpoolCmdLine, $tw ] ],
                      
                    [ 'command'    => 'Tkg2rc File',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'Tkg2rc.pod'] ],  
                    [ 'command'    => 'Instructions',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'Instructions.pod' ] ],
                    [ 'command'    => 'General Utilities',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'GeneralUtilities.pod' ] ],
                    [ 'command'    => 'NWIS Utilities',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'NWISUtilities.pod' ] ],
                    [ 'command'    => 'Add Data File to Plot',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'AddDataFile.pod' ] ],
                    "-",  
                    [ 'command'    => 'FILE', 
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'FileMenu.pod' ] ],
                    [ 'command'    => 'EDIT',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'EditMenu.pod' ] ],
                    [ 'command'    => 'PLOT',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'PlotMenu.pod' ] ],
                    [ 'command'    => 'DATA',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'DataMenu.pod' ] ],
                    [ 'command'    => '  Data Class (File) Editor',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'DataClassEditor.pod'] ],
                    [ 'command'    => '  Data Set Editor',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'DataSetEditor.pod'] ],
                    [ 'command'    => 'ANNOTATION',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'AnnoMenu.pod' ] ],
                    [ 'command'    => 'Global Settings',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'SettingsMenu.pod' ] ],
                    "-",
                    [ 'command'    => 'Plot Editor',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'PlotEditor.pod' ] ],
                    [ 'command'    => 'Continuous Axis Editor',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'ContinuousAxisEditor.pod' ] ],
                    [ 'command'    => 'Discrete Axis Editor',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'DiscreteAxisEditor.pod' ] ],
                    [ 'command'    => 'Draw Data Editor (Symbology)',
                      -font        => $font,
                      -command     => [ \&Help, $tw, 'DrawDataEditor.pod' ] ] );                  
                      
   $tw->bind("<Control-Key-n>", sub { &New  }                         );
   $tw->bind("<Control-Key-o>", sub { &Open($tw)    }                 );
   $tw->bind("<Control-Key-s>", sub { $template->Save($canv, $tw)  } );
   $tw->bind("<Control-Key-p>", sub { $template->Print($canv, $tw) } );
   $tw->bind("<Control-Key-e>", sub { \&TotalExit }                   );
   $tw->bind("<Control-Key-q>", sub { $template->Exit($canv, $tw) }   );
  
   $tw->bind("<Control-Key-N>", sub { &New  }                         );
   $tw->bind("<Control-Key-O>", sub { &Open($tw)    }                 );
   $tw->bind("<Control-Key-S>", sub { $template->Save($canv, $tw)   } );
   $tw->bind("<Control-Key-P>", sub { $template->Print($canv, $tw)  } );
   $tw->bind("<Control-Key-E>", sub { &TotalExit  }                   );
   $tw->bind("<Control-Key-W>", sub { $template->Exit($canv, $tw) }   );   
   
   # place the entries onto each menu
   $menus[0]->AddItems(@filemenu);
   $menus[1]->AddItems(@editmenu);
   $menus[2]->AddItems(@plotmenu);
   $menus[3]->AddItems(@datamenu);
   $menus[4]->AddItems(@annomenu);
   $menus[5]->AddItems(@settingsmenu);
   $menus[6]->AddItems(@screenmenu);
   foreach my $key (keys %sc_subs) {  # pack the submenus on
      $menus[6]->entryconfigure($key, -menu => $sc_subs{$key});
   }
   $menus[7]->AddItems(@helpmenu);
   
}

sub ViewInternalData {
   my ($template, $tw) = (shift, shift);
   return;
}

1;
