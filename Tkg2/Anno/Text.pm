package Tkg2::Anno::Text;

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
# $Date: 2007/09/07 18:18:54 $
# $Revision: 1.36 $

use strict;
use Tk;
use Exporter;
use SelfLoader;
use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

use Tkg2::Base qw(Message isNumber Show_Me_Internals 
                  adjustCursorBindings deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAnnoTextMetaPost);

print $::SPLASH "=";

use constant TWO => scalar 2;

sub new {
   my ($pkg, $x, $y) = ( shift, shift, shift);
   my $self = { -xorigin      => $x,
                -yorigin      => $y,
                -doit         => 1,
                -username     => "",
                -text         => "",
                -justify      => 'center',
                -anchor       => 'nw',
                -borderwidth  => '0.01i',
                -dashstyle    => undef,
                -outlinecolor => undef,
                -fillcolor    => undef,
                -fillstyle    => undef,
                -font         => { -family   => "Helvetica",
                                   -size     => 10,
                                   -weight   => 'normal',
                                   -slant    => 'roman',
                                   -color    => 'black',
                                   -rotation => 0,
                                   -stackit  => 0,
                                   -custom1  => undef,
                                   -custom2  => undef
                                 }
              };
   return bless $self, $pkg;
}

sub draw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $canv, $template) = @_;
   
   return unless($self->{-doit});
   
   
   my $ref = $self->{-font};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font = $canv->fontCreate($self."annotextfont",
                     -family => $ref->{-family},
                     -size   => ($ref->{-size}*
                                 $::TKG2_ENV{-SCALING}*
                                 $::TKG2_CONFIG{-ZOOM}),
                     -weight => $ref->{-weight},
                     -slant  => $ref->{-slant} );

  my $text = &_get_text(\$self->{-text});

  # insert the new lines if we're stacking the text regardless of where
  # the text was read from
  $text =~ s/(.)/$1\n/g if($ref->{-stackit});
  
  $self->{-anchor} = 'center' if(not defined $self->{-anchor}); # 0.37b PATCH 
  
  $canv->createText($self->{-xorigin}, $self->{-yorigin},
                     -text    => $text,
                     -justify => $self->{-justify},
                     -anchor  => $self->{-anchor},
                     -font    => $font,
                     -fill    => $ref->{-color},
                     -tags    => [ $self, $self."annotext" ]);

   &_blankit( $self, $canv, $self."annotext" );
  
   createAnnoTextMetaPost($self->{-xorigin}, $self->{-yorigin},
                          {-text    => $text,
                          -justify => $self->{-justify},
                          -anchor  => $self->{-anchor},
                          -family  => $ref->{-family},
                          -size    => $ref->{-size},
                          -weight  => $ref->{-weight},
                          -slant   => $ref->{-slant},
                          -angle   => $ref->{-rotation},
                          -fill    => $ref->{-color}});

   $canv->fontDelete($self."annotextfont"); 
      
   # do not form the bindings if started in display only mode                   
   return if( $::CMDLINEOPTS{'nobind'} );
   
   &adjustCursorBindings($canv,"$self");
   
   $canv->bind("$self", "<Button-1>", [ \&_selectanno, $self, $template ] );
   $canv->bind("$self", "<Double-Button-3>",
               sub { my @coord = $canv->bbox("$self");
                     $canv->createRectangle(@coord, -outline => 'red',
                                            -tags => "selectedanno");
                     $canv->raise("$self", "selectedanno");                      
                     $self->AnnoEditor($canv, $template); } );               
     
}



