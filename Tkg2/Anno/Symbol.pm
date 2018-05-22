package Tkg2::Anno::Symbol;

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
# $Date: 2006/09/17 22:39:40 $
# $Revision: 1.27 $

use strict;
use Tk;
use Exporter;
use SelfLoader;
use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

$EDITOR = "";

use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints);
use Tkg2::Base qw(Message isNumber Show_Me_Internals
                  adjustCursorBindings);

use constant TWO => scalar 2;

print $::SPLASH "=";

sub new {
   my ($pkg, $x, $y) = ( shift, shift, shift);
   my $self = { -xorigin      => $x,
                -yorigin      => $y,
                -username     => "",
                -symbol       => 'Circle',
                -outlinewidth => '0.01i',
                -outlinecolor => 'black',
                -fillcolor    => 'white',
                -fillstyle    => undef,
                -dashstyle    => undef,
                -size         => 10,
                -doit         => 1,
                -angle        => 0
              };
   return bless $self, $pkg;
}

sub draw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $canv, $template) = @_;
   return unless($self->{-doit});
    
   my ($x, $y) = ( $self->{-xorigin}, $self->{-yorigin});
   
   # if the size is in inches, then convert it to pixels
   # this permits operation from the Instructions
   if($self->{-size} =~ m/i$/o) {
      $self->{-size} = $template->inch_to_pixel($self->{-size});
   }
   
   # the attributes are set up as an explicit hash so that we
   # get a copy of the important symbol attributes to feed
   # into _reallydrawpoints.  _reallydrawpoints only needs
   # certain attributes
   my %attr = ( -symbol       => $self->{-symbol},
                -size         => $self->{-size},
                -angle        => $self->{-angle},
                -outlinecolor => $self->{-outlinecolor},
                -outlinewidth => $self->{-outlinewidth},
                -fillcolor    => $self->{-fillcolor} ); 
   &_reallydrawpoints($canv, $x, $y, ["$self", $self."symbolanno"], \%attr);

   # do not form the bindings if started in display only mode                   
   return if($::CMDLINEOPTS{'nobind'});
    
   &adjustCursorBindings($canv,"$self");
    
   $canv->bind("$self", "<Button-1>", [ \&_selectanno, $self, $template ] );
   $canv->bind("$self", "<Double-Button-3>",
               sub { my @coords = $canv->bbox("$self");
                     $canv->createRectangle(@coords, -outline => 'red',
                                            -tags => "selectedanno");
                     $canv->raise("$self", "selectedanno");                      
                     $self->AnnoEditor($canv, $template); } );               
}

1;

__DATA__

sub CanvHeightWidth_have_changed {
   my ($self, $newcanvwidth, $newcanvheight,
              $oldcanvwidth, $oldcanvheight) = @_;
   my $origin        = $self->{-xorigin};
   my $percentage    = $origin / $oldcanvwidth;
   my $newval        = $percentage*$newcanvwidth;
   $self->{-xorigin} = $newval;
   
      $origin        = $self->{-yorigin};
      $percentage    = $origin / $oldcanvheight;
      $newval        = $percentage*$newcanvheight;
   $self->{-yorigin} = $newval;
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
   my @anno = @{$template->{-annosymbol}};
   # first test whether the annotation already is loaded into template
   foreach (@anno) { return if($_ eq $self); }
   push(@{$template->{-annosymbol}}, $self);
}

sub delete {
   my ($self, $template) = ( shift, shift);
   my @anno = ();
   foreach ( @{ $template->{-annosymbol} } ) {
      push(@anno, $_) unless($_ eq $self);
   }
   $template->{-annosymbol} = [ @anno ];
}

sub _selectanno {
   my ($canv, $self, $template) = ( shift, shift, shift);
   if($::SELECTEDANNO) {
      $canv->delete("selectedanno");
      $::SELECTEDANNO = "";
      return;
   }
   else {
      $::SELECTEDANNO = $self;
   }
   my @coord = $canv->bbox("$self");
   $canv->createRectangle(@coord, -outline => 'red',
                          -tags    => "selectedanno");
   my $move = $self->newmove($canv, $template, \@coord);
   $move->bindStart;
}   

sub newmove {
   my ($anno, $canv, $template, $coord) = (shift, shift, shift, shift);
   my $self = { -canvas   => $canv,
                -template => $template,
                -anno     => $anno,
                -coord    => $coord,
                -width    => ($coord->[2] - $coord->[0]),
                -height   => ($coord->[3] - $coord->[1])
              };
   return bless $self, ref($anno);
}

sub bindStart {
   my $drag = shift;
   my $canv = $drag->{-canvas};
   $canv->configure(-cursor => 'crosshair');
   $canv->Tk::bind("<Button-1>", [\&_startMove, $drag, Ev('x'), Ev('y')]);
}

