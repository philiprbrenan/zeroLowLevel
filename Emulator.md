# Name

Zero::Emulator - Assemble and emulate a program written in the [Zero](https://github.com/philiprbrenan/zeroLowLevel) assembler programming language.

<div>

    <p><a href="https://github.com/philiprbrenan/zeroLowLevel"><img src="https://github.com/philiprbrenan/zeroLowLevel/workflows/Test/badge.svg"></a>
</div>

# Synopsis

Say "hello world":

    Start 1;

    Out "Hello World";

    my $e = Execute;

    is_deeply $e->out, <<END;
  Hello World
  END

# Description

Version 20230519.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Immediately useful methods

These methods are the ones most likely to be of immediate use to anyone using
this module for the first time:

[ArrayOut($target)](#arrayout-target)

Write an array to out

# Instruction Set

The instruction set used by the Zero assembler programming language.

## Add($target, $s1, $s2)

Add the source locations together and store the result in the target area.

       Parameter  Description
    1  $target    Target address
    2  $s1        Source one
    3  $s2        Source two

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Add 3, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out  $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [5];
    
      $e->generateVerilogMachineCode("Add") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Array($source)

Create a new memory area and write its number into the address named by the target operand.

       Parameter  Description
    1  $source    Name of allocation

**Example:**

    if (1)                                                                           
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov     [$a,  0, "aaa"],  11;
      Mov     [$a,  1, "aaa"],  22;
    
      my $A = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov     [$A,  1, "aaa"],  33;
      my $B = Mov [$A, \1, "aaa"];
      Out     [$a,  \0, "aaa"];
      Out     [$a,  \1, "aaa"];
      Out     $B;
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11, 22, 33];
    
      $e->generateVerilogMachineCode("Array") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    
    if (1)                                                                           
     {Start 1;
    
      my $a = Array "alloc";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = Mov 99;
      my $c = Mov $a;
      Mov [$a, 0, 'alloc'], $b;
      Mov [$c, 1, 'alloc'], 2;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->Heap->($e, 0), [99, 2];
     }
    
    if (1)                                                                            
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Dump;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Stack trace:
        1     2 dump
    END
     }
    
    if (1)                                                                              
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $i = Mov 1;
      my $v = Mov 11;
      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
      Call $set;
      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11];
     }
    
    if (0)                                                                           
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      #Clear $a, 10, 'aaa';
      my $e = &$ee(suppressOutput=>1, maximumArraySize=>10);
      is_deeply $e->Heap->($e, 0), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
     }
    
    if (1)                                                                            
     {Start 1;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        Out $a;
       };
      ParamsPut 0, 1;  Call $set;
      ParamsPut 0, 2;  Call $set;
      ParamsPut 0, 3;  Call $set;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    3
    END
     }
    
    if (1)                                                                           
     {Start 1;
    
      my $a = Array 'aaa';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = Mov 2;                                                                # Location to move to in a
      Mov [$a,  0, 'aaa'], 1;
      Mov [$a,  1, 'aaa'], 2;
      Mov [$a,  2, 'aaa'], 3;
    
      For
       {my ($i, $check, $next, $end) = @_;
        Out 1;
        Jeq $next, [$a, \$i, 'aaa'], 2;
        Out 2;
       } 3;
    
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed";
      is_deeply $e->outLines, [1, 2, 1, 1, 2];
      $e->generateVerilogMachineCode("Mov2") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                          
     {Start 1;
    
      For                                                                           # Allocate and free several times to demonstrate area reuse
       {my ($i) = @_;
    
        my $a = Array 'aaaa';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Mov [$a, 0, 'aaaa'], $i;
        Free $a, 'aaaa';
        Dump;
       } 3;
    
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->counts,                                                         # Several allocations and frees
       {array=>3, free=>3, add=>3, jGe=>4, jmp=>3, mov=>4
       };
      is_deeply $e->out, <<END;
    Stack trace:
        1     8 dump
    Stack trace:
        1     8 dump
    Stack trace:
        1     8 dump
    END
     }
    
    if (1)                                                                             
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Parallel
        sub{Mov [$a, 0, "aaa"], 1},
        sub{Mov [$a, 1, "aaa"], 22},
        sub{Mov [$a, 2, "aaa"], 333};
    
      my $n = ArraySize $a, "aaa";
    
      Out "Array size:";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $n;
      ArrayDump $a;
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->Heap->($e, 0), [1, 22, 333];
      is_deeply $e->out, <<END;
    
    Array size:  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    3
    bless([1, 22, 333], "aaa")
    0
    1
    1
    22
    2
    333
    END
     }
    

## ArrayCountLess()

Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
    
    
      Out ArrayCountLess($a, 20);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    END
    
      $e->generateVerilogMachineCode("ArrayCountLess") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
      Resize $a, 3, "aaa";
    
      Out ArrayIndex       ($a, 30); Out ArrayIndex       ($a, 20); Out ArrayIndex       ($a, 10); Out ArrayIndex       ($a, 15);
    
      Out ArrayCountLess   ($a, 35); Out ArrayCountLess   ($a, 25); Out ArrayCountLess   ($a, 15); Out ArrayCountLess   ($a,  5);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out ArrayCountGreater($a, 35); Out ArrayCountGreater($a, 25); Out ArrayCountGreater($a, 15); Out ArrayCountGreater($a,  5);
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->outLines, [qw(3 2 1 0 3 2 1 0 0 1 2 3)];
      $e->generateVerilogMachineCode("Array_scans") if $testSet == 1 and $debug;
     }
    

## ArrayCountGreater()

Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
    
    
      Out ArrayCountGreater($a, 15);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    2
    END
      $e->generateVerilogMachineCode("ArrayCountGreaterIndex") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
      Resize $a, 3, "aaa";
    
      Out ArrayIndex       ($a, 30); Out ArrayIndex       ($a, 20); Out ArrayIndex       ($a, 10); Out ArrayIndex       ($a, 15);
      Out ArrayCountLess   ($a, 35); Out ArrayCountLess   ($a, 25); Out ArrayCountLess   ($a, 15); Out ArrayCountLess   ($a,  5);
    
      Out ArrayCountGreater($a, 35); Out ArrayCountGreater($a, 25); Out ArrayCountGreater($a, 15); Out ArrayCountGreater($a,  5);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->outLines, [qw(3 2 1 0 3 2 1 0 0 1 2 3)];
      $e->generateVerilogMachineCode("Array_scans") if $testSet == 1 and $debug;
     }
    

## ArrayDump($target)

Dump an array.

       Parameter  Description
    1  $target    Array to dump

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
      Mov [$a, 0, "aaa"], 1;
      Mov [$a, 1, "aaa"], 22;
      Mov [$a, 2, "aaa"], 333;
    
      ArrayDump $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
    
      is_deeply eval($e->out), [1, 22, 333];
    
      #say STDERR $e->block->codeToString;
    
      is_deeply $e->block->codeToString, <<'END' if $testSet % 2 == 1;
    0000     array            0             3
    0001       mov [\0, 0, 3, 0]             1
    0002       mov [\0, 1, 3, 0]            22
    0003       mov [\0, 2, 3, 0]           333
    0004  arrayDump            0
    END
    
      is_deeply $e->block->codeToString, <<'END' if $testSet % 2 == 0;
    0000     array [undef, 0, 3, 0]  [undef, 3, 3, 0]  [undef, 0, 3, 0]
    0001       mov [\0, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
    0002       mov [\0, 1, 3, 0]  [undef, 22, 3, 0]  [undef, 0, 3, 0]
    0003       mov [\0, 2, 3, 0]  [undef, 333, 3, 0]  [undef, 0, 3, 0]
    0004  arrayDump [undef, 0, 3, 0]  [undef, 0, 3, 0]  [undef, 0, 3, 0]
    END
     }
    

## ArrayOut($target)

Write an array to out

       Parameter  Description
    1  $target    Array to dump

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      ForIn
       {my ($i, $v, $Check, $Next, $End) = @_;
        Push $a, $v, "aaa";
       };
    
      ArrayOut $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1, in => [9,88,777]);
      is_deeply $e->out, "9 88 777";
    
    # $e->generateVerilogMachineCode("ArrayOut") if $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## ArrayIndex()

Store in the target location the 1 based index of the second source operand in the array referenced by the first source operand if the secound source operand is present somwhere in the array else store 0 into the target location.  If the sought element appears in multiple locations, any one of these locations can be chosen.  The business of returning a zero based result with -1 signalling an error would have led to the confusion of "try catch" and we certainly do not want that.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
    
    
      Out ArrayIndex       ($a, 20);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    2
    END
    
      $e->generateVerilogMachineCode("ArrayIndex") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov   [$a, 0, "aaa"], 10;
      Mov   [$a, 1, "aaa"], 20;
      Mov   [$a, 2, "aaa"], 30;
      Resize $a, 3, "aaa";
    
    
      Out ArrayIndex       ($a, 30); Out ArrayIndex       ($a, 20); Out ArrayIndex       ($a, 10); Out ArrayIndex       ($a, 15);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out ArrayCountLess   ($a, 35); Out ArrayCountLess   ($a, 25); Out ArrayCountLess   ($a, 15); Out ArrayCountLess   ($a,  5);
      Out ArrayCountGreater($a, 35); Out ArrayCountGreater($a, 25); Out ArrayCountGreater($a, 15); Out ArrayCountGreater($a,  5);
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->outLines, [qw(3 2 1 0 3 2 1 0 0 1 2 3)];
      $e->generateVerilogMachineCode("Array_scans") if $testSet == 1 and $debug;
     }
    

