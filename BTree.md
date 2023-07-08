# Name

Zero::NWayTree - N-Way-Tree written in the Zero assembler programming language.

<div>

    <p><a href="https://github.com/philiprbrenan/zeroLowLevel"><img src="https://github.com/philiprbrenan/zeroLowLevel/workflows/Test/badge.svg"></a>
</div>

# Synopsis

Create a tree, load it from an array of random numbers, then print out the
results. Show the number of instructions executed in the process.  The
challenge, should you wish to acceopt it, is to reduce these instruction counts
to the minimum possible while still passing all the tests.

    {my $W = 3; my $N = 107; my @r = randomArray $N;

     Start 1;
     my $t = New($W);                                                              # Create tree at expected location in memory

     my $a = Array "aaa";
     for my $I(1..$N)                                                              # Load array
      {my $i = $I-1;
       Mov [$a, $i, "aaa"], $r[$i];
      }

     my $f = FindResult_new;

     ForArray                                                                      # Create tree
      {my ($i, $k) = @_;
       my $n = Keys($t);
       AssertEq $n, $i;                                                            # Check tree size
       my $K = Add $k, $k;
       Tally 1;
       Insert($t, $k, $K,                                                          # Insert a new node
         findResult=>          $f,
         maximumNumberOfKeys=> $W,
         splitPoint=>          int($W/2),
         rightStart=>          int($W/2)+1,
       );
       Tally 0;
      } $a, q(aaa);

     Iterate                                                                       # Iterate tree
      {my ($find) = @_;                                                            # Find result
       my $k = FindResult_key($find);
       Out $k;
       Tally 2;
       my $f = Find($t, $k, findResult=>$f);                                       # Find
       Tally 0;
       my $d = FindResult_data($f);
       my $K = Add $k, $k;
       AssertEq $K, $d;                                                            # Check result
      } $t;

     Tally 3;
     Iterate {} $t;                                                                # Iterate tree
     Tally 0;

     my $e = Execute(suppressOutput=>1);

     is_deeply $e->out, [1..$N];                                                   # Expected sequence

     #say STDERR dump $e->tallyCount;
     is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts

     #say STDERR dump $e->tallyTotal;
     is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};

     #say STDERR dump $e->tallyCounts->{1};
     is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
     add               => 159,
     array             => 247,
     arrayCountGreater => 2,
     arrayCountLess    => 262,
     arrayIndex        => 293,
     dec               => 30,
     inc               => 726,
     jEq               => 894,
     jGe               => 648,
     jLe               => 461,
     jLt               => 565,
     jmp               => 878,
     jNe               => 908,
     mov               => 7724,
     moveLong          => 171,
     not               => 631,
     resize            => 161,
     shiftUp           => 300,
     subtract          => 606,
   };

     #say STDERR dump $e->tallyCounts->{2};
     is_deeply $e->tallyCounts->{2}, {                                             # Find tally
     add => 137,
     arrayCountLess => 223,
     arrayIndex => 330,
     inc => 360,
     jEq => 690,
     jGe => 467,
     jLe => 467,
     jmp => 604,
     jNe => 107,
     mov => 1975,
     not => 360,
     subtract => 574};

     #say STDERR dump $e->tallyCounts->{3};
     is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
     add        => 107,
     array      => 1,
     arrayIndex => 72,
     dec        => 72,
     free       => 1,
     inc        => 162,
     jEq        => 260,
     jFalse     => 28,
     jGe        => 316,
     jmp        => 252,
     jNe        => 117,
     jTrue      => 73,
     mov        => 1111,
     not        => 180};

     #say STDERR printTreeKeys($e->memory); x;
     #say STDERR printTreeData($e->memory); x;
     is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                   38                                                                                                    72
                                                                21                                                                                                       56                                                                                                 89
                               10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
           3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
     1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
   END

     is_deeply printTreeData($e->memory), <<END;
                                                                                                                   76                                                                                                   144
                                                                42                                                                                                      112                                                                                                178
                               20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
           6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
     2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
   END

