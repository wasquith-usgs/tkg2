#!/usr/bin/perl -w
use strict;
#
# Author: John Helly (hellyj@ucsd.edu)
# Copyright 2005: All Rights Reserved
# 
#
# Substantial reorganization by William H. Asquith
# USGS, Austin, Texas
# Writing more idiomatic perl and added station_nm, state_cd, county_cd, to output

my $US         = '_';
my $year       = '2';
#
#$latNW=460000;
#$lonNW=1120000;
#$latSE=450000;
#$lonSE=1110000;
#
# ./NWIS_get_sitelists.pl lat_nw lon_nw lat_se lon_se
#
die "DIED: Please provide paired minimums of latitude and longitude and pair maximums ".
    "of latitude and longitude as four arguments on the command line\n" unless(@ARGV == 4);
my ($lat_min, $lon_min, $lat_max, $lon_max) = @ARGV; 
#

#
#$lat_max = 50;
#$lon_max = 125;
#$lat_min = 25;
#$lon_min = 65;
#
#$lat_max = 50;
#$lon_max = 125;
#$lat_min = 38;
#$lon_min = 65;
#
#$lat_max = 45;
#$lon_max = 116;
#$lat_min = 35;
#$lon_min = 112;
#
for(my $lat = $lat_min; $lat <= $lat_max; $lat++) {
   for(my $lon = $lon_min; $lon <= $lon_max; $lon++) {
      my $latSE = $lat     * 10000;
      my $latNW = ($lat+1) * 10000;
      my $lonSE = $lon     * 10000;
      my $lonNW = ($lon+1) * 10000;
        
      my $datestamp = sprintf "%03d%02d%02d%02d%02d", ((localtime)[5]%100, (localtime)[4]+1, (localtime)[3],(localtime)[2],(localtime)[1]);
      my $tmpfile = "./NWIS.SITELIST.$latSE$US$lonSE$US$latNW$US$lonNW$US$year$datestamp.xml";
      #$tmpfile = "./NWIS_get.log";
      open(OUTFILE, "> $tmpfile") or die "DIED: Cannot open $tmpfile because $!";

      my $command =
          "'http://nwis.waterdata.usgs.gov/nwis/inventory?nw_longitude_va=".
          "$lonNW&nw_latitude_va=$latNW&se_longitude_va=$lonSE&se_latitude_va=$latSE".
          "&coordinate_format=dms&format=sitefile_output&sitefile_output_format=xml".
          "&column_name=agency_cd&column_name=site_no&column_name=station_nm&column_name=state_cd&column_name=county_cd".
          "&column_name=dec_lat_va&column_name=dec_long_va&column_name=coord_datum_cd&column_name=alt_va".
          "&column_name=alt_datum_cd&column_name=station_type_cd&column_name=rt_bol".
          "&column_name=discharge_begin_date&column_name=discharge_end_date".
          "&column_name=discharge_count_nu&column_name=peak_begin_date".
          "&column_name=peak_end_date&column_name=peak_count_nu&column_name=qw_begin_date".
          "&column_name=qw_end_date&column_name=qw_count_nu&column_name=gw_begin_date".
          "&column_name=gw_end_date&column_name=gw_count_nu&list_of_search_criteria=lat_long_bounding_box'";
        # print "CURL COMMAND: $command\n";
        # The -s(--silent) option on curl supresses the progress meter 
      open(FD, "curl -s $command |") or die "DIED: Could not open the http command pipe because $!\n";         
      my $count = 0;
      while(<FD>) {
        s/\r\n/\n/g; # curl returns the carriage return (a dos file?)--strip to unix convention
        print OUTFILE;
        $count++ if(m/<site>/);
      }
      print "STATUS: For $latSE(latSE)/$lonSE(lonSE) and $latNW(latNW)/$lonNW(lonNW) $count sites found.\n";
   }
}