## ArraySize($area, $name)

The current size of an array.

       Parameter  Description
    1  $area      Location of area
    2  $name      Name of area

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
    
      Out ArraySize $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArraySize $b, "bbb";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Free $b, "bbb";
    
      Out ArraySize $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Free $a, "aaa";
    
      Out ArraySize $a, "aaa";                                                      #FIX - an unalocated array should not be accessible  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    0
    0
    0
    No such with array: 0 in arena 1
        1    11 arraySize
    END
     }
    
    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
      Parallel
        sub{Mov [$a, 0, "aaa"], 1},
        sub{Mov [$a, 1, "aaa"], 22},
        sub{Mov [$a, 2, "aaa"], 333};
    
    
      my $n = ArraySize $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out "Array size:";
      Out $n;
      ArrayDump $a;
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->Heap->($e, 0), [1, 22, 333];
      is_deeply $e->out, <<END;
    Array size:
    3
    bless([1, 22, 333], "aaa")
    0
    1
    1
    22
    2
    333
    END
     }
    

## Assert(%options)

Assert regardless.

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Assert;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    
    Assert failed  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        1     1 assert
    END
     }
    

## AssertEq($a, $b, %options)

Assert two memory locations are equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertEq \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 == 2 failed
        1     2 assertEq
    END
     }
    

## AssertFalse($a, %options)

Assert false.

       Parameter  Description
    1  $a         Source operand
    2  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      AssertTrue  1;
    
      AssertFalse 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1, trace=>1);
      #say STDERR dump($e->out);
    
      is_deeply $e->out, <<END;
        1     0     0    16    assertTrue
    
    AssertFalse 1 failed  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        1     2 assertFalse
        2     1     0    10   assertFalse
    END
     }
    

## AssertGe($a, $b, %options)

Assert that the first value is greater than or equal to the second value.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertGe \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 >= 2 failed
        1     2 assertGe
    END
     }
    

## AssertGt($a, $b, %options)

Assert that the first value is greater than the second value.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertGt \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 >  2 failed
        1     2 assertGt
    END
     }
    

## AssertLe($a, $b, %options)

Assert that the first value is less than or equal to the second value.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertLe \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 <= 0 failed
        1     2 assertLe
    END
     }
    

## AssertLt($a, $b, %options)

Assert that the first value is less than  the second value.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertLt \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 <  0 failed
        1     2 assertLt
    END
     }
    

## AssertNe($a, $b, %options)

Assert two memory locations are not equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertNe \0, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Assert 1 != 1 failed
        1     2 assertNe
    END
     }
    

## AssertTrue($a, %options)

Assert true.

       Parameter  Description
    1  $a         Source operand
    2  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      AssertFalse 0;
    
      AssertTrue  0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1, trace=>1);
      #say STDERR dump($e->out);
    
      is_deeply $e->out, <<END;
        1     0     0    10   assertFalse
    
    AssertTrue 0 failed  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        1     2 assertTrue
        2     1     0    16    assertTrue
    END
     }
    

## Bad($bad)

A bad ending to a block of code.

       Parameter  Description
    1  $bad       What to do on a bad ending

**Example:**

    if (1)                                                                            
     {Start 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
      Good
       {Out 2;
       },
    
      Bad  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 3;
       };
      Out 4;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    4
    END
     }
    

## Block($block, %options)

Block of code that can either be restarted or come to a good or a bad ending.

       Parameter  Description
    1  $block     Block
    2  %options   Options

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Block  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
      Good
       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    4
    END
     }
    
    if (1)                                                                          
     {Start 1;
    
      Block  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $bad;
       }
      Good
       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    3
    4
    END
     }
    

## Call($p)

Call the subroutine at the target address.

       Parameter  Description
    1  $p         Procedure description.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $w = Procedure 'write', sub
       {Out 1;
        Return;
       };
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1];
     }
    
    if (1)                                                                          
     {Start 1;
      my $w = Procedure 'write', sub
       {my $a = ParamsGet 0;
        Out $a;
        Return;
       };
      ParamsPut 0, 999;
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [999];
     }
    
    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
       {ReturnPut 0, 999;
        Return;
       };
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ReturnGet \0, 0;
      Out \0;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [999];
     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Dump;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Stack trace:
        1     2 dump
    END
     }
    
    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
    
      Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11];
     }
    
    if (1)                                                                            
     {Start 1;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        Out $a;
       };
    
      ParamsPut 0, 1;  Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 0, 2;  Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 0, 3;  Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    3
    END
     }
    

## Confess()

Confess with a stack trace showing the location both in the emulated code and in the code that produced the emulated code.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $c = Procedure 'confess', sub
    
       {Confess;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       };
      Call $c;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    
    Confess at:  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        2     3 confess
        1     6 call
    END
     }
    

## Dec($target)

Decrement the target.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      Dec $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
     }
    

## Dump()

Dump all the arrays currently in memory.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "node";
      Out $a;
      Mov [$a, 1, 'node'], 1;
      Mov [$a, 2, 'node'], 2;
      Out Mov [$a, \1, 'node'];
      Out Mov [$a, \2, 'node'];
      Free $a, "node";
      my $e = Execute(suppressOutput=>1);
      #say STDERR $e->PrintHeap->($e); exit;
      is_deeply $e->PrintHeap->($e), <<END;
    Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
    END
      is_deeply $e->outLines, [0..2];
     }
    

## Else($e)

Else block.

       Parameter  Description
    1  $e         Else block subroutine

**Example:**

    if (1)                                                                            
     {Start 1;
      IfFalse 1,
      Then
       {Out 1
       },
    
      Else  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 0
       };
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0];
     }
    
    if (1)                                                                            
     {Start 1;
      Trace 1;
      IfEq 1, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
    
      Else  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
    
      Else  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->out, <<END;
    Trace: 1
        1     0     0    59         trace
        2     1     1    29           jNe
        3     5     0    32         label
        4     6     1    35           mov  [0, 3, stackArea] = 3
        5     7     1    35           mov  [0, 4, stackArea] = 4
        6     8     0    32         label
        7     9     1    29           jNe
        8    10     1    35           mov  [0, 1, stackArea] = 1
        9    11     1    35           mov  [0, 2, stackArea] = 1
       10    12     1    31           jmp
       11    16     0    32         label
    END
    
      is_deeply scalar($e->notExecuted->@*), 6;
     }
    

## Execute(%options)

Execute the current assembly.

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                            
     {Start 1;
      Out "Hello World";
    
      my $e = Execute(suppressOutput=>1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $e->out, <<END;
    Hello World
    END
     }
    

## For($block, $range, %options)

For loop 0..range-1 or in reverse.

       Parameter  Description
    1  $block     Block
    2  $range     Limit
    3  %options   Options

**Example:**

    if (1)                                                                          
     {Start 1;
    
      For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i) = @_;
        Out $i;
       } 10;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0..9];
     }
    
    if (1)                                                                          
     {Start 1;
    
      For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i) = @_;
        Out $i;
       } 10, reverse=>1;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [reverse 0..9];
     }
    
    if (1)                                                                          
     {Start 1;
    
      For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i) = @_;
        Out $i;
       } [2, 10];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2..9];
     }
    
    if (1)                                                                           
     {my $N = 5;
      Start 1;
    
      For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Tally 1;
        my $a = Mov 1;
        Tally 2;
        Inc $a;
        Tally 0;
       } $N;
      my $e = Execute;
    
      is_deeply $e->tallyCount, 2 * $N;
      is_deeply $e->tallyCounts, { 1 => {mov => $N}, 2 => {add => $N}};
     }
    

## ForArray($block, $area, $name, %options)

For loop to process each element of the named area.

       Parameter  Description
    1  $block     Block of code
    2  $area      Area
    3  $name      Area name
    4  %options   Options

**Example:**

    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
      Parallel
        sub{Mov [$a, 0, "aaa"], 1},
        sub{Mov [$a, 1, "aaa"], 22},
        sub{Mov [$a, 2, "aaa"], 333};
    
      my $n = ArraySize $a, "aaa";
      Out "Array size:";
      Out $n;
      ArrayDump $a;
    
    
      ForArray  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->Heap->($e, 0), [1, 22, 333];
      is_deeply $e->out, <<END;
    Array size:
    3
    bless([1, 22, 333], "aaa")
    0
    1
    1
    22
    2
    333
    END
     }
    

