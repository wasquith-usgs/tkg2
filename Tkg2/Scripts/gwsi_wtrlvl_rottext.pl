#!/usr/bin/perl -w
# --------------------------------------------------------------
# A Tkg2 file -- by the enigmatic William H. Asquith
# --------------------------------------------------------------
#   The following is the standard header written by tkg2
#   during a file save.   Tkg2 requires that the DATA
#   token be present as it uses this as a flag to begin actually
#   reading a file in.  You can edit anything you want
#   above the DATA token or even remove all this entirely.
#   Or you can put any data retrieval scripts above the 'exec'
#   to get the data files in place before tkg2 and this file is
#   actually launched.
use File::Copy;
my $gwsi_file = (@ARGV) ? shift(@ARGV) : undef;
if(defined $gwsi_file and $gwsi_file =~ /help/io) {
   print STDERR
      "%%\n%%            **** The $0 Graphics Package ****\n%%\n",
      "%% You are using the tkg2 implementation of GWSI standard table\n",
      "%% output files for graphical output.\n",
      "%%\n%% A GWSI standard table file name is provided as the first argument\n",
      "%% on the command line.  All other arguments are passed to tkg2.\n",
      "%% This program copies the table to a file called gwsi4tkg2.tmp.\n",
      "%% The gwsi4tkg2.tmp file is then passed through the \n",
      "%% /usr/local/Tkg2/Util/gwsi_std2rdb.pl script via the\n",
      "%% megacommand feature of tkg2.  Please leave a copy of gwsi4tkg2.tmp\n",
      "%% in the current directory as this tkg2 file\n",
      "%%\n%% Usage: $0 gwsi4tkg2.tmp\n%%   Danger--editing the raw tkg2 template\n",
      "%%\n%%      : $0 stan.table\n%%   Usual Mode--To view the graphical output\n",
      "%%                 A TMP_gwsi.tkg2 file is used by tkg2 for safety.\n",
      "%%\n%% by William Asquith <wasquith\@usgs.gov>, August 2001\n";
      exit;
}
die " DIED: Please provide an existing GWSI file name as first argument.\n".
    "         Try '$0 help' for more details\n"
     if(not defined $gwsi_file or not -e $gwsi_file);

# No copying is needed if we just want the temporary file name plotted.
if($gwsi_file ne 'gwsi4tkg2.tmp') {
   copy($gwsi_file,"gwsi4tkg2.tmp");
   $tkg2_template = "TMP_gwsi.tkg2";
   copy($0, $tkg2_template);
   push(@ARGV, "--justdisplayone --nobind");   
}
else {
   $tkg2_template = $0;
}
# Begin the self executing portion
#   gwsi_wtrlvl.tkg2 contains the command line arguments following
#         this file name: e.g. % /usr/local/bin/tkg2 --presenter.
#   /usr/local/bin/tkg2 is the name of this file.
exec("/usr/local/bin/tkg2 @ARGV $0") or      
print STDERR "The error message above indicates that the 
tkg2 executable could not be found along the above path 
Because tkg2 is a continuously developing product, it is 
possible that other versions are installed along your path 
with names such as 'asqplot' or 'g2'.  Try editing '/usr/local/bin/tkg2' 
and use one of these other names in the exec command.
";

