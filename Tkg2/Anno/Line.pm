package Tkg2::Anno::Line;

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
# $Date: 2007/09/10 02:25:10 $
# $Revision: 1.25 $

use strict;
use Tk;
use Exporter;
use SelfLoader;
use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

use Tkg2::Base qw(Show_Me_Internals getDashList adjustCursorBindings);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAnnoLineMetaPost);

$EDITOR = "";

print $::SPLASH "=";

sub new {
   my ($pkg, $x, $y) = ( shift, shift, shift);
   my $self = { -x1        => $x,
                -y1        => $y,
                -x2        => undef,
                -y2        => undef,
                -username  => "",
                -doit      => 1,
                -linewidth => '0.015i',
                -dashstyle => undef,
                -linecolor => 'black',
                -capstyle  => 'round',
                -arrow1    => 10,
                -arrow2    => 17,
                -arrow3    => 8,
                -arrow     => 'none'
              };
   return bless $self, $pkg;
}

sub draw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $canv, $template) = @_;
   return unless($self->{-doit}); 
   my ($x1, $y1) = ( $self->{-x1}, $self->{-y1} );
   my ($x2, $y2) = ( $self->{-x2}, $self->{-y2} );
   my @shape = ( $self->{-arrow1}, $self->{-arrow2}, $self->{-arrow3} );
   
   # deal with dashes
   my @dash  = ();
   my $dashstyle = $self->{-dashstyle};
   push(@dash, (-dash => $dashstyle) )
              if($dashstyle and $dashstyle !~ /Solid/io);
   
   $canv->createLine($x1, $y1, $x2, $y2,
                     -width      => $self->{-linewidth},
                     -fill       => $self->{-linecolor},
                     -arrow      => $self->{-arrow},
                     -arrowshape => [ @shape ],
                     -capstyle   => $self->{-capstyle},
                     @dash,
                     -tags       => ["$self", $self."annoline"]);
   createAnnoLineMetaPost($x1,$y1, $x2, $y2,
                     {-width     => $self->{-linewidth},
                     -fill       => $self->{-linecolor},
                     -arrow      => $self->{-arrow},
                     -arrowshape => [ @shape ],
                     -linecap    => $self->{-capstyle},
                     @dash});
                  
   # do not form the bindings if started in display only mode                   
   return if($::CMDLINEOPTS{'nobind'});
   
   &adjustCursorBindings($canv,"$self");
   
   $canv->bind("$self", "<Button-1>", [ \&_selectanno, $self, $template ] );
   $canv->bind("$self", "<Double-Button-3>",
               sub { my @coord = ( $self->{-x1}, $self->{-y1},
                                   $self->{-x2}, $self->{-y2} );
                     $self->createNodes($canv, $template, [@coord], 4, 0, "nodeone");
                     @coord = @coord[2,3,0,1];
                     $self->createNodes($canv, $template, [@coord], 4, 0, "nodetwo"); 
                     $canv->raise("$self", "nodeone");
                     $canv->raise("$self", "nodetwo");                    
                     $self->AnnoEditor($canv, $template); } );               
}

1;

__DATA__

sub CanvHeightWidth_have_changed {
   my ($self, $newcanvwidth, $newcanvheight,
              $oldcanvwidth, $oldcanvheight) = @_;

   my $origin      = $self->{-x1};
   my $percentage  = $origin / $oldcanvwidth;
   my $newval      = $percentage*$newcanvwidth;
   $self->{-x1}    = $newval;

      $origin      = $self->{-x2};
      $percentage  = $origin / $oldcanvwidth;
      $newval      = $percentage*$newcanvwidth;
   $self->{-x2}    = $newval;
   
      $origin      = $self->{-y1};
      $percentage  = $origin / $oldcanvheight;
      $newval      = $percentage*$newcanvheight;
   $self->{-y1}    = $newval;

      $origin      = $self->{-y2};
      $percentage  = $origin / $oldcanvheight;
      $newval      = $percentage*$newcanvheight;
   $self->{-y2}    = $newval;      
}

sub highlightAnno {
   my ($self, $canv) = (shift, shift);
   my @coords = $canv->bbox("$self");
   return unless(@coords == 4);
   $canv->delete('selectedanno');
   $canv->createRectangle(@coords, -outline => 'red', -tag => 'selectedanno');   
}