## ForIn($block, %options)

For loop to process each element remaining in the input channel

       Parameter  Description
    1  $block     Block of code
    2  %options   Area

**Example:**

    if (1)                                                                          
     {Start 1;
    
    
      ForIn  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       };
    
      my $e = Execute(suppressOutput=>1, trace=>0, in=>[333, 22, 1]);
    
      $e->generateVerilogMachineCode("ForIn") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $e->outLines, [3, 333,  2, 22, 1, 1];
     }
    
    if (1)                                                                          
     {Start 1;
    
      ForIn  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i, $v, $Check, $Next, $End) = @_;
        Out $i;
        Out $v;
       };
      my $e = Execute(suppressOutput=>1, in => [33,22,11]);
      is_deeply $e->outLines, [3,33, 2,22, 1,11];
      $e->generateVerilogMachineCode("In") if $debug;
     }
    

## Free($target, $source)

Free the memory area named by the target operand after confirming that it has the name specified on the source operand.

       Parameter  Description
    1  $target    Target area yielding the id of the area to be freed
    2  $source    Source area yielding the name of the area to be freed

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "node";
    
      Free $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Wrong name: aaa for array with name: node
        1     2 free
    END
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "node";
      Out $a;
      Mov [$a, 1, 'node'], 1;
      Mov [$a, 2, 'node'], 2;
      Out Mov [$a, \1, 'node'];
      Out Mov [$a, \2, 'node'];
    
      Free $a, "node";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      #say STDERR $e->PrintHeap->($e); exit;
      is_deeply $e->PrintHeap->($e), <<END;
    Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
    END
      is_deeply $e->outLines, [0..2];
     }
    

## Good($good)

A good ending to a block of code.

       Parameter  Description
    1  $good      What to do on a good ending

**Example:**

    if (1)                                                                            
     {Start 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
    
      Good  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    4
    END
     }
    

## IfEq($a, $b, %options)

