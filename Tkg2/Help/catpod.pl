#!/usr/bin/perl -w
@files = qw(About.pod
            main.pod
            CmdLineSummary.pod
            Tkg2rc.pod Environment.pod Instructions.pod
            GeneralUtilities.pod  NWISUtilities.pod
            AddDataFile.pod
            FileMenu.pod EditMenu.pod PlotMenu.pod DataMenu.pod AnnoMenu.pod
            SettingsMenu.pod
            PlotEditor.pod ContinuousAxisEditor.pod DiscreteAxisEditor.pod
            DataClassEditor.pod  DataSetEditor.pod DrawDataEditor.pod
            faqs.pod);

my $g2 = 'Tkg2_1.5';
print `cat @files > $g2.pod; pod2pdf $g2.pod`;
print `pod2html --infile=$g2.pod --outfile=$g2.html`;
unlink("$g2.pod");
unlink("$g2");