sub add {
   my ($self, $template) = ( shift, shift);
   my @anno = @{$template->{-annoline}};
   # first test whether the annotation already is loaded into template
   foreach (@anno) { return if($_ eq $self); }
   push(@{$template->{-annoline}}, $self);
}

sub delete {
   my ($self, $template) = ( shift, shift);
   my @anno = ();
   foreach (@{$template->{-annoline}}) { push(@anno, $_) unless($_ eq $self); }
   $template->{-annoline} = [ @anno ];
}



sub _selectanno {
   my ($canv, $self, $template) = @_;
   if($::DIALOG{-SELECTEDANNO}) {
      $canv->delete("nodeone","nodetwo");
      $::DIALOG{-SELECTEDANNO} = "";
      return;
   }
   else {
      $::DIALOG{-SELECTEDANNO} = $self;
   }
   my @coord = ($self->{-x1}, $self->{-y1}, $self->{-x2}, $self->{-y2});
   $self->createNodes($canv, $template, [@coord], 4, 0, "nodeone");
   @coord = @coord[2,3,0,1];
   $self->createNodes($canv, $template, [@coord], 4, 0, "nodetwo");            
}   



sub createNodes {
   my ($self, $canv, $template, $coord,    $s,   $ang,  $tag) = @_;
   my ($x, $y) = ( $coord->[0], $coord->[1]);
   my $rad = 3.14159265359 / 180;   
   my $xoff1 = $s*sin( $rad*(45+$ang)  );
   my $xoff2 = $s*sin( $rad*(135+$ang) );
   my $xoff3 = $s*sin( $rad*(225+$ang) );
   my $xoff4 = $s*sin( $rad*(315+$ang) );
   my $yoff1 = $s*cos( $rad*(45+$ang)  );
   my $yoff2 = $s*cos( $rad*(135+$ang) );
   my $yoff3 = $s*cos( $rad*(225+$ang) );
   my $yoff4 = $s*cos( $rad*(315+$ang) );
   my (@ll, @lr) = ( ($x+$xoff1,$y+$yoff1), ($x+$xoff2,$y+$yoff2) );
   my (@ur, @ul) = ( ($x+$xoff3,$y+$yoff3), ($x+$xoff4,$y+$yoff4) );
   #print "Anno::Line createNodes ll @ll, lr @lr, ur @ur, ul @ul, ur @ur\n" if($::TKG2_DEBUG);
   $canv->createPolygon( @ll, @lr, @ur, @ul, @ur,
                         -tag     => $tag,
                         -fill    => 'red',
                         -outline => 'red' );
   # The node is initially filled with red, but when the cursor
   # enters it, lets remove the filling to show the tip of the line.
   $canv->bind($tag, "<Enter>",
          sub { $canv->itemconfigure($tag, -fill    => undef,
                                           -outline => 'red'  );
                $canv->configure(-cursor => 'crosshair');
                $canv->update; } );
   $canv->bind($tag, "<Leave>",
          sub { $canv->itemconfigure($tag, -fill    => 'red',
                                           -outline => 'red'  );
                $canv->configure(-cursor => 'top_left_arrow');
                $canv->update; } );
   $canv->bind($tag, "<ButtonPress-1>",
          sub { my $move = $self->newmove($canv, $template, $tag);
                   $canv->bind($tag, "<ButtonPress-1>", "");
                   $move->startMove($canv, $coord); } );    
}


sub newmove {
   my ($anno, $canv, $template, $tag ) = (shift, shift, shift, shift);
   my $self = { -canvas    => $canv,
                -template  => $template,
                -anno      => $anno,
                -whichnode => $tag };
   return bless $self, ref($anno);
}


## MOVE THE LINE
sub startMove {
   my ($drag, $canv, $coord) = (shift, shift, shift);
   my $template = $drag->{-template};
   
   my ($x, $y)       = ($coord->[0], $coord->[1]);
   my ($xend, $yend) = ($coord->[2], $coord->[3]);
   
   ($x, $y)       = $template->snap_to_grid($x,$y);
   ($xend, $yend) = $template->snap_to_grid($xend,$yend);
   
   &{$template->{-markrulerXY}}($canv, $x, $y, 'drag1','blue');
   $canv->Tk::bind("<Motion>",   [\&_move, $drag,  Ev('x'), Ev('y'),
                                           $xend, $yend ] );
   $canv->Tk::bind("<ButtonRelease-1>", [\&_endMove, $drag,  Ev('x'), Ev('y'),
                                              $xend, $yend ] );
}