Execute then or else clause depending on whether two memory locations are equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $a, $a, Then {Out 111};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $a, $a, Then {Out 222};
      IfLe $a, $a, Then {Out 333};
      IfLt $a, $a, Then {Out 444};
      IfGe $a, $a, Then {Out 555};
      IfGt $a, $a, Then {Out 666};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $a, $b, Then {Out "Eq"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $b, $a, Then {Out "Eq"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfFalse($a, %options)

Execute then clause if the specified memory address is zero thus representing false.

       Parameter  Description
    1  $a         Memory address
    2  %options   Then block

**Example:**

    if (1)                                                                            
     {Start 1;
    
      IfFalse 1,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Then
       {Out 1
       },
      Else
       {Out 0
       };
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0];
     }
    

## IfGe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are greater than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out 111};
      IfNe $a, $a, Then {Out 222};
      IfLe $a, $a, Then {Out 333};
      IfLt $a, $a, Then {Out 444};
    
      IfGe $a, $a, Then {Out 555};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $a, $a, Then {Out 666};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
    
      IfGe $a, $b, Then {Out "Ge"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
    
      IfGe $b, $a, Then {Out "Ge"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfGt($a, $b, %options)

Execute then or else clause depending on whether two memory locations are greater than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out 111};
      IfNe $a, $a, Then {Out 222};
      IfLe $a, $a, Then {Out 333};
      IfLt $a, $a, Then {Out 444};
      IfGe $a, $a, Then {Out 555};
    
      IfGt $a, $a, Then {Out 666};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
    
      IfGt $a, $b, Then {Out "Gt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
    
      IfGt $b, $a, Then {Out "Gt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfNe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are not equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out 111};
    
      IfNe $a, $a, Then {Out 222};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $a, $a, Then {Out 333};
      IfLt $a, $a, Then {Out 444};
      IfGe $a, $a, Then {Out 555};
      IfGt $a, $a, Then {Out 666};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
    
      IfNe $a, $b, Then {Out "Ne"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
    
      IfNe $b, $a, Then {Out "Ne"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfLe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are less than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out 111};
      IfNe $a, $a, Then {Out 222};
    
      IfLe $a, $a, Then {Out 333};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $a, $a, Then {Out 444};
      IfGe $a, $a, Then {Out 555};
      IfGt $a, $a, Then {Out 666};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
    
      IfLe $a, $b, Then {Out "Le"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
    
      IfLe $b, $a, Then {Out "Le"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfLt($a, $b, %options)

Execute then or else clause depending on whether two memory locations are less than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out 111};
      IfNe $a, $a, Then {Out 222};
      IfLe $a, $a, Then {Out 333};
    
      IfLt $a, $a, Then {Out 444};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $a, $a, Then {Out 555};
      IfGt $a, $a, Then {Out 666};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    111
    333
    555
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
    
      IfLt $a, $b, Then {Out "Lt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Le
    Lt
    END
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
    
      IfLt $b, $a, Then {Out "Lt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Ne
    Ge
    Gt
    END
     }
    

## IfTrue($a, %options)

Execute then clause if the specified memory address is not zero thus representing true.

       Parameter  Description
    1  $a         Memory address
    2  %options   Then block

**Example:**

    if (1)                                                                          
     {Start 1;
    
      IfTrue 1,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Then
       {Out 1
       },
      Else
       {Out 0
       };
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1];
     }
    

## In(if (@\_ == 0))

Read a value from the input channel

       Parameter     Description
    1  if (@_ == 0)  Create a new stack frame variable to hold the value read from input

**Example:**

    if (1)                                                                           
     {Start 1;
      my $i2 = InSize;
    
      my $a = In;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $i1 = InSize;
    
      my $b = In;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $i0 = InSize;
      Out $a;
      Out $b;
      Out $i2;
      Out $i1;
      Out $i0;
      my $e = Execute(suppressOutput=>1, in=>[88, 44]);
      is_deeply $e->outLines, [88, 44, 2, 1, 0];
      $e->generateVerilogMachineCode("InSize") if $testSet == 1 and $debug;
     }
    

## InSize(if (@\_ == 0))

Number of elements remining in the input channel

       Parameter     Description
    1  if (@_ == 0)  Create a new stack frame variable to hold the value read from input

**Example:**

    if (1)                                                                           
     {Start 1;
    
      my $i2 = InSize;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $a = In;
    
      my $i1 = InSize;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = In;
    
      my $i0 = InSize;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      Out $b;
      Out $i2;
      Out $i1;
      Out $i0;
      my $e = Execute(suppressOutput=>1, in=>[88, 44]);
      is_deeply $e->outLines, [88, 44, 2, 1, 0];
    
      $e->generateVerilogMachineCode("InSize") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Inc($target)

Increment the target.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      Inc $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [4];
     }
    

## Jeq($target, $source, $source2)

Jump to a target label if the first source field is equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jeq $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                          
     {Start 1;
      Block
       {my ($Start, $Good, $Bad, $End) = @_;
    
        my $a = Mov 1;
        my $b = Mov 2;
    
        Jeq $Good, $a, $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 111;
    
        Jeq $Good, $a, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 222;
       }
      Good
       {Out 333;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->outLines, [111, 333];
    
      $e->generateVerilogMachineCode("Jeq") if $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## JFalse($target, $source)

Jump to a target label if the first source field is equal to zero.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          JFalse $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          JFalse $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
    
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Jge($target, $source, $source2)

Jump to a target label if the first source field is greater than or equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jge  $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## Jgt($target, $source, $source2)

Jump to a target label if the first source field is greater than the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jgt  $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## Jle($target, $source, $source2)

Jump to a target label if the first source field is less than or equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jle $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## Jlt($target, $source, $source2)

Jump to a target label if the first source field is less than the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jlt  $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## Jmp($target)

Jump to a label.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Jmp (my $a = label);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out  1;
    
        Jmp (my $b = label);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      setLabel($a);
        Out  2;
      setLabel($b);
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
    
      $e->generateVerilogMachineCode("Jmp") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Jne($target, $source, $source2)

Jump to a target label if the first source field is not equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JTrue $end, $a;
          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          Jne $end, $a, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## JTrue($target, $source)

Jump to a target label if the first source field is not equal to zero.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test

**Example:**

    if (1)                                                                                 
     {Start 1;
      For
       {my ($a, $check, $next, $end) = @_;
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          JTrue $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 1;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 2;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
    
          JTrue $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          Out 3;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          JFalse $end, $a;
          Out 4;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jeq $end, $a, 3;
          Out 5;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jne $end, $a, 3;
          Out 6;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jle $end, $a, 3;
          Out 7;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jlt  $end, $a, 3;
          Out 8;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jge  $end, $a, 3;
          Out 9;
         };
        Block
         {my ($start, $good, $bad, $end) = @_;
          Jgt  $end, $a, 3;
          Out 10;
         };
       } 5;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
      $e->generateVerilogMachineCode("JFalse") if $testSet == 1 and $debug;
     }
    

## LoadAddress()

Load the address component of an address.

**Example:**

    if (0)                                                                           
     {Start 1;
      my $a = Array "array";
      my $b = Mov 2;
      my $c = Mov 5;
    
      my $d = LoadAddress $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $f = LoadArea    [$a, \0, 'array'];
    
      Out $d;
      Out $f;
    
      Mov [$a, \$b, 'array'], 22;
      Mov [$a, \$c, 'array'], 33;
      Mov [$f, \$d, 'array'], 44;
    
      my $e = &$ee(suppressOutput=>1, maximumArraySize=>6);
    
      is_deeply $e->out, <<END;
    2
    1
    END
    
      is_deeply $e->Heap->($e, 0), [undef, undef, 44, undef, undef, 33] if $testSet <= 2;
      is_deeply $e->Heap->($e, 0), [0,     0,     44, 0,     0,     33] if $testSet  > 2;
    
      is_deeply $e->widestAreaInArena, [undef, 5, 4];
      is_deeply $e->namesOfWidestArrays, [undef, "array", "stackArea"]   if $testSet % 2;
     }
    

## LoadArea()

Load the area component of an address.

**Example:**

    if (0)                                                                           
     {Start 1;
      my $a = Array "array";
      my $b = Mov 2;
      my $c = Mov 5;
      my $d = LoadAddress $c;
    
      my $f = LoadArea    [$a, \0, 'array'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out $d;
      Out $f;
    
      Mov [$a, \$b, 'array'], 22;
      Mov [$a, \$c, 'array'], 33;
      Mov [$f, \$d, 'array'], 44;
    
      my $e = &$ee(suppressOutput=>1, maximumArraySize=>6);
    
      is_deeply $e->out, <<END;
    2
    1
    END
    
      is_deeply $e->Heap->($e, 0), [undef, undef, 44, undef, undef, 33] if $testSet <= 2;
      is_deeply $e->Heap->($e, 0), [0,     0,     44, 0,     0,     33] if $testSet  > 2;
    
      is_deeply $e->widestAreaInArena, [undef, 5, 4];
      is_deeply $e->namesOfWidestArrays, [undef, "array", "stackArea"]   if $testSet % 2;
     }
    

## Mov()

Copy a constant or memory address to the target address.

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Mov 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
     }
    
     {Start 1;                                                                      
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
    
      Mov     [$a,  0, "aaa"],  11;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov     [$a,  1, "aaa"],  22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $A = Array "aaa";
    
      Mov     [$A,  1, "aaa"],  33;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $B = Mov [$A, \1, "aaa"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out     [$a,  \0, "aaa"];
      Out     [$a,  \1, "aaa"];
      Out     $B;
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11, 22, 33];
      $e->generateVerilogMachineCode("Array") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "alloc";
    
      my $b = Mov 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $c = Mov $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a, 0, 'alloc'], $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$c, 1, 'alloc'], 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->Heap->($e, 0), [99, 2];
     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Dump;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Stack trace:
        1     2 dump
    END
     }
    
    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
    
      my $i = Mov 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $v = Mov 11;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
    
        Mov [$a, \$i, 'aaa'], $v;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Return;
       };
      Call $set;
    
      my $V = Mov [$a, \$i, 'aaa'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11];
     }
    
    if (1)                                                                            
     {Start 1;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        Out $a;
       };
      ParamsPut 0, 1;  Call $set;
      ParamsPut 0, 2;  Call $set;
      ParamsPut 0, 3;  Call $set;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    1
    2
    3
    END
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array 'aaa';
    
      my $b = Mov 2;                                                                # Location to move to in a  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a,  0, 'aaa'], 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a,  1, 'aaa'], 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a,  2, 'aaa'], 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      For
       {my ($i, $check, $next, $end) = @_;
        Out 1;
        Jeq $next, [$a, \$i, 'aaa'], 2;
        Out 2;
       } 3;
    
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed";
      is_deeply $e->outLines, [1, 2, 1, 1, 2];
      $e->generateVerilogMachineCode("Mov2") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
    
      Mov [$a, 0, "aaa"], 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a, 1, "aaa"], 22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a, 2, "aaa"], 333;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ArrayDump $a;
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply eval($e->out), [1, 22, 333];
    
      #say STDERR $e->block->codeToString;
    
      is_deeply $e->block->codeToString, <<'END' if $testSet % 2 == 1;
    0000     array            0             3
    0001       mov [\0, 0, 3, 0]             1
    0002       mov [\0, 1, 3, 0]            22
    0003       mov [\0, 2, 3, 0]           333
    0004  arrayDump            0
    END
    
      is_deeply $e->block->codeToString, <<'END' if $testSet % 2 == 0;
    0000     array [undef, 0, 3, 0]  [undef, 3, 3, 0]  [undef, 0, 3, 0]
    0001       mov [\0, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
    0002       mov [\0, 1, 3, 0]  [undef, 22, 3, 0]  [undef, 0, 3, 0]
    0003       mov [\0, 2, 3, 0]  [undef, 333, 3, 0]  [undef, 0, 3, 0]
    0004  arrayDump [undef, 0, 3, 0]  [undef, 0, 3, 0]  [undef, 0, 3, 0]
    END
     }
    

## MoveLong($target, $source, $source2)

Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.

       Parameter  Description
    1  $target    Target of move
    2  $source    Source of move
    3  $source2   Length of move

**Example:**

    if (1)                                                                          
     {my $N = 10;
      Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      For
       {my ($i, $Check, $Next, $End) = @_;
        Mov [$a, \$i, "aaa"], $i;
        my $j = Add $i, 100;
        Mov [$b, \$i, "bbb"], $j;
       } $N;
    
    
      MoveLong [$b, \2, 'bbb'], [$a, \4, 'aaa'], 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = &$ee(suppressOutput=>1, maximumArraySize=>11);
      is_deeply $e->Heap->($e, 0), [0 .. 9];
      is_deeply $e->Heap->($e, 1), [100, 101, 4, 5, 6, 105 .. 109];
      $e->generateVerilogMachineCode("MoveLong_1") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, \0, 'aaa'],  11;
      Mov [$a, \1, 'aaa'],  22;
      Mov [$a, \2, 'aaa'],  33;
      Mov [$a, \3, 'aaa'],  44;
      Mov [$a, \4, 'aaa'],  55;
      Mov [$b, \0, 'bbb'],  66;
      Mov [$b, \1, 'bbb'],  77;
      Mov [$b, \2, 'bbb'],  88;
      Mov [$b, \3, 'bbb'],  99;
      Mov [$b, \4, 'bbb'], 101;
      Resize $a, 5, 'aaa';
      Resize $b, 5, 'bbb';
    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "aaa";
    
      ForArray
       {my ($i, $b, $Check, $Next, $End) = @_;
        Out $b;
       } $b, "bbb";
    
    
      MoveLong [$a, \1, 'aaa'], [$b, \2, 'bbb'], 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "aaa";
    
      ForArray
       {my ($i, $b, $Check, $Next, $End) = @_;
        Out $b;
       } $b, "bbb";
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->heap(0), bless([11, 88, 99, 44, 55], "aaa");
      is_deeply $e->heap(1), bless([66, 77, 88, 99, 101],"bbb");
      is_deeply $e->outLines, [11, 22, 33, 44, 55, 66, 77, 88, 99, 101, 11, 88, 99, 44, 55, 66, 77, 88, 99, 101];
      $e->generateVerilogMachineCode("MoveLong_2") if $debug;
     }
    

## Not()

Move and not.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      my $b = Not $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $c = Not $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      Out $b;
      Out $c;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, <<END;
    3
    0
    1
    END
    
      $e->generateVerilogMachineCode("Not") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Nop()

Do nothing (but do it well!).

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Nop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee;
      is_deeply $e->out, "";
     }
    
    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
      Parallel
        sub{Mov [$a, 0, "aaa"], 1},
        sub{Mov [$a, 1, "aaa"], 22},
        sub{Mov [$a, 2, "aaa"], 333};
    
      my $n = ArraySize $a, "aaa";
      Out "Array size:";
      Out $n;
      ArrayDump $a;
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
    
      Nop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->Heap->($e, 0), [1, 22, 333];
      is_deeply $e->out, <<END;
    Array size:
    3
    bless([1, 22, 333], "aaa")
    0
    1
    1
    22
    2
    333
    END
     }
    

## Out($source)

Write memory location contents to out.

       Parameter  Description
    1  $source    Value to write

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Out "Hello World";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Hello World
    END
     }
    

## ParamsGet()

Get a word from the parameters in the previous frame and store it in the current frame.

**Example:**

    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
    
       {my $a = ParamsGet 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $i = ParamsGet 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $v = ParamsGet 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
      Call $set;
      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11];
     }
    

## ParamsPut($target, $source)

Put a word into the parameters list to make it visible in a called procedure.

       Parameter  Description
    1  $target    Parameter number
    2  $source    Address to fetch parameter from