sub _startMove {
   my ($canv, $drag, $x, $y) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x,$y) = $template->snap_to_grid($x,$y);
   
   my $width  = $drag->{-width};
   my $height = $drag->{-height};
   my $xmid   = $width/TWO;
   my $ymid   = $height/TWO;
   &{$template->{-markrulerXY}}($canv, $x, $y, 'drag1','blue');
   
   $canv->Tk::bind("<Motion>",   [\&_move, $drag,  Ev('x'), Ev('y'),
                                           $width, $height ] );
   $canv->Tk::bind("<Button-1>", [\&_endMove, $drag,  Ev('x'), Ev('y'),
                                              $width, $height ] );
}

sub _move {
   my ($canv, $drag, $x, $y, $width, $height) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   
   my $xmid = $width/TWO;
   my $ymid = $height/TWO;
   
   &{$template->{-markrulerXY}}($canv, $x, $y, 'drag1','blue');
  
   $canv->coords("selectedanno", $x, $y, $x+$width, $y+$height);
}

sub _endMove {
   my ($canv, $drag, $x, $y, $width, $height) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x,$y);
   
   &{$template->{-markrulerXY}}($canv,undef,undef,'drag1',undef);
   
   $canv->coords("selectedanno", $x, $y, $x+$width, $y+$height );
   $canv->Tk::bind("<Motion>", [$template->{-markrulerEv}, Ev('x'), Ev('y')]);

   my $anno = $drag->{-anno};
   $anno->{-xorigin} = $x;
   $anno->{-yorigin} = $y;
   
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
   my ($mb_fillcolor, $mb_outlinecolor, $mb_width);
   
   my $pickedfillcolor   = $self->{-fillcolor};
   my $pickedfillcolorbg = $pickedfillcolor;
      $pickedfillcolor   = 'none'  if(not defined $pickedfillcolor   );
      $pickedfillcolorbg = 'white' if(not defined $pickedfillcolorbg );
      $pickedfillcolorbg = 'white' if($pickedfillcolor eq 'black');
      
   my $pickedoutlinecolor   = $self->{-outlinecolor};
   my $pickedoutlinecolorbg = $pickedoutlinecolor;
      $pickedoutlinecolor   = 'none'  if(not defined $pickedoutlinecolor   ); 
      $pickedoutlinecolorbg = 'white' if(not defined $pickedoutlinecolorbg );
      $pickedoutlinecolorbg = 'white' if($pickedoutlinecolor eq 'black');



   my $_fillcolor = sub { $pickedfillcolor = shift;
                          my $color   = $pickedfillcolor;
                          my $mbcolor = $pickedfillcolor;
                          $color   =  undef  if($color   eq 'none');
                          $mbcolor = 'white' if($mbcolor eq 'none' or
                                                $mbcolor eq 'black');
                          $self->{-fillcolor} = $color;
                          $mb_fillcolor->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor); };
   my $_outlinecolor = sub { $pickedoutlinecolor = shift;
                             my $color   = $pickedoutlinecolor;
                             my $mbcolor = $pickedoutlinecolor;
                             $color   =  undef  if($color   eq 'none');
                             $mbcolor = 'white' if($mbcolor eq 'none' or
                                                   $mbcolor eq 'black');
                             $self->{-outlinecolor} = $color;
                             $mb_outlinecolor->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor); };
                                               
   my (@fillcolors, @outlinecolors ) = ( (), ());
   foreach (@{$::TKG2_CONFIG{-COLORS}}) {
      push(@fillcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fillcolor, $_ ] ] );
      push(@outlinecolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_outlinecolor, $_ ] ] );
   } 
   my $width = $self->{-outlinewidth};
   my $_width = sub { $width = shift;
                      $self->{-outlinewidth} = $width; };
   my @width = ();
   foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
       push(@width,
            [ 'command' => $_,
              -font     => $font,
              -command  => [ $_width, $_ ] ] );          
   }
   
   my $size = $self->{-size};
      $size = $template->pixel_to_inch($size);

   my @pointsymbol = (
      [ 'command' => 'Circle',
        -font     => $font,
        -command  => sub { $self->{-symbol} =    'Circle'} ],
      
      [ 'command' => 'Square',
        -font     => $font,
        -command  => sub { $self->{-symbol} =    'Square'} ],
      
      [ 'command' => 'Triangle',
        -font     => $font,
        -command  => sub { $self->{-symbol} =  'Triangle'} ],

      [ 'command' => 'Arrow',
        -font     => $font,
        -command  => sub { $self->{-symbol} =     'Arrow'} ],

      [ 'command' => 'Phoenix',
        -font     => $font,
        -command  => sub { $self->{-symbol} =   'Phoenix'} ],


      [ 'command' => 'ThinBurst',
        -font     => $font,
        -command => sub { $self->{-symbol} =  'ThinBurst'} ],

      [ 'command' => 'Burst',
        -font     => $font,
        -command => sub { $self->{-symbol} =      'Burst'} ],

      [ 'command' => 'FatBurst',
        -font     => $font,
        -command => sub { $self->{-symbol} =   'FatBurst'} ],
            
      [ 'command' => 'Cross',
        -font     => $font,
        -command  => sub { $self->{-symbol} =     'Cross'} ],
      
      [ 'command' => 'Star',
        -font     => $font,
        -command  => sub { $self->{-symbol} =      'Star'} ],
      
      [ 'command' => 'Horz Bar',
        -font     => $font,
        -command  => sub { $self->{-symbol} = 'Horz Bar' } ],
      
      [ 'command' => 'Vert Bar',
        -font     => $font,
        -command  => sub { $self->{-symbol} = 'Vert Bar' } ]
      );

 
   my $finishsub;
   my ($px, $py) = (2, 2);

   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Tkg2 Symbol Annotation Editor');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   $pe->Label(-text => 'CONFIGURE PARAMETERS OF SYMBOL ANNOTATION',
              -font => $fontbig)
      ->pack( -fill =>'x');

   my $f_di = $pe->Frame->pack(-side => 'top', -fill => 'x');  
      $f_di->Checkbutton(-text     => 'DoIt   ',
                         -font     => $fontb,
                         -variable => \$self->{-doit},
                         -onvalue  => 1,
                         -offvalue => 0 )
           ->pack(-side => 'left');    

   my $f_1 = $pe->Frame()->pack(-side => 'top', -fill => 'x');
   $f_1->Label(-text => "Symbol",
               -font => $fontb)
       ->pack(-side => 'left');
   $f_1->Menubutton(-textvariable => \$self->{-symbol},
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @pointsymbol ],
                    -activebackground => 'white' )
       ->pack(-side => 'left');
     
 
   $f_1->Label(-text => '  Outline',
               -font => $fontb)
       ->pack(-side => 'left');   
   $mb_outlinecolor = $f_1->Menubutton(
                          -textvariable => \$pickedoutlinecolor,
                          -font         => $fontb,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @outlinecolors ],
                          -tearoff      => 0,
                          -background   => $pickedoutlinecolorbg,
                          -activebackground => $pickedoutlinecolorbg)
                          ->pack(-side => 'left');
 
   $f_1->Label(-text => '  Fill',
               -font => $fontb)
       ->pack(-side => 'left');   
   $mb_fillcolor = $f_1->Menubutton(
                       -textvariable => \$pickedfillcolor,
                       -font         => $fontb,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -menuitems    => [ @fillcolors ],
                       -tearoff      => 0,
                       -background   => $pickedfillcolorbg,
                       -activebackground => $pickedfillcolorbg)
                       ->pack(-side => 'left');
        
   my $f_2 = $pe->Frame()->pack(-side => 'top', -fill => 'x');
   $f_2->Label(-text => 'Size',
               -font => $fontb)
       ->pack(-side => 'left');
   $f_2->Entry(-textvariable => \$size,
               -font         => $font,
               -background   => 'white',
               -width        => 10)
       ->pack(-side => 'left');        
   $f_2->Label(-text => '  Width',
               -font => $fontb)
       ->pack(-side => 'left');
   $mb_width = $f_2->Menubutton(
                   -textvariable => \$width,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -menuitems    => [ @width ],
                   -tearoff      => 0)
                   ->pack(-side => 'left', -fill => 'x');                
          
          
   $f_2->Label(-text => '  Angle',
               -font => $fontb)
       ->pack(-side => 'left', -anchor => 'w');
   $f_2->Entry(-textvariable => \$self->{-angle},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left', -fill => 'x');

   my $f_d = $pe->Frame()->pack(-side => 'top', -fill => 'x');
   $f_d->Label(-text => 'User Name', 
               -font => $fontb)
       ->pack(-side => 'left');
   $f_d->Entry(-textvariable => \$self->{-username},
               -font => $font,
               -width => 40,
               -background => 'white')
       ->pack(-side => 'left');
   $f_d->Button(-text    => 'Delete',
                -font    => $fontb,
                -command => sub {
            $self->delete($template);
            $Tkg2::Anno::SelectAnno::SELECTANNOEDITOR->destroy
                  if( Tk::Exists($Tkg2::Anno::SelectAnno::SELECTANNOEDITOR) );
            $pe->destroy;
            $template->UpdateCanvas($canv); })
         ->pack(-side => 'right', -fill => 'x');
 # the SELECTANNOEDITOR requires destruction because when an object is 
 # deleted by the 'Delete' key, there isn't a logical/maintainable way
 # to tell the selection scale in the *EDITOR that an object has been
 # removed.
  
   my $f_b = $pe->Frame(-relief => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   my $b_apply = $f_b->Button(
                  -text        => 'Apply',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { my $go = &$finishsub;
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  
   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { my $go = &$finishsub;
                                    $pe->destroy if($go);
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  


   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $canv->delete("selectedanno");
                                  $::SELECTEDANNO = "";
                                  $pe->destroy;
                                } )
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text => "Help", 
                -font => $font,
                -padx => 4,
                -pady => 4,
                -command => sub { return; } )
       ->pack(-side => 'left', -padx => $px, -pady => $py,);

   $finishsub = sub { if(not &isNumber($self->{-angle}) ) {
                         &Message($pe,'-generic',"Invalid angle\n");
                         return 0;                  
                      }
                      $self->add($template);
                      $size =~ s/^([0-9.]+)$/$1i/;  
                      $self->{-size} = $pe->fpixels($size);
                      $::SELECTEDANNO = ""; 
                      $template->UpdateCanvas($canv); return 1; };
}

1;
