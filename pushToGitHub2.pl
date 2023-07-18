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

my $home     =  q(/home/phil/perl/cpan/ZeroEmulatorLowLevel/);                  # Local files
my $user     =  q(philiprbrenan);                                               # User
my $repo     =  q(zeroLowLevel);                                                # Store code here so it can be referenced from a browser
my $wf       =  q(.github/workflows/main.yml);                                  # Work flow on Ubuntu
my $repoUrl  = qq(https://github.com/philiprbrenan/$repo);                      # Repo

my @uploadFiles = q(/home/phil/perl/cpan/ZeroEmulatorLowLevel/verilog/fpga/tests/Add/fpga.sv);

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

    - uses: actions/checkout@v3
      with:
        repository: philiprbrenan/DataTableText
        path: dtt

    - name: Cpan
      run:  sudo cpan install -T Data::Dump
    - name: Ubuntu update
      run:  sudo apt update

    - name: Verilog
      run:  sudo apt -y install iverilog

    - name: Verilog Version
      run:  iverilog -V

    - name: Yosys
      run:  wget -q https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-06-14/oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys unzip
      run: gunzip  oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys untar
      run: tar -xf oss-cad-suite-linux-x64-20230614.tar

  Yosys_Push2_:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
      with:
        ref: 'main'

    - uses: actions/checkout@v3
      with:
        repository: philiprbrenan/DataTableText
        path: dtt

    - name: Cpan
      run:  sudo cpan install -T Data::Dump
    - name: Yosys
      run:  wget -q https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-06-14/oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys unzip
      run: gunzip  oss-cad-suite-linux-x64-20230614.tgz

    - name: Yosys untar
      run: tar -xf oss-cad-suite-linux-x64-20230614.tar

    - name: Yosys_Push2_
      if: ${{ always() }}
      run: |
        export PATH="$PATH:$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        yosys -d -Q -p "read_verilog -nomem2reg verilog/fpga/tests/Push2/fpga.sv; synth_gowin -top fpga -json verilog/fpga/tests/Push2/fpga.json"

    - name: NextPnr_Push2_
      if: ${{ always() }}
      run: |
        export PATH="$PATH:$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        nextpnr-gowin --json verilog/fpga/tests/Push2/fpga.json --write verilog/fpga/tests/Push2/fpga.pnr --device "GW1NR-LV9QN88PC6/I5" --family GW1N-9C --cst verilog/fpga/tests/Push2/tangnano9k.cst

    - name: Pack_Push2_
      if: ${{ always() }}
      run: |
        export PATH="$PATH:$GITHUB_WORKSPACE/oss-cad-suite/bin/"
        gowin_pack -d GW1N-9C -o verilog/fpga/tests/Push2/fpga.fs verilog/fpga/tests/Push2/fpga.pnr

    - uses: actions/upload-artifact@v3
      if: ${{ always() }}
      with:
        path: verilog/fpga/tests/Push2/
END

my $f = writeFileUsingSavedToken $user, $repo, $wf, $y;                         # Upload workflow
lll "Ubuntu work flow for $repo written to: $f";
