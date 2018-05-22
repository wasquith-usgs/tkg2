package Tkg2::Plot::Editors::ShowHideExplanEntries;

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
# $Date: 2006/09/01 13:18:51 $
# $Revision: 1.10 $

use strict;
use vars qw(@ISA @EXPORT $EDITOR $NAMEIT);

use Exporter;
use SelfLoader;

@ISA = qw(Exporter SelfLoader);
@EXPORT = qw(ShowHideExplanEntries); 
$EDITOR = "";
$NAMEIT = "";

use Tk::Pane; # This module is only one needing Pane, so load here
              # otherwise Perl will stderr that require Tk::Pane; is
	      # assumed.

print $::SPLASH "=";

1;
__DATA__

sub ShowHideExplanEntries {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $template) = @_; 
   my $pw = $canv->parent;

   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Hide/Show Entries');
   $EDITOR = $pe;
   
   my $text = "SHOW/HIDE ENTRIES IN EXPLANATION\n".
              "DataSets are left justified and the ".
              "data objects are indented.";
   $pe->Label(-text    => $text,
              -font    => $fontb,
	      -width   => 75,
              -justify => 'left',
              -anchor  => 'w',
	      -relief  => 'raise')
      ->pack(-fill => 'x');

   my $frame = $pe->Frame(-relief => 'groove',
                          -borderwidth => 2)
                  ->pack(-side   => 'top',
                         -fill   => 'both',
		         -expand => 1);   
   my $pane = $frame->Scrolled('Pane',
                               -scrollbars => 'se')
	            ->pack(-side   => 'top',
			   -expand => 1,
			   -fill   => 'both');
   
   my $dataclass = $self->{-dataclass};
   foreach my $dataset (@$dataclass) {
      my $setname  = $dataset->{-setname};
      my $hideit   = \$dataset->{-show_in_explanation};
      my $username = \$dataset->{-username};
      &_widgets($pane,$fontb,$setname,$hideit,$username,'nopad',$canv);
      
      foreach my $data ( @{ $dataset->{-DATA} } ) {
         my $name     = $data->{-showordinate};
         my $hideit   = \$data->{-show_in_explanation};
         my $username = \$data->{-username};
         &_widgets($pane,$fontb,$name,$hideit,$username,'pad',$canv);
      }
   }
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'bottom', -fill => 'x');
   $f_b->Button(-text        => 'Apply',
                -font        => $fontb,
                -command => sub { $template->UpdateCanvas($canv);
                                } )
                ->pack(-side => 'left');      
   $f_b->Button(-text        => 'Exit',
                -font        => $fontb,
                -command => sub { $pe->destroy; } )
                ->pack(-side => 'left');                  
}


sub _widgets {
   my ($frame, $fontb, $text, $varref, $username, $pad, $canv ) = @_;
   my $cb_relief = 'flat'; 
   my $b_relief  = 'raised';
   my $f = $frame->Frame()->pack(-side => 'top', -fill => 'x');
   $text = substr($text,0,70);
   if($pad eq 'pad') {
     $f->Label(-text   => '   ',
               -font   => $fontb,
               -anchor => 'w',)
       ->pack(-side => 'left');
   }
   $f->Checkbutton(
     -text     => $text,
     -font     => $fontb,
     -variable => $varref,
     -onvalue  => 1,
     -offvalue => 0,
     -relief   => $cb_relief,
     -anchor   => 'w')
     ->pack(-side => 'left', -fill => 'x');
   
   $f->Button(-text    => 'NameIt',
              -relief  => $b_relief,
              -font    => $fontb,
              -command => sub { &_NameIt($username, $canv); } )
     ->pack(-side => 'right');
}


# _NameIt is just a simple Entry widget and its container to 
# name or set the -username hash value in the dataset and in
# the data objects.
sub _NameIt {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($username, $canv) = @_; 
   my $pw = $canv->parent;      

   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};

   $NAMEIT->destroy if( Tk::Exists($NAMEIT) );
   my $pe = $pw->Toplevel(-title => 'DataSet or Data Name Editor');
   $NAMEIT = $pe;
   $pe->resizable(0,0);

   $pe->Label(-text => 'PROVIDE A NAME FOR THE DATA OBJECT',
              -font => $font)
      ->pack( -fill =>'x');
   
   my $f = $pe->Frame->pack(-side => 'top', -fill => 'x');
   $f->Entry(-textvariable => $username,
             -width        => 40,
             -font         => $font,
             -background   => 'white')
     ->pack(-side => 'top', -fill => 'x');

   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   $f_b->Button(-text    => 'Exit',
                -font    => $font,
                -command => sub { $pe->destroy; } )
       ->pack(-side => 'left');                  
   
}        

1;
