package Tkg2::DeskTop::Instructions;

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software (tkg2 and related modules) were
developed by the Author as an employee of the U.S. Geological Survey
Water-Resources Division, neither the USGS, the Department of the
Interior, or other entities of the Federal Government make any claim
whatsoever about suitability, reliability, editability or usability
of this product.

=cut

# $Author: wasquith $
# $Date: 2004/10/01 13:16:17 $
# $Revision: 1.33 $

use strict;
use Exporter;
use vars  qw(@ISA @EXPORT @STDIN $STDIN_READ $Verbose );
@ISA    = qw(Exporter);
@EXPORT = qw(Instructions);
$Verbose = 0;
use Tkg2::Base qw(strip_space Message Show_Me_Internals);

print $::SPLASH "=";

# Instructions is a nifty subroutine that provides runtime access
# to the hash for reconfiguration of many of the plot settings
# Actually, the user can access every element of the plot hash, but
# for some of the elements it is very difficult to make meaningful
# access.  We will see how this mechanism develops.  The intent of
# Instructions is to provide for alteration of the plot style
# type of settings such as min and max limits on an axis, the ticking
# style, axis titles, and so on.  Instructions also permits
# access into the annotation, reference lines, or quantile-quantile
# lines, and access into the data oriented objects.  The Instructions
# are applied at the last moment before the plot is rendered on the
# canvas for the first time.  PlotInstructions are not accessed again,
# though in time it might become desirable that they be.
# NOTE: Instructions is likely never to have the field checking that
# the dialog boxes have, thus, the user of plotinstructions should be
# careful otherwise figures will potentially be rendered invalid.  
# FORTUNATELY, BECAUSE THERE IS NO PERMANENT ADJUSTMENT TO A PLOT FILE
# UNLESS THE TEMPLATE IS SAVED AFTER INSTRUCTIONS ARE RUN THERE IS LITTLE
# IMMEDIATE DANGER THAT SOMEONE WOULD SCREW UP.
sub Instructions {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my $template = shift;
   my $plotins;
   ($plotins, $Verbose) = &_startinst();  
   return unless($plotins);  # no plot instructions were provided at the
                             # command line, quietly return
   
   # Retrieve the instructions from all of the files identified by the
   # -inst or --instv switches
   my @allins; # The instructions from all the files
   foreach my $file (@$plotins) { # foreach of the identified files
      my $ins = &_parse($file);  # the instructions contained in a given file 
      next unless($ins); # go on to the next file if no instructions were parsed
      push(@allins, $ins);
   }
   
   &_applyInstToPlots($template, \@allins);
   &_applyInstToAnnotation($template, \@allins);
}


sub _startinst {
   # the presence of -instv is usually not done, I am just trying to get
   # expected behavior
   my $opts = \%::CMDLINEOPTS; # make a reference, just to clean the code up
      # at the expense of a slight decrease in processing speed
   my $inst = $opts->{'inst'};            # try loading inst files from -inst
   if($inst and $opts->{'instv'}) {       # hey some were found, then
      push(@$inst, @{$opts->{'instv'}} ); # load the values from -instv
   }
   elsif($opts->{'instv'}) {
      $inst = $opts->{'instv'};
   }
   
   # The following is a trap that turns instructions stdin reading when
   # --stdin is specified.  --stdin cause tkg2 to look for an actual
   # tkg2 file along stdin.
   my @tmp;
   if($opts->{'stdin'}) {
      foreach (@$inst) {
         push(@tmp, $_) if($_ ne '-');
      }  
      $inst = [ @tmp ];
   }
   
   return ($inst, ($opts->{'instv'}) ? 1 : 0 ); # array ref of inst and verbose or not
}   
 

