#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# _
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
eval "use Test::More qw(no_plan);" unless caller;



my $home    = q(/home/phil/perl/cpan/ZeroEmulatorLowLevel/verilog/countUp/);       # This folder
my $exec    = q(countUp);
my $source  = fpe $home, $exec, q(sv);
my $net     = fpe $home, $exec, q(net);

unlink $exec;

my $command = qq(iverilog -g2012 -o $exec -N $net -t pcb $source);
say STDERR qx($command);
