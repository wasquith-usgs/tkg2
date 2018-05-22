#!/usr/bin/perl -w
use File::Copy;
use File::Spec;
use File::Path;
my $rel     = 'latest';
my $dir     = '/usr/local/';
my $bindir  = '/usr/local/bin/';
my $target  = '# REMOVE COMMENT FOR DAVID BOLDT RPM '; 
my $time    = localtime;

my $tar    = ($^O =~ /linux/)                     ? '/bin/tar'            : 
             ($^O eq 'darwin')                    ? '/usr/bin/tar'        :
	                                            '/usr/bin/tar';
my $gzip   = ($^O =~ /linux/ or $^O eq 'darwin')  ? '/usr/bin/gzip'       :
                                                    '/usr/opt/bin/gzip';
my $gunzip = ($^O =~ /linux/ or $^O eq 'darwin')  ? '/usr/bin/gunzip'     :
                                                    '/usr/opt/bin/gunzip';
my $homedir = ($^O =~ /linux/)  ? '/home/wasquith/tkg2' :
              ($^O eq 'darwin') ? '/Users/wasquith'     :
                                  '/u/wasquith/tkg2';


print "Tkg2: RPM overwrite in preparation for new RPM build\n";
print "  Do you want to continue?\n";
my $go = <STDIN>;
exit unless($go =~ m/y/io);

print "Tkg2-Simple install into $dir of VERSION $rel\n";

# Remove the tkg2.log file from /tmp as this is a whole new installation
#unlink("/tmp/tkg2.log");

$g = `pwd`;
print "Currently in $g";


# Need to take the tkg2.pl file and perform a substitution on
# the $target line so that the proper installation directory
# becomes available.
print "Converting tkg2.pl to tkg2.g2\n";
print "tkg2.g2 will be the executable\n";
open(INFH, "<Tkg2/tkg2.pl") or die "Could not open tkg2.pl: $!\n";
   open(OTFH, ">Tkg2/tkg2.g2") or die "Could not open tkg2.g2: $!\n";
      while(<INFH>) {
         s/$target// if(/$target/);
         s/INSERT LOCALTIME RESULT/$time/;
         print OTFH;
      }   
   close(OTFH);
close(INFH);
chmod 0755, 'Tkg2/tkg2.g2';

print "     Archiving\n";
$g = unlink("tkg2-$rel.tar.gz");     &p($g);
$g = `$tar -cvf tkg2-$rel.tar Tkg2`; &p($g); 
$g = `$gzip tkg2-$rel.tar`;          &p($g);

print "     Installing in $dir as ";
my $dest = File::Spec->catfile($dir,"tkg2-$rel.tar.gz");
print "$dest\n";
&copy("tkg2-$rel.tar.gz", $dest) or die "No copy because $!\n";

chdir("$dir") or die "Could not change to $dir because $!";
$g = `pwd`;
print "Currently in $g\n";

#&rmtree("Tkg2",1,0); # remove the whole directory tree
unlink("tkg2-$rel.tar");  # incase a bailout on last install
$g = `$gunzip tkg2-$rel.tar.gz`; &p($g);
$g = `$tar -xvf tkg2-$rel.tar`;  &p($g);

unlink("tkg2-$rel.tar");
unlink($bindir."tkg2");

# Build the aliases in something like /usr/local/bin
# This is the main tkg2 command
$command = "$dir"."Tkg2/tkg2.pl $bindir"."tkg2";
print "Building the softlink $command\n";
$g = `ln -s $command`;                           &p($g);
# work on the utilities
if($^O ne 'darwin') {
foreach my $util (qw(outwat2rdb.pl
                     get_nonzero_from_rdb.pl
                     sumtkg2log.pl
                     daysbetween.pl
                     checktkg2time.pl
                     UVgetem.pl
                     UVlastwk.pl
                     UVgetpor.pl
                     DVgetem.pl
                     DVgetpor.pl
                     DVlastwk.pl
                     gwsi_std2rdb.pl
                     dtgaprdb.pl
		     fastgaprdb.pl
                     rdb_dt2d_t.pl
                     rdb_ymd2d_t.pl
                     rdbtc.pl)) {
  unlink($bindir."$util");
  $command = "$dir"."Tkg2/Util/$util $bindir"."$util";
  $g = `ln -s $command`;                         &p($g);
}
# work on the premades
foreach my $premade (qw(tkg2p2.pl
                        tkg2p3.pl
                        tkg2p4.pl
                        tkg2pd2.pl
                        tkg2pd3.pl
                        tkg2pd4.pl)) {
  unlink($bindir."$premade");
  $command = "$dir"."Tkg2/Util/PreMades/$premade $bindir"."$premade";
  $g = `ln -s $command`;                         &p($g);
}
} # end of darwin test
$g = `pwd`;
print "Still in $g\n";
rename("Tkg2/tkg2.g2","Tkg2/tkg2.pl");
chmod 0777, "Tkg2/Time/TimeCache";
chmod 0666, "Tkg2/Time/TimeCache/dumped_time_cache";

chdir("$homedir") or die "Could not change to $homedir because $!";
$g = `pwd`;
print "Now in $g\n";
unlink("Tkg2/tkg2.g2");

unlink("tkg2-$rel.tar.gz");
print "\a\a\a";

sub p { print shift() } # cute little printing subroutine
