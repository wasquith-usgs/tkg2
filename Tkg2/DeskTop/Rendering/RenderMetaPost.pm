package Tkg2::DeskTop::Rendering::RenderMetaPost;

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
# $Date: 2008/09/03 15:18:34 $
# $Revision: 1.10 $

use strict;

use Exporter;
#use SelfLoader;

use vars  qw( @ISA @EXPORT $DOTLABELS $HELLOWORLD $DOLABELS
              $CLEANTEX $OFFSETMARK $SPECIAL_PIC
              $SPAWN_MPOST $AUTOSPAWN_MPOST $CLEANUP $CLEANUP_THE_MPFILE);
@ISA    = qw( Exporter);# SelfLoader );
@EXPORT = qw( RenderMetaPost
              createAxisLabelsMetaPost
	      createLineMetaPost
	      createRectangleMetaPost
	      createPolygonMetaPost
	      createOvalMetaPost
	      createTextMetaPost
	      createAnnoTextMetaPost
	      createExplanationMetaPost
	      createExplanationTextMetaPost
	      beginExplanationMetaPost
	      endExplanationMetaPost
	      createAxisTitlesMetaPost
	      createAnnoLineMetaPost);

use Tkg2::Base qw(Show_Me_Internals routeMetaPost Message);
 
 
$DOTLABELS   = 0;
$HELLOWORLD  = 0;
$DOLABELS    = 1;
$CLEANTEX    = 1;
$OFFSETMARK  = 0;
$SPECIAL_PIC = 0;
$SPAWN_MPOST = 1;
$CLEANUP     = 1;
$CLEANUP_THE_MPFILE = 0;
$AUTOSPAWN_MPOST = 0;


my $_massive_line_limiter = 1500;
 #MetaPost seems to be able to handle 1500 or so, but mpto -tex crashes with btex/etex constructs with
 #value much smaller than shown.
my $_massive_line_limiter_for_btexetex = 20;

print $::SPLASH "=";

1;

#__DATA__


sub cleanupFilesMetaPost {
  my ($bname) = shift;
  return if(not defined $bname or $bname eq "");
  return unless($CLEANUP);
  unlink($bname.".log");
  unlink($bname.".1");
  unlink($bname.".mpo");
  unlink($bname.".mpx");
  unlink($bname.".mp.keep");
  unlink($bname.".mp") if($CLEANUP_THE_MPFILE);
}

#
sub createOffsetMarkMetaPost {
  return unless($OFFSETMARK);
  print $::MP "% BEGIN SPECIAL OFFSET MARK\n",
              "draw (0in,-1in)--(2in,-1in) withcolor red;\n",
              "draw (1in,0in)--(1in,-2in) withcolor red;\n",
              "% END SPECIAL OFFSET MARK\n";
}


sub corePreambleMetaPost {
  my $scaling = shift;
  print $::MP <<HERE;
beginfig(1);
prologues:=2;
numeric u;
u:=(1/($scaling));
HERE
}


# Material to follow the core preamble, the %&latex toggles LaTeX
# processing of the metapost file regardless of the status of the
# TEX environment variable of the shell (which could otherwise be
# set as: export TEX=latex.
sub fontPreambleMetaPost {
   print $::MP <<HERE;
verbatimtex
\%\&latex
\\documentclass{article}
\\usepackage[romanmath]{usgsfonts}
\\begin{document}
\\rmfamily
etex;
HERE
}


sub corePostambleMetaPost {
   print $::MP <<HERE;
endfig;
end
HERE
}


