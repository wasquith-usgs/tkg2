package Tkg2::DeskTop::CreateTemplate;

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
# $Revision: 1.21 $

use strict;
use Tkg2::Base;
use Exporter;
use SelfLoader;
use vars qw(@ISA @EXPORT_OK $EDITOR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(CreateTemplate CreateTemplateOnTheFly);

use Tkg2::Base qw(isNumber Message strip_space Show_Me_Internals);

print $::SPLASH "=";

1; 

#__DATA__

# CreateTemplateOnTheFly
# called only from DeskTop::Activities::ProcessOptions
# The first argument is the page dimensions of the template to build
#   such as 8.5x11 for an 8.5 inch by 11 inch sheet
# The second argument is optional and is an array reference of x
# delimited strings containing the left, right, top, and bottom margins
# in inches of the plot.  Any number of plots can be built on the fly.
# The subroutine ends by calling the AddDataToPlot dialog at which point
# the user is to specify all the usual plot configuration stuff.
# The command line arguments that are used are:
#   --mktemp=8.5x11 and --mkplot=1x1x1x1 etc
sub CreateTemplateOnTheFly {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($maketemp, $makeplot) = @_; # comandline arguments
   
   # l is for matching 'letter' and p is for matching portrait
   $maketemp = ($maketemp =~ /^p/io) ? '8.5x11' :
               ($maketemp =~ /^l/io) ? '11x8.5' : $maketemp;
   
   unless($makeplot) {
      my $template    = &_newTemplate('main',$maketemp);  # create the template
      my ($canv, $pe) = $template->StartTemplate();       #  start the template
      my $plot        = $template->AddPlot($canv,'onthefly'); # create the plot
      push(@{$template->{-plots}}, $plot);   # push plot ref on to the template
      
      # setup default margins, and convert to pixels
      $plot->{-xlmargin} = $pe->fpixels('1.75i');
      $plot->{-xrmargin} = $pe->fpixels('1i');
      $plot->{-yumargin} = $pe->fpixels('1i');
      $plot->{-ylmargin} = $pe->fpixels('2i');
      $plot->configwidth; # makes sure that the all the geometry parameters
                                # of the plot are consistent.
      $template->UpdateCanvas($canv);
     
      # call the AddDataToPlot dialog box
      $plot->{-dataclass}->AddDataToPlot($canv, $plot, $template, "DEFAULT");
     
      return;
   }
  
   # now that margins are set up, go about building a plot
   my $template    = &_newTemplate('main',$maketemp);
   my ($canv, $pe) = $template->StartTemplate();
  
   foreach my $eachplot (@$makeplot) {     
       
       my $plot        = $template->AddPlot($canv,'onthefly');
       push(@{$template->{-plots}}, $plot);
   
       my ($xlmargin, $xrmargin,$yumargin, $ylmargin);
       my @margins = split(/x/oi, $eachplot, 4);
       foreach my $margin (@margins) {
          if(not &isNumber($margin) ) {
             my $mess = "CommandLineError: At least one margin was not ".
                        "parsed into a number.  Tkg2 will be using defaults ".
                        "as necessary.  The margins before parsing: '@margins'";
             &Message($pe,'-generic',$mess);
             $margin = undef;  # undefine it, we catch it next
          }
       }
       # for the undefined margins, given em the defaults
       $xlmargin = ( defined $margins[0] ) ? $margins[0]."i" : '1.75i';
       $xrmargin = ( defined $margins[1] ) ? $margins[1]."i" : '1i'   ;
       $yumargin = ( defined $margins[2] ) ? $margins[2]."i" : '1i'   ;
       $ylmargin = ( defined $margins[3] ) ? $margins[3]."i" : '2i'   ;
       
       $plot->{-xlmargin} = $pe->fpixels($xlmargin);
       $plot->{-xrmargin} = $pe->fpixels($xrmargin);
       $plot->{-yumargin} = $pe->fpixels($yumargin);
       $plot->{-ylmargin} = $pe->fpixels($ylmargin);
       $plot->configwidth; # makes sure that the all the geometry parameters
                                 # of the plot are consistent.
                           
       $template->UpdateCanvas($canv);
       $plot->{-dataclass}->AddDataToPlot($canv, $plot, $template, $eachplot);
   }
}



sub CreateTemplate {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $font = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my ($px, $py) = (14, 4);
   
   my $template;
   my @dimensionoptions = qw(8.5x11 11x8.5 8.5x14 14x8.5 11x17);
   $EDITOR->destroy if(Tk::Exists($EDITOR) );
   my $tw = $::MW->Toplevel(-title => 'Create Tkg2 Template');
   $EDITOR = $tw;
   $tw->resizable(0,0);
   $tw->geometry("-0+100");
   my $f_t = $tw->Frame(-relief => 'groove')
                ->pack(-fill => 'x');
   my $lab1 = $f_t->Label(-text    => " New Template dimensions in inches ",
                          -font    => $font,
                          -justify => 'left')
                 ->pack(-side => 'top');

   my $f_lb = $tw->Frame(-relief => 'groove')
                 ->pack;
   my $lb_1 = $f_lb->Listbox(-background => 'white',
                             -font       => $font,
                             -selectmode => 'single')
                   ->pack(-side => 'right');
   $lb_1->insert('end',@dimensionoptions);
   $lb_1->selectionSet(1,1);
        
   my $f_cust = $tw->Frame()->pack(-fill => 'x');
   $f_cust->Label(-text => 'Custom Size: WWxHH in inches',
                  -font => $font)->pack(-side => 'top');
   my $custdim;
   my $entry1 = $f_cust->Entry(-textvariable => \$custdim,
                               -background   => 'white',
                               -font         => $font)
                       ->pack(-side => 'top');
   my $b_cust = $f_cust->Button(-text               => 'Custom Size', 
                                -font               => $font,
                                -borderwidth        => 3,
                                -highlightthickness => 2,
                  -command => sub {  $custdim = &strip_space($custdim);
                                     if($custdim !~ m/^\d+[xX]\d+$/) {
                                        &Message($tw,'-generic',
                                                      "Invalid Custom Dimensions\n");
                                        return;                  
                                     };
                                     $tw->destroy; 
                                     $template = &_newTemplate('main',$custdim);
                                     $template->StartTemplate;
                                     return;
                                   } )->pack(-side => 'top');
   
   # Set up and place the buttons at buttom of dialog box  I d                                 
   my @p = ( '-side', 'left', '-padx', "$px", '-pady', "$py" );
   my $f_b = $tw->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-fill => 'x');
                
   my $b_ok = $f_b->Button(-text               => 'OK',
                           -font               => $font,
                           -borderwidth        => 3,
                           -highlightthickness => 2,
                  -command => sub { my $stddim  = $lb_1->get($lb_1->curselection);
                                    $tw->destroy;
                                    $template = &_newTemplate('main',$stddim);
                                    $template->StartTemplate;
                                    return;
                                  } )
                  ->pack(@p);                  
   $b_ok->focus;
   
   $f_b->Button(-text    => "Cancel", 
                -font    => $font,
                -command => sub { $tw->destroy; } )
       ->pack(@p);
                        
   $f_b->Button(-text => "Help", 
                -font => $font,
                -padx => 4,
                -pady => 4,
                -command => sub { return; } )
       ->pack(@p);
}


