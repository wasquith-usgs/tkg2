        tkg2.pl - The ultimate 2-D charting application?

Welcome to a Perl/Tk based charting and data visualization progrom.

This Tkg2 program is authored by the enigmatic William H. Asquith.


HOST ENVIRONMENT

tkg2.pl runs exclusively under X11.app. It is an X-windows program. You must have this program for operation. Tkg2 will not run from the Terminal.app as this terminal does not attach to an X-server.


PROGRAM LOCATION

The program /usr/local/bin/tkg2 is a softlink to the real program /usr/local/Tkg2/tkg2.pl in which tkg2.pl has been configured to find its libraries at /usr/local/Tkg2. You will need /usr/local/bin on your $PATH to execute 'tkg2' from the command line.

PERL AND PERL MODULES NEEDED TO RUN

To maintain cross-platform compatibility, it is assumed that operational version of perl is available on /usr/bin/perl.

tkg2.pl is a perl script and the written *.tkg2 files are themselves perl scripts. A limited number of nonstandard perl modules will have to be installed prior to running the Installer. However, the preflight script of the Installer does check for presence of these modules so the log file will help guide you to problems. The Installer DOES NOT modify your Perl installation.

Other versions might work, but these are tested

Tk800.025+?
Data-Calc-4.3
DateManip-5.39  required 5.39 or better
Tk::Pod 3.15  (has a tkpod reader!!!)

These packages might have dependencies not listed here. The simple method of package installation is (as root)

  perl -MCPAN -e 'shell'
  # configuration might be prompted for
  > install Date::Manip # to test installation of the 
    # Date::Manip module.

Your author has noted that Tk fails on a test and does not know how to force the install through the CPAN shell, so your author falls back to the manual method (as user, unless root stated).

  gunzip Tk800.025.tar.gz
  tar -xvf Tk800.025.tar
  cd Tk800.025
  perl Makefile.PL
  make
  make test # just to see most of the test suite
  make install (as root)
  cd ..
  /bin/rm -r Tk800.025

This process has been repeated on two MacOSX PPC 10.3 and 10.4 and two MacOSX Intel 10.4 and 10.5 machines.


EXTERNAL UTILITIES THAT ARE REQUIRED

The Tk module only exports postscript. Therefore, to export to other formats supported (PNG|PDF), the following utilities are
needed.

  ghostscript    For conversion of postscript to PNG format.
  ps2pdf         For conversion of postscript to PDF format.

The usage of these two is seen when the --verbose option is used
as in

  tkg2 --format=[ png | pdf ] --verbose yourtkg2file.tkg2

MetaPost/LaTeX support is available and the following are needed.

pdflatex, mpost, mptopdf, (and other "TEX" programs)?

The Tkg2 MetaPost subsystem writes native MetaPost with embedded LaTeX commands. The environment variable must be $TEX=latex and the mptopdf program is used for the generation. The pdflatex engine is used. The author relied on the TeXLive2007 installation for the development of the MetaPost support.


SYSTEM CONFIGURATION

The file Tkg2/tkg2rc is an X-resources type file that contains various things that are platform or installation specific such as system color names. The line thicknesses are those specific one for which testing has shown that the Tk postscript driver produces as different thicknesses. The Tkg2/tkg2rc file that comes with the distribution provides the core default settings that the author uses, but also has custom settings in ~/.tkg2rc.

See the Tkg2/Tkg2rc.pm module for details on where other .tkg2rc files are written or use the 'Help'->'Tkg2rc File' after a template is started with the 'New' button for further information.


NEW USERS
It is suggested that you try tkg2 as

  tkg2 --autoexit

and evaluate whether the system is up and running.

Next, it is suggest that you try Tkg2 as

  tkg2 --help | more

to inspect the command line arguments (most you will not need at first), but the Tutorial about mouse control is pretty important!
