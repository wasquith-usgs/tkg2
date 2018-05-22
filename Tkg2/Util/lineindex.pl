#!/usr/bin/perl -w
print STDERR
  "ERR: Program lineindex.pl by William H. Asquith\n",
  "ERR:   This program adds an index (line count) on the left-hand side\n",
  "ERR:   to each 'data' line of the file using a user specified\n",
  "ERR:   delimiter.  Lines beginning with # are not numbered and \n",
  "ERR:   the number of 'label' lines is not numbered either.\n",
  "ERR:   A column title called INDEX is added to each label line.\n",
  "ERR:   Example:  % lineindex.pl data.txt > data_index.txt\n",
  "ERR:\n",
  "ERR: Specify the file delimiter: ";
$delimiter = <STDIN>;
chomp($delimiter);
print STDERR "STDERR: Enter the number of label lines: ";
$labels = <STDIN>;
chomp($labels);
$labels = (not $labels) ? 1 : int($labels);
die "DIED: Bad number of label lines\n" if($labels < 0);


$n = 0;
while(<>) {
   print, next if(/^#/);
   print "INDEX",$delimiter,$_;
   $n++;
   last if($n == $labels);
}

$n=0;
while(<>) { $n++;  print $n,$delimiter,$_; }

__END__

=head1 LICENSE

 This utility is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software were developed by the Author as an
employee of the U.S. Geological Survey Water-Resources Division, neither
the USGS, the Department of the Interior, or other entities of the Federal
Government make any claim whatsoever about suitability, reliability,
editability or usability of this product.

=cut

# $Author: wasquith $
# $Date: 2002/05/02 17:52:00 $
# $Revision: 1.1 $
