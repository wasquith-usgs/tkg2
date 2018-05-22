#! /usr/local/bin/rpm -bb
# ======================================================================
# @(#)  RPM Spec file for building tkg2
# ======================================================================
Summary: tkg2 - Perl/Tk charting program
Name: tkg2
Version: 1.50
Release: 1
Copyright: none
Group: Applications/Graphics
URL: http://unix.usgs.gov/solaris/tkg2.html
Distribution: DIS Solaris RPM
Vendor: WRD Distributed Information System
Packager: William H. Asquith <wasquith@usgs.gov>
Prefix: /usr/local
BuildArch: noarch
requires: perl-modules >= 5.10.1-2

%description
Tkg2 is a full featured interactive and batch processing capable 2-D
charting package. Tkg2 is entirely written in Perl and the Tk graphics
module.  Other nonstandard Perl modules are required.  Tkg2 features
include: linear, log, normal and Gumbel probability, time series,
x and x-y error bar and limit, bar, and text plots.  A fantastic array
of ancillary features, options, and general capabilities exists.

%changelog
* Tue Apr 11 2011 William H. Asquith <wasquith@usgs.gov>

- 1.50  Release

         Targeted refinement to features and responding to Perl5.10
         associated with NWIS4.10 release.

* Mon Jan 28 2007 William H. Asquith <wasquith@usgs.gov>

- 1.10   Release
  
         Path breaking feature added. Experimental MetaPost support added.

* Tue May 17 2005 William H. Asquith <wasquith@usgs.gov>

- 1.00   Rerelease

         Additional documentation added.


* Mon May 2 2005 William H. Asquith <wasquith@usgs.gov>

- 1.00   Rerelease

         Trapping window closure hangs in --justdisplayone, --nomw,
         --withdraw, and --presenter operational modes.  Rug plotting
         now available.

* Wed Feb 23 2005 William H. Asquith <wasquith@usgs.gov>

- 1.00   Several important fixes and enhancements made.

         See /usr/local/Tkg2/Help/info.pod for full history and changes.

* Thu Aug 05 2004 William H. Asquith <wasquith@usgs.gov>

- 0.81   Correction to the implementation of the 'curselection' method on
         listboxes after apparent changes to the Tk module at versions greater
         than 804.026.  The method no longer returns the index of a listbox
         when called in a scalar context: ReferenceLines, DataSetEditor, and
         DataClassEditor dialog boxes required changes.  The fix basically
         involves the addition of the 'index' method as in $lb->index($lb->curselection). 

         See /usr/local/Tkg2/Help/info.pod for full history and changes.

         Added the deleteFontCache in the Tkg2::Base module to make sure that
         the font cache is empty before any attempt to create a font is made.
         This is a stop gap measure designed to alleviate (random?) core dumps
         reported on some Perl5.8.3/Tk804.026 systems.

%prep
if [ `ls -ld /usr/local/Tkg2| awk '{print $3}'` != 'root' ]; then
  echo setting ownership on /usr/local/Tkg2
  chown -R root /usr/local/Tkg2
fi
if [ `ls -ld /usr/local/Tkg2| awk '{print $4}'` != 'root' ]; then
  echo setting group on /usr/local/Tkg2
  chgrp -R root /usr/local/Tkg2
  chmod 664 /usr/local/Tkg2/tkg2rc
  chgrp sys /usr/local/Tkg2/tkg2rc
fi

%clean
# Copy binary release to ftp area
RPM_ROOT_DIR=`dirname $RPM_BUILD_DIR`
#
package="$RPM_ROOT_DIR/RPMS/$RPM_ARCH/$RPM_PACKAGE_NAME-$RPM_PACKAGE_VERSION-$RPM_PACKAGE_RELEASE.$RPM_ARCH.rpm"
#scp -a $package disftp.er.usgs.gov:/var/ftp/pub/$RPM_OS/beta/.

%post
# stuff to do after software is loaded
#catman -w -M /usr/local/man

%postun
# uninstaller script

%files
/usr/local/bin/tkg2
/usr/local/bin/checktkg2time.pl
/usr/local/bin/daysbetween.pl
/usr/local/bin/dtgaprdb.pl
/usr/local/bin/gwsi_std2rdb.pl
/usr/local/bin/outwat2rdb.pl
/usr/local/bin/sumtkg2log.pl
/usr/local/bin/rdb_dt2d_t.pl
/usr/local/bin/rdb_ymd2d_t.pl
/usr/local/bin/get_nonzero_from_rdb.pl
/usr/local/bin/rdbtc.pl
/usr/local/bin/tkg2p2.pl
/usr/local/bin/tkg2p3.pl
/usr/local/bin/tkg2p4.pl
/usr/local/bin/tkg2pd2.pl
/usr/local/bin/tkg2pd3.pl
/usr/local/bin/tkg2pd4.pl
/usr/local/bin/DVgetem.pl
/usr/local/bin/DVgetpor.pl
/usr/local/bin/DVlastwk.pl
/usr/local/bin/UVgetem.pl
/usr/local/bin/UVlastwk.pl
/usr/local/bin/UVgetpor.pl
/usr/local/Tkg2/Anno
/usr/local/Tkg2/Base.pm
/usr/local/Tkg2/EditGlobalVars.pm
/usr/local/Tkg2/TestLoading.pm
/usr/local/Tkg2/TemplateUtilities.pm
/usr/local/Tkg2/RescaleTemplate.pm
/usr/local/Tkg2/Bitmaps
/usr/local/Tkg2/DataMethods
/usr/local/Tkg2/DeskTop
/usr/local/Tkg2/Draw
/usr/local/Tkg2/Help
/usr/local/Tkg2/Math
/usr/local/Tkg2/MenusRulersScrolls
/usr/local/Tkg2/NWISWeb
/usr/local/Tkg2/Plot
/usr/local/Tkg2/README
/usr/local/Tkg2/README_licensing
/usr/local/Tkg2/Scripts
/usr/local/Tkg2/Time
/usr/local/Tkg2/Tkg2rc.pm
/usr/local/Tkg2/Util
/usr/local/Tkg2/tkg2.pl

%config /usr/local/Tkg2/tkg2rc