**Example:**

    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
    
      ParamsPut 0, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 1, $i;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 2, $v;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
      Call $set;
      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [11];
     }
    

## Pop(if (@\_ == 2))

Pop the memory area specified by the source operand into the memory address specified by the target operand.

       Parameter     Description
    1  if (@_ == 2)  Pop indicated area into a local variable

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array   "aaa";
      Push $a, 1,     "aaa";
      Push $a, 2,     "aaa";
    
      my $c = Pop $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $d = Pop $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out $c;
      Out $d;
      my $e = &$ee(suppressOutput=>1);
    
      #say STDERR $e->PrintLocal->($e); x;
      is_deeply $e->PrintLocal->($e), <<END;
    Memory    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31
    Local:    0    2    1
    END
      is_deeply $e->Heap->($e, 0), [];
      is_deeply $e->outLines, [2, 1];
    
      $e->generateVerilogMachineCode("Pop") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Procedure($name, $source)

Define a procedure.

       Parameter  Description
    1  $name      Name of procedure
    2  $source    Source code as a subroutine

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $add = Procedure 'add2', sub  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my $a = ParamsGet 0;
        my $b = Add $a, 2;
        ReturnPut 0, $b;
        Return;
       };
      ParamsPut 0, 2;
      Call $add;
      my $c = ReturnGet 0;
      Out $c;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [4];
     }
    
    if (1)                                                                          
     {Start 1;
      for my $i(1..10)
       {Out $i;
       };
      IfTrue 0,
      Then
       {Out 99;
       };
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1..10];
      is_deeply $e->outLines, [1..10];
     }
    

## Push($target, $source, $source2)

Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.

       Parameter  Description
    1  $target    Memory area to push to
    2  $source    Memory containing value to push
    3  $source2

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array   "aaa";
    
      Push $a, 1,     "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $a, 2,     "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      #say STDERR $e->PrintHeap->($e); x;
      is_deeply $e->PrintHeap->($e), <<END;
    Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
     0  2 |  1  2
    END
     }
    
    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
    
      Push $a, 1, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $a, 2, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $a, 3, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = Array "bbb";
    
      Push $b, 11, "bbb";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $b, 22, "bbb";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $b, 33, "bbb";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->GetMemoryArrays->($e), 2;
    
      #say STDERR $e->PrintHeap->($e); exit;
      is_deeply $e->PrintHeap->($e), <<END;
    Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
     0  3 |  1  2  3
     1  3 | 11 22 33
    END
      is_deeply $e->mostArrays, [undef, 2, 1, 1, 1];
     }
    
    if (1)                                                                          
     {Start 1;
      my $a = Array   "aaa";
    
      Push $a, 1,     "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $a, 2,     "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "aaa";
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1);
      is_deeply $e->Heap->($e, 0), [1..2];
      is_deeply $e->outLines,      [1..2];
    
      $e->generateVerilogMachineCode("Push") if $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Resize($target, $source, $source2)

Resize the target area to the source size.

       Parameter  Description
    1  $target    Target array
    2  $source    New size
    3  $source2   Array name

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array 'aaa';
      Parallel
        sub{Mov [$a, 0, 'aaa'], 1},
        sub{Mov [$a, 1, 'aaa'], 2},
        sub{Mov [$a, 2, 'aaa'], 3};
    
      Resize $a, 2, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ArrayDump $a;
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->Heap->($e, 0), [1, 2];
      is_deeply eval($e->out), [1,2];
     }
    

## Random(if (@\_ == 1))

Create a random number in a specified range.

       Parameter     Description
    1  if (@_ == 1)  Create a variable

**Example:**

    if (1)                                                                           
     {Start 1;
      RandomSeed 1;
    
      my $a = Random 10;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      ok $e->out =~ m(\A\d\Z);
     }
    

## RandomSeed($seed)

Seed the random number generator.

       Parameter  Description
    1  $seed      Parameters

**Example:**

    if (1)                                                                           
     {Start 1;
    
      RandomSeed 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $a = Random 10;
      Out $a;
      my $e = &$ee(suppressOutput=>1);
      ok $e->out =~ m(\A\d\Z);
     }
    

## Return()

Return from a procedure via the call stack.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $w = Procedure 'write', sub
       {Out 1;
    
        Return;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       };
      Call $w;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [1];
     }
    

## ReturnGet(if (@\_ == 1))

Get a word from the return area and save it.

       Parameter     Description
    1  if (@_ == 1)  Create a variable

**Example:**

    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
       {ReturnPut 0, 999;
        Return;
       };
      Call $w;
    
      ReturnGet \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out \0;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [999];
     }
    

## ReturnPut($target, $source)

Put a word into the return area.

       Parameter  Description
    1  $target    Offset in return area to write to
    2  $source    Memory address whose contents are to be placed in the return area

**Example:**

    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
    
       {ReturnPut 0, 999;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Return;
       };
      Call $w;
      ReturnGet \0, 0;
      Out \0;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [999];
     }
    

## ShiftDown(if (@\_ == 1))

Shift an element down one in an area.

       Parameter     Description
    1  if (@_ == 1)  Create a variable

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "array";
    
      Parallel
        sub{Mov [$a, 0, 'array'], 0},
        sub{Mov [$a, 1, 'array'], 99},
        sub{Mov [$a, 2, 'array'], 2};
    
    
      my $b = ShiftDown [$a, \1, 'array'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $b;
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->Heap->($e, 0), [0, 2];
      is_deeply $e->outLines, [99];
     }
    

## ShiftLeft(my ($target, $source)

