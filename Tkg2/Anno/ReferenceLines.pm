package Tkg2::Anno::ReferenceLines;

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
# $Date: 2007/09/10 02:19:40 $
# $Revision: 1.25 $

use strict;
use Tk;
use Exporter;
use SelfLoader;
use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

$EDITOR = "";

# Recall that the reallygenerateLines subroutine performs the
# ray tracing calculations to derive the coordinates necessary to
# plot the line within a rectangular plot.
use Tkg2::Draw::DrawLineStuff qw(reallygenerateLines);
use Tkg2::Base qw(Message isNumber Show_Me_Internals getDashList);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAnnoLineMetaPost);

print $::SPLASH "=";

sub new { return bless { -y  => [], -y2 => [] }, shift(); }

sub draw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   &_reallydraw(@_, '-y');
   &_reallydraw(@_, '-y2');
}

sub _reallydraw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($self, $canv, $plot, $yax) = @_;
   
   # just quietly return if the second y axis has not been activiated
   return if($yax eq '-y2' and not $plot->{-y2}->{-turned_on});
   
   foreach my $index (0..(@{$self->{$yax}}-1)) {
      my ($x1, $y1, $x2, $y2, $color, $width, $dashstyle, $doit, $username) =
                                     $self->grabone($yax,$index);
      next unless($doit);
      
      # deal with dashes
      my @dash  = ();
      push(@dash, (-dash => $dashstyle) )
              if($dashstyle and $dashstyle !~ /Solid/io);

      
      my $coords       = [ [ $x1, $y1 ], [ $x2, $y2 ] ];
      my $parsed_lines = &reallygenerateLines($plot, [ $coords ], 0, $yax);
      # there should ONLY be one array because no missing values
      my @lines        = @{ $parsed_lines->[0] };
      if(@lines == 4) {
        $canv->createLine(@lines,
                          -fill  => $color,
                          -width => $width,
                          @dash,
                          -tags  => [ "$plot" ]);
        createAnnoLineMetaPost(@lines,{-fill    => $color,
                                       -width   => $width,
                                       -linecap => "butt", @dash});
      }
      # the lines == 4 is protection on the createLine call
      # quietly do nothing if there not 4 viable coordinates   
   }
}

sub add {
   my ($self, $yax, $x1, $y1, $x2, $y2, $color, $width) = @_;
   my $href = { -x1        => $x1,
                -y1        => $y1,
                -x2        => $x2,
                -y2        => $y2,
                -linecolor => $color,
                -linewidth => $width,
                -dashstyle => "Solid",
                -username  => "",
                -doit      => 1 };
   return push( @{ $self->{$yax} }, $href );
}

