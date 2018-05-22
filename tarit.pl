#!/usr/bin/perl -w
unlink('tkg2-latest.tar.gz');
`tar -cvf tkg2-latest.tar Tkg2 myg2 epm`;
`gzip tkg2-latest.tar`;

