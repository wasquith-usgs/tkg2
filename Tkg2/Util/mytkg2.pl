#!/usr/bin/perl
# ~wasquith/tkg2/Tkg2/Util/mytkg2.pl -- William H. Asquith, June 1, 2000
use  Net::FTP;   # provide access to ftp methods
use File::Path;  # import the &rmtree subroutine
my $i = 14;
sub p { print --$i,"-" }

my $tkg2 = "tkg2-latest.tar"; # the latest tkg2 version
my $exam = "examples.tar";
my $serv = '136.177.160.51';  # the anonymous ftp server
select((select(STDOUT), $| = 1)[0]); # autobuffering off

# Remove previous version--if applicable
unlink('myg2','epm');                     &p;
&rmtree("Tkg2",0,0);                      &p;

# Build FTP object and perform anonymous retrieval
$ftp = Net::FTP->new($serv);
die "\nUserID in shell variable 'USER' is undef\n" if(not defined $ENV{USER});
$ftp->login("anonymous",$ENV{USER});      &p;
$ftp->cwd("pub");                         &p;
$ftp->get("$tkg2.gz");                    &p;
$ftp->get("$exam.gz");                    &p;
$ftp->quit;                               &p;

die "\nNo $tkg2.gz retrieved\n"  if not -e "$tkg2.gz";
warn "\nNo $exam.gz retrieved\n" if not -e "$exam.gz";

# The complete paths for the utilities are
# specified so theoretically this can be used
# to install by a knowledgable superuser.
system("gunzip $tkg2.gz");   &p;
system("tar -xf $tkg2");         &p;
system("gunzip $exam.gz");   &p;
system("tar -xf $exam");         &p;

# Remove the tar file
unlink("$tkg2");                          &p;
unlink("$exam");                          &p;
# Make the new script executable
chmod(0755,'myg2','epm');                 print " done\n";

print "Note that the example files do not use dynamic loading of data.\n";

print "Starting myg2 up with an autoexit\n";
system("myg2 --autoexit");
print "Starting myg2 up with an glob on the example files ",
      "with a five second autoexit\n";
system("myg2 --verbose --glob=examp  -autoexit=5");
print "Starting myg2 up with a glob on the example files ",
      "in presenter mode\n";
system("myg2 --presenter --glob=examp");
print "Showing you some tkg2 help (see the help option)\n";
system("myg2 --help\n");
__END__

THE CUTTING EDGE OF TKG2 DEVELOPMENT

Tkg2 is a still evolving software application and is working to 
adapt to its users needs.  Therefore, keeping up to date on the
latest tkg2 version is unfortunately a difficult problem at best 
and will remain so for an unknown amount of time.

The good news is that periodically official tkg2 releases are made,
and an RPM is made for USGS computer users.  There is a committment
by the tkg2 devlopers to support backwards compatability with the
officially released versions--at least until it becomes unmanagable.
The tkg2 core is in advanced beta, so backwards compatability is
not a big concern.

For the adventurous individual, there is a simple way to live on
the cutting edige of tkg2 development and always have the latest
tkg2 version.  There are many advantages for both the user and
perhaps more importantly, the tkg2 developers when users take it
upon themselves to try out the last versions.

First, users get to take advantage of the latest features,
enhancements, and perhaps more importantly the bug fixes.  Second,
users are continuously contributing to a better tkg2 product by
identifying bugs, loose ends, suggesting features or alternative
behaviors.  Third, the tkg2 developers benefit because as the
number of eyes on the software interface and source code increases
bugs are shallow.  Fourth, you are even free to patch your own
source code into the project or to fork the tkg2 source code for
your own purposes.

In the traditional world of software development, staying current
with the latest version is nearly impossible.  However, tkg2
development follows the increasingly popular open-source development
model in which releases are made fast, furious, and often.  It has
not been unusual for the tkg2 development team to post serveral 
times a day to the host ftp server.  According, they have made it
a snap to stay on the cutting edge.  With the simple utility,
myg2.pl.  Myg2.pl can be downloaded from LINK<here>, and LINK<here>
is what the myg2.pl source code looks like.

Myg2.pl connects to an ftp server, downloads the latest posted
tkg2 version archive, unzips the archive, cleans up after itself,
and then actually launches tkg2 for you by calling './myg2'.
WARNING -- myg2.pl will delete the following files from your current
directory, myg2, epm, and recursively delete a Tkg2/ directory.
Myg2.pl will then install the latest versions of ./myg2, ./epm, and
./Tkg2/.

The Tkg2 directory contains the tkg2 distribution and ./Tkg2/tkg2.pl
is the executable.  The @INC for tkg2.pl however is set for execution
in the directory above, so ./myg2 is the executable that you want to
use.  Epm is the source code organizer that WHA uses for source code
editing.  You are welcome to use ./epm to view, modify, and test the
source code.  A global variable in ./epm, $EDITOR, is set to nedit,
but your favorite editor could easily be inserted or set when ./epm
is run.  For example, ./epm emacs, ./epm vi, ./emp xemacs.

Good Luck.

William H. Asquith
