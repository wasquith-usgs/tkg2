#!/usr/bin/perl -w
use Date::Calc qw(leap_year);
for(1900..2050){print"$_ ",leap_year($_)?"yes":"no","\n"}