#
sub createOvalMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my ($x, $y, $xmin, $ymin, $xmax, $ymax, $attr) = @_;
  ($x,$y)       = coord2MetaPost($x,$y);
  ($xmin,$ymin) = coord2MetaPost($xmin,$ymin);
  ($xmax,$ymax) = coord2MetaPost($xmax,$ymax);
  my $width   = width2MetaPost($attr->{-width});
  my $outline = color2MetaPost($attr->{-outline});
  my $fill    = color2MetaPost($attr->{-fill});
  my $dash    = dash2MetaPost($attr->{-dash});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $blankit = $attr->{-blankit};
  return if($fill eq "none" and $outline eq "none");
  print $::MP "pickup pencircle scaled $width; path p;\n";
  print $::MP "p:=($xmin,$y)..($x,$ymax)..($xmax,$y)..($x,$ymin)..cycle;\n";

  if($SPECIAL_PIC) {
    print $::MP "addto $SPECIAL_PIC contour p withcolor $fill;\n" unless($fill eq "none");
    return if($outline eq "none");
    print $::MP "addto $SPECIAL_PIC doublepath p $dash withcolor $outline withpen pencircle scaled $width;\n";
  }
  else {
    print $::MP "fill p withcolor $fill;\n" unless($fill eq "none");
    return if($outline eq "none");
    print $::MP "draw p $dash withcolor $outline;\n";
  }
}


sub createCanvasBackgroundMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  createPolygonMetaPost(@_);
}

sub createRectangleMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my ($xmin,$ymin,$xmax,$ymax,$attr) = @_;
  createPolygonMetaPost($xmin,$ymin,$xmin,$ymax,$xmax,$ymax,$xmax,$ymin,$attr);
}

sub _createPolygonShadeBetweenMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $attr = pop(@_);

  my $angle   = angle2MetaPost($attr->{-angle});
  my $width   = width2MetaPost($attr->{-width});
  my $outline = color2MetaPost($attr->{-outline});
  my $fill    = color2MetaPost($attr->{-fill});
  my $dash    = dash2MetaPost($attr->{-dash});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $blankit = $attr->{-blankit};
  my $linejoin = ($attr->{-linejoin}) ? $attr->{-linejoin} : "beveled";

  my @c = @_;
  my $n = $#c-1;
  my $m = ($n-2)/2;
  #print "METABUG: $m and $n\n";
  print $::MP "% BEGIN special polygon generated for a shade between\n";
  print $::MP "pickup pencircle scaled 0.25pt; linecap:=butt; linejoin:=mitered; path p;\n";
  my $counter = 0;
  my $subcounter = 0;
  my $f = 0;
  my $s = $_massive_line_limiter;
  while($f < $m) {
    #print "METABUG: path to null\n";
    my $path = "";
    my $t = $f+$s;
       $t = $m if($t > $m);
    for(my $i=$f;$i<=$t;$i+=2) {
      #print "METABUG: $i and ",$i+1,"\n";
      my ($x,$y) = coord2MetaPost($c[$i],$c[$i+1]);
      $path .= "($x,$y)--";
      if($subcounter > $_massive_line_limiter_for_btexetex) {
        $path .= "\n";
        $subcounter = 0;
      }
      $subcounter++;
    }
    #print "METABUG-------------------\n";
    $subcounter = 0;
    for(my $i=$n-$t;$i<=$n-$f;$i+=2) {
      #print "METABUG: $i and ",$i+1,"\n";
      my ($x,$y) = coord2MetaPost($c[$i],$c[$i+1]);
      $path .= "($x,$y)--";
      if($subcounter > $_massive_line_limiter_for_btexetex) {
        $path .= "\n";
        $subcounter = 0;
      }
      $subcounter++;
    }
    $path .= "cycle;\n";
    print $::MP "p:=$path\n";
    #print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "fill p rotatedabout ((center p), $angle) withcolor $fill;\n"
              unless($fill eq "none");
    print $::MP "draw p rotatedabout((center p), $angle) withcolor $fill;\n";
    print $::MP "% END special polygon generated for a shade between\n";
    $f += $s;
  }
}

