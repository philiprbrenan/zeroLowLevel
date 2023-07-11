#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Push Zero code to GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);
use Pod::Markdown;
use feature qw(say current_sub);

makeDieConfess;

my $home     =  q(/home/phil/perl/cpan/ZeroEmulatorLowLevel/);                  # Local files
my $user     =  q(philiprbrenan);                                               # User
my $repo     =  q(zeroLowLevel);                                                # Store code here so it can be referenced from a browser
my $wf       =  q(.github/workflows/main.yml);                                  # Work flow on Ubuntu
my $repoUrl  = qq(https://github.com/philiprbrenan/$repo);                      # Repo
my $timeFile =  q(.fileTimes.data);                                             # Last upload time
my $emulator = fpf $home, q(lib/Zero/Emulator.pm);                              # Emulator
my $btree    = fpf $home, q(lib/Zero/BTree.pm);                                 # Btree
my $readMe   = fpe $home, qw(README md2);                                       # Read me

my $testsDir = fpd $home, qw(verilog fpga tests);                               # Tests folder
my $verilog  = 1;                                                               # Run the low level tests using verilog
my $yosys    = 0;                                                               # Run the low level tests using Yosys

my $T = -e $timeFile ? eval readFile($timeFile) : undef;                        # Last upload time

sub pod($$$)                                                                    # Write pod file
 {my ($in, $out, $intro) = @_;                                                  # Input, output file, introduction
  binModeAllUtf8;
  my $d = updateDocumentation readFile $in;
  if ($d =~ m(\A(.*)(=head1 Description.*=cut\n))s)
   {my $p = Pod::Markdown->new;
    my $m;
       $p->output_string(\$m);
       $p->parse_string_document(my $pod = "$intro\n$2");                       # Create Pod and convert to markdown
    owf($out, $m);                                                              # Write markdown
    my $podFile = setFileExtension($out, q(pod));                               # Corresponding pod file
    owf($podFile, $pod);                                                        # Write corresponding pod

    say STDERR "$in\n$1\n";                                                     # Print any error messages from automated documentation
    return;
   }
  confess "Cannot extract documentation for file: $in";
 }

if (!defined($T) or $T < fileModTime($emulator) or $T < fileModTime($btree))    # Pod for modules                                                                      # Documentation - specific components
 {pod $emulator, fpf($home, q(Emulator.md)), &introEmulator;
  pod $btree,    fpf($home, q(BTree.md)),    &introBTree;
 }

if (!defined($T) or $T < fileModTime($readMe))                                  # Read me
 {expandWellKnownWordsInMarkDownFile $readMe, fpe $home, qw(README md);
 }

push my @files,
  grep {!/backups/}
  grep {!/_build/}
  grep {!/Build.PL/}
  grep {!/blib/}
  searchDirectoryTreesForMatchingFiles($home,                                   # Files to upload
    qw(.pm .pl .md .sv .tb .cst));

my @uploadFiles;                                                                # Locate files to upload
if (-e $timeFile)
 {my $T = eval readFile($timeFile);                                             # Last upload time
  for my $file(@files)
   {my $t = fileModTime($file);
    push @uploadFiles, $file unless defined($T) and $T >= $t;
   }
 }
else
 {@uploadFiles = @files;
 }

for my $s(@uploadFiles)                                                         # Upload each selected file
 {my $c = readFile($s);                                                         # Load file
  my $t = swapFilePrefix $s, $home;
  my $w = writeFileUsingSavedToken($user, $repo, $t, $c);
  lll "$w $s $t";
 }

owf($timeFile, time);                                                           # Save current time

&run();                                                                         # Upload run configuration

sub lowLevelTests                                                               # Low level tests to run
 { #grep {!m(BTree)}
   map  {s($home) ()r}
   searchDirectoryTreesForMatchingFiles($testsDir, qw(.sv));                    # Test these local files
 }

sub run                                                                         # Work flow on github
 {my $d = dateTimeStamp;

  my $y = <<"END".job("test");
# Test $d

name: Test

on:
  push:
    paths:
      - '**.pm'
      - '**pushToGitHub.pl'
      - '**.yml'

jobs:
END

  $y .= &highLevelTests;                                                        # High level tests using Perl on Ubuntu
  if ($verilog or $yosys)
   {$y .= &job("fpga");                                                         # Low level tests using verilog and Yosys for a real device
    $y .= &fpgaLowLevelTestsVerilog if $verilog;                                #   Verilog
    $y .= &fpgaLowLevelTestsYosys   if $yosys;                                  #   Yosys jobs
   }
  my $f = writeFileUsingSavedToken $user, $repo, $wf, $y;                       # Upload workflow
  lll "Ubuntu work flow for $repo written to: $f";
 }

sub job                                                                         # Create a job that runs on Ubuntu
 {my ($job) = @_;                                                               # Job name
   <<"END";

  $job:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout\@v3
      with:
        ref: 'main'

    - uses: actions/checkout\@v3
      with:
        repository: philiprbrenan/DataTableText
        path: dtt

    - name: Cpan
      run:  sudo cpan install -T Data::Dump
END
 }

sub verilog {<<END}                                                             # Install verilog
    - name: Ubuntu update
      run:  sudo apt update

    - name: Verilog
      run:  sudo apt -y install iverilog

    - name: Verilog Version
      run:  iverilog -V
END

sub yosys {<<END}                                                               # Install yosys
    - name: Yosys
      run:  wget -q https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-06-14/oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys unzip
      run: gunzip  oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys untar
      run: tar -xf oss-cad-suite-linux-x64-20230614.tar

    - name: Memory fallocate
      run: |
        sudo fallocate -l 20G swapfile
        sudo chmod 600        swapfile
        sudo ls -la           swapfile
        sudo mkswap           swapfile
        sudo swapon           swapfile
        free -h

    - name: Memory fallocate2
      run: |
        sudo fallocate -l  8G /mnt/swapfile2
        sudo chmod 600        /mnt/swapfile2
        sudo ls -la           /mnt/swapfile2
        sudo mkswap           /mnt/swapfile2
        sudo swapon           /mnt/swapfile2
        free -h
END

sub highLevelTests{<<END}                                                       # High level tests using Perl on Ubuntu
    - name: Ubuntu update
      run:  sudo apt update

    - name: Verilog
      run:  sudo apt -y install iverilog

    - name: Verilog Version
      run:  iverilog -V

    - name: Emulator
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib lib/Zero/Emulator.pm

    - name: BubbleSort
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/bubbleSort.pl

    - name: InsertionSort
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/insertionSort.pl

    - name: QuickSort
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/quickSort.pl

    - name: QuickSort Parallel
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/quickSortParallel.pl

    - name: SelectionSort
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/selectionSort.pl

    - name: TestEmulator
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/testEmulator.pl

    - name: BTree
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib lib/Zero/BTree.pm

    - name: TestBTree - last as it is longest
      run:  perl -I\$GITHUB_WORKSPACE/dtt/lib examples/testBTree.pl
END

sub fpgaLowLevelTestsVerilog                                                    # Low level tests
 {my @tests = lowLevelTests;

  my $y = verilog();

  for my $s(@tests)                                                             # Test run as verilog
   {my $t = setFileExtension $s, q(tb);                                         # Test bench

    $y .= <<END;
    - name: $s
      if: \${{ always() }}
      run: |
        rm -f fpga z1.txt; iverilog -Iverilog/includes -g2012 -o fpga $t $s && timeout 1m ./fpga | tee z1.txt; grep -qv "FAILED" z1.txt

END
   }
  $y
 }

sub fpgaLowLevelTestsYosys                                                      # Low level tests
 {my @tests = lowLevelTests;
  my $y = '';
  my $d = q(GW1NR-LV9QN88PC6/I5);                                               # Device
  my $f = q(GW1N-9C);                                                           # Device family

  for my $s(@tests)                                                             # Tests
   {my $t = fp($s) =~ s(/) (_)gsr =~ s(verilog_fpga_tests_) ()gsr;              # Test name in a form suitable for github

    my $v = setFileExtension $s, q(sv);                                         # Source file
    my $j = setFileExtension $s, q(json);                                       # Json description
    my $p = setFileExtension $s, q(pnr);                                        # Place and route
    my $P = setFileExtension $s, q(fs);                                         # Bit stream
    my $b = fpe fp($s), qw(tangnano9k cst);                                     # Device description

    $y .= job("Yosys_$t").yosys(). <<END;

    - name: Yosys_$t
      if: \${{ always() }}
      run: |
        export PATH="\$PATH:\$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        yosys -q -d -p "read_verilog $v; synth_gowin -top fpga -json $j"

    - name: NextPnr_$t
      if: \${{ always() }}
      run: |
        export PATH="\$PATH:\$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        nextpnr-gowin --json $j --write $p --device "$d" --family $f --cst $b

    - name: Pack_$t
      if: \${{ always() }}
      run: |
        export PATH="\$PATH:\$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        gowin_pack -d GW1N-9C -o $P $p

END
   }
  $y
 }
#yosys -q -d -p "read_verilog -nomem2reg $v; synth_gowin -top fpga -json $j"    # nomem2reg

sub fpgaLowLevelArtefacts                                                       # The resulting bitstreams used to progrma the fpga
 {my $h = fpd qw(verilog fpga tests);                                           # Low level bit streams created by this run

  <<END
    - uses: actions/upload-artifact\@v3
      with:
        path: $h
END
 }

sub introEmulator{&introEmulator1.&introEmulator2}

sub introEmulator1{<<"END"}
=pod

=encoding utf-8

=head1 Name

Zero::Emulator - Assemble and emulate a program written in the L<Zero|$repoUrl> assembler programming language.

=for html
<p><a href="$repoUrl"><img src="$repoUrl/workflows/Test/badge.svg"></a>
END

sub introEmulator2{<<'END2'}

=head1 Synopsis

Say "hello world":

  Start 1;

  Out "Hello World";

  my $e = Execute;

  is_deeply $e->out, <<END;
Hello World
END
END2

sub introBTree{&introBTree1.&introBTree2}

sub introBTree1{<<"END"}
=pod

=encoding utf-8

=head1 Name

Zero::NWayTree - N-Way-Tree written in the Zero assembler programming language.

=for html
<p><a href="$repoUrl"><img src="$repoUrl/workflows/Test/badge.svg"></a>

=head1 Synopsis

Create a tree, load it from an array of random numbers, then print out the
results. Show the number of instructions executed in the process.  The
challenge, should you wish to acceopt it, is to reduce these instruction counts
to the minimum possible while still passing all the tests.

END

sub introBTree2{<<'END2'}
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
END2