sub _move {
   my ($canv, $drag, $x, $y) = ( shift, shift, shift, shift );
   my ($xend, $yend) = (shift, shift);
   my $template = $drag->{-template};
   
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   
   ($x, $y) = $template->snap_to_grid($x, $y);
   
   my $anno = $drag->{-anno};
   &{$template->{-markrulerXY}}($canv, $x, $y, 'drag1','blue');
   $canv->delete('junk'); 
   my @coord;
   if($drag->{-whichnode} eq 'nodeone') {                                      
      @coord = ( $xend, $yend, $x, $y );
   }
   elsif($drag->{-whichnode} eq 'nodetwo') {
      @coord = ( $x, $y, $xend, $yend );
   }
   else {
      print STDERR "Tkg2 _move Line anno Have no idea which ",
                   "node was being used\n";
   }
   $canv->createLine($x, $y, $xend, $yend, -tag => 'junk');                                             
   $canv->coords($anno."annoline", $x, $y, $xend, $yend );
}

sub _endMove {
   my ($canv, $drag, $x, $y) = (shift, shift, shift, shift);
   my ($xend, $yend ) = ( shift, shift);
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
  
   ($x, $y) = $template->snap_to_grid($x,$y);  
  
   &{$template->{-markrulerXY}}($canv,undef,undef,'drag1',undef);

   my $anno = $drag->{-anno};
   
   $canv->coords($anno."annoline", $xend, $yend, $x, $y );
   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);

   if($drag->{-whichnode} eq 'nodeone') {
       ( $anno->{-x1}, $anno->{-y1} ) = ( $x , $y );
       ( $anno->{-x2}, $anno->{-y2} ) = ( $xend , $yend );
   }
   elsif($drag->{-whichnode} eq 'nodetwo') {
       ( $anno->{-x2}, $anno->{-y2} ) = ( $x , $y );
       ( $anno->{-x1}, $anno->{-y1} ) = ( $xend , $yend );   

   }
   else {
      print STDERR "Tkg2 _endMove Line anno have no idea which ",
                   "node was being used\n";
   }
   
   $canv->Tk::bind("<ButtonRelease-1>", "");
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}



## ADD THE LINE BY DRAG AND EXTENSION
sub startDrag {
   my $drag = shift;
   my $template = $drag->{-template};
   my $canv = $drag->{-canvas};
   my $x = $drag->{-anno}->{-x1};
   my $y = $drag->{-anno}->{-y1};
   
   ($x, $y) = $template->snap_to_grid($x,$y);
   
   &{$template->{-markrulerXY}}($canv,$x,$y,'line','blue');
   $canv->createLine($x, $y, $x, $y,
                     -width => 1,
                     -tags  => 'annoline');
   my ($startx, $starty) = ($x, $y);
   $canv->Tk::bind("<Motion>", [\&_size, $drag,   Ev('x'), Ev('y'),
                                         $startx, $starty]);
   $canv->Tk::bind("<Button-1>", [\&_endDrag, $drag,   Ev('x'), Ev('y'),
                                              $startx, $starty]);
}

sub _size {
   my ($canv, $drag, $x, $y, $startx, $starty) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   
   ($x, $y) = $template->snap_to_grid($x,$y);
   
   &{$template->{-markrulerXY}}($canv,$x,$y,'line','blue');
   $canv->coords("annoline", $startx, $starty, $x, $y);
}

sub _endDrag {
   my ($canv, $drag,    $x,      $y, $startx, $starty) = @_;
   my $template = $drag->{-template};   
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   &{$template->{-markrulerXY}}($canv,undef,undef,'line',undef);
   my $w = $canv->cget(-width);
   my $h = $canv->cget(-height);
   $canv->coords("annoline", $startx, $starty, $x, $y);
   my $anno = $drag->{-anno};
   $anno->{-x2} = $x;
   $anno->{-y2} = $y;
   $anno->add($template);
   
   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);
   $canv->Tk::bind("<Button-1>", "");
   
   $template->UpdateCanvas($canv);
   $canv->configure(-cursor => 'top_left_arrow');
}