sub createPolygonMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $attr = pop(@_);

  my $angle   = angle2MetaPost($attr->{-angle});
  my $width   = width2MetaPost($attr->{-width});
  my $outline = color2MetaPost($attr->{-outline});
  my $fill    = color2MetaPost($attr->{-fill});
  my $dash    = dash2MetaPost($attr->{-dash});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $blankit = $attr->{-blankit};
  my $linejoin = ($attr->{-linejoin}) ? $attr->{-linejoin} : "beveled";

  return if($fill eq "none" and $outline eq "none");

  my @c = @_;
  my $n = $#c;
  if($c[0] == $c[$n-1] and $c[1] == $c[$n]) {
     pop(@c); pop(@c);
  }
  $n = $#c;
  my ($xo,$yo) = coord2MetaPost($c[$n-1],$c[$n]);
  my ($xbase,$ybase) = ($xo,$yo);


  my $dir = ($attr->{-shadedir}) ? $attr->{-shadedir} : 0; 
  if($dir eq "shade between") { 
    _createPolygonShadeBetweenMetaPost(@c,$attr);
    return;
  }
  
  print $::MP "pickup pencircle scaled $width; linecap:=butt; linejoin:=$linejoin; path p;\n";


  my $path = "";
  my $counter = 0;
  my $subcounter = 0;
  for(my $i=0;$i<=$n-2;$i+=2) {
    my ($x,$y) = coord2MetaPost($c[$i],$c[$i+1]);
    $path .= "($x,$y)--";
    
    if($counter > $_massive_line_limiter) {
      if($dir) {
        if($dir eq 'below' or $dir eq 'above') {
          $path .= "($x,$ybase)--($xo,$yo)--";
          ($xo,$yo) = ($x,$ybase);
        }
        else { # 'left' and 'right'
          $path .= "($xbase,$y)--($xo,$yo)--";
          ($xo,$yo) = ($xbase,$y);
        }
        $i -= 2;
      }
      print $::MP "p:=$path"."cycle;\n";
      if($SPECIAL_PIC) {
        print $::MP "addto $SPECIAL_PIC also bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
        print $::MP "addto $SPECIAL_PIC contour p rotatedabout ((center p), $angle) withcolor $fill;\n"
              unless($fill eq "none");
        print $::MP "addto $SPECIAL_PIC doublepath p rotatedabout((center p), $angle) $dash withcolor $outline withpen pencircle scaled $width;\n"
              unless($outline eq "none");
      }
      else {
        print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
        print $::MP "fill p rotatedabout ((center p), $angle) withcolor $fill;\n"
              unless($fill eq "none");
        print $::MP "draw p rotatedabout((center p), $angle) $dash withcolor $outline;\n"
              unless($outline eq "none");
      }
      $path = "";
      $counter=0;
      next;
    }
    elsif($subcounter > $_massive_line_limiter_for_btexetex) {
      $path .= "\n";
      $subcounter = 0;
    }
    else {
      $counter++;
      $subcounter++;
    }
  }
  print $::MP "p:=$path($xo,$yo)--cycle;\n";
  if($SPECIAL_PIC) {
        print $::MP "addto $SPECIAL_PIC also bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
        print $::MP "addto $SPECIAL_PIC contour p rotatedabout ((center p), $angle) withcolor $fill;\n"
              unless($fill eq "none");
        print $::MP "addto $SPECIAL_PIC doublepath p rotatedabout((center p), $angle) $dash withcolor $outline withpen pencircle scaled $width;\n"
              unless($outline eq "none");
  }
  else {
    print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "fill p rotatedabout ((center p), $angle) withcolor $fill;\n"
          unless($fill eq "none");
    print $::MP "draw p rotatedabout ((center p), $angle) $dash withcolor $outline;\n"
          unless($outline eq "none");
  }
}