Shift left within an element.

       Parameter    Description
    1  my ($target  Target to shift
    2  $source      Amount to shift

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Mov 1;
    
      ShiftLeft $a, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
    
      $e->generateVerilogMachineCode("ShiftLeft") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## ShiftRight(my ($target, $source)

Shift right with an element.

       Parameter    Description
    1  my ($target  Target to shift
    2  $source      Amount to shift

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 4;
    
      ShiftRight $a, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
    
      $e->generateVerilogMachineCode("ShiftRight") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## ShiftUp($target, $source)

Shift an element up one in an area.

       Parameter  Description
    1  $target    Target to shift
    2  $source    Amount to shift

**Example:**

    if (1)                                                                          
     {Start 1;
      my $b = Array "array";
      my $a = Array "array";
    
      Mov [$a, 0, 'array'], 0;
      Mov [$a, 1, 'array'], 1;
      Mov [$a, 2, 'array'], 2;
      Resize $a, 3, 'array';
    
    
      ShiftUp [$a, 0, 'array'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "array";
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines,      [99, 0, 1, 2];
      $e->generateVerilogMachineCode("Shift_up") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                          
     {Start 1;
      my $b = Array "array";
      my $a = Array "array";
    
      Mov [$a, 0, 'array'], 0;
      Mov [$a, 1, 'array'], 1;
      Mov [$a, 2, 'array'], 2;
      Resize $a, 3, 'array';
    
      ShiftUp [$a, 1, 'array'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "array";
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0, 99, 1, 2];
     }
    
    if (1)                                                                           
     {Start 1;
      my $b = Array "array";
      my $a = Array "array";
    
      Sequential
        sub{Mov [$a, 0, 'array'], 0},
        sub{Mov [$a, 1, 'array'], 1},
        sub{Mov [$a, 2, 'array'], 2},
        sub{Resize $a, 3, 'array'};
    
    
      ShiftUp [$a, 2, 'array'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "array";
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines,      [0, 1, 99, 2];
      $e->generateVerilogMachineCode("Shift_up_2") if $testSet == 1 and $debug;
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "array";
    
      Parallel
        sub{Mov [$a, 0, 'array'], 0},
        sub{Mov [$a, 1, 'array'], 1},
        sub{Mov [$a, 2, 'array'], 2};
    
    
      ShiftUp [$a, 3, 'array'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = &$ee(suppressOutput=>0);
      is_deeply $e->Heap->($e, 0), [0, 1, 2, 99];
      is_deeply [$e->timeParallel, $e->timeSequential], [3,5];
     }
    
    if (1)                                                                          
     {Start 1;
      my $a = Array "array";
    
      my @i;
      for my $i(1..7)
       {push @i, sub{Mov [$a, $i-1, 'array'], 10*$i};
       }
      Parallel @i;
    
    
      ShiftUp [$a, 2, 'array'], 26;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = &$ee(suppressOutput=>1, maximumArraySize=>8);
      is_deeply $e->Heap->($e, 0), bless([10, 20, 26, 30, 40, 50, 60, 70], "array");
     }
    

## Start($version)

Start the current assembly using the specified version of the Zero language.  At  the moment only version 1 works.

       Parameter  Description
    1  $version   Version desired - at the moment only 1

**Example:**

    if (1)                                                                            
    
     {Start 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out "Hello World";
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Hello World
    END
     }
    

## Subtract($target, $s1, $s2)

Subtract the second source operand value from the first source operand value and store the result in the target area.

       Parameter  Description
    1  $target    Target address
    2  $s1        Source one
    3  $s2        Source two

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Subtract 4, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
    
      $e->generateVerilogMachineCode("Subtract") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Tally($source)

Counts instructions when enabled.

       Parameter  Description
    1  $source    Tally instructions when true

**Example:**

    if (1)                                                                           
     {my $N = 5;
      Start 1;
      For
    
       {Tally 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $a = Mov 1;
    
        Tally 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Inc $a;
    
        Tally 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
      my $e = Execute;
    
      is_deeply $e->tallyCount, 2 * $N;
      is_deeply $e->tallyCounts, { 1 => {mov => $N}, 2 => {add => $N}};
     }
    

## Then($t)

Then block.

       Parameter  Description
    1  $t         Then block subroutine

**Example:**

    if (1)                                                                            
     {Start 1;
      IfFalse 1,
    
      Then  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 1
       },
      Else
       {Out 0
       };
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0];
     }
    
    if (1)                                                                            
     {Start 1;
      Trace 1;
      IfEq 1, 2,
    
      Then  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
    
      Then  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->out, <<END;
    Trace: 1
        1     0     0    59         trace
        2     1     1    29           jNe
        3     5     0    32         label
        4     6     1    35           mov  [0, 3, stackArea] = 3
        5     7     1    35           mov  [0, 4, stackArea] = 4
        6     8     0    32         label
        7     9     1    29           jNe
        8    10     1    35           mov  [0, 1, stackArea] = 1
        9    11     1    35           mov  [0, 2, stackArea] = 1
       10    12     1    31           jmp
       11    16     0    32         label
    END
    
      is_deeply scalar($e->notExecuted->@*), 6;
     }
    

## Trace($source)

Start or stop tracing.  Tracing prints each instruction executed and its effect on memory.

       Parameter  Description
    1  $source    Trace setting

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Trace 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfEq 1, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->out, <<END;
    
    Trace: 1  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        1     0     0    59         trace
        2     1     1    29           jNe
        3     5     0    32         label
        4     6     1    35           mov  [0, 3, stackArea] = 3
        5     7     1    35           mov  [0, 4, stackArea] = 4
        6     8     0    32         label
        7     9     1    29           jNe
        8    10     1    35           mov  [0, 1, stackArea] = 1
        9    11     1    35           mov  [0, 2, stackArea] = 1
       10    12     1    31           jmp
       11    16     0    32         label
    END
    
      is_deeply scalar($e->notExecuted->@*), 6;
     }
    

## TraceLabels($source)

Enable or disable label tracing.  If tracing is enabled a stack trace is printed for each label instruction executed showing the call stack at the time the instruction was generated as well as the current stack frames.

       Parameter  Description
    1  $source    Trace points if true

**Example:**

    if (1)                                                                          
     {my $N = 5;
      Start 1;
    
      TraceLabels 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      For
       {my $a = Mov 1;
        Inc $a;
       } $N;
      my $e = &$ee(suppressOutput=>1);
    
      is_deeply $e->out, <<END;
    
    TraceLabels: 1  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Label
        1     2 label
    Label
        1     4 label
    Label
        1     8 label
    Label
        1     4 label
    Label
        1     8 label
    Label
        1     4 label
    Label
        1     8 label
    Label
        1     4 label
    Label
        1     8 label
    Label
        1     4 label
    Label
        1     8 label
    Label
        1     4 label
    Label
        1    11 label
    END
     }
    

## Var($value)

Create a variable initialized to the specified value.

       Parameter  Description
    1  $value     Value

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Var 22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      AssertEq $a, 22;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->out, "";
     }
    

## Watch($target)

Watches for changes to the specified memory location.

       Parameter  Description
    1  $target    Memory address to watch

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      my $c = Mov 3;
    
      Watch $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov $a, 4;
      Mov $b, 5;
      Mov $c, 6;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    Change at watched arena: 2, area: 0(stackArea), address: 1
        1     6 mov
    Current value: 2 New value: 5
    END
     }
    

## Parallel(@subs)

Runs its sub sections in simulated parallel so that we can prove that the sections can be run in parallel.

       Parameter  Description
    1  @subs      Subroutines containing code to be run in simulated parallel

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "array";
    
    
      Parallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        sub{Mov [$a, 0, 'array'], 0},
        sub{Mov [$a, 1, 'array'], 1},
        sub{Mov [$a, 2, 'array'], 2};
    
      ShiftUp [$a, 3, 'array'], 99;
    
      my $e = &$ee(suppressOutput=>0);
      is_deeply $e->Heap->($e, 0), [0, 1, 2, 99];
      is_deeply [$e->timeParallel, $e->timeSequential], [3,5];
     }
    

## Sequential(@subs)

Runs its sub sections in sequential order

       Parameter  Description
    1  @subs      Subroutines containing code to be run sequentially

**Example:**

    if (1)                                                                           
     {Start 1;
      my $b = Array "array";
      my $a = Array "array";
    
    
      Sequential  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        sub{Mov [$a, 0, 'array'], 0},
        sub{Mov [$a, 1, 'array'], 1},
        sub{Mov [$a, 2, 'array'], 2},
        sub{Resize $a, 3, 'array'};
    
      ShiftUp [$a, 2, 'array'], 99;
    
      ForArray
       {my ($i, $a, $Check, $Next, $End) = @_;
        Out $a;
       } $a, "array";
    
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines,      [0, 1, 99, 2];
      $e->generateVerilogMachineCode("Shift_up_2") if $testSet == 1 and $debug;
     }
    

# Instruction Set Architecture

Map the instruction set into a machine architecture.

## GenerateMachineCode(%options)

Generate a string of machine code from the current block of code.

       Parameter  Description
    1  %options   Generation options

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Mov 1;
    
      my $g = GenerateMachineCode;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $d = disAssemble $g;
         $d->assemble;
      is_deeply $d->codeToString, <<'END';
    0000       mov [undef, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
    END
      my $e =  GenerateMachineCodeDisAssembleExecute;
      is_deeply $e->block->codeToString, <<'END';
    0000       mov [0, 0, 3, 0]  [0, 1, 3, 0]  [0, 0, 3, 0]
    END
     }
    

## disAssemble($mc)

Disassemble machine code.

       Parameter  Description
    1  $mc        Machine code string

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Mov 1;
      my $g = GenerateMachineCode;
    
    
      my $d = disAssemble $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $d->assemble;
      is_deeply $d->codeToString, <<'END';
    0000       mov [undef, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
    END
      my $e =  GenerateMachineCodeDisAssembleExecute;
      is_deeply $e->block->codeToString, <<'END';
    0000       mov [0, 0, 3, 0]  [0, 1, 3, 0]  [0, 0, 3, 0]
    END
     }
    

## GenerateMachineCodeDisAssembleExecute(%options)

Round trip: generate machine code and write it onto a string, disassemble the generated machine code string and recreate a block of code from it, then execute the reconstituted code to prove that it works as well as the original code.

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Mov 1;
      my $g = GenerateMachineCode;
    
      my $d = disAssemble $g;
         $d->assemble;
      is_deeply $d->codeToString, <<'END';
    0000       mov [undef, 0, 3, 0]  [undef, 1, 3, 0]  [undef, 0, 3, 0]
    END
    
      my $e =  GenerateMachineCodeDisAssembleExecute;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $e->block->codeToString, <<'END';
    0000       mov [0, 0, 3, 0]  [0, 1, 3, 0]  [0, 0, 3, 0]
    END
     }
    

# Generate Verilog

## generateVerilogMachineCode($exec, $name)

Generate machine code and print it out in Verilog format. We need the just completed execution environment so we can examine the out channel for the expected results.

       Parameter  Description
    1  $exec      Execution environment of completed run
    2  $name      Name of subroutine to contain generated code

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Mov 1;
      ShiftLeft $a, $a;
      Out $a;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2];
    
      $e->generateVerilogMachineCode("ShiftLeft") if $testSet == 1 and $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

# Compile to verilog

Compile each sub sequence of instructions into equivalent verilog.  A sub sequence starts at an instruction marked as an entry point

## compileToVerilog($exec, $name)

Compile each sub sequence of instructions into equivalent verilog.  A sub sequence starts at an instruction marked as an entry point

       Parameter  Description
    1  $exec      Execution environment of completed run
    2  $name      Name of subroutine to contain generated code