# Description

Version 20230519.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Constructor

Create a new N-Way tree.

## New($n)

Create a variable referring to a new tree descriptor.

       Parameter  Description
    1  $n         Constant indicating the maximum number of keys per node in this tree

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Out New(3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    0
    END
      is_deeply $e->heap(0), [ 0, 0, 3, 0];
      $e->compileToVerilog("BTree/basic/1");
     }
    
    if (1)                                                                          
     {Start 1;
    
      my $t = New(3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $r = root($t);
    
      setRoot($t, 1);
      my $R = root($t);
    
      my $n = maximumNumberOfKeys($t);
    
      incKeys($t) for 1..3;
      Out [$t, $Tree->address(q(keys)), 'Tree'];
    
      incNodes($t) for 1..5;
      Out nodes($t);
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, <<END;
    3
    5
    END
      is_deeply $e->heap(0), [ 3, 5, 3, 1];
      $e->compileToVerilog("BTree/basic/2");
     }
    
    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
    
      my $t = New($W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, "";                                                        # No asserts
      $e->compileToVerilog("BTree/insert/66");
     }
    

## Keys($tree)

Get the number of keys in the tree..

       Parameter  Description
    1  $tree      Tree to examine

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
    
        my $n = Keys($t);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

# Find

Find a key in a tree.

## FindResult\_cmp($f)

Get comparison from find result.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
    
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, "";                                                        # No asserts
      $e->compileToVerilog("BTree/insert/66");
     }
    

## FindResult\_data($f)

