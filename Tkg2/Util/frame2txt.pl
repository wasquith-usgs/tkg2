#!/usr/bin/perl -w
# frame2txt.pl
#    A hand Perl script to convert Abobe FrameMaker files in their native
#    format to text files.  The fmbatch utility shipped with Unix FrameMaker
#    is required as it is the processing engine.
#
# LICENSE:
#
# This program is authored by the enigmatic 
#    William H. Asquith and Jennifer Lanning-Rush
#      USGS, Austin, Texas
#      
# This program is absolutely free software
#
# Authors of this software makes no claim whatsoever about suitability,
# reliability, editability or usability of this product. If you can use it,
# you are in luck, if not, we should not be and can not be held responsible.
#
# This software was developed by the Authors as an employees of the
# U.S. Geological Survey Water-Resources Division, neither the USGS,
# the Department of the Interior, or other entities of the Federal
# Government make any claim whatsoever about suitability, reliability,
# editability or usability of this product.
#
# NOTES:
#        The file names to process are listed under the __DATA__ token.
#        The easiest way to get a file name is to 'cd' into a directory
#        containing the framemaker files and then 'ls *.fm > doframe2txt.pl'
#        The 'frame2txt.pl' file now contains the file names to process.
#        Now copy the program listed here to the top of this file. Next,
#        'chmod 755 doframe2txt.pl' to make it executable.  Finally, simply
#        'doframe2txt.pl' will do the dirty work and .txt is appended to
#        the outputted text files.
#
# MORE NOTES: 
#    fmbatch is currently only available on the Unix side
#    fmbatch can open/import/print/save/update (see Frame help for more details)
#    fmbatch requires that the temp setting in .bash_profile be a valid path
#    in one's .bash_profile the following line sets the temp path
#      export TMPDIR=/home/userid/temp
#    Other suitable TMPDIR might be required for your system.

# PROGRAM: The program begins here.
my $confile = "frame2txt_control_file"; # file to be written in current dir.
while(<DATA>){ # read __DATA__
  print; chomp; # print the file that is being worked on, then remove newline
  open(FH,">$confile") or die "$confile not opened because $!\n";
  print FH "Open $_\n",
           "SaveAs a $_ $_.txt\n\n",
	        "Quit\n"; # build the control file open on FH
  close(FH); # close the filehandle, not formally required, but makes nice code
  system("fmbatch -v -makername maker $confile"); # hope fmbatch is on PATH
}
unlink($confile); # politely remove the control file
__DATA__
BH-65-29-802.fm
BH-65-30-601.fm
BH-65-30-603.fm