**Example:**

    if (1)                                                                          
     {Start 1;
      Out 1;
      Out 2;
      Out 3;
      ForIn
       {my ($i, $v, $Check, $Next, $End) = @_;
        Out $i;
        Out $v;
       };
      my $e = Execute(suppressOutput=>1, in => [33,22,11]);
      is_deeply $e->in, [];
      is_deeply $e->inOriginally, [33, 22, 11];
      is_deeply $e->outLines, [1,2,3, 3,33, 2,22, 1,11];
      is_deeply [map {$_->entry} $e->block->code->@*], [qw(1 0 0 1 0 0 0 0 0 0 0 0)]; # Sub sequence start points
    
      $e->compileToVerilog("ForIn") if $debug;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

# Hash Definitions

## Zero::CompileToVerilog Definition

Compile to verilog

### Output fields

#### NArea

The size of an array in the heap area

#### NArrays

The number of heap arrays need

#### WLocal

Size of local area

#### code

Generated code

#### constraints

Constraints file

#### testBench

Test bench for generated code

## Zero::Emulator Definition

Emulator execution environment

### Output fields

#### AllocMemoryArea

Low level memory access - allocate new area

#### FreeMemoryArea

Low level memory access - free an area

#### GetMemoryArea

Low level memory access - area

#### GetMemoryArrays

Low level memory access - arenas in use

#### GetMemoryLocation

Low level memory access - location

#### Heap

Get the contents of the specified array

#### PopMemoryArea

Low level memory access - pop from area

#### PrintHeap

Print heap memory

#### PrintLocal

Print local memory

#### PushMemoryArea

Low level memory access - push onto area

#### ResizeMemoryArea

Low level memory access - resize an area

#### block

Block of code to be executed

#### calls

Call stack

#### checkArrayNames

Check array names to confirm we are accessing the expected data

#### compileToVerilogTests

Make sure that all the compile to verilog tests have distinct names

#### count

Executed instructions count

#### counts

Executed instructions by name counts

#### doubleWrite

Source of double writes {instruction number} to count - an existing value was overwritten before it was used

#### freedArrays

Arrays that have been recently freed and can thus be reused

#### in

The input channel.  the [In](https://metacpan.org/pod/In) instruction reads one element at a time from this array.

#### inOriginally

A copy of the input channel that does not get consumed by the execution of  the program so that we can use it to construct tests

#### instructionCounts

The number of times each actual instruction is executed

#### instructionPointer

Current instruction

#### lastAssignAddress

Last assignment performed - address

#### lastAssignArea

Last assignment performed - area

#### lastAssignArena

Last assignment performed - arena

#### lastAssignBefore

Prior value of memory area before assignment

#### lastAssignType

Last assignment performed - name of area assigned into

#### lastAssignValue

Last assignment performed - value

#### latestLeftTarget

The most recent value of the target operand evaluated as a left operand

#### latestRightSource

The most recent value of the source operand evaluated as a right operand

#### memory

Memory contents at the end of execution

#### memoryString

Memory packed into one string

#### memoryStringElementWidth

Width in bytes of a memory area element

#### memoryStringElements

Maximum number of elements in an array on the heap

#### memoryStringLengths

Lengths of each array

#### memoryType

Memory contents at the end of execution

#### mostArrays

The maximum number of arrays active at any point during the execution in each arena

#### namesOfWidestArrays

The name of the widest arrays in each arena

#### notExecuted

Instructions not executed

#### out

The out channel. [Out](https://metacpan.org/pod/Out) writes an array of items to this followed by a new line.  [out](https://metacpan.org/pod/out) does the same but without the new line.

#### parallelLastStart

Point in time at which last parallel section started

#### parallelLongest

Longest paralle section so far

#### pointlessAssign

Location already has the specified value

#### printDoubleWrite

Double writes: earlier instruction number to later instruction number

#### printPointlessAssign

Pointless assigns {instruction number} to count - address already has the specified value

#### read

Records whether a memory address was ever read allowing us to find all the unused locations

#### rw

Read / write access to memory

#### stopOnError

Stop on non fatal errors if true

#### suppressOutput

If true the Out instruction will only write to the execution out array but not to stdout as well.

#### tally

Tally executed instructions in a bin of this name

#### tallyCount

Executed instructions tally count

#### tallyCounts

Executed instructions by name tally counts

#### tallyTotal

Total instructions executed in each tally

#### timeDelta

Time for last instruction if something other than 1

#### timeParallel

Notional time elapsed since start with parallelism taken into account

#### timeSequential

Notional time elapsed since start without parellelism

#### totalInstructions

Count of every instruction executed

#### totalLabels

Count of every label instruction executed

#### trace

Trace all statements

#### traceLabels

Trace changes in execution flow

#### watch

Addresses to watch for changes

#### widestAreaInArena

Track highest array access in each arena

## Zero::Emulator::Address Definition

Address memory

### Output fields

#### address

Address within area, either a number or a reference to a number indicating the level of indirection

#### area

Area in memory, either a number or a reference to a number indicating the level of indirection

#### arena

Arena in memory

#### delta

Offset from indicated address

#### exec

Execution environment for address

#### name

Name of area

## Zero::Emulator::AreaStructure Definition

Description of a data structure mapping a memory area

### Output fields

#### fieldNames

Maps the names of the fields to their offsets in the structure

#### fieldOrder

Order of the elements in the structure, in effect, giving the offset of each element in the data structure

#### structureName

Name of the structure

## Zero::Emulator::Assembly Definition

Block of code description.

### Output fields

#### arrayNames

Array names as strings to numbers

#### arrayNumbers

Array number to name

#### code

An array of instructions

#### files

File number to file name

#### labelCounter

Label counter used to generate unique labels

#### labels

Label name to instruction

#### procedures

Procedures defined in this block of code

#### variables

Variables in this block of code

## Zero::Emulator::Assembly::Instruction Definition

Instruction details

### Output fields

#### action

Instruction name

#### context

The call context in which this instruction was created

#### entry

An entry point into the code

#### executed

The number of times this instruction was executed

#### file

Source file in which instruction was encoded

#### jump

Jump target

#### line

Line in source file at which this instruction was encoded

#### number

Instruction sequence number

#### source

Source memory address

#### source2

Secondary source memory address

#### step

The last time (in steps from the start) that this instruction was executed

#### target

Target memory address

## Zero::Emulator::Deref Definition

Memory operations

### Output fields

#### Area

Area

#### Arena

Arena

#### Location

Source location

#### Value

Source value

#### targetIndex

Target index within array

#### targetLocation

Target as a location

#### targetLocationArea

Number of array containing target

#### targetValue

Target as value

## Zero::Emulator::Procedure Definition

Description of a procedure

### Output fields

#### target

Label to call to call this procedure

#### variables

Registers local to this procedure

## Zero::Emulator::StackFrame Definition

Description of a stack frame. A stack frame provides the context in which a method runs.

### Output fields

#### file

The file number from which the call was made - this could be folded into the line number but for reasons best known to themselves people who cannot program very well often scatter projects across several files a practice that is completely pointless in this day of git and so can only lead to chaos and confusion

#### instruction

The address of the instruction making the call

#### line

The line number from which the call was made

#### params

Memory area containing parameter list

#### return

Memory area containing returned result

#### stackArea

Memory area containing data for this method

#### target

The address of the subroutine being called

#### variables

Variables local to this stack frame

# Private Methods

## Assembly(%options)

Start some assembly code.

       Parameter  Description
    1  %options   Options

## Assert1($op, $a)

Assert operation.

       Parameter  Description
    1  $op        Operation
    2  $a         Source operand

## Assert2($op, $a, $b)

Assert operation.

       Parameter  Description
    1  $op        Operation
    2  $a         First memory address
    3  $b         Second memory address

## Ifx($cmp, $a, $b, %options)

Execute then or else clause depending on whether two memory locations are equal.

       Parameter  Description
    1  $cmp       Comparison
    2  $a         First memory address
    3  $b         Second memory address
    4  %options   Then block

## Label($source)

Create a label.

       Parameter  Description
    1  $source    Name of label

**Example:**

    if (1)                                                                           
     {Start 1;
      Mov 0, 1;
      my $e = &$ee(suppressOutput=>1);
     }
    
    if (1)                                                                           
     {Start 1;
      Mov 0, 1;
      Jlt ((my $a = label), \0, 2);
        Out  1;
        Jmp (my $b = label);
      setLabel($a);
        Out  2;
      setLabel($b);
    
      Jgt ((my $c = label), \0, 3);
        Out  3;
        Jmp (my $d = label);
      setLabel($c);
        Out  4;
      setLabel($d);
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [2..3];
     }
    
    if (1)                                                                          
     {Start 1;
      Mov 0, 0;
      my $a = setLabel;
        Out \0;
        Inc \0;
      Jlt $a, \0, 10;
      my $e = &$ee(suppressOutput=>1);
      is_deeply $e->outLines, [0..9];
     }
    

## ParallelStart()

Start recording the elapsed time for parallel sections.

## ParallelContinue()

Continue recording the elapsed time for parallel sections.

## ParallelStop()

Stop recording the elapsed time for parallel sections.

## instructionMap()

Instruction map

## Zero::Emulator::Assembly::packRef($code, $instruction, $ref, $type)

Pack a reference into 8 bytes.

       Parameter     Description
    1  $code         Code block being packed
    2  $instruction  Instruction being packed
    3  $ref          Reference being packed
    4  $type         Type of reference being packed 0-target 1-source1 2-source2

## Zero::Emulator::Assembly::unpackRef($code, $a, $operand)

Unpack a reference.

       Parameter  Description
    1  $code      Code block being packed
    2  $a         Instruction being packed
    3  $operand   Reference being packed

## Zero::Emulator::Assembly::packInstruction($code, $i)

Pack an instruction.

       Parameter  Description
    1  $code      Code being packed
    2  $i         Instruction to pack

## disAssembleMinusContext($D)

Disassemble and remove context information from disassembly to make testing easier.

       Parameter  Description
    1  $D         Machine code string

## CompileToVerilog(%options)

Execution environment for a block of code.

       Parameter  Description
    1  %options   Execution options

## Zero::CompileToVerilog::deref($compile, $ref)

Compile a reference in assembler format to a corresponding verilog expression

       Parameter  Description
    1  $compile   Compile
    2  $ref       Reference

# Index

1 [Add](#add) - Add the source locations together and store the result in the target area.

2 [Array](#array) - Create a new memory area and write its number into the address named by the target operand.

3 [ArrayCountGreater](#arraycountgreater) - Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.

4 [ArrayCountLess](#arraycountless) - Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.

5 [ArrayDump](#arraydump) - Dump an array.

6 [ArrayIndex](#arrayindex) - Store in the target location the 1 based index of the second source operand in the array referenced by the first source operand if the secound source operand is present somwhere in the array else store 0 into the target location.

7 [ArrayOut](#arrayout) - Write an array to out

8 [ArraySize](#arraysize) - The current size of an array.

9 [Assembly](#assembly) - Start some assembly code.

10 [Assert](#assert) - Assert regardless.

11 [Assert1](#assert1) - Assert operation.

12 [Assert2](#assert2) - Assert operation.

13 [AssertEq](#asserteq) - Assert two memory locations are equal.

14 [AssertFalse](#assertfalse) - Assert false.

15 [AssertGe](#assertge) - Assert that the first value is greater than or equal to the second value.

16 [AssertGt](#assertgt) - Assert that the first value is greater than the second value.

17 [AssertLe](#assertle) - Assert that the first value is less than or equal to the second value.

18 [AssertLt](#assertlt) - Assert that the first value is less than  the second value.

19 [AssertNe](#assertne) - Assert two memory locations are not equal.

20 [AssertTrue](#asserttrue) - Assert true.

21 [Bad](#bad) - A bad ending to a block of code.

22 [Block](#block) - Block of code that can either be restarted or come to a good or a bad ending.

23 [Call](#call) - Call the subroutine at the target address.

24 [compileToVerilog](#compiletoverilog) - Compile each sub sequence of instructions into equivalent verilog.

25 [CompileToVerilog](#compiletoverilog) - Execution environment for a block of code.

26 [Confess](#confess) - Confess with a stack trace showing the location both in the emulated code and in the code that produced the emulated code.

27 [Dec](#dec) - Decrement the target.

28 [disAssemble](#disassemble) - Disassemble machine code.

29 [disAssembleMinusContext](#disassembleminuscontext) - Disassemble and remove context information from disassembly to make testing easier.

30 [Dump](#dump) - Dump all the arrays currently in memory.

31 [Else](#else) - Else block.

32 [Execute](#execute) - Execute the current assembly.

33 [For](#for) - For loop 0.

34 [ForArray](#forarray) - For loop to process each element of the named area.

35 [ForIn](#forin) - For loop to process each element remaining in the input channel

36 [Free](#free) - Free the memory area named by the target operand after confirming that it has the name specified on the source operand.

37 [GenerateMachineCode](#generatemachinecode) - Generate a string of machine code from the current block of code.

38 [GenerateMachineCodeDisAssembleExecute](#generatemachinecodedisassembleexecute) - Round trip: generate machine code and write it onto a string, disassemble the generated machine code string and recreate a block of code from it, then execute the reconstituted code to prove that it works as well as the original code.

39 [generateVerilogMachineCode](#generateverilogmachinecode) - Generate machine code and print it out in Verilog format.

40 [Good](#good) - A good ending to a block of code.

41 [IfEq](#ifeq) - Execute then or else clause depending on whether two memory locations are equal.

42 [IfFalse](#iffalse) - Execute then clause if the specified memory address is zero thus representing false.

43 [IfGe](#ifge) - Execute then or else clause depending on whether two memory locations are greater than or equal.

44 [IfGt](#ifgt) - Execute then or else clause depending on whether two memory locations are greater than.

45 [IfLe](#ifle) - Execute then or else clause depending on whether two memory locations are less than or equal.

46 [IfLt](#iflt) - Execute then or else clause depending on whether two memory locations are less than.

47 [IfNe](#ifne) - Execute then or else clause depending on whether two memory locations are not equal.

48 [IfTrue](#iftrue) - Execute then clause if the specified memory address is not zero thus representing true.

49 [Ifx](#ifx) - Execute then or else clause depending on whether two memory locations are equal.

50 [In](#in) - Read a value from the input channel

51 [Inc](#inc) - Increment the target.

52 [InSize](#insize) - Number of elements remining in the input channel

53 [instructionMap](#instructionmap) - Instruction map

54 [Jeq](#jeq) - Jump to a target label if the first source field is equal to the second source field.

55 [JFalse](#jfalse) - Jump to a target label if the first source field is equal to zero.

56 [Jge](#jge) - Jump to a target label if the first source field is greater than or equal to the second source field.

57 [Jgt](#jgt) - Jump to a target label if the first source field is greater than the second source field.

58 [Jle](#jle) - Jump to a target label if the first source field is less than or equal to the second source field.

59 [Jlt](#jlt) - Jump to a target label if the first source field is less than the second source field.

60 [Jmp](#jmp) - Jump to a label.

61 [Jne](#jne) - Jump to a target label if the first source field is not equal to the second source field.

62 [JTrue](#jtrue) - Jump to a target label if the first source field is not equal to zero.

63 [Label](#label) - Create a label.

64 [LoadAddress](#loadaddress) - Load the address component of an address.

65 [LoadArea](#loadarea) - Load the area component of an address.

66 [Mov](#mov) - Copy a constant or memory address to the target address.

67 [MoveLong](#movelong) - Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.

68 [Nop](#nop) - Do nothing (but do it well!).

69 [Not](#not) - Move and not.

70 [Out](#out) - Write memory location contents to out.

71 [Parallel](#parallel) - Runs its sub sections in simulated parallel so that we can prove that the sections can be run in parallel.

72 [ParallelContinue](#parallelcontinue) - Continue recording the elapsed time for parallel sections.

73 [ParallelStart](#parallelstart) - Start recording the elapsed time for parallel sections.

74 [ParallelStop](#parallelstop) - Stop recording the elapsed time for parallel sections.

75 [ParamsGet](#paramsget) - Get a word from the parameters in the previous frame and store it in the current frame.

76 [ParamsPut](#paramsput) - Put a word into the parameters list to make it visible in a called procedure.

77 [Pop](#pop) - Pop the memory area specified by the source operand into the memory address specified by the target operand.

78 [Procedure](#procedure) - Define a procedure.

79 [Push](#push) - Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.

80 [Random](#random) - Create a random number in a specified range.

81 [RandomSeed](#randomseed) - Seed the random number generator.

82 [Resize](#resize) - Resize the target area to the source size.

83 [Return](#return) - Return from a procedure via the call stack.

84 [ReturnGet](#returnget) - Get a word from the return area and save it.

85 [ReturnPut](#returnput) - Put a word into the return area.

86 [Sequential](#sequential) - Runs its sub sections in sequential order

87 [ShiftDown](#shiftdown) - Shift an element down one in an area.

88 [ShiftLeft](#shiftleft) - Shift left within an element.

89 [ShiftRight](#shiftright) - Shift right with an element.

90 [ShiftUp](#shiftup) - Shift an element up one in an area.

91 [Start](#start) - Start the current assembly using the specified version of the Zero language.

92 [Subtract](#subtract) - Subtract the second source operand value from the first source operand value and store the result in the target area.

93 [Tally](#tally) - Counts instructions when enabled.

94 [Then](#then) - Then block.

95 [Trace](#trace) - Start or stop tracing.

96 [TraceLabels](#tracelabels) - Enable or disable label tracing.

97 [Var](#var) - Create a variable initialized to the specified value.

98 [Watch](#watch) - Watches for changes to the specified memory location.

99 [Zero::CompileToVerilog::deref](#zero-compiletoverilog-deref) - Compile a reference in assembler format to a corresponding verilog expression

100 [Zero::Emulator::Assembly::packInstruction](#zero-emulator-assembly-packinstruction) - Pack an instruction.

101 [Zero::Emulator::Assembly::packRef](#zero-emulator-assembly-packref) - Pack a reference into 8 bytes.

102 [Zero::Emulator::Assembly::unpackRef](#zero-emulator-assembly-unpackref) - Unpack a reference.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Zero::Emulator

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
