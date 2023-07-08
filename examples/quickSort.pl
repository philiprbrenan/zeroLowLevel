#!/usr/bin/perl -Ilib -I../lib -I/home/phil/perl/cpan/ZeroEmulator/lib/
#-------------------------------------------------------------------------------
# Zero assembler programming language of in situ quick sort
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
use Test::More tests=>5;

sub swap($$$$)                                                                  # Swap two elements of a named array
 {my ($array, $name, $a, $b) = @_;                                              # Array, name of array, first index, second index
  my $A = Mov [$array, \$a, $name];
  my $B = Mov [$array, \$b, $name];

          Mov [$array, \$a, $name], $B;
          Mov [$array, \$b, $name], $A;
 }

sub partition($$$$)                                                             # Partition a sub array starting at the low end and working up. Start and end of partition. Return index of pivot in Z
 {my ($array, $name, $start, $end) = @_;                                        # Array, name of array, start - inclusive, end - exclusive

  if (1)                                                                        # Randomize first element of the partition to mitigate worst case performance
   {my $d = Subtract $end, $start;
    my $r = ShiftRight $d, 1;
    my $s = Add $start, $r;
    swap($array, $name, $start, $s);
   }
  my $p = Mov $start;                                                           # Pivot point: the pivot value is assumed to be the first element of the partition

  For                                                                           # Partition around pivot
   {my ($i) = @_;                                                               # Position in array being paritioned
    IfLt [$array, \$i, $name], [$array, \$p, $name],                            # Less than pivot so move into lower partition
    Then
     {my $p1 = Add $p, 1;
      IfEq $i, $p1,
      Then
       {swap($array, $name, $p, $i);
       },
      Else                                                                      # Move pivot up to make room for new element not adjacent with the pivot
       {my $P = Mov [$array, \$p,  $name];
        my $Q = Mov [$array, \$p1, $name];
        my $A = Mov [$array, \$i,  $name];                                      # Both exist because i > p + 1 and t >= s

        Mov [$array, \$p,  $name], $A;
        Mov [$array, \$p1, $name], $P;
        Mov [$array, \$i,  $name], $Q;
       };
      Inc $p;                                                                   # Move pivot point up
     };
   } [$start, $end];
  $p                                                                            # Return pivot
 }

sub quickSort($$)                                                               # Quick Sort an array using a stack to track the partitions rather than recursion
 {my ($array, $name) = @_;                                                      # Array, name of array
  my $S = Array "start";                                                        # Start of each partition to be sorted
  my $E = Array "end";                                                          # End   of each partition to be sorted
  my $N = ArraySize $array, $name;                                              # Size of array

  Push $S, 0, "start"; Push $E, $N, "end";                                      # Initial partition

  Block                                                                         # Each partition
   {my ($start, $good, $bad, $end) = @_;                                        # Block labels
    my $s = Pop $S, "start";                                                    # Start of partition
    my $e = Pop $E, "end";                                                      # End of partition
    my $d = Subtract $e, $s;                                                    # Size of the partition

    Jlt $good, $d, 2;                                                           # The partition is already sorted

    IfLt $d, 4,
    Then                                                                        # Sort a small partition with insertion sort
     {For                                                                       # Outer loop
       {my ($i) = @_;
        my $a = Mov [$array, \$i, $name];

        Block
         {my ($Start, $Good, $Bad, $End) = @_;
          For                                                                   # Inner loop
           {my ($j) = @_;
            my  $b  = Mov [$array, \$j, $name];

            IfLt $a, $b,
            Then                                                                # Move up
             {Mov [$array, \$j, $name, 1], $b;
             },
            Else                                                                # Insert
             {Mov [$array, \$j, $name, 1], $a;
              Jmp $End;
             };
           } $i, reverse=>1;
           Jmp $Bad;
         }                                                                      # NB: a comma here would be dangerous as the first block is a standalone sub
        Bad                                                                     # Insert at start
         {Mov [$array, \0, $name], $a;
         };
       } [$s, $e];

       Jmp $good;
     };

    my $q = partition($array, $name, $s, $e);                                   # Pivot points
    my $Q = Add $q, 1;
    Push $S, $s, "start";  Push $E, $q, "end";                                  # New lower partition to sort
    Push $S, $Q, "start";  Push $E, $e, "end";                                  # New upper partition to sort
    Jmp $good;
   }                                                                            # NB: a comma here would be dangerous as the first block is a standalone sub
  Good                                                                          # Restart the loop if we still have partitions to sort
   {my ($start, $good, $bad, $end) = @_;                                        # Block labels
    my $N = ArraySize $S, "start";
    JTrue $start, $N;
   };
 }

if (1)                                                                          # Small array
 {Start 1;
  my $a = Array "array";
  my @a = qw(6 8 4 2 1 3 5 7);
  Push $a, $_, "array" for @a;                                                  # Load array

  quickSort $a, "array";                                                        # Sort

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program
  is_deeply $e->outLines, [1 .. 8];

  is_deeply $e->count,  284;                                                    # Instructions executed

  #say STDERR formatTable($e->counts); exit;
  is_deeply formatTable($e->counts), <<END;                                     # Counts of each instruction type executed
add         39
array        3
arraySize    8
jGe         57
jLt         12
jNe          5
jTrue        7
jmp         37
mov         58
pop         14
push        22
shiftRight   3
subtract    19
END
 }

if (1)                                                                          # Reversed array 4 times larger
 {Start 1;
  my $a = Array "array";
  my @a = reverse 1..32;
  Push $a, $_, "array" for @a;

  quickSort $a, "array";                                                        # Quick sort

  ArrayOut $a;

  my $e = Execute(suppressOutput=>1);                                           # Execute assembler program

  is_deeply $e->outLines, [1 .. 32];
  is_deeply $e->count, 1433;                                                    # Approximately 5 times bigger
 }