# _parse is the reader and parser on the plot instructions
# It takes a file name as the only argument and returns a reference
# to the instructions
sub _parse {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my $file = shift;
   my @slurped_file;  # the entire file will be read into that array
         # space considerations be damned.  The reason is that STDIN
         # is closed as a file handle after the first tkg2 file is 
         # processed.  If more tkg2 files are specified on the command
         # line, the read errors on a closed file handle occur.
         # By reading the file into an array we'll saveit for another
         # day.
   
   local $/ = $::TKG2_ENV{-INPUT_RECORD_SEPARATOR};
   # The explicit setting of $/ is necessary because -batch
   # causes $/ to become undef somewhere.  It is best to set the flag 
   # anyway.
   
   if($file eq '-' and not @STDIN ) { # read from STDIN
      @slurped_file = <STDIN>;  # read the entire STDIN at once
      @STDIN = @slurped_file;   # copy the entire 'file' into GLOBAL Variable 
   }
   elsif($file eq '-'  and @STDIN ) {
      @STDIN = @slurped_file;   # hey, @STDIN available so just copy into slurped
   }
   else {
      local *FH;
      open(FH,"<$file") or
           do {
                 &Message($::MW, '-generic', "Instruction File=$file\n".
                                             "was not opened because $!");
                 return 0;
              };
      @slurped_file = <FH>;
      close(FH) or
           do {
                 &Message($::MW, '-fileerror', $!);
                 return 0;
              };
   }
   print $::VERBOSE "      Reading Instructions from file '$file'\n" if($Verbose);
   my (@ins, $line, @cobj, $ck, $cv, $o, $k, $v, @obj);
   # c -- 'current'
   # $o = object, $k = key, $v = value
   foreach (@slurped_file) {
      $line++;
      last if(/^\s*__END__/o);
      next if(/^#/o);  # comments are allowed
      next if(/^!/o);  # bang symbol too following some Unix conventions
      chomp($_); # remove the new line
      $_ = &strip_space($_); # get rid of leading and trailing spaces
      next if($_ eq ""); 
      
      if(/:.+==/o) { # this allows Plot2D / PLOT1 : plottitle == Hello:World
         # thanks david yancey for crashing this section and forcing me
         # to make things correct (better)
         # the object, $o, still needs splitting
         ($o, $k, $v) = $_ =~ m/(.+):(.+)==(.+)?/o;
         #  See how the ? added after the last capture makes it optional.
         #  This appears to allow undefined values to enter in
         #  If the stuff after the == is null, then $o ends up not
         #  being defined and that is annoying.  Discovered by Dane Ohe
         #  June 20, 2001, but not fixed yet owing to sensitivity of 
         #  the instructions to NWIS implementation.
         # PRIOR TO 0.70 ($o, $k, $v) = $_ =~ m/(.+):(.+)==(.+)/o;
         print $::VERBOSE "Tkg2: --inst[v] Warning: Could not parse ",
                          "the object from '$_'\n",
                          "  This line should match the following ",
                          " m/(.+):(.+)==(.+)/o\n" if(not defined $o);
         @obj = split(m|/|, $o);  # splitting is on the forward slash
      }
      elsif(/==/o) {
         ($k, $v) = $_ =~ /(.+)==(.+)?/o;
         # PRIOR TO 0.70 ($k, $v) = $_ =~ /(.+)==(.+)/o;
      }
      elsif(/:/o) { # It is important the colon only test occur after
                    # the == test so the lines like the following can
                    # be parsed.      text == <softcat: /tmp/tkg2.log>
         ($o) = $_ =~ m/(.+):/o;
         print $::VERBOSE "Tkg2: --inst[v] Warning: Could not parse ",
                          "the object from '$_'\n",
                          "  This line should match the following ",
                          " m/(.+):/o\n" if(not defined $o);
         @obj = split(m|/|, $o);
         $k = $v = $ck = $cv = undef;
         # only the plot name was found so undef the keys and values for
         # major protection against unwanted consequences
      }
      else {
         print $::VERBOSE "Tkg2: --inst[v] Warning: Could not parse ",
                          "line $line in '$file'\n";
         next;
      }
 
      @cobj = (@obj)       ? @obj : @cobj;
      $ck   = (defined $k) ? $k   : $ck;
      $cv   = (defined $v) ? $v   : $cv;
      
      # the current values MUST all be defined, otherwise, move on
      next if(not @cobj or not defined $ck or not defined $cv);
      foreach my $f (@cobj, $ck, $cv) { $f = &strip_space($f) }
      my %obj = @obj;
      push(@ins, { -object => { @cobj },
                   -keys   => [ (map {(/^-/o) ? $_ : "-$_"} split(/\s+/o,$ck)) ],
                   -values => $cv
                 } );
   }
   
   print $::BUG "### parsing Instructions\n",
                "  #   The object hierarchy is likely not shown in\n",
                "  #   proper order here because this is a hash dump.\n";
   foreach my $ins (@ins) {
      map { print $::BUG "   OBJECT: $_ => '$ins->{-object}->{$_}'\n" }
                                       keys %{$ins->{-object}};
      map { print $::BUG "     KEYS: '$_'\n" } @{$ins->{-keys}};
            print $::BUG "   VALUES: '$ins->{-values}'\n\n";
   }
   print $::BUG "### done parsing Instructions\n";
     
   return [ @ins ]; # reference to the parsed instructions
}


sub _trimInst {
   my ($target, $allins) = @_;
   # Loop through the all of the instructions and reject those
   # that are not $targer oriented.  wha thinks that it is more optimal to 
   # process just those records that we're interested in, but who knows
   my @trimins;
   foreach my $fileins (@$allins) {     # the instructions from each file
      foreach my $ins  (@$fileins)  {   # the instructions within each file
         my $object = $ins->{-object};
         foreach my $type (keys %$object) { 
            push(@trimins, $ins), last if($target =~ /$type/); 
         }
      }
   }
   return @trimins;
}


sub _recurseKeys {
   my ($head, $movon, $valref, $vals) = ( shift, shift, shift, pop );
   my @keys = @_;        
   my $firstkey = shift(@keys); 
   my $lastkey  = pop(@keys);
   
   # the first key is a little different because the ref of the
   # plot is a package name and not 'HASH'
   if( exists $valref->{$firstkey} ) { # the first key is valid
      # if the first key points to a hash, then we can recurse
      # further and valref will continue to be a reference when
      # ? returns the value; otherwise we need to return a
      # reference to the value \
      $valref = (ref $valref->{$firstkey} eq 'HASH') ? 
                     $valref->{$firstkey} : \$valref->{$firstkey};
   }
   else { 
      # the first key was invalid
      print $::VERBOSE "$head: *First key warning*  Key '$firstkey' ".
                       "does not exist. $movon" if($Verbose);
      return 0;
   }
            
   # Loop through the keys in the middle
   KEY: foreach my $key (@keys) {
      if(ref $valref eq "HASH") {
         $valref = $valref->{$key}, next KEY if( exists $valref->{$key} );
         print $::VERBOSE "$head: *Key loop warning*  Valref is a ",
                          "hash ref but the key '$key' does not ",
                          "exist. $movon" if($Verbose);
         return 0;
      }
      else {
         print $::VERBOSE "$head: *Warning*  Valref is a not a hash ",
                          "ref but there are still keys to go.  ",
                          "The current key is '$key'. $movon" if($Verbose);
         return 0;
      }
   }
            
   # Deal with the last key, if the lastkey is undef then that
   # means we are about to set the first level plot hash elements
   if(defined $lastkey) {
      if(ref $valref eq 'HASH') {
         if( exists $valref->{$lastkey} ) {
            $valref = \$valref->{$lastkey};
         }
         else {
            print $::VERBOSE "$head: *Last key warning*  Valref is a ",
                             "hash ref but the key '$lastkey' does ",
                             "not exist. $movon" if($Verbose);
            return 0;
         }
      }
      else {
         print $::VERBOSE "$head: last key warning, key ",
                          "'$lastkey' does not exist. $movon" if($Verbose);
         return 0;
      }
   }
            
   # Finally, set the value in the hash
   # see that the magic here is that we have had goal of tracking
   # the value as a reference so that not only can we now determine
   # whether the value is an array or not, but all by changing the
   # value here, it is updated in the hash too. 
   #$$valref = (ref $$valref eq 'ARRAY') ?
   #           [ split(/\s+/, $vals) ] : $vals;
            
   $vals =~ s/\\n/\n/g;  
   my $diffORsame;
   if(ref $$valref eq 'ARRAY') { # value is an array reference
      my $oldval  = [ @{$$valref} ];
      # The user can use [] to set the array to 
      # nothing, pretty cool, this feature added very late
      # September 2001.  Odd that issue had not arisen before.
      if($vals =~ /\[\s*\]/o) { # if [] or [ ] or [  ] etc . . .  
         $$valref = [ ]; # set to empty array ref
      }
      else {
         # split on spaces and create array ref 
         $$valref = [ split(/\s+/o, $vals) ];
      }  
      # now lets check that the two arrays are purely
      # different or the same independent of the order that
      # either array might be in.
      my %check;
      map { $check{$_}++ } (@{$oldval}, @{$$valref});
      foreach my $key (keys %check) {
         return 'diff' if($check{$key} > 1);
      }
      return 'same';
   }
   else {        # value is just a scalar
      my $oldval  = $$valref;
      $$valref = $vals;
      # $vals should always be at least defined by this point
      # but it could be that the original value in the file
      # was undefined.  Lets us go ahead and return different
      # if the vals is defined and the oldvalue is not.  The
      # test on vals might not be required, but for safety
      return 'diff' if(defined $vals and not defined $oldval);
      return ($vals eq $oldval) ? 'same' : 'diff';
   }
}


sub _applyInstToPlots {
   my ($template, $allins) = @_;
   
   my @plotins = &_trimInst('Plot2D',$allins);
      
   # Apply the instructions for each plot in the template
   my $head  = "       --inst";
   my $movon = "\n                ** Moving on to the next instruction **\n";
   PLOT: foreach my $plot ( @{$template->{-plots}} ) {
      my $plotname = $plot->{-username}; # this is the actual plot name
      next PLOT unless($plotname);       # this means that the plotname
                                         # can not be 0 or null
      print $::VERBOSE "$head"."Plot: '$plotname'\n" if($Verbose);
      
      # variables for checking whether or not the x, y, and y2 axis
      # types were changed
      my ($xtype_changed, $ytype_changed, $y2type_changed) = (0,0,0);
      
      INST: foreach my $i (0..$#plotins) {
         #print $::VERBOSE "$head using file ",$i+1," of ",scalar(@plotins),
         #                 " eligible Plot2D instructions\n" if($Verbose);
         
         my %obj     = %{ $plotins[$i]->{-object} };
         my @keys    = @{ $plotins[$i]->{-keys}   };
         my $vals    =    $plotins[$i]->{-values}  ;
         
         # get the plot name of interest and delete its record from hash
         my $insname = delete($obj{'Plot2D'});

         next INST unless($insname eq $plotname or $insname =~ /all/io);
            
        
         # Now route the proper call into the various objects contained
         # in a plot
         my $value_is = "not tested";
         if(not %obj) { # THE PLOT OBJECT ITSELF
            print $::VERBOSE "$head"."main: $insname => ","@keys = $vals\n"
                  if($Verbose);
            # if the hash is empty, then now other objects are slated.
            $value_is = &_recurseKeys($head, $movon, $plot, @keys, $vals);
         }
         elsif(exists($obj{'DataSet'})) { # a DataSet is named
            #print $::VERBOSE "$head:    on a DataSet Object within $plotname.\n";
            # we're are now working on the DataSet objects 
            my $dataclass = $plot->{-dataclass};
            if(exists($obj{'Data'})) {
               #print $::VERBOSE "$head:    on Data Object within $obj{DataSet}.\n";
               # a Data pair inside a Set is named
               foreach my $dataset (@$dataclass) {
                  my $setname  = $dataset->{-username};
                  my $insname  = $obj{'DataSet'};
                  my $insname2 = $obj{'Data'};
                  next unless($insname eq $setname or $insname =~ /all/io);
                  foreach my $data (@{$dataset->{-DATA}}) {
                     # notice that -DATA is already used for you, you
                     # do not have to have -DATA in your key list.
                     my $dataname = $data->{-username};
                     next unless($insname2 eq $dataname or $insname2 =~ /all/io);
                     
                     print $::VERBOSE "$head"."Data: $insname => ","@keys = $vals\n"
                           if($Verbose);
                     
                     $value_is = &_recurseKeys($head, $movon, $data, @keys, $vals);
                  }
               }
            }
            else {  # JUST WORK ON DATASET
               foreach my $dataset (@$dataclass) {
                  my $setname = $dataset->{-username};
                  my $insname = $obj{'DataSet'};
                  next unless($insname eq $setname or $insname =~ /all/io);
                  
                  print $::VERBOSE "$head"."DataSet: $insname => ","@keys = $vals\n"
                           if($Verbose);
                  
                  $value_is = &_recurseKeys($head, $movon, $dataset, @keys, $vals);
               }
            }
         }
         elsif(exists($obj{'QQLine'})) { # QUANTILE-QUANTILE LINES
            # yes there is a slight mis-match in QQLine verse QQLines naming
            # this works however.
            print $::VERBOSE "$head"."Anno: QQLine => ","@keys = $vals\n"
                           if($Verbose);
            
            $value_is = &_recurseKeys($head, $movon, $plot->{-QQLines}, @keys, $vals);
         }
         elsif(exists($obj{'RefLine'})) { # REFERENCE LINES
            my $insname = $obj{'RefLine'};
            foreach my $refline (@{$plot->{-RefLines}->{-y}},
                                 @{$plot->{-RefLines}->{-y2}}) {
               my $linename = $refline->{-username};
               next unless($insname eq $linename or $insname =~ /all/io);
               
               print $::VERBOSE "$head"."AnnoRefLine: $insname => ","@keys = $vals\n"
                           if($Verbose);
            
               $value_is = &_recurseKeys($head, $movon, $refline, @keys, $vals);
            }
         }
         else {
            print $::VERBOSE "Tkg2:--inst[v] Warning: Could not route in Plot2D\n",
                             "         Sub-object name is not valid?\n",
                             "         Check for proper capitalization?\n",
                             "         Valid names include: DataSet, QQLine, RefLine\n";
         } 
         
         # Check to determine which axis types were potentially changed
         my $string_keys = "@keys";
         if($string_keys eq '-x -type') {
            $xtype_changed  = ($value_is eq 'diff' ) ? 1 : 0;
         }
         if($string_keys eq '-y -type') {
            $ytype_changed  = ($value_is eq 'diff' ) ? 1 : 0;
         }
         if($string_keys eq '-y2 -type') {
            $y2type_changed = ($value_is eq 'diff' ) ? 1 : 0;
         }
      } # END INST LOOP
      
      
      # This provides a quick check on the min and max fields for each axis
      # if a min or max field checks out as a valid tkg2 time, then the time
      # is converted to a integer for the user.  This allows the user to
      # modify the min and max fields for a time series plot using dates and time
      # and have tkg2 do the conversion to integer.fracdays since that is how
      # tkg2 works with time -- feature suggested by Willard Gibbons, Austin, Texas
      # This is an very subtle feature.
      $plot->convertAxisMinMaxtoIntegerifTime;
      
      if($xtype_changed or $ytype_changed or $y2type_changed) {
         my %which_axis;
         $which_axis{-x}  = (  $xtype_changed ) ? 1 : 0;
         $which_axis{-y}  = (  $ytype_changed ) ? 1 : 0;
         $which_axis{-y2} = ( $y2type_changed ) ? 1 : 0;
         print $::VERBOSE "     Inst Message: calling routeAutoLimits because ",
                          "one or more axis\n",
                          "                   types were changed for plot ",
                          "'$plotname'.\n";
         # The automatic determination of limits can still be controlled
         # using the -autominlimit and -automaxlimit keys.  This is important
         # because user's in the know can take over the responsibility of 
         # determining appropriate axis limits instead of tkg2.
         $plot->routeAutoLimits(\%which_axis);
         # so if the instructions changed the 
         # axis type, then we can be reasonably be assured that the  plot
         # will have proper mins and maxs.  The call to routeAutoLimits
         # could also be triggered by changing an axis type to a different
         # type and then changing it back again.
      }            
      # FINAL ADJUSTMENTS
      # At this point, it is highly advisable that we run through
      # whatever consistency checks are necessary.
      # such checks include unit conversions or conversions into
      # internal tkg2 representations
      $plot->convertUnitsToPixels;  
      
      $plot->configwidth; # in case the margins were changed
   } # END PLOT LOOP
   print $::VERBOSE "\n";
}


#
# ANNOTATION SUBROUTINES
#
sub _applyInstToAnnotation {
   &_reallyapplyInstToAnno(@_,'AnnoLine');
   &_reallyapplyInstToAnno(@_,'AnnoSymbol');
   &_reallyapplyInstToAnno(@_,'AnnoText');   
}

sub _reallyapplyInstToAnno {
   my ($template, $allins, $type) = @_;
   my @annoins = &_trimInst($type, $allins);

   # Apply the instructions for each plot in the template
   my $head  = "       --inst:";
   my $movon = " Moving on to the next $type instruction\n";
   
   my $keytype = ($type eq 'AnnoLine')   ? '-annoline'   :
                 ($type eq 'AnnoSymbol') ? '-annosymbol' : '-annotext';
   ANNO: foreach my $anno ( @{$template->{$keytype}} ) {
      my $annoname = $anno->{-username};
      next ANNO unless($annoname);
      print $::VERBOSE "$head on $type '$annoname'\n" if($Verbose);
      
      
      INST: foreach my $i (0..$#annoins) {
         #print $::VERBOSE "$head using file ",$i+1," of ",scalar(@annoins),
         #                 " eligible $type instructions\n" if($Verbose);
         
         my %obj     = %{ $annoins[$i]->{-object} };
         my @keys    = @{ $annoins[$i]->{-keys}   };
         my $vals    =    $annoins[$i]->{-values};
         
         # get the plot name of interest and delete its record from hash
         my $insname = delete($obj{$type});

         next INST unless($insname eq $annoname or $insname =~ /all/io);
         
         print $::VERBOSE "$head $insname => ","@keys = $vals\n" if($Verbose);
         
         # Now route the proper call into the various objects contained
         # in a plot
         my $value_is;
         if(not %obj) {
            # if the hash is empty, which it better be for proper annotext
            $value_is = &_recurseKeys($head, $movon, $anno, @keys, $vals);          
         }
         else {
            print $::VERBOSE "Tkg2:--inst[v] Warning: Could not route in $type\n",
                             "         Annotation type name is not valid?\n",
                             "         Check for proper capitalization?\n",
                             "         Valid names include: AnnoLine, AnnoSymbol, AnnoText\n";
         }
      }
   }
   print $::VERBOSE "\n";
}

1;

__END__
Example instruction scripting format:

Plot2D/Plot Name:
   key key key key == value
     key key key key == value

Plot2D/Other Plot Name:
  key key key key == value
  key key key key == value

Plot2D/Yet Another Plot Name:key key key key    key == Area=3.14r**2

# The Plot Commented OUT: key key key key  = value

Plot2D/all/DataSet/all/data/MEAN DATA::


Here is a trick to test instructions from the command line:
[wasquith,tkg2]$ myg2 -instv=- freq.tkg2
Plot2D/ TOP PLOT : y laboffset == -0.4i
cntl-D  # which stops the reading from the command line, cool!
               
