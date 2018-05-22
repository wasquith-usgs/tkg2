#!/usr/bin/perl -w 
=head1 LICENSE

 This Perl Program program is authored by the enigmatic William H. Asquith.
     
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

=head1 DESCRIPTION

This program is intended to act as editor to simplify and standardize
the manual entry of dive logs for USGS employees.

=cut

# $Author: wasquith $
# $Date: 2003/07/18 19:43:41 $
# $Revision: 1.4 $

use strict;
use Tk;

use Text::Wrap qw(wrap);
   $Text::Wrap::columns = 67;

our $MW;
our ($DiverName) = ("");
our ($Date, $Time, $Location, $Site) = ("", "", "", "");
our ($AltRange, $IS_AltRange_in_meters, $DiverInterval) = ("", 1, "");
our ($Weather, $AirTemp, $IS_AirTemp_in_C) = ("", "", 1);
our ($DiveSuit, $TankSize) = ("", "");
our ($MaxDepth, $IS_MaxDepth_in_meters, $DiveTime) = ("", 0, "");
our ($MinTemp, $IS_MinTemp_in_C, $AirConsumption, $Visibility) = ("", 1, "", "");
our ($DiveType, $DiveActivities, $Alarms, $DivePartners) = ("", "", "", "");
our ($RemarksFieldWidget, $DiveRemarks, $DiveComputerUsed) = (undef, "", 1);
our ($Message) = "";

eval {  # Make sure that a connection to the X server can be made.
  $MW = MainWindow->new(-title => 'DiveIt: USGS Manual Dive Log Software V1.4');
};
if($@) { # this traps segmentation faults
  print STDERR "#########################################\n",
               "diveit.pl: X-server Connection Error\n   $@\n",
               "  % xhost +'your server name'\n",
               "on your client will likely fix things\n",
               "#########################################\n";
  exit;
} 

my @f = (-font => 'Courier 10');

my @ALTRANGES = ('   0..3000ft','3000..6000ft','6000..9000ft','9000..120000ft',
                 '   0.. 914m', ' 914..1830m', '1830..2740m', '2740..3660m');
my @altranges = ();
foreach my $val (@ALTRANGES) {
  my $are_meters = ($val =~ /m/) ? 1 : 0;
  my $newval = $val;
     $newval =~ s/ft|m//;
     $newval =~ s/\s+//g;
  if($are_meters) {
    push(@altranges,  [ 'command' => "$val", @f,
                        -command  => sub { $AltRange = "$newval"; 
                                           $IS_AltRange_in_meters = 1; } ]);
  }
  else {
    push(@altranges,  [ 'command' => "$val", @f,
                        -command  => sub { $AltRange = "$newval"; 
                                           $IS_AltRange_in_meters = 0; } ]);
  }
}


my @SUITTYPES = ('no suit', 'wet suit');
my @suittypes = ();
foreach my $val (@SUITTYPES) {
  push(@suittypes,  [ 'command' => "$val", @f,
                      -command  => sub { $DiveSuit = "$val"} ]);
}
my @WEATHERTYPES = ('clear', 'sunny', 'partly cloudy', 'cloudy', 'overcast',
                    'rain',  'drizzle', 'fog', 'snow', 'ice');
my @weathertypes = ();
foreach my $val (@WEATHERTYPES) {
  push(@weathertypes, [ 'command' => $val, @f,
                        -command  => sub { $Weather = "$val"} ]);
}
my @DIVETYPES = ('no stop','decompression','multiple decompression','not known');
my @divetypes = ();
foreach my $val (@DIVETYPES) {
  push(@divetypes, [ 'command' => $val, @f,
                     -command  => sub { $DiveType = "$val"} ]);
}

my @VISIBILITYTYPES = ('excellent', 'good', 'fair', 'poor',
                       'arms length', 'none', 'infinite', );
my @visibilities = ();
foreach my $val (@VISIBILITYTYPES) {
  push(@visibilities, [ 'command' => $val, @f,
                        -command  => sub { $Visibility = "$val"} ]);
}