sub createLineMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  my $attr = pop(@_);
  my $width = width2MetaPost($attr->{-width});
  my $color = color2MetaPost($attr->{-fill});
  my $dash  = dash2MetaPost($attr->{-dash});
  my $angle = angle2MetaPost($attr->{-angle});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $blankit = $attr->{-blankit};

  return if($color eq "none");

  print $::MP "pickup pencircle scaled $width; linecap:=butt; linejoin:=beveled; path p;\n"; 

  my @c = @_;
  my ($x,$y) = coord2MetaPost($c[0],$c[1]);
  my $path = "($x,$y)";
  my $counter = 0;
  my $subcounter = 0;
  for(my $i=2;$i<=$#c;$i+=2) {
    my ($x,$y) = coord2MetaPost($c[$i],$c[$i+1]); #$x .= "u"; $y = -$y."u";
    $path .= "--($x,$y)";
    if($counter > $_massive_line_limiter) {
      print $::MP "p:=$path;\n";
      if($SPECIAL_PIC) {
        print $::MP "addto $SPECIAL_PIC also bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
        print $::MP "addto $SPECIAL_PIC doublepath p rotatedabout((center p), $angle) $dash withcolor $color;\n";
      }
      else {
        print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
        print $::MP "draw p rotatedabout((center p), $angle) $dash withcolor $color;\n";
      }
      ($x,$y) = coord2MetaPost($c[$i],$c[$i+1]);
      $path = "($x,$y)";
      $counter=0;
      next;
    }
    elsif($subcounter > $_massive_line_limiter_for_btexetex) {
      $path .= "\n";
      $subcounter = 0;
    }
    else {
      $counter++;
      $subcounter++;
    }
  }
  print $::MP "p:=$path;\n";
  if($SPECIAL_PIC) {
    print $::MP "addto $SPECIAL_PIC also bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "addto $SPECIAL_PIC doublepath p rotatedabout((center p), $angle) $dash withcolor $color withpen pencircle scaled $width;\n";
  }
  else {
    print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "draw p rotatedabout((center p), $angle) $dash withcolor $color;\n";
  }
}



#===================================================================
#                  AXIS SPECIFIC FUNCTIONS
#===================================================================
# The createAxisLabelsMetaPost is needed as a special implementation
# because of the need for left/right top/bottom offsetting. Primarily
# we have to handle the suffix differently.
sub createAxisLabelsMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  return unless($DOLABELS);

  my ($x,$y,$suffix,$attr) = @_;
  ($x,$y) = coord2MetaPost($x,$y);

  my $offset = ($attr->{-offset}) ? $attr->{-offset}."u" : 0; 

  my $shift  = ($suffix eq "lft") ? "(-$offset,0)"  :
               ($suffix eq "rt")  ? "($offset,0)"   :
               ($suffix eq "top") ? "(0,$offset)"   :
               ($suffix eq "bot") ? "(0,-$offset)"  : "(0,0)";

  my $use_suffix = "";
     $use_suffix = ".$suffix" if($shift ne "(0,0)"); 

  my $tmp    = text2MetaPost_text($attr->{-text});
  if($tmp->{-error}) { return }
  my $text   = $tmp->{-text};
  my $angle  = angle2MetaPost($attr->{-angle});
  my $color  = color2MetaPost($attr->{-fill});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $family = textfamily2MetaPost($attr->{-family});
  my $size   = textsize2MetaPost($attr->{-size});
  my $weight = textweight2MetaPost($attr->{-weight});
  my $slant  = textslant2MetaPost($attr->{-slant});
  my $blankit = $attr->{-blankit};
  print $::MP "% createAxisLabelsMetaPost\n";
  print $::MP "picture p; labeloffset:=$offset;\n";
  print $::MP "p:=thelabel$use_suffix (btex\n",
              "$family $weight $size $slant \n $text ",
              "etex,($x,$y));\n";
  print $::MP "% special line\n";
  print $::MP "fill bbox p rotatedabout ((center p), $angle) shifted $shift withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
  print $::MP "draw p rotatedabout ((center p), $angle) shifted $shift withcolor $color;\n" unless($color eq "none");
  print $::MP "dotlabel (\"\",($x,$y));\n" if($DOTLABELS);
}