__DATA__
Tkg2 File Version|0.60-4|Data::Dumper|Wed Aug 29 08:51:03 2001
$template = bless( {
  '-x_grid' => [],
  '-draw_annotation_first' => '0',
  '-annotext_plot_order' => '3',
  '-annoline' => [],
  '-annosymbol' => [],
  '-plots' => [
    bless( {
      '-plottitleyoffset' => '14.687',
      '-xmincanvas' => '76.498',
      '-RefLines' => bless( {
        '-y' => [],
        '-y2' => []
      }, 'Tkg2::Anno::ReferenceLines' ),
      '-xmaxcanvas' => '504.701',
      '-plottitlefont' => {
        '-size' => '10',
        '-weight' => 'bold',
        '-slant' => 'roman',
        '-stackit' => '0',
        '-custom1' => undef,
        '-family' => 'Helvetica',
        '-custom2' => undef,
        '-rotation' => 0,
        '-color' => 'black'
      },
      '-explanation' => {
        '-title' => 'EXPLANATION',
        '-font' => {
          '-size' => '8',
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => 0,
          '-custom1' => undef,
          '-family' => 'Times',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-linewidth' => '20.3792865882353',
        '-area_line_point_order' => 0,
        '-outlinecolor' => 'white',
        '-colspacing' => '0.10i',
        '-titlexoffset' => 'auto',
        '-fillstyle' => undef,
        '-numcol' => '1',
        '-titlejustify' => 'center',
        '-xorigin' => '259',
        '-hide' => '1',
        '-titleyoffset' => 'auto',
        '-dashstyle' => undef,
        '-fillcolor' => 'white',
        '-vertspacing' => 'auto',
        '-horzgap' => '3.42714729411765',
        '-outlinewidth' => '0.015i',
        '-yorigin' => '463'
      },
      '-borderwidth' => '0.015i',
      '-doit' => 1,
      '-ypixels' => '122.21',
      '-yumargin' => '275.395',
      '-plotbgfillstyle' => undef,
      '-plottitlexoffset' => '3.671',
      '-xrmargin' => '15.299',
      '-skip_axis_config_on_1st_data' => '0',
      '-plottitlejustify' => 'center',
      '-QQLines' => bless( {
        '-one2one' => {
          '-y' => {
            '-linewidth' => '0.015i',
            '-dashstyle' => undef,
            '-doit' => 0,
            '-linecolor' => 'black'
          },
          '-y2' => {
            '-linewidth' => '0.015i',
            '-dashstyle' => undef,
            '-doit' => 0,
            '-linecolor' => 'black'
          }
        },
        '-negone2one' => {
          '-y' => {
            '-linewidth' => '0.015i',
            '-dashstyle' => undef,
            '-doit' => 0,
            '-linecolor' => 'black'
          },
          '-y2' => {
            '-linewidth' => '0.015i',
            '-dashstyle' => undef,
            '-doit' => 0,
            '-linecolor' => 'black'
          }
        }
      }, 'Tkg2::Anno::QQLine' ),
      '-canvheight' => 673,
      '-plotbgcolor' => 'white',
      '-scaling' => '0.849986928104575',
      '-username' => '',
      '-borderdashstyle' => undef,
      '-xpixels' => '428.203',
      '-y2' => {
        '-reverse' => 0,
        '-max' => '10',
        '-title' => 'Y-DATA',
        '-origindoit' => 0,
        '-invertprob' => 0,
        '-numdecimal' => 0,
        '-make_axis_square' => '0',
        '-gridminor' => {
          '-linewidth' => '0.005i',
          '-dashstyle' => undef,
          '-doit' => 0,
          '-linecolor' => 'grey75'
        },
        '-num2offset' => '2.753',
        '-min_to_begin_labeling' => '',
        '-min' => '-10',
        '-numcommify' => 0,
        '-tickwidth' => '0.015i',
        '-originwidth' => '0.015i',
        '-numoffset' => '2.753',
        '-labelmax' => 1,
        '-tickratio' => '0.6',
        '-type' => 'linear',
        '-origindashstyle' => undef,
        '-basemajor' => [],
        '-major' => undef,
        '-labskip' => 0,
        '-labelmin' => 1,
        '-probUSGStype' => 0,
        '-max_to_end_labeling' => '',
        '-numfont' => {
          '-size' => 9,
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => 0,
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-labelequation' => 0,
        '-labfont' => {
          '-size' => 10,
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => 0,
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-gridmajor' => {
          '-linewidth' => '0.015i',
          '-dashstyle' => undef,
          '-doit' => 0,
          '-linecolor' => 'grey75'
        },
        '-blankit' => 0,
        '-blankcolor' => 'white',
        '-logoffset' => 0,
        '-spectickratio' => '0.8',
        '-autominlimit' => 1,
        '-automaxlimit' => 1,
        '-turned_on' => 0,
        '-numminor' => 1,
        '-lab2offset' => 0,
        '-location' => 'right',
        '-laboffset' => '42.839',
        '-datamax' => {
          '-whenlinear' => undef,
          '-whenprob' => undef,
          '-whenlog' => undef
        },
        '-ticklength' => '5.446',
        '-basemajortolabel' => [],
        '-datamin' => {
          '-whenlinear' => undef,
          '-whenprob' => undef,
          '-whenlog' => undef
        },
        '-hideit' => 0,
        '-discrete' => {
          '-doit' => 0,
          '-bracketgroup' => 1,
          '-labelhash' => {}
        },
        '-origincolor' => 'grey85',
        '-numformat' => 'free',
        '-time' => {
          '-max' => '',
          '-daydoit' => 1,
          '-min' => '',
          '-seconddoit' => 1,
          '-show_day_of_year_instead' => 0,
          '-hourtickevery' => 'auto',
          '-labellevel1' => 1,
          '-tickratio' => '0.7',
          '-monthtickevery' => 'auto',
          '-basedate' => [],
          '-yeartickevery' => 'auto',
          '-secondtickevery' => 'auto',
          '-monthdoit' => 1,
          '-labeldepth' => 1,
          '-showyear' => 1,
          '-hourdoit' => 1,
          '-minutetickevery' => 'auto',
          '-labeldensity' => 1,
          '-daytickevery' => 'auto',
          '-minutedoit' => 1,
          '-show_day_as_additional_string' => 0,
          '-yeardoit' => 1
        },
        '-usesimplelog' => 0,
        '-majorstep' => 2,
        '-baseminor' => [],
        '-doublelabel' => 0,
        '-minor' => undef
      },
      '-ymincanvas' => '275.395',
      '-plottitle' => '',
      '-xlmargin' => '76.498',
      '-ymaxcanvas' => '397.605',
      '-x' => {
        '-reverse' => '0',
        '-max' => '36900',
        '-title' => 'TIME',
        '-origindoit' => '0',
        '-invertprob' => 0,
        '-numdecimal' => '0',
        '-gridminor' => {
          '-linewidth' => '0.005i',
          '-dashstyle' => 'Solid',
          '-doit' => '0',
          '-linecolor' => 'grey75'
        },
        '-num2offset' => '3.059',
        '-min_to_begin_labeling' => '',
        '-min' => '17119',
        '-numcommify' => '0',
        '-tickwidth' => '0.015i',
        '-originwidth' => '0.015i',
        '-numoffset' => '3.059',
        '-labelmax' => '1',
        '-tickratio' => '0.6',
        '-type' => 'time',
        '-origindashstyle' => 'Solid',
        '-basemajor' => [],
        '-major' => undef,
        '-labskip' => 0,
        '-labelmin' => '1',
        '-probUSGStype' => 0,
        '-max_to_end_labeling' => '',
        '-numfont' => {
          '-size' => '9',
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => '0',
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-labelequation' => '0',
        '-labfont' => {
          '-size' => '10',
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => '0',
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-gridmajor' => {
          '-linewidth' => '0.015i',
          '-dashstyle' => 'Solid',
          '-doit' => '0',
          '-linecolor' => 'grey75'
        },
        '-blankit' => '0',
        '-blankcolor' => 'white',
        '-logoffset' => 0,
        '-spectickratio' => '0.8',
        '-autominlimit' => 1,
        '-automaxlimit' => 1,
        '-numminor' => 1,
        '-lab2offset' => 0,
        '-location' => 'bottom',
        '-laboffset' => '12.239',
        '-datamax' => {
          '-whenlinear' => '36900',
          '-whenprob' => undef,
          '-whenlog' => '36900'
        },
        '-ticklength' => '5.446',
        '-datamin' => {
          '-whenlinear' => '17119',
          '-whenprob' => undef,
          '-whenlog' => '17119'
        },
        '-basemajortolabel' => [],
        '-hideit' => '0',
        '-discrete' => {
          '-doit' => 0,
          '-bracketgroup' => 1,
          '-labelhash' => {}
        },
        '-origincolor' => 'grey85',
        '-numformat' => 'free',
        '-time' => {
          '-max' => '2001011100:00:00',
          '-daydoit' => 0,
          '-min' => '1946111500:00:00',
          '-seconddoit' => 0,
          '-show_day_of_year_instead' => '0',
          '-hourtickevery' => 'auto',
          '-labellevel1' => '1',
          '-tickratio' => '0.7',
          '-monthtickevery' => 'auto',
          '-basedate' => [
            1900,
            1,
            1
          ],
          '-yeartickevery' => 'auto',
          '-secondtickevery' => 'auto',
          '-monthdoit' => 0,
          '-labeldepth' => '1',
          '-showyear' => '1',
          '-hourdoit' => 0,
          '-minutetickevery' => 'auto',
          '-labeldensity' => '1',
          '-daytickevery' => 'auto',
          '-minutedoit' => 0,
          '-show_day_as_additional_string' => 0,
          '-yeardoit' => '1'
        },
        '-usesimplelog' => 0,
        '-majorstep' => 2,
        '-baseminor' => [],
        '-doublelabel' => '0',
        '-minor' => undef
      },
      '-y' => {
        '-reverse' => '1',
        '-max' => '250',
        '-title' => 'WATER LEVEL DEPTH BELOW LAND SURFACE IN FEET <Ang 90>',
        '-origindoit' => '0',
        '-invertprob' => 0,
        '-numdecimal' => '0',
        '-make_axis_square' => '0',
        '-gridminor' => {
          '-linewidth' => '0.005i',
          '-dashstyle' => 'Solid',
          '-doit' => '0',
          '-linecolor' => 'grey75'
        },
        '-num2offset' => '2.753',
        '-min_to_begin_labeling' => '',
        '-min' => '0',
        '-numcommify' => '0',
        '-tickwidth' => '0.015i',
        '-originwidth' => '0.015i',
        '-numoffset' => '2.75395764705882',
        '-labelmax' => '1',
        '-tickratio' => '0.6',
        '-type' => 'linear',
        '-origindashstyle' => 'Solid',
        '-basemajor' => [],
        '-major' => [],
        '-labskip' => '0',
        '-labelmin' => '1',
        '-probUSGStype' => 0,
        '-max_to_end_labeling' => '',
        '-numfont' => {
          '-size' => '9',
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => '0',
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-labelequation' => '0',
        '-labfont' => {
          '-size' => '10',
          '-weight' => 'normal',
          '-slant' => 'roman',
          '-stackit' => '0',
          '-custom1' => undef,
          '-family' => 'Helvetica',
          '-custom2' => undef,
          '-rotation' => 0,
          '-color' => 'black'
        },
        '-gridmajor' => {
          '-linewidth' => '0.015i',
          '-dashstyle' => 'Solid',
          '-doit' => '0',
          '-linecolor' => 'grey75'
        },
        '-blankit' => '0',
        '-blankcolor' => 'white',
        '-logoffset' => 0,
        '-spectickratio' => '0.8',
        '-autominlimit' => '1',
        '-turned_on' => 0,
        '-automaxlimit' => '1',
        '-numminor' => '1',
        '-lab2offset' => '-122.398117647059',
        '-location' => 'left',
        '-laboffset' => '-152.997647058824',
        '-datamax' => {
          '-whenlinear' => '216.51',
          '-whenprob' => undef,
          '-whenlog' => '216.51'
        },
        '-ticklength' => '5.44671623529412',
        '-basemajortolabel' => [],
        '-datamin' => {
          '-whenlinear' => '82.6',
          '-whenprob' => undef,
          '-whenlog' => '82.6'
        },
        '-hideit' => '0',
        '-discrete' => {
          '-doit' => 0,
          '-bracketgroup' => 1,
          '-labelhash' => {}
        },
        '-origincolor' => 'grey85',
        '-numformat' => 'free',
        '-time' => {
          '-max' => '1900090800:00:00',
          '-daydoit' => 1,
          '-min' => '1900010100:00:00',
          '-seconddoit' => 1,
          '-show_day_of_year_instead' => 0,
          '-hourtickevery' => 'auto',
          '-labellevel1' => 1,
          '-tickratio' => '0.7',
          '-monthtickevery' => 'auto',
          '-basedate' => [],
          '-yeartickevery' => 'auto',
          '-secondtickevery' => 'auto',
          '-monthdoit' => 1,
          '-labeldepth' => 1,
          '-showyear' => 1,
          '-hourdoit' => 1,
          '-minutetickevery' => 'auto',
          '-labeldensity' => 1,
          '-daytickevery' => 'auto',
          '-minutedoit' => 1,
          '-show_day_as_additional_string' => 0,
          '-yeardoit' => 1
        },
        '-usesimplelog' => 0,
        '-majorstep' => '50',
        '-baseminor' => [],
        '-doublelabel' => '0',
        '-minor' => undef
      },
      '-dataclass' => bless( [
        bless( {
          '-username' => '',
          '-setname' => 'tkg2_megacommand_file_0',
          '-show_in_explanation' => 1,
          '-DATA' => [
            {
              '-origabscissa' => 'DATE_TIME:time',
              '-username' => '',
              '-showthirdord' => undef,
              '-origthirdord' => undef,
              '-show_in_explanation' => 1,
              '-showordinate' => 'WATER_LEVEL(FEET):number_from_/home/wasquith/tkg2_megacommand_file_0',
              '-origordinate' => 'WATER_LEVEL(FEET):number',
              '-attributes' => {
                '-bars' => {
                  '-outlinecolor' => 'black',
                  '-dashstyle' => undef,
                  '-doit' => 0,
                  '-fillcolor' => 'white',
                  '-fillstyle' => undef,
                  '-outlinewidth' => '0.015i',
                  '-barwidth' => '0.1i',
                  '-direction' => 'below'
                },
                '-yerrorbar' => {
                  '-dashstyle' => undef,
                  '-width' => '0.005i',
                  '-whiskerwidth' => '0.05i',
                  '-color' => 'black'
                },
                '-text' => {
                  '-anchor' => 'center',
                  '-xoffset' => '1.223',
                  '-doit' => 1,
                  '-justify' => 'left',
                  '-numdecimal' => 0,
                  '-font' => {
                    '-size' => 8,
                    '-weight' => 'normal',
                    '-slant' => 'roman',
                    '-stackit' => 0,
                    '-custom1' => undef,
                    '-family' => 'Helvetica',
                    '-custom2' => undef,
                    '-blankit' => 0,
                    '-blankcolor' => 'white',
                    '-rotation' => 0,
                    '-color' => 'black'
                  },
                  '-yoffset' => '3.427',
                  '-numcommify' => 0,
                  '-numformat' => 'free',
                  '-leaderline' => {
                    '-endoffset' => '6.11990588235294',
                    '-doit' => 0,
                    '-width' => '0.005i',
                    '-shuffleit' => 0,
                    '-overlap_correction_doit' => 0,
                    '-lines' => [
                      {
                        '-length' => '24.4796235294118',
                        '-angle' => '225'
                      },
                      {
                        '-length' => '15.2997647058824',
                        '-angle' => '180'
                      }
                    ],
                    '-beginoffset' => '6.11990588235294',
                    '-dashstyle' => undef,
                    '-blankit' => 0,
                    '-blankcolor' => 'white',
                    '-flip_lines_with_shuffle' => 1,
                    '-color' => 'black'
                  }
                },
                '-points' => {
                  '-size' => '3.427',
                  '-doit' => 0,
                  '-fillstyle' => undef,
                  '-symbol' => 'Circle',
                  '-outlinecolor' => 'black',
                  '-dashstyle' => undef,
                  '-num2skip' => 0,
                  '-blankit' => 0,
                  '-fillcolor' => 'white',
                  '-blankcolor' => 'white',
                  '-outlinewidth' => '0.015i',
                  '-angle' => 0
                },
                '-shades' => {
                  '-fillcolor' => 'white'
                },
                '-lines' => {
                  '-linewidth' => '0.015i',
                  '-stepit' => 0,
                  '-dashstyle' => undef,
                  '-doit' => 1,
                  '-linecolor' => 'black'
                },
                '-xerrorbar' => {
                  '-dashstyle' => undef,
                  '-width' => '0.005i',
                  '-whiskerwidth' => '0.05i',
                  '-color' => 'black'
                },
                '-plotstyle' => 'X-Y Line',
                '-special_plot' => undef,
                '-which_y_axis' => '1',
                '-shade' => {
                  '-doit' => 0,
                  '-fillcolor' => 'black',
                  '-fillstyle' => undef,
                  '-shadedirection' => 'below',
                  '-shade2origin' => 0
                }
              },
              '-data' => [],
              '-showfourthord' => undef,
              '-origfourthord' => undef,
              '-showabscissa' => 'DATE_TIME:time'
            }
          ],
          '-file' => {
            '-ordinates_as1_column' => '0',
            '-sorttype' => 'numeric',
            '-filedelimiter' => '\\s+',
            '-sortdoit' => '0',
            '-numlabellines' => '1',
            '-fileisRDB' => '1',
            '-userelativepath' => 0,
            '-transform_data' => {
              '-script' => '',
              '-doit' => 0,
              '-command_line_args' => ''
            },
            '-thresholds' => '0',
            '-missingval' => '',
            '-numskiplines' => '0',
            '-numlinestoread' => '',
            '-fullfilename' => '/home/wasquith/tkg2_megacommand_file_0',
            '-megacommand' => '/usr/local/Tkg2/Util/gwsi_std2rdb.pl gwsi4tkg2.tmp',
            '-columntypes' => 'auto',
            '-numskiplines_afterlabel' => '0',
            '-relativefilename' => '',
            '-sortdir' => 'ascend',
            '-dataimported' => '0',
            '-skiplineonmatch' => '^#'
          }
        }, 'Tkg2::DataMethods::DataSet' )
      ], 'Tkg2::DataMethods::DataClass' ),
      '-canvwidth' => 520,
      '-ylmargin' => '275.395',
      '-bordercolor' => 'black'
    }, 'Tkg2::Plot::Plot2D' )
  ],
  '-y_grid' => [],
  '-annosymbol_plot_order' => '2',
  '-scaling' => '0.849986928104575',
  '-snap_to_grid' => '1',
  '-tkg2filename' => '/home/wasquith/tkg2/gwsi_wtrlvl_rottext.tkg2',
  '-annoline_plot_order' => '1',
  '-width' => '8.5',
  '-fileformat' => 'DataDumper',
  '-height' => '11',
  '-postscript' => {
    '-colormode' => 'color',
    '-fontmap' => undef,
    '-rotate' => '0'
  },
  '-undonum' => 0,
  '-annobox' => [],
  '-needsaving' => 0,
  '-annotext' => [],
  '-color' => 'white',
  '-no_update_on_data_add' => '0'
}, 'main' );
