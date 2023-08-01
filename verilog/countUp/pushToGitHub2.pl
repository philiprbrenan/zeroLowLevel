#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Push Yosys Add to GitHub to test gowin_synth problems
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

my $home     =  q(/home/phil/perl/cpan/ZeroEmulatorLowLevel/verilog/countUp/);  # Local files
my $user     =  q(philiprbrenan);                                               # User
my $repo     =  q(posEdgeNegEdge);                                              # Store code here so it can be referenced from a browser
my $wf       =  q(.github/workflows/main.yml);                                  # Work flow on Ubuntu
my $repoUrl  = qq(https://github.com/philiprbrenan/$repo);                      # Repo

my @uploadFiles = searchDirectoryTreesForMatchingFiles($home, qw(.sv .tb));     # Files to upload

for my $s(@uploadFiles)                                                         # Upload each selected file
 {my $c = readFile($s);                                                         # Load file
  my $t = swapFilePrefix $s, $home;
  my $w = writeFileUsingSavedToken($user, $repo, $t, $c);
  lll "$w $s $t";
 }

my $d = dateTimeStamp;

my $y = <<'END';
# Test $d

name: Test

on:
  push:

jobs:

  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
      with:
        ref: 'main'

    - name: Verilog
      run:  sudo apt -y install iverilog

    - name: Verilog Version
      run:  iverilog -V

    - name: Clock on positive and negative edges
      run: rm -f countUp; iverilog -g2012 -o countUp countUp.sv countUp.tb && timeout 1m ./countUp

END

my $f = writeFileUsingSavedToken $user, $repo, $wf, $y;                         # Upload workflow
lll "Ubuntu work flow for $repo written to: $f";