sub createAxisTitlesMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  return unless($DOLABELS);

  my ($x,$y,$suffix,$attr) = @_;
  ($x,$y) = coord2MetaPost($x,$y);

  my $offset = ($attr->{-offset}) ? $attr->{-offset}."u" : 0; 

  my $shift  = ($suffix eq "lft") ? "(-$offset,0)"  :
               ($suffix eq "rt")  ? "($offset,0)"   :
               ($suffix eq "top") ? "(0,$offset)"   :
               ($suffix eq "bot") ? "(0,-$offset)"  : "(0,0)";
  my $use_suffix = "";
     #$use_suffix = ".$suffix" if($shift ne "(0,0)");

  my $tmp    = text2MetaPost_text($attr->{-text});
  if($tmp->{-error}) { return }
  my $text   = $tmp->{-text};
  my $angle  = angle2MetaPost($attr->{-angle});
  my $color  = color2MetaPost($attr->{-fill});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $family = textfamily2MetaPost($attr->{-family});
  my $size   = textsize2MetaPost($attr->{-size});
  my $weight = textweight2MetaPost($attr->{-weight});
  my $slant  = textslant2MetaPost($attr->{-slant});
  my $blankit = $attr->{-blankit};
  print $::MP "picture p;\n";
  print $::MP "p:=thelabel$use_suffix (btex\n",
              "$family $weight $size $slant \n $text ",
              "etex,($x,$y));\n";
  print $::MP "% special line\n";
  print $::MP "fill bbox p rotatedabout ((center p), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
  print $::MP "draw p rotatedabout ((center p), $angle) withcolor $color;\n" unless($color eq "none");
  print $::MP "dotlabel (\"\",($x,$y));\n" if($DOTLABELS);
}




#===================================================================
#                  ANNOTATION SPECIFIC FUNCTIONS
#===================================================================
sub createAnnoLineMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my ($x1,$y1,$x2,$y2,$attr) = @_;
  ($x1,$y1) = coord2MetaPost($x1,$y1);
  ($x2,$y2) = coord2MetaPost($x2,$y2);

  my $width = width2MetaPost($attr->{-width});
  my $color = color2MetaPost($attr->{-fill});
  my $cap   = capstyle2MetaPost($attr->{-linecap});
  my $dash  = dash2MetaPost($attr->{-dash});
  return if($color eq "none");
  #print STDERR "COLOR $color\n";
  print $::MP "pickup pencircle scaled $width;linecap:=$cap;\n";
  #print STDERR "$cap\n";
  print $::MP "draw ($x1,$y1)--($x2,$y2) $dash withcolor $color;\n";
}


sub createAnnoTextMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  return unless($DOLABELS);

  my ($x,$y,$attr) = @_;
  ($x,$y) = coord2MetaPost($x,$y);

  my $tmp    = text2MetaPost_text($attr->{-text});
  if($tmp->{-error}) { return }
  my $text   = $tmp->{-text};
  my $angle  = angle2MetaPost($attr->{-angle});
  my $color  = color2MetaPost($attr->{-fill});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $suffix = textanchor2MetaPost($attr->{-anchor});
  my $family = textfamily2MetaPost($attr->{-family});
  my $size   = textsize2MetaPost($attr->{-size});
  my $weight = textweight2MetaPost($attr->{-weight});
  my $slant  = textslant2MetaPost($attr->{-slant});
  my $blankit = $attr->{-blankit};
  my $shift  = "(0u,0u)";

  print $::MP "picture pic;\n";
  print $::MP "pic:=thelabel$suffix (btex\n",
              "$family $weight $size $slant\n $text ",
              "etex,($x,$y));\n";
  print $::MP "% special line\n";
  if($SPECIAL_PIC) {
    print $::MP "addto $SPECIAL_PIC contour bbox pic rotatedabout ((center pic), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "addto $SPECIAL_PIC also pic rotatedabout ((center pic), $angle) shifted $shift withcolor $color;\n" unless($color eq "none");
  }
  else {
    print $::MP "fill bbox pic rotatedabout ((center pic), $angle) withcolor $blankcolor;\n" if($blankit and $blankcolor ne "none");
    print $::MP "draw pic rotatedabout ((center pic), $angle) shifted $shift withcolor $color;\n" unless($color eq "none");
  }
  print $::MP "dotlabel (\"\",($x,$y));\n" if($DOTLABELS);
}





