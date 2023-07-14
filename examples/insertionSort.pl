#!/usr/bin/perl -Ilib -I../lib -I/home/phil/perl/cpan/ZeroEmulator/LowLevel/lib/
#-------------------------------------------------------------------------------
# Zero assembler programming language of in situ insertion sort
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
use Test::More tests=>2;

sub insertionSort($$)                                                           # As described at: https://en.wikipedia.org/wiki/Insertion_sort
 {my ($array, $name) = @_;                                                      # Array, name of array memory

  my $N = ArraySize $array, $name;                                              # Size of array

  For                                                                           # Outer loop
   {my ($i) = @_;
    my $a = Mov [$array, \$i, $name];

    Block
     {my ($Start, $Good, $Bad, $End) = @_;
      For                                                                       # Inner loop
       {my ($j) = @_;
        my  $b  = Mov [$array, \$j, $name];

        IfLt $a, $b,
        Then                                                                    # Move up
         {Mov [$array, \$j, $name, 1], $b;
         },
        Else                                                                    # Insert
         {Mov [$array, \$j, $name, 1], $a;
          Jmp $End;
         };
       } $i, reverse=>1;
       Jmp $Bad;
     }                                                                          # NB: a comma here would be dangerous as the first block is a standalone sub
    Bad                                                                         # Insert at start
     {Mov [$array, \0, $name], $a;
     };
   } [1, $N];
 }

if (1)                                                                          # Small array
 {Start 1;
  my $a = Array "array";
  my @a = qw(6 8 4 2 1 3 5 7);
  Push $a, $_, "array" for @a;                                                  # Load array

  insertionSort($a, "array");                                                   # Sort

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program

  is_deeply $e->outLines, [1 .. 8];

  is_deeply $e->count, 188 unless $e->assembly->lowLevelOps or  1;              # Instructions executed
  is_deeply $e->count, 266 if     $e->assembly->lowLevelOps and 0;              # Instructions executed

  #say STDERR formatTable($e->counts); exit;
  is_deeply formatTable($e->counts), <<END unless $e->assembly->lowLevelOps or 1;
add         7
array       1
arraySize   1
jGe        27
jLt        22
jmp        44
mov        49
push        8
subtract   29
END

  is_deeply formatTable($e->counts), <<END if     $e->assembly->lowLevelOps and 0;
add          7
array        1
arraySize    1
jGe         27
jLt         22
jmp         44
mov         49
movHeapOut   2
movRead1    26
movRead2    26
movWrite1   22
push         8
start        1
start2       1
subtract    29
END
 }

if (1)                                                                          # Reversed array 4 times larger
 {Start 1;
  my $a = Array "array";
  my @a = reverse 1..32;
  Push $a, $_, "array" for @a;

  insertionSort($a, "array");

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program

  is_deeply $e->outLines, [1 .. 32];
  is_deeply $e->count, 3787 unless $e->assembly->lowLevelOps or  1;             # Approximately 4*4== 16 times bigger
  is_deeply $e->count, 5372 if     $e->assembly->lowLevelOps and 0;             # Approximately 4*4== 16 times bigger
 }