sub dropone {
   my ($self, $yax, $index) = @_;
   return undef if($index > $#{$self->{$yax}} or $index < 0);
   my $arrayref = $self->{$yax};
   splice(@$arrayref, $index, 1);
   $self->{$yax} = $arrayref;
}

sub grabone {
   my ($self, $yax, $index) = @_;
   return undef if($index > $#{$self->{$yax}} or $index < 0);
   my $refline = $self->{$yax}->[$index];
   return ( $refline->{-x1},
            $refline->{-y1},
            $refline->{-x2},
            $refline->{-y2},
            $refline->{-linecolor},
            $refline->{-linewidth},
            $refline->{-dashstyle},
            $refline->{-doit},
            $refline->{-username} );
}
   
sub changeone {
   my ($self, $yax, $index,
       $x1, $y1, $x2, $y2,
       $color, $width, $dashstyle,
       $doit, $username, $which_y_axis) = @_;
   return undef if($index > $#{$self->{$yax}} or $index < 0);
   $self->{$yax}->[$index] = { -x1        => $x1,
                               -y1        => $y1,
                               -x2        => $x2,
                               -y2        => $y2,
                               -linecolor => $color,
                               -linewidth => $width,
                               -dashstyle => $dashstyle,
                               -doit      => $doit,
                               -username  => $username };
}

1;

__DATA__


sub ReferenceLineEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $plot, $canv, $template, $yax) = @_; 
   my $pw = $canv->parent;

   if($yax eq '-y2' and not $plot->{-y2}->{-turned_on}) {
      my $mess = "Warning: You are trying to edit reference ".
                 "lines for the second y axis, but that axis ".
                 "has not been activated by adding data to ".
                 "it.  Returning home.";
      &Message($pw, '-generic', $mess);
      return;
   }

   my $whichy = ($yax eq '-y2') ? 'Second' : 'First';
   my $text = "Tkg2 Reference Line Editor for $whichy Axis";   
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => $text);
   $EDITOR = $pe;
   $pe->resizable(0,0);
   

   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
 
   my ($mb_color, $mb_width, $mb_dash, $lb);
        
   my $pickedcolor   = (@{$self->{$yax}}) ?
                          $self->{$yax}->[0]->{-linecolor} : 'black';
   my $pickedcolorbg = $pickedcolor;
   
   my $_configColor  =
   sub {
      $pickedcolor   = 'none'  if(not defined $pickedcolor   );
      $pickedcolorbg = 'white' if(not defined $pickedcolorbg );
      $pickedcolorbg = 'white' if( $pickedcolor eq 'black'   );
   };
   
   &$_configColor;  # run the color configuration
   
   my $_color = sub { $pickedcolor = shift;
                      my $color    = $pickedcolor;
                      my $mbcolor  = $pickedcolor;
                      $color       =  undef  if(   $color   eq 'none' );
                      $mbcolor     = 'white' if(   $mbcolor eq 'none'
                                                or $mbcolor eq 'black');
                      $mb_color->configure(-background       => $mbcolor,
                                           -activebackground => $mbcolor);
                    };

   my @colors = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@colors, [ 'command' => $_,
                      -command  => [ \&$_color, $_ ],
                      -font     => $fontb ] );
   } 
   
   my $width = ( @{$self->{$yax}} ) ?
                   $self->{$yax}->[0]->{-linewidth} : '0.015i';
   my $_width = sub { $width = shift };
   my @width = ();
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
       push(@width, [ 'command' => $_,
                      -command  => [ $_width, $_ ],
                      -font     => $fontb ] );          
   }
   
   
   #my $dashstyle = ( @{$self->{$yax}} ) ?
   #                    $self->{$yax}->[0]->{-dashstyle} : 'Solid';
   my $dashstyle = 'Solid';
   # the above is for backwards compatability
   my @dashstyle = &getDashList(\$dashstyle,$font);

   
   my $doit     = 1;
   my $username = "";
   my $finishsub;

   my $inst = "Configure reference lines for plot by setting\n".
              "the coordinates of the line in real-world units\n".
              "(Ref. lines are not implemented for time axis.)";
   $pe->Label(-text    => "$inst",
              -font    => $fontb,
              -justify => 'left')->pack(-fill =>'x');


   my $f_1  =  $pe->Frame->pack(-side => 'top',  -fill => 'x');
   my $f_11 = $f_1->Frame->pack(-side => 'left', -fill => 'x');
   my $f_12 = $f_1->Frame->pack(-side => 'left', -fill => 'x');
    
    
    
   my (@XY1, @XY2);   
   my $f_beg = $f_11->Frame->pack(-side => 'top', -fill => 'x');        
      $f_beg->Label(-text => "X1 and X2",
                    -font => $fontb)
            ->pack(-side => 'left', -anchor => 'w');
   $XY1[0] = "";  # X1
   $f_beg->Entry(-textvariable => \$XY1[0],
                 -background   => 'white',
                 -width        => 10,
                 -font         => $fontb  )
         ->pack(-side => 'left');
   $XY2[0] = ""; # X2
   $f_beg->Entry(-textvariable => \$XY2[0],
                 -background   => 'white',
                 -width        => 10,
                 -font         => $font  )
         ->pack(-side => 'left');       
            
            
   my $f_end = $f_11->Frame->pack(-side => 'top', -fill => 'x');                
      $f_end->Label(-text => "Y1 and Y2",
                    -font => $fontb)
            ->pack(-side => 'left', -anchor => 'w'); 
   $XY1[1] = ""; # Y1
   $f_end->Entry(-textvariable => \$XY1[1],
                 -background   => 'white',
                 -width        => 10,
                 -font         => $font )
         ->pack(-side => 'left');
   $XY2[1] = ""; # Y2
   $f_end->Entry(-textvariable => \$XY2[1],
                 -background   => 'white',
                 -width        => 10,
                 -font         => $font )
         ->pack(-side => 'left');         
     
     
     
   my $f_112  = $f_11->Frame->pack(-fill => 'x');
   my $f_112a = $f_11->Frame->pack(-fill => 'x');
   my $f_112b = $f_11->Frame->pack(-fill => 'x');
   my $f_112c = $f_11->Frame->pack(-fill => 'x');   
   my $f_112d = $f_11->Frame->pack(-fill => 'x');
   $f_112a->Label(-text => '  Color     ',
                  -font => $fontb)
          ->pack(-side => 'left');   
   $mb_color = $f_112a->Menubutton(
                      -textvariable => \$pickedcolor,
                      -indicator    => 1,
                      -relief       => 'ridge',
                      -menuitems    => [ @colors ],
                      -tearoff      => 0,
                      -width        => 14,
                      -font         => $font,
                      -background   => $pickedcolorbg,
                      -activebackground => $pickedcolorbg)
                      ->pack(-side => 'left');
   $f_112b->Label(-text => '  Width     ',
                  -font => $fontb)
          ->pack(-side => 'left');
   $mb_width = $f_112b->Menubutton(
                      -textvariable => \$width,
                      -indicator    => 1,
                      -font         => $fontb,
                      -relief       => 'ridge',
                      -menuitems    => [ @width ],
                      -tearoff      => 0,
                      -width        => 14)
                      ->pack(-side => 'left');                 

   $f_112c->Label(-text => '  Dash Style',
                  -font => $fontb)
          ->pack(-side => 'left');
   $mb_dash = $f_112c->Menubutton(
                      -textvariable => \$dashstyle,
                      -indicator    => 1,
                      -font         => $fontb,
                      -relief       => 'ridge',
                      -menuitems    => [ @dashstyle],
                      -tearoff      => 0,
                      -width        => 14)
                      ->pack(-side => 'left'); 
                      
   $f_112d->Label(-text => 'Username',
                  -font => $fontb)
          ->pack(-side => 'left');
   $f_112d->Entry(-textvariable => \$username,
                  -background   => 'white',
                  -width        => 20,
                  -font         => $font )
          ->pack(-side => 'left');         
   
                      
   my $grabindex = undef;
   $f_12->Checkbutton(-text      => 'Do this one',
                      -variable  => \$doit,
                      -indicator => 1,
                      -font      => $fontb )
        ->pack();       
   $f_12->Button(
        -text    => 'Add Entry',
        -font    => $fontb,
        -command => sub { foreach (@XY1, @XY2) {
                             unless( &isNumber($_) ) {
                                $_ = "";
                                &Message($pe,'-notnumber');
                                return; 
                             }; 
                          }
                          $lb->insert('end',"$XY1[0] and $XY1[1]:".
                                            "$XY2[0] and $XY2[1]:".
                                            "$pickedcolor:$width:".
                                            "$dashstyle:".
                                            "$doit:$username");
                          $self->add($yax,@XY1,@XY2,
                                     $pickedcolor, $width, $dashstyle,
                                     $doit, $username);
                          foreach (@XY1, @XY2) { $_ = ""; }
                          $grabindex = undef;
                        } )
        ->pack(-fill => 'x');
   
   $f_12->Button(
        -text    => 'Grab Entry',
        -font    => $fontb,
        -command => sub { $grabindex = $lb->index($lb->curselection);
                          unless(defined $grabindex ) {
                             &Message($pe,'-selfromlist');
                             return;
                          }
                          ( $XY1[0], $XY1[1],
                            $XY2[0], $XY2[1],
                            $pickedcolor, $width,
                            $dashstyle, $doit, $username ) =
                               $self->grabone($yax,$grabindex);
                           &$_configColor;
                        } )
        ->pack(-fill => 'x');
   
   # The update has been made a separate subroutine so that the 
   # Apply button at the bottom of the dialog box can access it as 
   # well.  This avoids some mouse motion and a mouse click.
   my $_updateEntry =
      sub {  return unless(defined $grabindex);
             foreach (@XY1, @XY2) {
                $_ = "", return unless( &isNumber($_) ); 
             }
             $lb->insert($grabindex,"$XY1[0] and $XY1[1]:".
                                    "$XY2[0] and $XY2[1]:".
                                    "$pickedcolor:$width:".
                                    "$dashstyle:".
                                    "$doit:$username");
             $lb->delete($grabindex+1);
             $self->changeone($yax,$grabindex,
                              @XY1,@XY2,$pickedcolor,
                              $width,$dashstyle,
                               $doit,$username);
             foreach (@XY1, @XY2) { $_ = ""; }
             $grabindex = undef;
          };
   $f_12->Button(
        -text    => 'Update Entry',
        -font    => $fontb,
        -command => sub { &$_updateEntry() } )
        ->pack(-fill => 'x');        
        
   $f_12->Button(
        -text    => 'Delete Entry',
        -font    => $fontb,
        -command => sub { my $index = $lb->index($lb->curselection);
                          &Message($pe,'-selfromlist'),
                          return unless(defined $index);
                          $self->dropone($yax,$index);
                          $lb->delete($index);
                          $grabindex = undef;
                        } )
        ->pack(-fill => 'x');
        
   
   my $f_2 = $pe->Frame->pack(-side => 'top', -fill => 'x');
   $lb = $f_2->Scrolled("Listbox",
                        -scrollbars => 'e',
                        -selectmode => 'single',
                        -font       => $fontb,
                        -background => 'linen',
                        -width      => 30)
             ->pack(-side => 'top', -fill => 'x');    

   # show me all the reference lines for the particular axis
   foreach my $refline ( @{$self->{$yax}} ) {
      my @xy1       = ( $refline->{-x1}, $refline->{-y1} );
      my @xy2       = ( $refline->{-x2}, $refline->{-y2} );
      my $color     = $refline->{-linecolor};
      my $width     = $refline->{-linewidth};
      my $dashstyle = $refline->{-dashstyle};
      # backwards compatability trap for the dash style
      $dashstyle = $refline->{-dashstyle}  = 'Solid' if(not defined $dashstyle);
      my $doit      = $refline->{-doit};
      my $username  = $refline->{-username};
      $lb->insert('end',"$xy1[0] and $xy1[1]:".
                        "$xy2[0] and $xy2[1]:".
                        "$color:$width:$dashstyle:$doit:$username");
   }
   
   my @p = qw(-side left -padx 2 -pady 2);
   my $f_3  =  $pe->Frame->pack(-side => 'bottom', -fill => 'x');             
   my $f_b  = $f_3->Frame(-relief      => 'groove',
                          -borderwidth => 2)
                  ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   $f_b->Button(-text        => 'Apply',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { &$_updateEntry();
                                  $template->UpdateCanvas($canv);
                                } )
       ->pack(@p);
   $f_b->Button(-text        => 'OK',
                -font        => $fontb,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { $pe->destroy;
                                  $template->UpdateCanvas($canv);
                                } )
       ->pack(@p);                  

   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; } )
       ->pack(@p);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(@p); 
}

1;