#===================================================================
#           Tkg2 Explanation MetaPost Subroutines
#===================================================================
sub createExplanationTextMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  return unless($DOLABELS);

  my ($x,$y,$attr) = @_;
  ($x,$y) = coord2MetaPost($x,$y);

  my $tmp    = text2MetaPost_text($attr->{-text});
  if($tmp->{-error}) { return }
  my $text   = $tmp->{-text};
  my $angle  = angle2MetaPost($attr->{-angle});
  my $color  = color2MetaPost($attr->{-fill});
  my $blankcolor = color2MetaPost($attr->{-blankcolor});
  my $suffix = textanchor2MetaPost($attr->{-anchor});
  my $family = textfamily2MetaPost($attr->{-family});
  my $size   = textsize2MetaPost($attr->{-size});
  my $weight = textweight2MetaPost($attr->{-weight});
  my $slant  = textslant2MetaPost($attr->{-slant});
  my $blankit = $attr->{-blankit};
  my $shift  = "(0u,0u)";

  print $::MP "picture pic;\n";
  print $::MP "pic:=thelabel$suffix (btex\n",
              "$family $weight $size $slant\n $text ",
              "etex,($x,$y));\n";
  print $::MP "% special line\n";
  print $::MP "addto explanation also pic rotatedabout ((center pic), $angle) shifted $shift withcolor $color;\n" unless($color eq "none");
  print $::MP "dotlabel (\"\",($x,$y));\n" if($DOTLABELS);
}


sub beginExplanationMetaPost {
  $SPECIAL_PIC = "explanation";
  print $::MP "% BEGIN EXPLANATION\n";
  print $::MP "picture explanation; explanation := nullpicture; picture pic;\n";
}

sub endExplanationMetaPost {
  my ($attr) = @_;
  my $width = width2MetaPost($attr->{-width});
  my $color = color2MetaPost($attr->{-outline});
  my $dash  = dash2MetaPost($attr->{-dash});
  my $blankcolor = color2MetaPost($attr->{-fill});
  print $::MP "pickup pencircle scaled $width; linecap:=butt; linejoin:=beveled;\n"; 
  print $::MP "fill bbox explanation withcolor $blankcolor;\n";
  print $::MP "draw bbox explanation $dash withcolor $color;\n" unless($color eq "none");
  print $::MP "draw explanation;\n";
  print $::MP "% END EXPLANATION\n";
  $SPECIAL_PIC = 0;
}



#===================================================================
#           Perl/Tk to MetaPost Translation Utilities
#===================================================================
sub color2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  #my $depth = $::MW->depth;
  #print STDERR "DEPTH = $depth\n";
  my $tkcolor = shift;
  return("none") if(not defined $tkcolor or $tkcolor eq "none");
  
  my $color;

  my ($rc,$gc,$bc) = $::MW->rgb("white");
  #print STDERR "$rc $gc $bc\n";
  my ($red, $green, $blue) = ("none", "none", "none");
     ($red, $green, $blue) = $::MW->rgb($tkcolor) unless($tkcolor eq "none");
  #print STDERR "COLOR:   $red, $green, $blue\n";
  my ($r,$g,$b) = ($red/$rc,$green/$gc,$blue/$bc);
  #print STDERR "$r,$g,$b\n";

  # CMYK: 
  #my @tmp = sort ($r,$g,$b);
  #my $k = $tmp[0];
  #my ($c,$m,$y) = ($b-$k,$r-$k,$g-$k);
  #my $cymk = "($c,$m,$y,$k)";
  
  $color = "($r,$g,$b)";
  #$color = $cymk;
  #print STDERR "color2MetaPost $tkcolor ---> $color\n";
  return($color);
}

sub width2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $tkwidth = shift;
  return("1pt") if(not defined $tkwidth); # emergency bailout
  my $width = ($tkwidth =~ /i/) ? $tkwidth."n" : "1pt"; # 1pt emergency default
  return($width);
}

