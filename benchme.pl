#!/usr/bin/perl
$__=(@ARGV)?shift():1;
die "First arg must be ",
"an integer: $__ @ARGV\n"
if($__ !~ /^\d+$/o); $|=1;
$c="myg2 -a -verb -opt @ARGV";
map
{($___=`$c 2>>/dev/null`
,@_=$___=~/
([-0-9.]+)
\susr\s\+\s
([-0-9.]+)
\ssys\s=\s
([-0-9.]+)
/xo,map
{$__[$_]+=
$_[$_]/$__}
(2,0,1),
(print
"$_",(/0$
/xo)?("\n"
):("->")))
}(1..$__);
print "\nCommand: $c\n$__[0]usr + $__[1]sys = $__[2]CPU\n"