&MainDialog($::MW);     # build the classic first dialog of an application
&RestoreValues(shift(@ARGV)) if(@ARGV);
&MainLoop;  # LAUNCH THE TK EVENT LISTENER, AMONG MANY OTHER THINGS

### SUBROUTINES ###
sub MainDialog {
  my $mw = shift;
  my @b = (-background => 'White');
  my @rgbw = (-relief => 'groove', -borderwidth => 3);
  my @e = (-expand => 1);
  my $pe = $mw->Frame->pack(-side => 'top', -fill => 'x');
  my $ft = $pe->Frame->pack(-side => 'top', -fill => 'x');
     $ft->Label(-text => 'Diver Name:', @f)
        ->pack(-side => 'left', -fill => 'x');
     $ft->Entry(-textvariable => \$DiverName, @b, @f, -width => 40)
        ->pack(-side => 'left');
     $ft->Checkbutton(-text => 'dive computer used?', @f,
                      -variable => \$DiveComputerUsed,
                      -onvalue => 1, 
                      -offvalue => 0)->pack(-side => 'left');
  my $f1     = $pe->Frame->pack(-side => 'top', -fill => 'x');
  my $f1_1   = $f1->Frame(@rgbw)->pack(-side => 'left', -fill => 'x', @e);
  my $f1_2   = $f1->Frame(@rgbw)->pack(-side => 'right', -fill => 'x', @e);
  my $f1_1_1 = $f1_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f1_1_2 = $f1_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f1_2_1 = $f1_2->Frame->pack(-side => 'top', -fill => 'x');
  my $f1_2_2 = $f1_2->Frame->pack(-side => 'top', -fill => 'x');
     $f1_1_1->Label(-text => 'Date:', @f)
            ->pack(-side => 'left', -anchor => 'w');
     $f1_1_1->Entry(-textvariable => \$Date, @b, @f,-width => 16)
            ->pack(-side => 'left');  
 
    $f1_1_2->Label(-text => 'Time:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f1_1_2->Entry(-textvariable => \$Time, @b, @f, -width => 16)
            ->pack(-side => 'left');  
 
     $f1_2_1->Label(-text => ' Location:',@f)
            ->pack(-side => 'left');
     $f1_2_1->Entry(-textvariable => \$Location, @b, @f,)
            ->pack(-side => 'left', -fill => 'x', @e);   

     $f1_2_2->Label(-text => '     Site:',@f)
            ->pack(-side => 'left');
     $f1_2_2->Entry(-textvariable => \$Site, @b, @f)
            ->pack(-side => 'left', -fill => 'x', @e);   

  my $f2     = $pe->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_1   = $f2->Frame(@rgbw)->pack(-side => 'left', -fill => 'x');
  my $f2_2   = $f2->Frame(@rgbw)->pack(-side => 'right', -fill => 'both', @e);
  my $f2_1_1 = $f2_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_1_2 = $f2_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_1_3 = $f2_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_2_1 = $f2_2->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_2_2 = $f2_2->Frame->pack(-side => 'top', -fill => 'x');
  my $f2_2_3 = $f2_2->Frame->pack(-side => 'top', -fill => 'x');

     $f2_1_1->Label(-text => 'Altitude Range:', @f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_1_1->Entry(-textvariable => \$AltRange, @b, @f, -width => 12)
            ->pack(-side => 'left');
     $f2_1_1->Menubutton(-text => "?", @f,
                         -indicator    => 0,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @altranges ], )
            ->pack(-side => 'left');
     $f2_1_1->Radiobutton(-text => 'm/ft', @f,
                          -variable => \$IS_AltRange_in_meters,
                          -value    => 1 )
            ->pack(-side => 'left');
     $f2_1_1->Radiobutton(-text => '', @f,
                          -variable => \$IS_AltRange_in_meters,
                          -value    => 0 )
            ->pack(-side => 'left');  

     $f2_1_2->Label(-text => ' Dive Interval:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_1_2->Entry(-textvariable => \$DiverInterval, @b, @f,
                    -width => 12)->pack(-side => 'left');
     $f2_1_2->Label(-text => 'hrs (if ##)',@f)
            ->pack(-side => 'left' );
 
     $f2_1_3->Label(-text => 'Dive Suit Type:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_1_3->Entry(-textvariable => \$DiveSuit, @b, @f, -width => 12)
            ->pack(-side => 'left');
     $f2_1_3->Menubutton(-text => "?", @f,
                         -indicator    => 0,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @suittypes ], )
            ->pack(-side => 'left');

     $f2_2_1->Label(-text => ' Tank Size:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_2_1->Entry(-textvariable => \$TankSize, @b, @f, -width => 6)
            ->pack(-side => 'left');
     $f2_2_1->Label(-text => 'cubic feet',@f)
            ->pack(-side => 'left', -anchor => 'w');

     $f2_2_2->Label(-text => ' Air Temp.:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_2_2->Entry(-textvariable => \$AirTemp, @b, @f,
                    -width => 6)->pack(-side => 'left');
     $f2_2_2->Radiobutton(-text => 'C/F', @f,
                          -variable => \$IS_AirTemp_in_C,
                          -value    => 1 )
            ->pack(-side => 'left');
     $f2_2_2->Radiobutton(-text => '', @f,
                          -variable => \$IS_AirTemp_in_C,
                          -value    => 0 )
            ->pack(-side => 'left');
  
     $f2_2_3->Label(-text => '   Weather:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f2_2_3->Entry(-textvariable => \$Weather, @b, @f, -width => 19)
            ->pack(-side => 'left', -fill => 'x');       
     $f2_2_3->Menubutton(-text => "?", @f,
                      -indicator    => 0,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @weathertypes ], )
            ->pack(-side => 'left');

  my $f3     = $pe->Frame->pack(-side => 'top', -fill => 'x');
  my $f3_1   = $f3->Frame(@rgbw)->pack(-side => 'left', -fill => 'x');
  my $f3_2   = $f3->Frame(@rgbw)->pack(-side => 'right', -fill => 'both', @e);
  my $f3_1_1 = $f3_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f3_1_2 = $f3_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f3_1_3 = $f3_1->Frame->pack(-side => 'top', -fill => 'x');
  my $f3_2_1 = $f3_2->Frame->pack(-side => 'top', -fill => 'x', @e);
  my $f3_2_2 = $f3_2->Frame->pack(-side => 'top', -fill => 'x', @e);
  my $f3_2_3 = $f3_2->Frame->pack(-side => 'top', -fill => 'x', @e);

     $f3_1_1->Label(-text => 'Dive Type:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_1_1->Entry(-textvariable => \$DiveType, @b, @f, -width => 20)
            ->pack(-side => 'left', -fill => 'x');  
     $f3_1_1->Menubutton(-text => "?", @f,
                         -indicator    => 0,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @divetypes ], )
            ->pack(-side => 'left');

     $f3_1_2->Label(-text => 'Maximum Depth:', @f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_1_2->Entry(-textvariable => \$MaxDepth, @b, @f,
                    -width => 12)->pack(-side => 'left');  
     $f3_1_2->Radiobutton(-text => 'm/ft', @f,
                          -variable => \$IS_MaxDepth_in_meters,
                          -value    => 1 )
            ->pack(-side => 'left');
     $f3_1_2->Radiobutton(-text => '', @f,
                          -variable => \$IS_MaxDepth_in_meters,
                          -value    => 0 )
            ->pack(-side => 'left'); 

     $f3_1_3->Label(-text => 'Minimum Temp.:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_1_3->Entry(-textvariable => \$MinTemp, @b, @f, -width => 12)
            ->pack(-side => 'left');  
     $f3_1_3->Radiobutton(-text => 'C/F ', @f,
                          -variable => \$IS_MinTemp_in_C,
                          -value    => 1 )
            ->pack(-side => 'left');
     $f3_1_3->Radiobutton(-text => '', @f,
                          -variable => \$IS_MinTemp_in_C,
                          -value    => 0 )
            ->pack(-side => 'left'); 
  
     $f3_2_1->Label(-text => '       Dive Time:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_2_1->Entry(-textvariable => \$DiveTime, @b, @f, -width => 10)
            ->pack(-side => 'left');   
     $f3_2_1->Label(-text => 'minutes',@f)
            ->pack(-side => 'left', -anchor => 'w');

     $f3_2_2->Label(-text => ' Air Consumption:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_2_2->Entry(-textvariable => \$AirConsumption, @b, @f, -width => 10)
            ->pack(-side => 'left');   
     $f3_2_2->Label(-text => 'psi',@f)
            ->pack(-side => 'left', -anchor => 'w');

     $f3_2_3->Label(-text => '      Visibility:',@f)
            ->pack(-side => 'left', -anchor => 'w');
     $f3_2_3->Entry(-textvariable => \$Visibility, @b, @f,
                    -width => 10)
            ->pack(-side => 'left');   
     $f3_2_3->Menubutton(-text => "?", @f,
                      -indicator    => 0,
                      -relief       => 'ridge',
                      -tearoff      => 0,
                      -menuitems    => [ @visibilities ], )
            ->pack(-side => 'left');

  my $f4   = $pe->Frame(@rgbw)->pack(-side => 'top', -fill => 'x');
  my $f4_1 = $f4->Frame->pack(-side => 'top', -fill => 'x');
  my $f4_2 = $f4->Frame->pack(-side => 'top', -fill => 'x');
  my $f4_3 = $f4->Frame->pack(-side => 'top', -fill => 'x');
  my $f4_4 = $f4->Frame->pack(-side => 'top', -fill => 'x');

  $f4_1->Label(-text => 'Activities:', @f)
       ->pack(-side => 'left', -anchor => 'w');
  $f4_1->Entry(-textvariable => \$DiveActivities, @b, @f)
       ->pack(-side => 'left', -fill => 'x', @e);

  $f4_2->Label(-text => '    Alarms:', @f)
       ->pack(-side => 'left', -anchor => 'w');
  $f4_2->Entry(-textvariable => \$Alarms, @b, @f)
       ->pack(-side => 'left', -fill => 'x', @e);

  $f4_3->Label(-text => '  Partners:', @f)
       ->pack(-side => 'left', -anchor => 'w');
  $f4_3->Entry(-textvariable => \$DivePartners, @b, @f)
       ->pack(-side => 'left', -fill => 'x', @e);
  
  $f4_4->Label(-text => '   Remarks:', @f)
       ->pack(-side => 'left', -anchor => 'w');
     $RemarksFieldWidget = $f4_4->Scrolled('Text', @f,
                            -scrollbars => 'se',
                            -width      => 63,
                            -height     => 3,
                            -background => 'white', )
                 ->pack(-side => 'left', -fill => 'x');

  my $f41 = $pe->Frame(@rgbw)->pack(-side => 'top', -fill => 'x');
  $f41->Label(-text => 'Message', -foreground => 'red', @f)
      ->pack(-side => 'left', -anchor => 'w');
  $f41->Label(-text => '(not dive related)', -foreground => 'red', @f)
      ->pack(-side => 'right', -anchor => 'w');
  $f41->Entry(-textvariable => \$Message,
              -background   => 'black',
              -foreground   => 'red',
              -relief       => 'raised', @f)
      ->pack(-side => 'left', -fill => 'x', @e);


  my $savesub =
     sub { return unless(&CheckFields());
           my $contents = &MakeContents;
           my $file =
              $mw->getSaveFile(-title => "Save Dive Log File",
                               -filetypes  => [ [ '*.gsdl', [ '*.gsdl' ] ],
                                                [ 'All Files',  [ '*'  ] ] ]);
           return unless(defined $file);
           $Message = "Saving: $file";
           $file .= ".gsdl" unless($file =~ /\.gsdl$/);
           &SaveValues($file);
         };
  my $opensub =
     sub { my $file =
              $mw->getOpenFile(-title => "Open Dive Log File",
                               -filetypes  => [ [ '*.gsdl', [ '*.gsdl' ] ],
                                                [ 'All Files',  [ '*'  ] ] ]);
           if(not defined $file) {
             $Message = "File name not defined--try again (possible bug)";
             return;
           }
           $Message = "Reading: $file";
           &RestoreValues($file);
         };
  my $exportsub =
     sub { return unless(&CheckFields());
           my $contents = &MakeContents;
           my $file =
              $mw->getSaveFile(-title => "Export Dive Log to Text File",
                               -filetypes  => [ [ '*.txt', [ '.txt' ] ],
                                                [ 'All Files', [ '*'] ] ]);
           return unless(defined $file);
           $file .= ".txt" unless($file =~ /\.txt$/);
           $Message = "Exporting: $file\n";
           open(FH,">$file") or die "$file not opened because $!\n";
           print FH $contents;
           close(FH);
         };
  my $printsub = sub { return unless(&CheckFields());
                       $Message = "Printing Contents";
                       my $contents = &MakeContents;
                       &MakePrintOut($contents);
                     };

  my $f5 = $pe->Frame(@rgbw)->pack(-side => 'top', -fill => 'x');
     $f5->Button( -text               => 'Save', 
                  -borderwidth        => 3,
                  -highlightthickness => 2,
                  -command            => $savesub )
        ->pack(-side => 'left');
     $f5->Button( -text               => 'Open',
                  -borderwidth        => 3,
                  -highlightthickness => 2,
                  -command            => $opensub )
        ->pack(-side => 'left');
     $f5->Button( -text               => 'Export as Text File',
                  -borderwidth        => 3,
                  -highlightthickness => 2,
                  -command            => $exportsub )
        ->pack(-side => 'left', -padx => 4, -pady => 2);
     $f5->Button( -text               => 'Print to Standard Output',
                  -borderwidth        => 3,
                  -highlightthickness => 2,
                  -command            => $printsub )
        ->pack(-side => 'left', -padx => 4, -pady => 2);
     $f5->Button(-text    => "Exit",
                 -command => sub { $mw->destroy; return; })
        ->pack(-side => 'right');
}


sub MakeContents {
   my $_computer = ($DiveComputerUsed) ? "A dive computer was used." :
                                         "A dive computer was not used.";

   my $_altrange = ($IS_AltRange_in_meters) ? "$AltRange meters" : 
                                              "$AltRange feet";
   my $_airtemp  = ($IS_AirTemp_in_C) ? "$AirTemp Celsius" :
                                        "$AirTemp Fahrenheit";
   
   my $_maxdepth = ($IS_MaxDepth_in_meters) ? "$MaxDepth meters" :
                                             "$MaxDepth feet";
   my $_mintemp  = ($IS_MinTemp_in_C) ? "$MinTemp Celsius" :
                                       "$MinTemp Fahrenheit";
   my $_remarks = $RemarksFieldWidget->get('0.0', 'end');
   chomp($_remarks);
   my $units = (&isNum($DiverInterval)) ? "hrs" : "";
   my $paragraph = wrap('','        ',$_remarks);

   my $string = <<HERE;
   DIVE LOG FILE for Diver: $DiverName
   -----------------------------------------------------------------------------   
    Site Information
     Date and Time: $Date at $Time
     Dive made at: $Location
             Site: $Site
   -----------------------------------------------------------------------------   
    Field Conditions
     Altitude Range: $_altrange
     Dive Interval: $DiverInterval $units
     Weather: $Weather with an air temperature of $_airtemp
     Visibility: $Visibility
     Dive Suit Type: $DiveSuit
     Tank Size: $TankSize cubic feet
   -----------------------------------------------------------------------------   
    Dive Statistics -- $_computer
     Maximum Depth: $_maxdepth
     Dive Time: $DiveTime minutes
     Minimum Temperature: $_mintemp
     Air Consumption: $AirConsumption pounds per square inch
     Dive Type: $DiveType
     Activities Performed: $DiveActivities
     Alarms: $Alarms
     Dive Team: $DivePartners
     Remarks: $paragraph
   -----------------------------------------------------------------------------   
   Signature(s):
   
   
   Date:
   -----------------------------------------------------------------------------   
HERE
1;
   return $string;
}


sub MakePrintOut {
   my $contents = shift;
   print "$contents";
}

sub RestoreValues {
  my $f = shift;
  do "$f" if(-e $f);
  chomp($DiveRemarks);
  $RemarksFieldWidget->delete('0.0','end');
  $RemarksFieldWidget->insert('0.0',$DiveRemarks);
}


sub SaveValues {
  my $f = shift;
  my $_remarks = $RemarksFieldWidget->get('0.0', 'end');

  local *FH;
  open(FH,">$f") or warn "SAVE: $f not opened because $!\n";

  print FH "# DIVE LOG STORAGE FILE FOR USGS PROGRAM\n",
           "# diveit.pl by William H. Asquith and Marcus O. Gary, Austin, Texas\n",
           "# initially developed in July 2003\n";

  print FH "\$DiverName        = '$DiverName';\n",
           "\$Date             = '$Date';\n",
           "\$Time             = '$Time';\n",           
           "\$Location         = '$Location';\n",
           "\$Site             = '$Site';\n",
           "\$AltRange         = '$AltRange';\n",
           "\$IS_AltRange_in_meters = '$IS_AltRange_in_meters';\n",
           "\$DiverInterval    = '$DiverInterval';\n",
           "\$Weather          = '$Weather';\n",
           "\$AirTemp          = '$AirTemp';\n",
           "\$IS_AirTemp_in_C  = '$IS_AirTemp_in_C';\n",
           "\$DiveSuit         = '$DiveSuit';\n",
           "\$TankSize         = '$TankSize';\n",
           "\$DiveComputerUsed = '$DiveComputerUsed';\n",
           "\$MaxDepth         = '$MaxDepth';\n",
           "\$IS_MaxDepth_in_meters = '$IS_MaxDepth_in_meters';\n",
           "\$DiveTime         = '$DiveTime';\n",
           "\$MinTemp          = '$MinTemp';\n",
           "\$IS_MinTemp_in_C  = '$IS_MinTemp_in_C';\n",
           "\$AirConsumption   = '$AirConsumption';\n",
           "\$Visibility       = '$Visibility';\n",
           "\$DiveType         = '$DiveType';\n",
           "\$DiveActivities   = '$DiveActivities';\n",
           "\$Alarms           = '$Alarms';\n",
           "\$DivePartners     = '$DivePartners';\n",
           "\$DiveRemarks      = '$_remarks';\n";  
  close(FH);
}

sub CheckFields {
  # true is returned on error so that the interface only
  # acts as a warning device only
  if(not &isNum($DiverInterval) and $DiverInterval ne "") {
     $Message = "Air temperature is not a number!";
     return 1;
  }
  if(not &isNum($AirTemp) and $AirTemp ne "") {
     $Message = "Air temperature is not a number!";
     return 1;
  }
  if(not &isNum($TankSize) and $TankSize ne "") {
     $Message = "Tank size is not a number!";
     return 1;
  }
  if(not &isNum($MaxDepth) and $MaxDepth ne "") {
     $Message = "Maximum depth is not a number!";
     return 1;
  }
  if(not &isNum($MinTemp) and $MinTemp ne "") {
     $Message = "Minimum temperature is not a number!";
     return 1;
  }
  if(not &isNum($AirConsumption) and $AirConsumption ne "") {
     $Message = "Air consumption is not a number!";
     return 1;
  }
  $Message = "";
  return 1;
}

sub isNum {
  my $v = shift;
  $v =~ /^[+-]?\d+\.?\d*$/o                 || 
    $v =~ /^[+-]?\.\d+$/o                   ||
      $v =~ /^[+-]?\d+\.?\d*[eE][+-]?\d+$/o || 
        $v =~ /^[+-]?\.\d+[eE][+-]?\d+$/o;
}
