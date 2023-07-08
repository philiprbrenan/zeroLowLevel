#!/usr/bin/perl -Ilib -I../lib -I/home/phil/perl/cpan/ZeroEmulator/lib/
#-------------------------------------------------------------------------------
# Test Zero Emulator
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Zero::Emulator qw(:all);
use Test::More tests=>2;

if (1)
 {Start 1;

  my $a = Array "aaa";
  Mov [$a, 0, "aaa"], 1;
  Out "Hello World";

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, "Hello World\n";
  is_deeply $e->heap(0), bless([1], "aaa");
 }

done_testing;
