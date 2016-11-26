#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Deploy 'do_system';
do_system ("rm -f examples/*-out.txt");
