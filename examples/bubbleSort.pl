#!/usr/bin/perl -Ilib -I../lib -I/home/phil/perl/cpan/ZeroEmulator/LowLevel/lib/
#-------------------------------------------------------------------------------
# Zero assembler programming language of in situ bubble sort
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
use Test::More tests=>1;

sub bubbleSort($$)                                                              # As described at: https://en.wikipedia.org/wiki/Bubble_sort
 {my ($array, $name) = @_;                                                      # Array, name of array memory

  my $N = ArraySize $array, $name;                                              # Size of array

  For                                                                           # Outer loop
   {my ($i, $start, $check, $end) = @_;                                         # Loop labels
    my $l = Subtract $N, $i;                                                    # An array of one element is already sorted
    my $c = Mov 0;                                                              # Count number of swaps

    For                                                                         # Inner loop
     {my ($j) = @_;
      my $a = Mov [$array, \$j, $name];
      my $b = Mov [$array, \$j, $name, -1];

      IfLt $a, $b,
      Then                                                                      # Swap elements to place smaller element lower in array
       {Mov [$array, \$j, $name, -1], $a;
        Mov [$array, \$j, $name],     $b;
        Inc $c;
       };
     } [1, $l];
    JFalse $end, $c;                                                            # Stop if the array is now sorted
   } $N;
 }

if (1)                                                                          # Small array
 {Start 1;
  my $a = Array 'array';
  my @a = qw(33 11 22 44 77 55 66 88);
  Push $a, $_, 'array' for @a;                                                  # Load array

  bubbleSort $a, 'array';                                                       # Sort
  Out [$a, \$_, 'array'] for keys @a;

  my $e = Execute(suppressOutput=>1);                                           # Execute
  #say STDERR generateVerilogMachineCode("Bubble_sort");
  #say STDERR $e->PrintHeap->($e); exit;
  is_deeply $e->PrintHeap->($e), <<END;
Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
 0  8 | 11 22 33 44 55 66 77 88
END
  #is_deeply $e->outLines, [11, 22, 33];

  is_deeply $e->count, 115 unless $e->assembly->lowLevelOps or  1;
  is_deeply $e->count, 195 if     $e->assembly->lowLevelOps and 0;

  #say STDERR formatTable($e->counts); exit;
  is_deeply formatTable($e->counts), <<END unless $e->assembly->lowLevelOps or 1;
add        18
array       1
arraySize   1
jFalse      2
jGe        30
jmp        14
mov        39
push        8
subtract    2
END

  is_deeply formatTable($e->counts), <<END if     $e->assembly->lowLevelOps and 0;
add         18
array        1
arraySize    1
jFalse       2
jGe         30
jmp         14
mov         39
movHeapOut   2
movRead1    34
movRead2    34
movWrite1    8
push         8
start        1
start2       1
subtract     2
END
 }