# _get_text is a subroutine that is responsible for feeding text back to the
# draw subroutine of the annotation.  There are five types of behavior that 
# can occur with the text:
# (1) If the text from the dialog box or from the tkg2 file matches the following
#      '<softcat: filename>', then the contents of the file (if it exists) are
#      read and inserted as the text at draw time.  This file will be read with
#      each update of the canvas.  Filename can include a path.
#
# (2) If the text from the dialog box or from the tkg2 file matches the following
#     '<hardcat: filename>', then the contents of the file (if it exists) are
#      read and inserted as the text at draw time.  This new text is permanently
#     loaded into the tkg2 file and will be preserved if the tkg2 file is saved.
#     Filename can include a path.
#
#
# Note: The colon is mandatory so that the following shell behavior can use the
# cat command.  Also (1), (2), and (5) are platform independent.
#
# (3) If the text from the dialog box or from the tkg2 file matches the following
#     '<softeval: expression possibly with pipes>', then the string after the eval:
#     is invoked as a shell command whose STDOUT is piped into the read by tkg2.
#     The command is run each time.
#
# (4) If the text from the dialog box or from the tkg2 file matches the following
#     '<hardeval: expression possibly with pipes>', then the string after the eval:
#     is invoked as a shell command whose STDOUT is piped into the read by tkg2.
#     The output from the command is permanently loaded (see 2).  Example:
#        <softeval: date> to insert the output from the date command
#        <hardeval: last | grep asquith> to insert filtered output of the last command
# Note: Eval is likely to only be supported on Unix-like operating systems?
#
# (5) If 1-4 are not triggered, then the contents of the text field are simply
#     drawn on the screen.
#
sub _get_text {
   my ($textref) = @_;
   my $text = $$textref;
   # Begin consideration of outside communication with the operating system
   my $hardORsoft = 0;
   my ( $catfile, $evaluate );
   my $os = $::TKG2_ENV{-OSNAME};

   local *FH;
   local $/ = undef;
   if(( $hardORsoft, $catfile ) = $text =~ m/^\s*<\s*(.+)cat:\s*(.+)>$/o) {
     if(-e $catfile) {
        open(FH, "<$catfile") or
           do { my $mess = "Text Annotation: '$catfile' not ".
                           "opened because $!.";
                &Message($::MW, '-generic', $mess);
              };
        $text = <FH>;
        chomp($text);
        close(FH);
     }
     else {
        my $mess = "Tkg2 thinks that you are reading '$catfile' into ".
                   "a text annotation but that file does not exist";
        &Message($::MW, '-generic', $mess);
     }
   }
   elsif($os eq 'solaris' or
         $os eq 'linux') {
     if(($hardORsoft, $evaluate) = $text =~ m/^\s*<\s*(.+)eval:\s*(.+)>$/o) {
        open(FH, "$evaluate |") or
           do { my $mess = "Text Annotation: '$catfile' pipe not ".
                           "opened because $!.";
                &Message($::MW, '-generic', $mess);
              };
        $text = <FH>;
        chomp($text);
        close(FH);
     }
   }
   else {
     # do nothing
   }
   $hardORsoft ||= 0; # insure that $hardORsoft is defined as it will 
                      # become undef often with the regex above
   $$textref = $text if($hardORsoft eq 'hard');
   return $text;  
}  



sub _blankit {
   my ($self, $canv, $tag) = @_;
   my %attr = %$self;
   return unless( defined $attr{-fillcolor} or
                  defined $attr{-outlinecolor} );
                
   my @coord = $canv->bbox($tag);
   $coord[0] -= TWO; # modify x 
   $coord[2] += TWO; # modify x 
   $coord[1] -= TWO; # modify y
   $coord[3] += TWO; # modify y
   
   $canv->createRectangle(@coord,
                          -fill    => $attr{-fillcolor},
                          -outline => $attr{-outlinecolor},
                          -width   => $attr{-borderwidth},
                          -tags    => [ $self, $tag."annotextbox" ]);

   # The newly created Rectangle requires being hidden behind the text                       
   $canv->raise($tag, $tag."annotextbox");  
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
   my @anno = @{$template->{-annotext}};
   # first test whether the annotation already is loaded into template
   foreach (@anno) { return if($_ eq $self); }
   push(@{$template->{-annotext}}, $self);
}