sub capstyle2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $cap = shift;
  return("rounded") if(not defined $cap);
  my $mp = ($cap eq "butt")       ? "butt"    :
           ($cap eq "projecting") ? "squared" : "rounded"; # default round
  return($mp);
}


sub textanchor2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  my $anchor = shift;
  return("") if(not defined $anchor);
  my $suffix = ($anchor eq "s")  ? ".top"  :
               ($anchor eq "n")  ? ".bot"  :
               ($anchor eq "w")  ? ".rt"   :
               ($anchor eq "e")  ? ".lft"  :
               ($anchor eq "se") ? ".ulft" :
               ($anchor eq "sw") ? ".urt"  :
               ($anchor eq "nw") ? ".lrt"  :
               ($anchor eq "ne") ? ".llft" : "";
  return($suffix);
}

sub textfamily2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $family = shift;
  return("\\rmfamily") if(not defined $family);
  my $mp = ($family =~ /Helvetica/io) ? "\\sffamily" :
           ($family =~ /Times/io)     ? "\\rmfamily" :
           ($family =~ /Courier/io)   ? "\\ttfamily" : "\\rmfamily";
  return($mp);
}

sub textsize2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $size = shift;
  return("\\fontsize{10}{11.04}\\selectfont") if(not defined $size);
  my $sizel = $size."pt";
  my $sizeb = $size*1.04."pt";
  my $mp = "\\fontsize{$sizel}{$sizeb}\\selectfont";
  return($mp);
}



sub textslant2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $slant = shift;
  return("") if(not defined $slant);
  my $mp = ($slant =~ /italic/io) ? "\\slshape" : "";
  #print "METAPOST slant $mp\n";
  return($mp);
}



sub textweight2MetaPost {
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $weight = shift;
  return("\\mdseries") if(not defined $weight);
  my $mp = ($weight =~ /bold/io) ? "\\bfseries" : "\\mdseries";
  return($mp);
}




sub dash2MetaPost { # See Tkg2::Base::getDashList
#  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my $dash = shift;
  return("") if(not defined $dash);
  my $mp = ($dash eq 'Solid')   ? ""                       :
           ($dash eq '--')      ? "dashed evenly"          : 
           ($dash eq '- -')     ? "dashed evenly scaled 2" : 
           ($dash eq '- - ')    ? "dashed evenly scaled 3" :
           ($dash eq '-  -')    ? "dashed evenly scaled 4" :
           ($dash eq '-  -  ')  ? "dashed dashpattern(on 4pt off 6pt on 4pt off 12pt)" :
           ($dash eq '-  --')   ? "dashed withdots" :
           ($dash eq '-.-.')    ? "dashed dashpattern(on 4pt off 3pt on 2pt off 3pt on 4pt)" :
           ($dash eq '.')       ? "dashed withdots"        : "";
  return($mp);
}



sub text2MetaPost_text {
  my $text = shift;
  $text =~ s/^\s+//; $text =~ s/\s+$//;
  return({-text => $text, -error => 1}) if(not defined $text or $text eq "");
  return({-text => "HELLO WORLD", -error => 0}) if($HELLOWORLD);
  if($CLEANTEX) {
    $text =~ s|/|\\slash |g;
    $text =~ s|_|\{\\_\}|g;
    $text =~ s|\#|\\\#|g;
    $text =~ s|\%|\\\%|g;
  }
  return({-text => $text, -error => 0});
}


sub angle2MetaPost {
  my $angle = shift;
  return(0) if(not defined $angle);
  return($angle);
}

sub coord2MetaPost {
  my ($x,$y) = @_;
  $x = sprintf("%0.3f",$x)."u";
  $y = sprintf("%0.3f",-$y)."u";
  return($x,$y);
}


