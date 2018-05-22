#!/usr/local/bin/perl -w
use strict;                             # all variables must be declared
use Getopt::Std;                        # import the getopts method
use ExtUtils::Installed;                # import the package

use vars qw($opt_l $opt_s);             # declaring the two option switches
&getopts('ls');                         # $opt_l and $opt_s are set to 1 or 0
unless($opt_l or $opt_s) {              # unless one switch is true (1)
  die "pmods: A utility to list all installed (nonstandard) modules\n",
      "  Usage: pmods.pl -l  # list each module and all its directories\n",
      "         pmods.pl -s  # list just the module names\n";
}

my $inst  = ExtUtils::Installed->new(); # a new installed object
foreach my $mod ( $inst->modules() ) {  # foreach of the installed modules
  my $ver = $inst->version($mod);       # version number of the module
     $ver = ($ver) ? $ver : 'NONE';     # for clean operation
  print "MODULE: $mod version $ver\n";  # print module names
  map { print "  $_\n" } $inst->directories($mod) if($opt_l);
}

__END__