sub delete {
   my ($self, $template) = ( shift, shift);
   my @anno = ();
   foreach ( @{$template->{-annotext}} ) {
      push(@anno, $_) unless($_ eq $self);
   }
   $template->{-annotext} = [ @anno ];
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
   ($x, $y) = $template->snap_to_grid($x, $y);
   
   my $width  = $drag->{-width};
   my $height = $drag->{-height};
   my $xmid   = $width/TWO;
   my $ymid   = $height/TWO;  
   
   &{$template->{-markrulerXY}}($canv, $x, $y,                'drag1','blue');
   &{$template->{-markrulerXY}}($canv, $x+$width, $y+$height, 'drag2','blue');
   &{$template->{-markrulerXY}}($canv, $x+$xmid,  $y+$ymid,   'drag3','blue');
      
   $canv->Tk::bind("<Motion>",   [\&_move, $drag,  Ev('x'), Ev('y'),
                                           $width, $height ] );
   $canv->Tk::bind("<Button-1>", [\&_endMove, $drag,  Ev('x'), Ev('y'),
                                              $width, $height ] );
}

sub _move {
   my ($canv, $drag, $x, $y, $width, $height ) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x, $y);
   
   my $xmid = $width/TWO;
   my $ymid = $height/TWO;  
   
   &{$template->{-markrulerXY}}($canv, $x, $y,                'drag1','blue');
   &{$template->{-markrulerXY}}($canv, $x+$width, $y+$height, 'drag2','blue');
   &{$template->{-markrulerXY}}($canv, $x+$xmid,  $y+$ymid,   'drag3','blue');               
  
   $canv->coords("selectedanno", $x, $y, $x+$width, $y+$height );
}

