#!/usr/bin/perl -w
use Tk;
$MW = MainWindow->new;
$MW->withdraw;  # hide it
   
print "tkcheckres.pl:   X resolution is ",$MW->screenwidth,"\n",
      "                 Y resolution is ",$MW->screenheight,"\n",
      "               Scaling factor is ",$MW->scaling,"\n";
