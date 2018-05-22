# Count total number of lines in all files in a directory
perl -n -e '$a++;END{print"$a\n"}' *


find ../../Tkg2 -type f -exec wc {} \; | perl -n -e '@_=split(/\s+/); 
$l+=$_[1];$w+=$_[2];$c+=$_[3]; END{print "\nLines=$l\nWords=$w\nChar=$c\n\n"}'