sub _endMove {
   my ($canv, $drag, $x, $y, $width, $height ) = @_;
   my $template = $drag->{-template};
   $x = $canv->canvasx($x);
   $y = $canv->canvasy($y);
   ($x, $y) = $template->snap_to_grid($x, $y);
   
   &{$template->{-markrulerXY}}($canv,undef,undef,'drag1',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'drag2',undef);
   &{$template->{-markrulerXY}}($canv,undef,undef,'drag3',undef);   

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
   my ($mb_fillcolor, $mb_outlinecolor, $mb_fontcolor, $mb_justify, $mb_anchor);
   my $mb_width;
   my $anchor  = $self->{-anchor};
   my $justify = $self->{-justify};

      
   my $pickedfillcolor   = $self->{-fillcolor};
   my $pickedfillcolorbg = $pickedfillcolor;
      $pickedfillcolor   = 'none'  if(not defined $pickedfillcolor    );
      $pickedfillcolorbg = 'white' if(not defined $pickedfillcolorbg );
      $pickedfillcolorbg = 'white' if($pickedfillcolor eq 'black');
      
   my $pickedoutlinecolor   = $self->{-outlinecolor};
   my $pickedoutlinecolorbg = $pickedoutlinecolor;
      $pickedoutlinecolor   = 'none'  if(not defined $pickedoutlinecolor   ); 
      $pickedoutlinecolorbg = 'white' if(not defined $pickedoutlinecolorbg );
      $pickedoutlinecolorbg = 'white' if($pickedoutlinecolor eq 'black');

   my $fontref = $self->{-font};
   my ($fontfam, $fontwgt, $fontslant, $fontcolor) =
        ( $fontref->{-family},  $fontref->{-weight},
          $fontref->{-slant} ,  $fontref->{-color}  );    
   my $fontcolorbg = $fontcolor;
      $fontcolorbg = 'white' if($fontcolorbg eq 'black');

   my $_fontfam   = sub { $fontfam            = shift;
                          $fontref->{-family} = $fontfam; };
   my $_fontwgt   = sub { $fontwgt            = shift;
                          $fontref->{-weight} = $fontwgt; };
   my $_fontslant = sub { $fontslant          = shift;
                          $fontref->{-slant}  = $fontslant; };
   my $_fontcolor = sub { $fontcolor          = shift;
                          $fontref->{-color}   = $fontcolor;
                          my $mbcolor = $fontcolor;
                          $mbcolor = 'white' if($mbcolor eq 'black');
                          $mb_fontcolor->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor); };
   my $_justify = sub { $justify = shift;
                        $self->{-justify} = $justify; };
                        
   my $_anchor  = sub { $anchor = shift;
                        $self->{-anchor} = $anchor };

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
                             my $color  = $pickedoutlinecolor;
                             my $mbcolor = $pickedoutlinecolor;
                             $color   =  undef  if($color   eq 'none');
                             $mbcolor = 'white' if($mbcolor eq 'none' or
                                                   $mbcolor eq 'black');
                             $self->{-outlinecolor} = $color;
                             $mb_outlinecolor->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor); };
                                               
   my (@fillcolors, @outlinecolors, @fontcolors ) = ( (), (), () );
   foreach (@{$::TKG2_CONFIG{-COLORS}}) {
      push(@fillcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fillcolor, $_ ] ] );
      push(@outlinecolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_outlinecolor, $_ ] ] );
      next if(/none/);
      push(@fontcolors,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fontcolor, $_ ] ] );         
   } 
   my @justify = ();
   foreach ( qw(center left right) ) {
      push(@justify,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_justify, $_ ] ] );
   }
   
   my @anchor = ();
   foreach ( qw(nw n ne e se s sw w center) ) {
      push(@anchor,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_anchor, $_ ] ] );
   }     
     
     
   my @fontfam = ( );
   foreach (@{$::TKG2_CONFIG{-FONTS}}) {
      push(@fontfam,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fontfam, $_ ] ] );
  }
   
   my @fontwgt = ( );
   foreach (qw(normal bold)) {
      push(@fontwgt,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fontwgt, $_ ] ] );
   }               
   
   my @fontslant = (  );
   foreach (qw(roman italic)) {
      push(@fontslant,
           [ 'command' => $_,
             -font     => $font,
             -command  => [ \&$_fontslant, $_ ] ] );
   }   
   
   my $width = $self->{-borderwidth};
   my $_width = sub { $width = shift;
                      $self->{-borderwidth} = $width; };
   my @width = ();
   foreach (@{$::TKG2_CONFIG{-LINETHICKNESS}}) {
       push(@width,
            [ 'command' => $_,
              -font     => $font,
              -command  => [ $_width, $_ ] ] );          
   }
 
   my $finishsub;
   my ($px, $py) = (2, 2);

   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Tkg2 Text Annotation Editor');
   $EDITOR = $pe;
   $pe->resizable(0,0);
   $pe->Label(-text => 'CONFIGURE PARAMETERS OF TEXT ANNOTATION',
              -font => $fontbig)
      ->pack( -fill =>'x');

   $pe->Label(-text => "Text",
              -font => $fontb)
      ->pack(-side => 'top', -expand => 'x', -anchor => 'w');
   my $entry = $pe->Scrolled('Text',
                             -font       => $font,
                             -scrollbars => 'se',
                             -width      => 30,
                             -height     => 7,
                             -background => 'white' )
                  ->pack(-side => 'top', -fill => 'x');
   $entry->insert('end', $self->{-text});
   
   $entry->focus;
   my $f_di = $pe->Frame->pack(-side => 'top', -fill => 'x');  
      $f_di->Checkbutton(-text     => 'DoIt   ',
                         -font     => $fontb,
                         -variable => \$self->{-doit},
                         -onvalue  => 1,
                         -offvalue => 0 )
           ->pack(-side => 'left');
    $f_di->Label(-text => '  Anchor',
                 -font => $fontb)
         ->pack(-side => 'left');
    $mb_anchor = $f_di->Menubutton(
                      -textvariable => \$anchor,
                      -font         => $fontb,
                      -indicator    => 1,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @anchor ],
                      -activebackground => 'white')
                      ->pack(-side => 'left');      
           
           
               
   my $f_3 = $pe->Frame()->pack(-side => 'top', -fill => 'x');
   $f_3->Label(-text => 'Font, Size, Wgt, Slant, Jusify, Color',
               -font => $fontb)
       ->pack(-side => 'top', -anchor => 'w');   
   $f_3->Menubutton(-textvariable => \$fontfam,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @fontfam ],
                    -width        => 10,
                    -activebackground => 'white')
       ->pack(-side => 'left');
   $f_3->Entry(-textvariable => \$fontref->{-size},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left');
   $f_3->Menubutton(-textvariable => \$fontwgt,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @fontwgt ],
                    -width        => 6,
                    -activebackground => 'white')
       ->pack(-side => 'left');
   $f_3->Menubutton(-textvariable => \$fontslant,
                    -font         => $fontb,
                    -indicator    => 1,
                    -relief       => 'ridge',
                    -tearoff      => 0,
                    -menuitems    => [ @fontslant ],
                    -width        => 6,
                    -activebackground => 'white')
       ->pack(-side => 'left');
   $mb_justify = $f_3->Menubutton(
                     -textvariable => \$justify,
                     -font         => $fontb,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @justify ],
                     -activebackground => 'white')
                     ->pack(-side => 'left');   
   $mb_fontcolor = $f_3->Menubutton(
                       -textvariable => \$fontcolor,
                       -font         => $fontb,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -tearoff      => 0,
                       -menuitems    => [ @fontcolors ],
                       -background   => $fontcolorbg, 
                       -activebackground => $fontcolorbg)
                       ->pack(-side => 'left');
     
   my $f_1 = $pe->Frame()->pack(-side => 'top', -fill => 'x');
   $f_1->Label(-text => 'Background color',
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

   $f_1->Label(-text => '  Border color',
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
        
   my $f_2 = $pe->Frame()->pack(-side => 'top', -fill => 'x');        
   $f_2->Label(-text => 'Border width ',
               -font     => $fontb)
       ->pack(-side => 'left', -anchor => 'w');
   $mb_width = $f_2->Menubutton(
                   -textvariable => \$width,
                   -font         => $fontb,
                   -indicator    => 1,
                   -relief       => 'ridge',
                   -menuitems    => [ @width ],
                   -tearoff      => 0,
                   -activebackground => 'white')
                   ->pack(-side => 'left', -fill => 'x');         
   $f_2->Label(-text => '  Angle (for MetaPost)',
               -font => $fontb)
       ->pack(-side => 'left', -anchor => 'w');
   $f_2->Entry(-textvariable => \$fontref->{-rotation},
               -font         => $font,
               -background   => 'white',
               -width        => 10  )
       ->pack(-side => 'left', -fill => 'x');
   $f_2->Checkbutton(-text     => "Stack Text",
                     -font     => $fontb,
                     -variable => \$fontref->{-stackit},
                     -onvalue  => 1,
                     -offvalue => 0)
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
  
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   my $b_apply = $f_b->Button(
                  -text        => 'Apply',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { my $go = &$finishsub;
                                    $template->UpdateCanvas($canv);
                                  } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py);                  

   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command => sub { my $go = &$finishsub;
                                    $pe->destroy if($go);
                                    $template->UpdateCanvas($canv);
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
                    
   $finishsub = sub { $self->{-text} = $entry->get('0.0', 'end');
                      $self->{-text} =~ s/\n$//;
                      if(not &isNumber($fontref->{-size})
                         or $fontref->{-size} < 0 ) {
                         &Message($pe,'-generic',"Invalid font size\n");
                         return 0;                  
                      }
                      if(not &isNumber($fontref->{-rotation}) ) {
                         &Message($pe,'-generic',"Invalid angle\n");
                         return 0;                  
                      }
                      $self->add($template);
                      $::SELECTEDANNO = "";
                      return 1;
                    };
}

1;