sub AnnoEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $canv, $template) = (shift, shift, shift); 
  
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontbig = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
  
   my $pw = $canv->parent;
   my ($mb_color, $mb_width, $mb_linedashstyle);
   
   $self->{-dashstyle} = 'Solid' if(not defined $self->{-dashstyle});
   # the above is for backwards compatability
   my @linedashstyle = &getDashList(\$self->{-dashstyle},$font);

   
   my $pickedcolor   = $self->{-linecolor};
   my $pickedcolorbg = $pickedcolor;
      $pickedcolor   = 'none'  if(not defined($pickedcolor)   );
      $pickedcolorbg = 'white' if(not defined($pickedcolorbg) );
      $pickedcolorbg = 'white' if($pickedcolor eq 'black');

   my $_color = sub { $pickedcolor = shift;
                      my $color    = $pickedcolor;
                      my $mbcolor  = $pickedcolor;
                      $color   =  undef  if(   $color   eq 'none'  );
                      $mbcolor = 'white' if(   $mbcolor eq 'none'
                                            or $mbcolor eq 'black' );
                      $self->{-linecolor} = $color;
                      $mb_color->configure(-background       => $mbcolor,
                                           -activebackground => $mbcolor); };

   my @colors = ();
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@colors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_color, $_ ] ] );
   } 
   
   my $width = $self->{-linewidth};
   my $_width = sub { $width = shift;
                      $self->{-linewidth} = $width; };
   my @width = ();
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
       push(@width,
            [ 'command' => $_,
              -font     => $font,
              -command  => [ $_width, $_ ] ] );          
   }
   
   my $arrow1 = $self->{-arrow1};
   my $arrow2 = $self->{-arrow2};
   my $arrow3 = $self->{-arrow3};
   foreach ($arrow1, $arrow2, $arrow3) { $_ = $template->pixel_to_inch($_); }
   
   my $finishsub;
   my ($px, $py) = (2, 2);

   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Tkg2 Line Annotation Editor');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   $pe->Label(-text => 'CONFIGURE PARAMETERS OF LINE ANNOTATION',
              -font => $fontbig)
      ->pack( -fill =>'x');
    
   my $f_di = $pe->Frame->pack(-side => 'top', -fill => 'x');  
      $f_di->Checkbutton(-text     => 'DoIt   ',
                         -font     => $fontb,
                         -variable => \$self->{-doit},
                         -onvalue  => 1,
                         -offvalue => 0 )
           ->pack(-side => 'left');    

        
   my $f_1 = $pe->Frame()->pack( -fill => 'x');
   $f_1->Label(-text => 'Width',
               -font => $fontb)
       ->pack(-side => 'left');
   $mb_width = $f_1->Menubutton(
                   -textvariable => \$width,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -menuitems    => [ @width ],
                   -tearoff      => 0)
                   ->pack(-side => 'left', -fill => 'x');                 

   $f_1->Label(-text => '  Color',
               -font => $fontb,)
       ->pack(-side => 'left');   
   $mb_color = $f_1->Menubutton(
                   -textvariable => \$pickedcolor,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -menuitems    => [ @colors ],
                   -tearoff      => 0,
                   -background   => $pickedcolorbg,
                   -activebackground => $pickedcolorbg)
        ->pack(-side => 'left');

   $f_1->Label(-text => ' Dash Style',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_linedashstyle = $f_1->Menubutton(
                          -textvariable => \$self->{-dashstyle},
                          -font         => $fontb,
                          -width        => 12,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -tearoff      => 0,
                          -menuitems    => [ @linedashstyle ],)
                          ->pack(-side => 'left');



   my $f_2 = $pe->Frame()->pack(-fill => 'x', -expand => 1);
   $f_2->Label(-text => 'Arrow distances (1, 2, 3)',
               -font => $fontb)
       ->pack(-side => 'left');
   $f_2->Entry(-textvariable => \$arrow1,
               -font         => $font,
               -background   => 'white',
               -width        => 10)
       ->pack(-side => 'left');
   $f_2->Entry(-textvariable => \$arrow2,
               -font         => $font,
               -background   => 'white',
               -width        => 10)
       ->pack(-side => 'left');
   $f_2->Entry(-textvariable => \$arrow3,
               -font         => $font,
               -background   => 'white',
               -width        => 10)
       ->pack(-side => 'left');
    
   my $f_3 = $pe->Frame()->pack(-fill => 'x');
   $f_3->Label(-text => 'Arrow style',
               -font => $fontb)
       ->pack(-side => 'left', -fill => 'x');
   $f_3->Radiobutton(-text     => 'none   ',
                     -font     => $fontb,
                     -variable => \$self->{-arrow},
                     -value    => 'none')
       ->pack(-side => 'left', -fill => 'x');
   $f_3->Radiobutton(-text     => 'first  ',
                     -font     => $fontb,
                     -variable => \$self->{-arrow},
                     -value    => 'first')
       ->pack(-side => 'left', -fill => 'x');
   $f_3->Radiobutton(-text     => 'last   ',
                     -font     => $fontb,
                     -variable => \$self->{-arrow},
                     -value    => 'last')
       ->pack(-side => 'left', -fill => 'x');
   $f_3->Radiobutton(-text     => 'both   ',
                     -font     => $fontb,
                     -variable => \$self->{-arrow},
                     -value    => 'both')
       ->pack(-side => 'left', -fill => 'x');

   my $f_4 = $pe->Frame()->pack(-fill => 'x');
   $f_4->Label(-text => '   Line end',
               -font => $fontb)
       ->pack(-side => 'left');
   $f_4->Radiobutton(-text     => 'butt   ',
                     -font     => $fontb,
                     -variable => \$self->{-capstyle},
                     -value    => 'butt')
       ->pack(-side => 'left');
   $f_4->Radiobutton(-text     => 'projecting',
                     -font     => $fontb,
                     -variable => \$self->{-capstyle},
                     -value    => 'projecting')
       ->pack(-side => 'left');
   $f_4->Radiobutton(-text     => 'round  ',
                     -font     => $fontb,
                     -variable => \$self->{-capstyle},
                     -value    => 'round')
       ->pack(-side => 'left');
               
   my $f_5 = $pe->Frame()->pack(-fill => 'x');
   $f_5->Label(-text => 'User Name', 
               -font => $fontb)
       ->pack(-side => 'left');
   $f_5->Entry(-textvariable => \$self->{-username},
               -font => $font,
               -width => 40,
               -background => 'white')
       ->pack(-side => 'left');
   $f_5->Button(-text    => 'Delete',
                -font    => $fontb,
                -command => sub {
             $self->delete($template);
             $Tkg2::Anno::SelectAnno::SELECTANNOEDITOR->destroy
                  if( Tk::Exists($Tkg2::Anno::SelectAnno::SELECTANNOEDITOR) );
             $pe->destroy;
             $template->UpdateCanvas($canv); } )
         ->pack(-side => 'right', -fill => 'x');
 # the SELECTANNOEDITOR requires destruction because when an object is 
 # deleted by the 'Delete' key, there isn't a logical/maintainable way
 # to tell the selection scale in the *EDITOR that an object has been
 # removed.
  
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');

   my $b_apply = $f_b->Button(
                  -text        => 'Apply',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { &$finishsub;
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  

   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { &$finishsub;
                                    $pe->destroy;
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  

   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $canv->delete("selectedanno");
                                  $::SELECTEDANNO = "";
                                  $pe->destroy;
                                } )
                ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
                    ->pack(-side => 'left', -padx => $px, -pady => $py,);
                    
   $finishsub = sub { $self->add($template);
                      foreach ($arrow1, $arrow2, $arrow3) { s/^([0-9.]+)$/$1i/ };  
                      $self->{-arrow1} = $pe->fpixels($arrow1);
                      $self->{-arrow2} = $pe->fpixels($arrow2);
                      $self->{-arrow3} = $pe->fpixels($arrow3);
                      $::SELECTEDANNO = ""; 
                      $template->UpdateCanvas($canv); };
}

1;