sub _newTemplate {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($pkg, $dimensions) = (shift, shift);
   my ($w, $h) = $dimensions =~ m/([0-9.]+)[xX]([0-9.]+)/;
   my $self = { };
   $self->{-fileformat} = $::TKG2_CONFIG{-FILEFORMAT};
   $self->{-color}      = 'white';
   $self->{-width}      = $w;
   $self->{-height}     = $h;
   $self->{-needsaving} = 0;  # start at no so after first mandatory update it is yes
   $self->{-plots}      = [ ];
   $self->{-annotext}   = [ ];
   $self->{-annotext_plot_order} = 3;
   $self->{-annoline}   = [ ];
   $self->{-annoline_plot_order} = 1;
   $self->{-annobox}    = [ ];
   $self->{-annosymbol} = [ ];
   $self->{-annosymbol_plot_order} = 2;
   $self->{-draw_annotation_first} = 0;
   $self->{-postscript} = { -colormode => 'color',
                            -rotate    => 0,
                            -fontmap   => undef };
   $self->{-postscript}->{-rotate} = 1 if($w == 11 or $w == 14);
   $self->{-snap_to_grid} = 1;
   $self->{-x_grid}       = [ ];
   $self->{-y_grid}       = [ ];
   # set the scaling of the original creation
   my $scaling       = $::MW->scaling;
   $self->{-scaling} = $scaling;  
   $self->{-no_update_on_data_add} = 0;
   $self->{-metapost} = 0;
   return bless $self, $pkg;   
}


1;
