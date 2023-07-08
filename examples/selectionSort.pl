#!/usr/bin/perl -Ilib -I../lib -I/home/phil/perl/cpan/ZeroEmulator/lib/
#-------------------------------------------------------------------------------
# Zero assembler programming language of in situ selection sort
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
use Test::More tests=>9;

sub selectionSort($$)                                                           # As described at: https://en.wikipedia.org/wiki/Selection_sort
 {my ($array, $name) = @_;                                                      # Array, name of array memory

  my $N = ArraySize $array, $name;                                              # Size of array

  For                                                                           # Outer loop
   {my ($i) = @_;
    my  $a  = Mov [$array, \$i, $name];                                         # Index into array

    For                                                                         # Inner loop
     {my ($j) = @_;
      my  $b  = Mov [$array, \$j, $name];

      IfGt $a, $b,
      Then                                                                      # Swap elements to place smaller element lower in array
       {Parallel
          sub {Mov [$array, \$i, $name], $b},
          sub {Mov [$array, \$j, $name], $a};
        Mov $a, $b;
       };
     } [$i, $N];                                                                # Move up through array
   } $N;
 }

if (1)                                                                          # Small array
 {Start 1;
  my $a = Array "array";
  my @a = qw(6 8 4 2 1 3 5 7);
  Push $a, $_, "array" for @a;                                                  # Load array

  selectionSort($a, "array");                                                   # Sort

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program

  is_deeply $e->outLines, [1 .. 8];

  is_deeply $e->count,           285;                                           # Instructions executed
  is_deeply $e->timeParallel,    270;
  is_deeply $e->timeSequential,  285;

  #say STDERR formatTable($e->counts); exit;
  is_deeply formatTable($e->counts), <<END;
add        44
array       1
arraySize   1
jGe        53
jLe        36
jmp        44
mov        98
push        8
END
 }

if (1)                                                                          # Reversed array 4 times larger
 {Start 1;
  my $a = Array "array";
  my @a = reverse 1..32;
  Push $a, $_, "array" for @a;

  selectionSort($a, "array");

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program

  is_deeply $e->outLines, [1 .. 32];
  is_deeply $e->count, 4356;                                                    # Approximately 4*4== 16 times bigger
  is_deeply $e->timeParallel,    3860;
  is_deeply $e->timeSequential,  4356;
 }