Get data field from find results.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
    
        my $d = FindResult_data($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

## FindResult\_key($f)

Get key field from find results.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
    
        my $k = FindResult_key($find);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
    
        my $k = FindResult_key($find);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

## Find($tree, $key, %options)

Find a key in a tree returning a [FindResult](https://metacpan.org/pod/FindResult) describing the outcome of the search.  To avoid allocating a new find result area for each individual request a preallocated find result area may be supplied via the findResult option.

       Parameter  Description
    1  $tree      Tree to search
    2  $key       Key to find
    3  %options   Options

**Example:**

    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
    
      For                                                                           # Find each prior element  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
    
        AssertEq $d, FindResult_data(Find($t, $j));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
    
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, "";                                                        # No asserts
      $e->compileToVerilog("BTree/insert/66");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
    
       {my ($find) = @_;                                                            # Find result  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
    
       {my ($find) = @_;                                                            # Find result  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
    
        my $f = Find($t, $k, findResult=>$f);                                       # Find  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
    
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

# Insert

Create a new entry in a tree to connect a key to data.

## Insert($tree, $key, $data, %options)

Insert a key and its associated data into a tree.

       Parameter  Description
    1  $tree      Tree
    2  $key       Key
    3  $data      Data
    4  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      my $t = New(3);                                                               # Create tree
      my $f = Find($t, 1);
      my $c = FindResult_cmp($f);
      AssertEq($c, FindResult_notFound);
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, "";
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, 1, 11);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0), bless([1, 1, 3, 2], "Tree");
      is_deeply $e->heap(2), bless([1, 1, 0, 0, 3, 4, 0], "Node");
      is_deeply $e->heap(3), bless([1], "Keys");
      is_deeply $e->heap(4), bless([11], "Data");
      $e->compileToVerilog("BTree/insert/01");
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, 1, 11);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Insert($t, 2, 22);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0), bless([2, 1, 3, 2], "Tree");
      is_deeply $e->heap(2), bless([2, 1, 0, 0, 3, 4, 0], "Node");
      is_deeply $e->heap(3), bless([1, 2], "Keys");
      is_deeply $e->heap(4), bless([11, 22], "Data");
      $e->compileToVerilog("BTree/insert/02");
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0), bless([3, 1, 3, 2], "Tree");
      is_deeply $e->heap(2), bless([3, 1, 0, 0, 3, 4, 0], "Node");
      is_deeply $e->heap(3), bless([1, 2, 3], "Keys");
      is_deeply $e->heap(4), bless([11, 22, 33], "Data");
      $e->compileToVerilog("BTree/insert/03");
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0 ), bless([4, 3, 3, 2], "Tree");
      is_deeply $e->heap(2 ), bless([1, 1, 0, 0, 3, 4, 11], "Node");
      is_deeply $e->heap(3 ), bless([2], "Keys");
      is_deeply $e->heap(4 ), bless([22], "Data");
      is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
      is_deeply $e->heap(6 ), bless([1], "Keys");
      is_deeply $e->heap(7 ), bless([11], "Data");
      is_deeply $e->heap(8 ), bless([2, 3, 2, 0, 9, 10, 0], "Node");
      is_deeply $e->heap(9 ), bless([3, 4], "Keys");
      is_deeply $e->heap(10), bless([33, 44], "Data");
      is_deeply $e->heap(11), bless([5, 8], "Down");
      $e->compileToVerilog("BTree/insert/04");
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0 ), bless([5, 4, 3, 2], "Tree");
      is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
      is_deeply $e->heap(3 ), bless([2, 4], "Keys");
      is_deeply $e->heap(4 ), bless([22, 44], "Data");
      is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
      is_deeply $e->heap(6 ), bless([1], "Keys");
      is_deeply $e->heap(7 ), bless([11], "Data");
      is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
      is_deeply $e->heap(9 ), bless([3], "Keys");
      is_deeply $e->heap(10), bless([33], "Data");
      is_deeply $e->heap(11), bless([5, 8, 12], "Down");
      is_deeply $e->heap(12), bless([1, 4, 2, 0, 13, 14, 0], "Node");
      is_deeply $e->heap(13), bless([5], "Keys");
      is_deeply $e->heap(14), bless([55], "Data");
      $e->compileToVerilog("BTree/insert/05");
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->heap(0 ), bless([6, 4, 3, 2], "Tree");
      is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
      is_deeply $e->heap(3 ), bless([2, 4], "Keys");
      is_deeply $e->heap(4 ), bless([22, 44], "Data");
      is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
      is_deeply $e->heap(6 ), bless([1], "Keys");
      is_deeply $e->heap(7 ), bless([11], "Data");
      is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
      is_deeply $e->heap(9 ), bless([3], "Keys");
      is_deeply $e->heap(10), bless([33], "Data");
      is_deeply $e->heap(11), bless([5, 8, 12], "Down");
      is_deeply $e->heap(12), bless([2, 4, 2, 0, 13, 14, 0], "Node");
      is_deeply $e->heap(13), bless([5, 6], "Keys");
      is_deeply $e->heap(14), bless([55, 66], "Data");
      $e->compileToVerilog("BTree/insert/06");
     }
    
    if (1)                                                                          
     {my $N = 6;
      Start 1;
      my $t = New(3);
      For
       {my ($i, $Check, $Next, $End) = @_;
    
        Insert($t, $i, $i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N, reverse=>1;
    
      Iterate
       {my ($find) = @_;
        Out FindResult_key($find);
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1);
      #$e->generateVerilogMachineCode("BTree/insert/06R");                          # Requires signed arithmetic which we are proposing to avoid on the fpga
      is_deeply $e->outLines, [0..5];
    
      is_deeply $e->count, 609;
    
      is_deeply $e->heap(0 ), bless([6, 4, 3, 2], "Tree");
      is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
      is_deeply $e->heap(3 ), bless([2, 4], "Keys");
      is_deeply $e->heap(4 ), bless([2, 4], "Data");
      is_deeply $e->heap(5 ), bless([2, 2, 2, 0, 6, 7, 0], "Node");
      is_deeply $e->heap(6 ), bless([0, 1], "Keys");
      is_deeply $e->heap(7 ), bless([0, 1], "Data");
      is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
      is_deeply $e->heap(9 ), bless([5], "Keys");
      is_deeply $e->heap(10), bless([5], "Data");
      is_deeply $e->heap(11), bless([5, 12, 8], "Down");
      is_deeply $e->heap(12), bless([1, 4, 2, 0, 13, 14, 0], "Node");
      is_deeply $e->heap(13), bless([3], "Keys");
      is_deeply $e->heap(14), bless([3], "Data");
     }
    
    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
    
       {my ($i, $check, $next, $end) = @_;                                          # Insert  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $d = Add $i, $i;
    
    
        Insert($t, $i, $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, "";                                                        # No asserts
      $e->compileToVerilog("BTree/insert/66");
     }
    

# Iteration

Iterate over the keys and their associated data held in a tree.

## Iterate($block, $tree)

Iterate over a tree.

       Parameter  Description
    1  $block     Block of code to execute for each key in tree
    2  $tree      Tree

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
    
      Iterate                                                                       # Iterate tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
    
      Iterate                                                                       # Iterate tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
    
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
    
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

# Print

Print trees horizontally.

## printTreeKeys($e)

Print the keys held in a tree.

       Parameter  Description
    1  $e         Memory

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
    
      #say STDERR printTreeKeys($e);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
    
      #say STDERR printTreeKeys($e); x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply printTreeKeys($e), <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      #say STDERR printTreeData($e); x;
      is_deeply printTreeData($e), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

## printTreeData($e)

Print the data held in a tree.

       Parameter  Description
    1  $e         Memory

**Example:**

    if (1)                                                                                
     {my $W = 3; my @r = randomArray 41; #107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $K = Add $k, $k;
        Insert($t, $k, $K);
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
      is_deeply $e->outLines, [1..@r];                                              # Expected sequence
      #say STDERR printTreeKeys($e);
      $e->compileToVerilog("BTree/in/2");
     }
    
    if (1)                                                                                
     {my $W = 3; my @r = randomArray 107;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $f = FindResult_new;                                                       # Preallocate find result
    
      ForIn                                                                         # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
    
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       };
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
      Tally 0;
    
      my $e = Execute(suppressOutput=>1, in=>[@r]);
      is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
      is_deeply $e->widestAreaInArena,   [undef, 7, 540];
    # is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
      is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
    #  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
    
      #say STDERR formatTable $e->tallyCounts->{1};   exit;
      is_deeply formatTable($e->tallyCounts->{1}), <<END;                           # Insert tally
    add                 885
    array               247
    arrayCountGreater     2
    arrayCountLess      262
    arrayIndex          293
    jEq                 894
    jGe                 648
    jLe                 461
    jLt                 565
    jNe                 908
    jmp                 878
    mov                7623
    moveLong            171
    not                 631
    resize              167
    shiftUp             300
    subtract            531
    END
    
      #say STDERR formatTable $e->tallyCounts->{2}; exit;
      is_deeply formatTable($e->tallyCounts->{2}), <<END;                           # Find tally
    add              497
    arrayCountLess   223
    arrayIndex       330
    jEq              690
    jGe              467
    jLe              467
    jNe              107
    jmp              604
    mov             1975
    not              360
    subtract         574
    END
    
      #say STDERR formatTable($e->tallyCounts->{3}); exit;
      is_deeply formatTable($e->tallyCounts->{3}), <<END;                           # Iterate tally
    add          162
    array          2
    arrayIndex    72
    free           2
    jEq          260
    jFalse        28
    jGe          208
    jNe          117
    jTrue         73
    jmp          252
    mov         1111
    moveLong     107
    not          180
    shiftLeft      1
    subtract      72
    END
    
      #say STDERR printTreeKeys($e); x;
      is_deeply printTreeKeys($e), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
    
      #say STDERR printTreeData($e); x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply printTreeData($e), <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
      $e->compileToVerilog("BTree/in/3");
     }
    

# Utilities

Utility functions.

## commandStart()

Start a tree

**Example:**

    if (1)                                                                          # Actions on a tree driven by the input channel    
     {Start 1;
      my $W = 3;                                                                    # Width of each node
      my $F = FindResult_new;                                                       # Find area
      my $T;                                                                        # The tree
    
      ForIn                                                                         # Read commands from input channel
       {my ($i, $v, $Check, $Next, $End) = @_;
    
        IfEq $v, commandStart(),                                                    # Start a new tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Then
         {$T = New $W;
          Jmp $Next;
         };
        IfEq $v, commandInsert(),                                                   # Insert a key
        Then
         {my $k = In; my $d = In;
          Insert $T, $k, $d;
          Jmp $Next;
         };
        IfEq $v, commandFind(),                                                     # Find a key. Indicate whether it was found and its value on the output channel
        Then
         {my $k = In;
          Find $T, $k, findResult=>$F;
          IfEq FindResult_cmp($F), FindResult_found,
          Then
           {Out 1;
            Out FindResult_data $F;
           },
          Else
           {Out 0;
           };
          Jmp $Next;
         };
        Jmp $End;                                                                   # Invalid command terminates the command sequence
       };
      my $e = Execute(suppressOutput=>1, in => [0, 1, 3, 33, 1, 1, 11, 1, 2, 22, 1, 4, 44, 2, 5, 2, 2, 2, 6, 2, 3]);
      is_deeply $e->outLines, [0, 1, 22, 0, 1, 33];
      $e->compileToVerilog("BTree/in/4");
     }
    

## commandInsert()

Insert into a tree.  Must be followed by the key and the associated data

**Example:**

    if (1)                                                                          # Actions on a tree driven by the input channel    
     {Start 1;
      my $W = 3;                                                                    # Width of each node
      my $F = FindResult_new;                                                       # Find area
      my $T;                                                                        # The tree
    
      ForIn                                                                         # Read commands from input channel
       {my ($i, $v, $Check, $Next, $End) = @_;
        IfEq $v, commandStart(),                                                    # Start a new tree
        Then
         {$T = New $W;
          Jmp $Next;
         };
    
        IfEq $v, commandInsert(),                                                   # Insert a key  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Then
         {my $k = In; my $d = In;
          Insert $T, $k, $d;
          Jmp $Next;
         };
        IfEq $v, commandFind(),                                                     # Find a key. Indicate whether it was found and its value on the output channel
        Then
         {my $k = In;
          Find $T, $k, findResult=>$F;
          IfEq FindResult_cmp($F), FindResult_found,
          Then
           {Out 1;
            Out FindResult_data $F;
           },
          Else
           {Out 0;
           };
          Jmp $Next;
         };
        Jmp $End;                                                                   # Invalid command terminates the command sequence
       };
      my $e = Execute(suppressOutput=>1, in => [0, 1, 3, 33, 1, 1, 11, 1, 2, 22, 1, 4, 44, 2, 5, 2, 2, 2, 6, 2, 3]);
      is_deeply $e->outLines, [0, 1, 22, 0, 1, 33];
      $e->compileToVerilog("BTree/in/4");
     }
    

## commandFind()

Find in a tree. Must be followed by the key to find

**Example:**

    if (1)                                                                          # Actions on a tree driven by the input channel    
     {Start 1;
      my $W = 3;                                                                    # Width of each node
      my $F = FindResult_new;                                                       # Find area
      my $T;                                                                        # The tree
    
      ForIn                                                                         # Read commands from input channel
       {my ($i, $v, $Check, $Next, $End) = @_;
        IfEq $v, commandStart(),                                                    # Start a new tree
        Then
         {$T = New $W;
          Jmp $Next;
         };
        IfEq $v, commandInsert(),                                                   # Insert a key
        Then
         {my $k = In; my $d = In;
          Insert $T, $k, $d;
          Jmp $Next;
         };
    
        IfEq $v, commandFind(),                                                     # Find a key. Indicate whether it was found and its value on the output channel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Then
         {my $k = In;
          Find $T, $k, findResult=>$F;
          IfEq FindResult_cmp($F), FindResult_found,
          Then
           {Out 1;
            Out FindResult_data $F;
           },
          Else
           {Out 0;
           };
          Jmp $Next;
         };
        Jmp $End;                                                                   # Invalid command terminates the command sequence
       };
      my $e = Execute(suppressOutput=>1, in => [0, 1, 3, 33, 1, 1, 11, 1, 2, 22, 1, 4, 44, 2, 5, 2, 2, 2, 6, 2, 3]);
      is_deeply $e->outLines, [0, 1, 22, 0, 1, 33];
      $e->compileToVerilog("BTree/in/4");
     }
    

## commandTest()

Run test programs

**Example:**

    if (1)                                                                          # Actions on a tree driven by the input channel    
     {Start 1;
      my $W = 3;                                                                    # Width of each node
      my $F = FindResult_new;                                                       # Find area
      my $T;                                                                        # The tree
    
      ForIn                                                                         # Read commands from input channel
       {my ($i, $v, $Check, $Next, $End) = @_;
        IfEq $v, commandStart(),                                                    # Start a new tree
        Then
         {$T = New $W;
          Jmp $Next;
         };
        IfEq $v, commandInsert(),                                                   # Insert a key
        Then
         {my $k = In; my $d = In;
          Insert $T, $k, $d;
          Jmp $Next;
         };
        IfEq $v, commandFind(),                                                     # Find a key. Indicate whether it was found and its value on the output channel
        Then
         {my $k = In;
          Find $T, $k, findResult=>$F;
          IfEq FindResult_cmp($F), FindResult_found,
          Then
           {Out 1;
            Out FindResult_data $F;
           },
          Else
           {Out 0;
           };
          Jmp $Next;
         };
        Jmp $End;                                                                   # Invalid command terminates the command sequence
       };
      my $e = Execute(suppressOutput=>1, in => [0, 1, 3, 33, 1, 1, 11, 1, 2, 22, 1, 4, 44, 2, 5, 2, 2, 2, 6, 2, 3]);
      is_deeply $e->outLines, [0, 1, 22, 0, 1, 33];
      $e->compileToVerilog("BTree/in/4");
     }
    

# Attributes

The following is a list of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

## Replaceable Attribute List

x 

## x

Stop if debugging.

# Private Methods

## FindResult\_copy($F, $f)

Copy a find result

       Parameter  Description
    1  $F         Target find result
    2  $f         Source find result

## randomArray($N)

Create a random array.

       Parameter  Description
    1  $N         Size of array

# Index

1 [commandFind](#commandfind) - Find in a tree.

2 [commandInsert](#commandinsert) - Insert into a tree.

3 [commandStart](#commandstart) - Start a tree

4 [commandTest](#commandtest) - Run test programs

5 [Find](#find) - Find a key in a tree returning a [FindResult](https://metacpan.org/pod/FindResult) describing the outcome of the search.

6 [FindResult\_cmp](#findresult_cmp) - Get comparison from find result.

7 [FindResult\_copy](#findresult_copy) - Copy a find result

8 [FindResult\_data](#findresult_data) - Get data field from find results.

9 [FindResult\_key](#findresult_key) - Get key field from find results.

10 [Insert](#insert) - Insert a key and its associated data into a tree.

11 [Iterate](#iterate) - Iterate over a tree.

12 [Keys](#keys) - Get the number of keys in the tree.

13 [New](#new) - Create a variable referring to a new tree descriptor.

14 [printTreeData](#printtreedata) - Print the data held in a tree.

15 [printTreeKeys](#printtreekeys) - Print the keys held in a tree.

16 [randomArray](#randomarray) - Create a random array.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Zero::BTree

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