sub RenderMetaPost {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

  my ($template, $canv, $options) = @_;

  my $dolabelsref   = \$Tkg2::DeskTop::Rendering::RenderMetaPost::DOLABELS;
  my $dotlabelsref  = \$Tkg2::DeskTop::Rendering::RenderMetaPost::DOTLABELS;
  my $helloworldref = \$Tkg2::DeskTop::Rendering::RenderMetaPost::HELLOWORLD;
  my $offset_mark   = \$Tkg2::DeskTop::Rendering::RenderMetaPost::OUTSETMARK;
  my $cleantex      = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANTEX;
  my $spawn         = \$Tkg2::DeskTop::Rendering::RenderMetaPost::SPAWN_MPOST;
  my $cleanup       = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANUP;
  my $cleanupmp     = \$Tkg2::DeskTop::Rendering::RenderMetaPost::CLEANUP_THE_MPFILE;


  my $set_zoom_to_one = 1;
  if($set_zoom_to_one and $::TKG2_CONFIG{-ZOOM} != 1) {
    # If the user wants to reset the zoom to one
    # for the postscript rendering and the current
    # zoom is not already one, then set zoom to one
    # update the canvas and proceed with drawing
    local $::TKG2_CONFIG{-ZOOM} = 1;
    $template->UpdateCanvas($canv);
  }
  else {
    # the toggle is set to zero so that we can 
    # trigger the final UpdateCanvas to restore
    # the canvas to the original --zoom setting.
    $set_zoom_to_one = 0;
  }

  my $tw = $canv->parent;
  my $tkg2file = $template->{-tkg2filename};
  my $file = "";
  if(not defined $tkg2file) {
    my $mess = "The tkg2 graphic has not yet been saved, so the MetaPost\n".
               "process can not begin because no file name can be made.\n".
               "for the external processing steps of MetaPost. Please\n".
               "save the tkg2 graphic from the FILE menu and try again.";
    &Message($tw,'-generic', $mess);
    return;
  }
  else {
    $file .= "$tkg2file.mp";
    print $::VERBOSE "Tkg2 to MetaPost: Tkg2 is beginning to build metapost file: $file\n";
  }

  print $::VERBOSE "Tkg2 to MetaPost: Tkg2 is unlinking $file if exists\n";
  unlink($file);

  $::MP = &routeMetaPost($file);
  open($::MP, ">$file") or
     die print STDERR "Tkg2 Error--MP (MetaPost channel not opened ",
                      "as $file because $!\n";
  print $::VERBOSE "Tkg2 to MetaPost: MetaPost calls have been rerouted to an actual file handle.\n";


  # BEGIN METAPOST FILE GENERATION
  print $::MP "% Begination of $file\n";
  &corePreambleMetaPost($::TKG2_ENV{-SCALING});
  &fontPreambleMetaPost();
  $template->{-metapost} = 1;
  my ($w,$h) = ($canv->cget(-width),$canv->cget(-height));
  createCanvasBackgroundMetaPost(0,0,$w,0,$w,$h,0,$h,{-fill => $template->{-color}});
  createOffsetMarkMetaPost();
                
  $template->UpdateCanvas($canv);
  $template->{-metapost} = 0;
                
  &corePostambleMetaPost();
  print $::MP "% Termination of $file\n";                
  close($::MP);
  $::MP = &routeMetaPost(); # back to /dev/null

  print $::VERBOSE "Tkg2 to MetaPost: MetaPost calls have been rerouted to /dev/null\n";

  if($spawn) {
    my $com1 = "mpost $file";
    print $::VERBOSE "\n EXTERNAL_COMMAND: $com1\n\n";
    system("mpost $file"); # MetaPost Experiment
    my $com2 = "mptopdf $file";
    print $::VERBOSE "\n EXTERNAL_COMMAND: $com2\n\n";
    system("$com2"); # MetaPost Experiment
  }
  cleanupFilesMetaPost($template->{-tkg2filename});
                
  print $::VERBOSE "=================================================\n".
                   "Tkg2 to MetaPost: auxillary files potentially have been deleted.\n";

  $template->UpdateCanvas($canv) if($set_zoom_to_one);
  rename("$tkg2file-1.pdf","$tkg2file.pdf");
}



1;
