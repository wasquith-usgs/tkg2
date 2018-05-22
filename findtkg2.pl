#!/usr/bin/perl -w
die "findtkg2.pl: No pattern for matching given\n" unless(@ARGV);
$p    = shift;
$find = "find Tkg2 -name '*.pm' -type f -exec ";
if($p =~ m/-lwc/io) {
   $code = '@_=split(/\s+/); $l+=$_[1];$w+=$_[2];$c+=$_[3]; '.
           'END{print "\nLines=$l\nWords=$w\nChar=$c\n\n"}';
   $code = "wc {} \\; | perl -n -e '$code'";
}
else {
   $code = "print \"-!- \$ARGV:\n \$_\" if(/$p/)";
   $code = "perl -n -e '$code' {} \\;";        
}
system("$find $code");
