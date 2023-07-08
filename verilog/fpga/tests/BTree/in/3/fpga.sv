//-----------------------------------------------------------------------------
// Fpga test
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga                                                                     // Run test programs
 (input  wire clock,                                                            // Driving clock
  input  wire reset,                                                            // Restart program
  output reg  finished,                                                         // Goes high when the program has finished
  output reg  success);                                                         // Goes high on finish if all the tests passed

  parameter integer MemoryElementWidth =  12;                                   // Memory element width

  parameter integer NArea   =        8;                                         // Size of each area on the heap
  parameter integer NArrays =      251;                                         // Maximum number of arrays
  parameter integer NHeap   =     2008;                                         // Amount of heap memory
  parameter integer NLocal  =      540;                                         // Size of local memory
  parameter integer NOut    =      107;                                         // Size of output area
  parameter integer NIn     =      107;                                         // Size of input area
  reg [MemoryElementWidth-1:0]   arraySizes[NArrays-1:0];                       // Size of each array
  reg [MemoryElementWidth-1:0]      heapMem[NHeap-1  :0];                       // Heap memory
  reg [MemoryElementWidth-1:0]     localMem[NLocal-1 :0];                       // Local memory
  reg [MemoryElementWidth-1:0]       outMem[NOut-1   :0];                       // Out channel
  reg [MemoryElementWidth-1:0]        inMem[NIn-1    :0];                       // In channel
  reg [MemoryElementWidth-1:0]  freedArrays[NArrays-1:0];                       // Freed arrays list implemented as a stack
  reg [MemoryElementWidth-1:0]   arrayShift[NArea-1  :0];                       // Array shift area

  integer inMemPos;                                                             // Current position in input channel
  integer outMemPos;                                                            // Position in output channel
  integer allocs;                                                               // Maximum number of array allocations in use at any one time
  integer freedArraysTop;                                                       // Position in freed arrays stack

  integer ip;                                                                   // Instruction pointer
  integer steps;                                                                // Number of steps executed so far
  integer i, j, k;                                                              // A useful counter

  task updateArrayLength(input integer arena, input integer array, input integer index); // Update array length if we are updating an array
    begin
      if (arena == 1 && arraySizes[array] < index + 1) arraySizes[array] = index + 1;
    end
  endtask

  always @(posedge clock) begin                                                 // Each instruction
    if (reset) begin
      ip             = 0;
      steps          = 0;
      inMemPos       = 0;
      outMemPos      = 0;
      allocs         = 0;
      freedArraysTop = 0;
      finished       = 0;
      success        = 0;

      inMem[0] = 72;
      inMem[1] = 103;
      inMem[2] = 3;
      inMem[3] = 89;
      inMem[4] = 49;
      inMem[5] = 6;
      inMem[6] = 38;
      inMem[7] = 91;
      inMem[8] = 21;
      inMem[9] = 39;
      inMem[10] = 52;
      inMem[11] = 62;
      inMem[12] = 19;
      inMem[13] = 83;
      inMem[14] = 7;
      inMem[15] = 70;
      inMem[16] = 73;
      inMem[17] = 18;
      inMem[18] = 40;
      inMem[19] = 67;
      inMem[20] = 59;
      inMem[21] = 10;
      inMem[22] = 20;
      inMem[23] = 56;
      inMem[24] = 86;
      inMem[25] = 90;
      inMem[26] = 27;
      inMem[27] = 98;
      inMem[28] = 45;
      inMem[29] = 15;
      inMem[30] = 1;
      inMem[31] = 48;
      inMem[32] = 33;
      inMem[33] = 4;
      inMem[34] = 28;
      inMem[35] = 87;
      inMem[36] = 24;
      inMem[37] = 66;
      inMem[38] = 84;
      inMem[39] = 80;
      inMem[40] = 65;
      inMem[41] = 75;
      inMem[42] = 97;
      inMem[43] = 85;
      inMem[44] = 63;
      inMem[45] = 54;
      inMem[46] = 12;
      inMem[47] = 101;
      inMem[48] = 31;
      inMem[49] = 41;
      inMem[50] = 30;
      inMem[51] = 106;
      inMem[52] = 26;
      inMem[53] = 68;
      inMem[54] = 60;
      inMem[55] = 95;
      inMem[56] = 35;
      inMem[57] = 76;
      inMem[58] = 96;
      inMem[59] = 61;
      inMem[60] = 105;
      inMem[61] = 32;
      inMem[62] = 42;
      inMem[63] = 37;
      inMem[64] = 43;
      inMem[65] = 57;
      inMem[66] = 102;
      inMem[67] = 93;
      inMem[68] = 29;
      inMem[69] = 78;
      inMem[70] = 55;
      inMem[71] = 82;
      inMem[72] = 23;
      inMem[73] = 22;
      inMem[74] = 44;
      inMem[75] = 9;
      inMem[76] = 81;
      inMem[77] = 5;
      inMem[78] = 79;
      inMem[79] = 14;
      inMem[80] = 13;
      inMem[81] = 51;
      inMem[82] = 88;
      inMem[83] = 74;
      inMem[84] = 94;
      inMem[85] = 17;
      inMem[86] = 16;
      inMem[87] = 2;
      inMem[88] = 47;
      inMem[89] = 36;
      inMem[90] = 8;
      inMem[91] = 100;
      inMem[92] = 53;
      inMem[93] = 25;
      inMem[94] = 34;
      inMem[95] = 64;
      inMem[96] = 77;
      inMem[97] = 46;
      inMem[98] = 99;
      inMem[99] = 11;
      inMem[100] = 50;
      inMem[101] = 69;
      inMem[102] = 58;
      inMem[103] = 104;
      inMem[104] = 71;
      inMem[105] = 92;
      inMem[106] = 107;
      if (0) begin                                                  // Clear memory
        for(i = 0; i < NHeap;   i = i + 1)    heapMem[i] = 0;
        for(i = 0; i < NLocal;  i = i + 1)   localMem[i] = 0;
        for(i = 0; i < NArrays; i = i + 1) arraySizes[i] = 0;
      end
    end
    else begin
      steps = steps + 1;
      case(ip)

          0 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[0] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[0] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[0]] = 0;
              ip = 1;
        end

          1 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 2] = 3;
              updateArrayLength(1, localMem[0], 2);
              ip = 2;
        end

          2 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 3] = 0;
              updateArrayLength(1, localMem[0], 3);
              ip = 3;
        end

          3 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = 0;
              updateArrayLength(1, localMem[0], 0);
              ip = 4;
        end

          4 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = 0;
              updateArrayLength(1, localMem[0], 1);
              ip = 5;
        end

          5 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[1] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[1] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[1]] = 0;
              ip = 6;
        end

          6 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 7;
        end

          7 :
        begin                                                                   // inSize
if (0) begin
  $display("AAAA %4d %4d inSize", steps, ip);
end
              localMem[2] = NIn - inMemPos;
              ip = 8;
        end

          8 :
        begin                                                                   // jFalse
if (0) begin
  $display("AAAA %4d %4d jFalse", steps, ip);
end
              ip = localMem[2] == 0 ? 1054 : 9;
        end

          9 :
        begin                                                                   // in
if (0) begin
  $display("AAAA %4d %4d in", steps, ip);
end
              if (inMemPos < NIn) begin
                localMem[3] = inMem[inMemPos];
                inMemPos = inMemPos + 1;
              end
              ip = 10;
        end

         10 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[4] = heapMem[localMem[0]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 11;
        end

         11 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[5] = localMem[3] + localMem[3];
              updateArrayLength(2, 0, 0);
              ip = 12;
        end

         12 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 13;
        end

         13 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 14;
        end

         14 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[6] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 15;
        end

         15 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[6] != 0 ? 38 : 16;
        end

         16 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[7] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[7] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[7]] = 0;
              ip = 17;
        end

         17 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 0] = 1;
              updateArrayLength(1, localMem[7], 0);
              ip = 18;
        end

         18 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 2] = 0;
              updateArrayLength(1, localMem[7], 2);
              ip = 19;
        end

         19 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[8] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[8] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[8]] = 0;
              ip = 20;
        end

         20 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 4] = localMem[8];
              updateArrayLength(1, localMem[7], 4);
              ip = 21;
        end

         21 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[9] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[9] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[9]] = 0;
              ip = 22;
        end

         22 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 5] = localMem[9];
              updateArrayLength(1, localMem[7], 5);
              ip = 23;
        end

         23 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 6] = 0;
              updateArrayLength(1, localMem[7], 6);
              ip = 24;
        end

         24 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 3] = localMem[0];
              updateArrayLength(1, localMem[7], 3);
              ip = 25;
        end

         25 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = heapMem[localMem[0]*8 + 1] + 1;
              updateArrayLength(1, localMem[0], 1);
              ip = 26;
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 1] = heapMem[localMem[0]*8 + 1];
              updateArrayLength(1, localMem[7], 1);
              ip = 27;
        end

         27 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = heapMem[localMem[7]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 28;
        end

         28 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[10]*8 + 0] = localMem[3];
              updateArrayLength(1, localMem[10], 0);
              ip = 29;
        end

         29 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = heapMem[localMem[7]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 30;
        end

         30 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[11]*8 + 0] = localMem[5];
              updateArrayLength(1, localMem[11], 0);
              ip = 31;
        end

         31 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 32;
        end

         32 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 3] = localMem[7];
              updateArrayLength(1, localMem[0], 3);
              ip = 33;
        end

         33 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = heapMem[localMem[7]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 34;
        end

         34 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[12]] = 1;
              ip = 35;
        end

         35 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = heapMem[localMem[7]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 36;
        end

         36 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[13]] = 1;
              ip = 37;
        end

         37 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1050;
        end

         38 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 39;
        end

         39 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = heapMem[localMem[6]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 40;
        end

         40 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = heapMem[localMem[0]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 41;
        end

         41 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[14] >= localMem[15] ? 77 : 42;
        end

         42 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = heapMem[localMem[6]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 43;
        end

         43 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[16] != 0 ? 76 : 44;
        end

         44 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[17] = !heapMem[localMem[6]*8 + 6];
              ip = 45;
        end

         45 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[17] == 0 ? 75 : 46;
        end

         46 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[18] = heapMem[localMem[6]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 47;
        end

         47 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[19] = 0; k = arraySizes[localMem[18]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[18] * NArea + i] == localMem[3]) localMem[19] = i + 1;
              end
              ip = 48;
        end

         48 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[19] == 0 ? 53 : 49;
        end

         49 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed    49");
        end

         50 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    50");
        end

         51 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    51");
        end

         52 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed    52");
        end

         53 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 54;
        end

         54 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[18]] = localMem[14];
              ip = 55;
        end

         55 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[21] = heapMem[localMem[6]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 56;
        end

         56 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[21]] = localMem[14];
              ip = 57;
        end

         57 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[18]];
//$display("AAAAA k=%d  source2=%d", k, localMem[3]);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[18] * NArea + i]);
                if (i < k && heapMem[localMem[18] * NArea + i] > localMem[3]) j = j + 1;
              end
              localMem[22] = j;
              ip = 58;
        end

         58 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[22] != 0 ? 66 : 59;
        end

         59 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = heapMem[localMem[6]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 60;
        end

         60 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[23]*8 + localMem[14]] = localMem[3];
              updateArrayLength(1, localMem[23], localMem[14]);
              ip = 61;
        end

         61 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[24] = heapMem[localMem[6]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 62;
        end

         62 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[24]*8 + localMem[14]] = localMem[5];
              updateArrayLength(1, localMem[24], localMem[14]);
              ip = 63;
        end

         63 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[6]*8 + 0] = localMem[14] + 1;
              updateArrayLength(1, localMem[6], 0);
              ip = 64;
        end

         64 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 65;
        end

         65 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1050;
        end

         66 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 67;
        end

         67 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[18]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[18] * NArea + i] < localMem[3]) j = j + 1;
              end
              localMem[25] = j;
              ip = 68;
        end

         68 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[26] = heapMem[localMem[6]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 69;
        end

         69 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[26] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[25], localMem[26], arraySizes[localMem[26]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[25] && i <= arraySizes[localMem[26]]) begin
                  heapMem[NArea * localMem[26] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[26] + localMem[25]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[26]] = arraySizes[localMem[26]] + 1;                              // Increase array size
              ip = 70;
        end

         70 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = heapMem[localMem[6]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 71;
        end

         71 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[27] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[25], localMem[27], arraySizes[localMem[27]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[25] && i <= arraySizes[localMem[27]]) begin
                  heapMem[NArea * localMem[27] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[27] + localMem[25]] = localMem[5];                                    // Insert new value
              arraySizes[localMem[27]] = arraySizes[localMem[27]] + 1;                              // Increase array size
              ip = 72;
        end

         72 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[6]*8 + 0] = heapMem[localMem[6]*8 + 0] + 1;
              updateArrayLength(1, localMem[6], 0);
              ip = 73;
        end

         73 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 74;
        end

         74 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1050;
        end

         75 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 76;
        end

         76 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 77;
        end

         77 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 78;
        end

         78 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 79;
        end

         79 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 80;
        end

         80 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[30] = heapMem[localMem[28]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 81;
        end

         81 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[30] <  3 ? 299 : 82;
        end

         82 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[31] = heapMem[localMem[28]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 83;
        end

         83 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[32] = heapMem[localMem[28]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 84;
        end

         84 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[32] == 0 ? 181 : 85;
        end

         85 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed    85");
        end

         86 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    86");
        end

         87 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    87");
        end

         88 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed    88");
        end

         89 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    89");
        end

         90 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed    90");
        end

         91 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    91");
        end

         92 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    92");
        end

         93 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    93");
        end

         94 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed    94");
        end

         95 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    95");
        end

         96 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed    96");
        end

         97 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed    97");
        end

         98 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed    98");
        end

         99 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    99");
        end

        100 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   100");
        end

        101 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   101");
        end

        102 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   102");
        end

        103 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   103");
        end

        104 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   104");
        end

        105 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   105");
        end

        106 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   106");
        end

        107 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   107");
        end

        108 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   108");
        end

        109 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   109");
        end

        110 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   110");
        end

        111 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   111");
        end

        112 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   112");
        end

        113 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   113");
        end

        114 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   114");
        end

        115 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   115");
        end

        116 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   116");
        end

        117 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   117");
        end

        118 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   118");
        end

        119 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   119");
        end

        120 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   120");
        end

        121 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   121");
        end

        122 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   122");
        end

        123 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   123");
        end

        124 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   124");
        end

        125 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   125");
        end

        126 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   126");
        end

        127 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   127");
        end

        128 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   128");
        end

        129 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   129");
        end

        130 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   130");
        end

        131 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   131");
        end

        132 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   132");
        end

        133 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   133");
        end

        134 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   134");
        end

        135 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   135");
        end

        136 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   136");
        end

        137 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   137");
        end

        138 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   138");
        end

        139 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   139");
        end

        140 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   140");
        end

        141 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   141");
        end

        142 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   142");
        end

        143 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   143");
        end

        144 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   144");
        end

        145 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   145");
        end

        146 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   146");
        end

        147 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   147");
        end

        148 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   148");
        end

        149 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   149");
        end

        150 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   150");
        end

        151 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   151");
        end

        152 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   152");
        end

        153 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   153");
        end

        154 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   154");
        end

        155 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   155");
        end

        156 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   156");
        end

        157 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   157");
        end

        158 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   158");
        end

        159 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
           $display("Should not be executed   159");
        end

        160 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   160");
        end

        161 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
           $display("Should not be executed   161");
        end

        162 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed   162");
        end

        163 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   163");
        end

        164 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   164");
        end

        165 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   165");
        end

        166 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   166");
        end

        167 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   167");
        end

        168 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   168");
        end

        169 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   169");
        end

        170 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   170");
        end

        171 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   171");
        end

        172 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   172");
        end

        173 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   173");
        end

        174 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   174");
        end

        175 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   175");
        end

        176 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   176");
        end

        177 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   177");
        end

        178 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   178");
        end

        179 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   179");
        end

        180 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   180");
        end

        181 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 182;
        end

        182 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[80] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[80] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[80]] = 0;
              ip = 183;
        end

        183 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 0] = 1;
              updateArrayLength(1, localMem[80], 0);
              ip = 184;
        end

        184 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 2] = 0;
              updateArrayLength(1, localMem[80], 2);
              ip = 185;
        end

        185 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[81] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[81] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[81]] = 0;
              ip = 186;
        end

        186 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 4] = localMem[81];
              updateArrayLength(1, localMem[80], 4);
              ip = 187;
        end

        187 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[82] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[82] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[82]] = 0;
              ip = 188;
        end

        188 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 5] = localMem[82];
              updateArrayLength(1, localMem[80], 5);
              ip = 189;
        end

        189 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 6] = 0;
              updateArrayLength(1, localMem[80], 6);
              ip = 190;
        end

        190 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 3] = localMem[31];
              updateArrayLength(1, localMem[80], 3);
              ip = 191;
        end

        191 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[31]*8 + 1] = heapMem[localMem[31]*8 + 1] + 1;
              updateArrayLength(1, localMem[31], 1);
              ip = 192;
        end

        192 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 1] = heapMem[localMem[31]*8 + 1];
              updateArrayLength(1, localMem[80], 1);
              ip = 193;
        end

        193 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[83] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[83] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[83]] = 0;
              ip = 194;
        end

        194 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 0] = 1;
              updateArrayLength(1, localMem[83], 0);
              ip = 195;
        end

        195 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 2] = 0;
              updateArrayLength(1, localMem[83], 2);
              ip = 196;
        end

        196 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[84] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[84] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[84]] = 0;
              ip = 197;
        end

        197 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 4] = localMem[84];
              updateArrayLength(1, localMem[83], 4);
              ip = 198;
        end

        198 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[85] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[85] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[85]] = 0;
              ip = 199;
        end

        199 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 5] = localMem[85];
              updateArrayLength(1, localMem[83], 5);
              ip = 200;
        end

        200 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 6] = 0;
              updateArrayLength(1, localMem[83], 6);
              ip = 201;
        end

        201 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 3] = localMem[31];
              updateArrayLength(1, localMem[83], 3);
              ip = 202;
        end

        202 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[31]*8 + 1] = heapMem[localMem[31]*8 + 1] + 1;
              updateArrayLength(1, localMem[31], 1);
              ip = 203;
        end

        203 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 1] = heapMem[localMem[31]*8 + 1];
              updateArrayLength(1, localMem[83], 1);
              ip = 204;
        end

        204 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[86] = !heapMem[localMem[28]*8 + 6];
              ip = 205;
        end

        205 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[86] != 0 ? 257 : 206;
        end

        206 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[87] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[87] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[87]] = 0;
              ip = 207;
        end

        207 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 6] = localMem[87];
              updateArrayLength(1, localMem[80], 6);
              ip = 208;
        end

        208 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[88] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[88] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[88]] = 0;
              ip = 209;
        end

        209 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 6] = localMem[88];
              updateArrayLength(1, localMem[83], 6);
              ip = 210;
        end

        210 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[89] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 211;
        end

        211 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[90] = heapMem[localMem[80]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 212;
        end

        212 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[90] + 0 + i] = heapMem[NArea * localMem[89] + 0 + i];
                  updateArrayLength(1, localMem[90], 0 + i);
                end
              end
              ip = 213;
        end

        213 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[91] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 214;
        end

        214 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[92] = heapMem[localMem[80]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 215;
        end

        215 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[92] + 0 + i] = heapMem[NArea * localMem[91] + 0 + i];
                  updateArrayLength(1, localMem[92], 0 + i);
                end
              end
              ip = 216;
        end

        216 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[93] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 217;
        end

        217 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[94] = heapMem[localMem[80]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 218;
        end

        218 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[95] = 1 + 1;
              updateArrayLength(2, 0, 0);
              ip = 219;
        end

        219 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[95]) begin
                  heapMem[NArea * localMem[94] + 0 + i] = heapMem[NArea * localMem[93] + 0 + i];
                  updateArrayLength(1, localMem[94], 0 + i);
                end
              end
              ip = 220;
        end

        220 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[96] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 221;
        end

        221 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[97] = heapMem[localMem[83]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 222;
        end

        222 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[97] + 0 + i] = heapMem[NArea * localMem[96] + 2 + i];
                  updateArrayLength(1, localMem[97], 0 + i);
                end
              end
              ip = 223;
        end

        223 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[98] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 224;
        end

        224 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[99] = heapMem[localMem[83]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 225;
        end

        225 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[99] + 0 + i] = heapMem[NArea * localMem[98] + 2 + i];
                  updateArrayLength(1, localMem[99], 0 + i);
                end
              end
              ip = 226;
        end

        226 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[100] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 227;
        end

        227 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[101] = heapMem[localMem[83]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 228;
        end

        228 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[102] = 1 + 1;
              updateArrayLength(2, 0, 0);
              ip = 229;
        end

        229 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[102]) begin
                  heapMem[NArea * localMem[101] + 0 + i] = heapMem[NArea * localMem[100] + 2 + i];
                  updateArrayLength(1, localMem[101], 0 + i);
                end
              end
              ip = 230;
        end

        230 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[103] = heapMem[localMem[80]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 231;
        end

        231 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[104] = localMem[103] + 1;
              updateArrayLength(2, 0, 0);
              ip = 232;
        end

        232 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[105] = heapMem[localMem[80]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 233;
        end

        233 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 234;
        end

        234 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[106] = 0;
              updateArrayLength(2, 0, 0);
              ip = 235;
        end

        235 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 236;
        end

        236 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[106] >= localMem[104] ? 242 : 237;
        end

        237 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[107] = heapMem[localMem[105]*8 + localMem[106]];
              updateArrayLength(2, 0, 0);
              ip = 238;
        end

        238 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[107]*8 + 2] = localMem[80];
              updateArrayLength(1, localMem[107], 2);
              ip = 239;
        end

        239 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 240;
        end

        240 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[106] = localMem[106] + 1;
              updateArrayLength(2, 0, 0);
              ip = 241;
        end

        241 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 235;
        end

        242 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 243;
        end

        243 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[108] = heapMem[localMem[83]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 244;
        end

        244 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[109] = localMem[108] + 1;
              updateArrayLength(2, 0, 0);
              ip = 245;
        end

        245 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[110] = heapMem[localMem[83]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 246;
        end

        246 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 247;
        end

        247 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[111] = 0;
              updateArrayLength(2, 0, 0);
              ip = 248;
        end

        248 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 249;
        end

        249 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[111] >= localMem[109] ? 255 : 250;
        end

        250 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[112] = heapMem[localMem[110]*8 + localMem[111]];
              updateArrayLength(2, 0, 0);
              ip = 251;
        end

        251 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[112]*8 + 2] = localMem[83];
              updateArrayLength(1, localMem[112], 2);
              ip = 252;
        end

        252 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 253;
        end

        253 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[111] = localMem[111] + 1;
              updateArrayLength(2, 0, 0);
              ip = 254;
        end

        254 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 248;
        end

        255 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 256;
        end

        256 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 272;
        end

        257 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 258;
        end

        258 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[113] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[113] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[113]] = 0;
              ip = 259;
        end

        259 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[28]*8 + 6] = localMem[113];
              updateArrayLength(1, localMem[28], 6);
              ip = 260;
        end

        260 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[114] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 261;
        end

        261 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[115] = heapMem[localMem[80]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 262;
        end

        262 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[115] + 0 + i] = heapMem[NArea * localMem[114] + 0 + i];
                  updateArrayLength(1, localMem[115], 0 + i);
                end
              end
              ip = 263;
        end

        263 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[116] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 264;
        end

        264 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[117] = heapMem[localMem[80]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 265;
        end

        265 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[117] + 0 + i] = heapMem[NArea * localMem[116] + 0 + i];
                  updateArrayLength(1, localMem[117], 0 + i);
                end
              end
              ip = 266;
        end

        266 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[118] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 267;
        end

        267 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[119] = heapMem[localMem[83]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 268;
        end

        268 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[119] + 0 + i] = heapMem[NArea * localMem[118] + 2 + i];
                  updateArrayLength(1, localMem[119], 0 + i);
                end
              end
              ip = 269;
        end

        269 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[120] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 270;
        end

        270 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[121] = heapMem[localMem[83]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 271;
        end

        271 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[121] + 0 + i] = heapMem[NArea * localMem[120] + 2 + i];
                  updateArrayLength(1, localMem[121], 0 + i);
                end
              end
              ip = 272;
        end

        272 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 273;
        end

        273 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[80]*8 + 2] = localMem[28];
              updateArrayLength(1, localMem[80], 2);
              ip = 274;
        end

        274 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[83]*8 + 2] = localMem[28];
              updateArrayLength(1, localMem[83], 2);
              ip = 275;
        end

        275 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[122] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 276;
        end

        276 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[123] = heapMem[localMem[122]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 277;
        end

        277 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[124] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 278;
        end

        278 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[125] = heapMem[localMem[124]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 279;
        end

        279 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[126] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 280;
        end

        280 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[126]*8 + 0] = localMem[123];
              updateArrayLength(1, localMem[126], 0);
              ip = 281;
        end

        281 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[127] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 282;
        end

        282 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[127]*8 + 0] = localMem[125];
              updateArrayLength(1, localMem[127], 0);
              ip = 283;
        end

        283 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[128] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 284;
        end

        284 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[128]*8 + 0] = localMem[80];
              updateArrayLength(1, localMem[128], 0);
              ip = 285;
        end

        285 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[129] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 286;
        end

        286 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[129]*8 + 1] = localMem[83];
              updateArrayLength(1, localMem[129], 1);
              ip = 287;
        end

        287 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[28]*8 + 0] = 1;
              updateArrayLength(1, localMem[28], 0);
              ip = 288;
        end

        288 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[130] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 289;
        end

        289 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[130]] = 1;
              ip = 290;
        end

        290 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[131] = heapMem[localMem[28]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 291;
        end

        291 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[131]] = 1;
              ip = 292;
        end

        292 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[132] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 293;
        end

        293 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[132]] = 2;
              ip = 294;
        end

        294 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 296;
        end

        295 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   295");
        end

        296 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 297;
        end

        297 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[29] = 1;
              updateArrayLength(2, 0, 0);
              ip = 298;
        end

        298 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 301;
        end

        299 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 300;
        end

        300 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[29] = 0;
              updateArrayLength(2, 0, 0);
              ip = 301;
        end

        301 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 302;
        end

        302 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 303;
        end

        303 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 304;
        end

        304 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[133] = 0;
              updateArrayLength(2, 0, 0);
              ip = 305;
        end

        305 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 306;
        end

        306 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[133] >= 99 ? 796 : 307;
        end

        307 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[134] = heapMem[localMem[28]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 308;
        end

        308 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[135] = localMem[134] - 1;
              updateArrayLength(2, 0, 0);
              ip = 309;
        end

        309 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[136] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 310;
        end

        310 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[137] = heapMem[localMem[136]*8 + localMem[135]];
              updateArrayLength(2, 0, 0);
              ip = 311;
        end

        311 :
        begin                                                                   // jLe
if (0) begin
  $display("AAAA %4d %4d jLe", steps, ip);
end
              ip = localMem[3] <= localMem[137] ? 548 : 312;
        end

        312 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[138] = !heapMem[localMem[28]*8 + 6];
              ip = 313;
        end

        313 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[138] == 0 ? 318 : 314;
        end

        314 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = localMem[28];
              updateArrayLength(1, localMem[1], 0);
              ip = 315;
        end

        315 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 1] = 2;
              updateArrayLength(1, localMem[1], 1);
              ip = 316;
        end

        316 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              heapMem[localMem[1]*8 + 2] = localMem[134] - 1;
              updateArrayLength(1, localMem[1], 2);
              ip = 317;
        end

        317 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 800;
        end

        318 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 319;
        end

        319 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[139] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 320;
        end

        320 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[140] = heapMem[localMem[139]*8 + localMem[134]];
              updateArrayLength(2, 0, 0);
              ip = 321;
        end

        321 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 322;
        end

        322 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[142] = heapMem[localMem[140]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 323;
        end

        323 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[142] <  3 ? 541 : 324;
        end

        324 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[143] = heapMem[localMem[140]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 325;
        end

        325 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[144] = heapMem[localMem[140]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 326;
        end

        326 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[144] == 0 ? 423 : 327;
        end

        327 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[145] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[145] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[145]] = 0;
              ip = 328;
        end

        328 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 0] = 1;
              updateArrayLength(1, localMem[145], 0);
              ip = 329;
        end

        329 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 2] = 0;
              updateArrayLength(1, localMem[145], 2);
              ip = 330;
        end

        330 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[146] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[146] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[146]] = 0;
              ip = 331;
        end

        331 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 4] = localMem[146];
              updateArrayLength(1, localMem[145], 4);
              ip = 332;
        end

        332 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[147] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[147] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[147]] = 0;
              ip = 333;
        end

        333 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 5] = localMem[147];
              updateArrayLength(1, localMem[145], 5);
              ip = 334;
        end

        334 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 6] = 0;
              updateArrayLength(1, localMem[145], 6);
              ip = 335;
        end

        335 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 3] = localMem[143];
              updateArrayLength(1, localMem[145], 3);
              ip = 336;
        end

        336 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[143]*8 + 1] = heapMem[localMem[143]*8 + 1] + 1;
              updateArrayLength(1, localMem[143], 1);
              ip = 337;
        end

        337 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 1] = heapMem[localMem[143]*8 + 1];
              updateArrayLength(1, localMem[145], 1);
              ip = 338;
        end

        338 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[148] = !heapMem[localMem[140]*8 + 6];
              ip = 339;
        end

        339 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[148] != 0 ? 368 : 340;
        end

        340 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[149] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[149] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[149]] = 0;
              ip = 341;
        end

        341 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 6] = localMem[149];
              updateArrayLength(1, localMem[145], 6);
              ip = 342;
        end

        342 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[150] = heapMem[localMem[140]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 343;
        end

        343 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[151] = heapMem[localMem[145]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 344;
        end

        344 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[151] + 0 + i] = heapMem[NArea * localMem[150] + 2 + i];
                  updateArrayLength(1, localMem[151], 0 + i);
                end
              end
              ip = 345;
        end

        345 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[152] = heapMem[localMem[140]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 346;
        end

        346 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[153] = heapMem[localMem[145]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 347;
        end

        347 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[153] + 0 + i] = heapMem[NArea * localMem[152] + 2 + i];
                  updateArrayLength(1, localMem[153], 0 + i);
                end
              end
              ip = 348;
        end

        348 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[154] = heapMem[localMem[140]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 349;
        end

        349 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[155] = heapMem[localMem[145]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 350;
        end

        350 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[156] = 1 + 1;
              updateArrayLength(2, 0, 0);
              ip = 351;
        end

        351 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[156]) begin
                  heapMem[NArea * localMem[155] + 0 + i] = heapMem[NArea * localMem[154] + 2 + i];
                  updateArrayLength(1, localMem[155], 0 + i);
                end
              end
              ip = 352;
        end

        352 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[157] = heapMem[localMem[145]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 353;
        end

        353 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[158] = localMem[157] + 1;
              updateArrayLength(2, 0, 0);
              ip = 354;
        end

        354 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[159] = heapMem[localMem[145]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 355;
        end

        355 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 356;
        end

        356 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[160] = 0;
              updateArrayLength(2, 0, 0);
              ip = 357;
        end

        357 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 358;
        end

        358 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[160] >= localMem[158] ? 364 : 359;
        end

        359 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[161] = heapMem[localMem[159]*8 + localMem[160]];
              updateArrayLength(2, 0, 0);
              ip = 360;
        end

        360 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[161]*8 + 2] = localMem[145];
              updateArrayLength(1, localMem[161], 2);
              ip = 361;
        end

        361 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 362;
        end

        362 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[160] = localMem[160] + 1;
              updateArrayLength(2, 0, 0);
              ip = 363;
        end

        363 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 357;
        end

        364 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 365;
        end

        365 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[162] = heapMem[localMem[140]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 366;
        end

        366 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[162]] = 2;
              ip = 367;
        end

        367 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 375;
        end

        368 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   368");
        end

        369 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   369");
        end

        370 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   370");
        end

        371 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   371");
        end

        372 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   372");
        end

        373 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   373");
        end

        374 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   374");
        end

        375 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 376;
        end

        376 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[140]*8 + 0] = 1;
              updateArrayLength(1, localMem[140], 0);
              ip = 377;
        end

        377 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[145]*8 + 2] = localMem[144];
              updateArrayLength(1, localMem[145], 2);
              ip = 378;
        end

        378 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[167] = heapMem[localMem[144]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 379;
        end

        379 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[168] = heapMem[localMem[144]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 380;
        end

        380 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[169] = heapMem[localMem[168]*8 + localMem[167]];
              updateArrayLength(2, 0, 0);
              ip = 381;
        end

        381 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[169] != localMem[140] ? 400 : 382;
        end

        382 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[170] = heapMem[localMem[140]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 383;
        end

        383 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[171] = heapMem[localMem[170]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 384;
        end

        384 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[172] = heapMem[localMem[144]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 385;
        end

        385 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[172]*8 + localMem[167]] = localMem[171];
              updateArrayLength(1, localMem[172], localMem[167]);
              ip = 386;
        end

        386 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[173] = heapMem[localMem[140]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 387;
        end

        387 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[174] = heapMem[localMem[173]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 388;
        end

        388 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[175] = heapMem[localMem[144]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 389;
        end

        389 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[175]*8 + localMem[167]] = localMem[174];
              updateArrayLength(1, localMem[175], localMem[167]);
              ip = 390;
        end

        390 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[176] = heapMem[localMem[140]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 391;
        end

        391 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[176]] = 1;
              ip = 392;
        end

        392 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[177] = heapMem[localMem[140]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 393;
        end

        393 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[177]] = 1;
              ip = 394;
        end

        394 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[178] = localMem[167] + 1;
              updateArrayLength(2, 0, 0);
              ip = 395;
        end

        395 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[144]*8 + 0] = localMem[178];
              updateArrayLength(1, localMem[144], 0);
              ip = 396;
        end

        396 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[179] = heapMem[localMem[144]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 397;
        end

        397 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[179]*8 + localMem[178]] = localMem[145];
              updateArrayLength(1, localMem[179], localMem[178]);
              ip = 398;
        end

        398 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 538;
        end

        399 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   399");
        end

        400 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   400");
        end

        401 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
           $display("Should not be executed   401");
        end

        402 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   402");
        end

        403 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
           $display("Should not be executed   403");
        end

        404 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed   404");
        end

        405 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   405");
        end

        406 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   406");
        end

        407 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   407");
        end

        408 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   408");
        end

        409 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   409");
        end

        410 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   410");
        end

        411 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   411");
        end

        412 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   412");
        end

        413 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   413");
        end

        414 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   414");
        end

        415 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   415");
        end

        416 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   416");
        end

        417 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   417");
        end

        418 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   418");
        end

        419 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   419");
        end

        420 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   420");
        end

        421 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   421");
        end

        422 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   422");
        end

        423 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   423");
        end

        424 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   424");
        end

        425 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   425");
        end

        426 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   426");
        end

        427 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   427");
        end

        428 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   428");
        end

        429 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   429");
        end

        430 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   430");
        end

        431 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   431");
        end

        432 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   432");
        end

        433 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   433");
        end

        434 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   434");
        end

        435 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   435");
        end

        436 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   436");
        end

        437 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   437");
        end

        438 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   438");
        end

        439 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   439");
        end

        440 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   440");
        end

        441 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   441");
        end

        442 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   442");
        end

        443 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   443");
        end

        444 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   444");
        end

        445 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   445");
        end

        446 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   446");
        end

        447 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   447");
        end

        448 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   448");
        end

        449 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   449");
        end

        450 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   450");
        end

        451 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   451");
        end

        452 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   452");
        end

        453 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   453");
        end

        454 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   454");
        end

        455 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   455");
        end

        456 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   456");
        end

        457 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   457");
        end

        458 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   458");
        end

        459 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   459");
        end

        460 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   460");
        end

        461 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   461");
        end

        462 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   462");
        end

        463 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   463");
        end

        464 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   464");
        end

        465 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   465");
        end

        466 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   466");
        end

        467 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   467");
        end

        468 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   468");
        end

        469 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   469");
        end

        470 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   470");
        end

        471 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   471");
        end

        472 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   472");
        end

        473 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   473");
        end

        474 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   474");
        end

        475 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   475");
        end

        476 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   476");
        end

        477 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   477");
        end

        478 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   478");
        end

        479 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   479");
        end

        480 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   480");
        end

        481 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   481");
        end

        482 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   482");
        end

        483 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   483");
        end

        484 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   484");
        end

        485 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   485");
        end

        486 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   486");
        end

        487 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   487");
        end

        488 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   488");
        end

        489 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   489");
        end

        490 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   490");
        end

        491 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   491");
        end

        492 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   492");
        end

        493 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   493");
        end

        494 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   494");
        end

        495 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   495");
        end

        496 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   496");
        end

        497 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   497");
        end

        498 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   498");
        end

        499 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   499");
        end

        500 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   500");
        end

        501 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   501");
        end

        502 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   502");
        end

        503 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   503");
        end

        504 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   504");
        end

        505 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   505");
        end

        506 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   506");
        end

        507 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   507");
        end

        508 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   508");
        end

        509 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   509");
        end

        510 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   510");
        end

        511 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   511");
        end

        512 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   512");
        end

        513 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   513");
        end

        514 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   514");
        end

        515 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   515");
        end

        516 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   516");
        end

        517 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   517");
        end

        518 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   518");
        end

        519 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   519");
        end

        520 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   520");
        end

        521 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   521");
        end

        522 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   522");
        end

        523 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   523");
        end

        524 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   524");
        end

        525 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   525");
        end

        526 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   526");
        end

        527 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   527");
        end

        528 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   528");
        end

        529 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   529");
        end

        530 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   530");
        end

        531 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   531");
        end

        532 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   532");
        end

        533 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   533");
        end

        534 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   534");
        end

        535 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   535");
        end

        536 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   536");
        end

        537 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   537");
        end

        538 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 539;
        end

        539 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[141] = 1;
              updateArrayLength(2, 0, 0);
              ip = 540;
        end

        540 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 543;
        end

        541 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 542;
        end

        542 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[141] = 0;
              updateArrayLength(2, 0, 0);
              ip = 543;
        end

        543 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 544;
        end

        544 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[141] != 0 ? 546 : 545;
        end

        545 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = localMem[140];
              updateArrayLength(2, 0, 0);
              ip = 546;
        end

        546 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 547;
        end

        547 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 793;
        end

        548 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 549;
        end

        549 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[245] = heapMem[localMem[28]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 550;
        end

        550 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[246] = 0; k = arraySizes[localMem[245]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[245] * NArea + i] == localMem[3]) localMem[246] = i + 1;
              end
              ip = 551;
        end

        551 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[246] == 0 ? 556 : 552;
        end

        552 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   552");
        end

        553 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   553");
        end

        554 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed   554");
        end

        555 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   555");
        end

        556 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 557;
        end

        557 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[245]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[245] * NArea + i] < localMem[3]) j = j + 1;
              end
              localMem[247] = j;
              ip = 558;
        end

        558 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[248] = !heapMem[localMem[28]*8 + 6];
              ip = 559;
        end

        559 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[248] == 0 ? 564 : 560;
        end

        560 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = localMem[28];
              updateArrayLength(1, localMem[1], 0);
              ip = 561;
        end

        561 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 1] = 0;
              updateArrayLength(1, localMem[1], 1);
              ip = 562;
        end

        562 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 2] = localMem[247];
              updateArrayLength(1, localMem[1], 2);
              ip = 563;
        end

        563 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 800;
        end

        564 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 565;
        end

        565 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[249] = heapMem[localMem[28]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 566;
        end

        566 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[250] = heapMem[localMem[249]*8 + localMem[247]];
              updateArrayLength(2, 0, 0);
              ip = 567;
        end

        567 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 568;
        end

        568 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[252] = heapMem[localMem[250]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 569;
        end

        569 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[252] <  3 ? 787 : 570;
        end

        570 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[253] = heapMem[localMem[250]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 571;
        end

        571 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[254] = heapMem[localMem[250]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 572;
        end

        572 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[254] == 0 ? 669 : 573;
        end

        573 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[255] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[255] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[255]] = 0;
              ip = 574;
        end

        574 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 0] = 1;
              updateArrayLength(1, localMem[255], 0);
              ip = 575;
        end

        575 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 2] = 0;
              updateArrayLength(1, localMem[255], 2);
              ip = 576;
        end

        576 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[256] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[256] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[256]] = 0;
              ip = 577;
        end

        577 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 4] = localMem[256];
              updateArrayLength(1, localMem[255], 4);
              ip = 578;
        end

        578 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[257] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[257] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[257]] = 0;
              ip = 579;
        end

        579 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 5] = localMem[257];
              updateArrayLength(1, localMem[255], 5);
              ip = 580;
        end

        580 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 6] = 0;
              updateArrayLength(1, localMem[255], 6);
              ip = 581;
        end

        581 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 3] = localMem[253];
              updateArrayLength(1, localMem[255], 3);
              ip = 582;
        end

        582 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[253]*8 + 1] = heapMem[localMem[253]*8 + 1] + 1;
              updateArrayLength(1, localMem[253], 1);
              ip = 583;
        end

        583 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 1] = heapMem[localMem[253]*8 + 1];
              updateArrayLength(1, localMem[255], 1);
              ip = 584;
        end

        584 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[258] = !heapMem[localMem[250]*8 + 6];
              ip = 585;
        end

        585 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[258] != 0 ? 614 : 586;
        end

        586 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[259] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[259] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[259]] = 0;
              ip = 587;
        end

        587 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 6] = localMem[259];
              updateArrayLength(1, localMem[255], 6);
              ip = 588;
        end

        588 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[260] = heapMem[localMem[250]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 589;
        end

        589 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[261] = heapMem[localMem[255]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 590;
        end

        590 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[261] + 0 + i] = heapMem[NArea * localMem[260] + 2 + i];
                  updateArrayLength(1, localMem[261], 0 + i);
                end
              end
              ip = 591;
        end

        591 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[262] = heapMem[localMem[250]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 592;
        end

        592 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[263] = heapMem[localMem[255]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 593;
        end

        593 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[263] + 0 + i] = heapMem[NArea * localMem[262] + 2 + i];
                  updateArrayLength(1, localMem[263], 0 + i);
                end
              end
              ip = 594;
        end

        594 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[264] = heapMem[localMem[250]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 595;
        end

        595 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[265] = heapMem[localMem[255]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 596;
        end

        596 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[266] = 1 + 1;
              updateArrayLength(2, 0, 0);
              ip = 597;
        end

        597 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[266]) begin
                  heapMem[NArea * localMem[265] + 0 + i] = heapMem[NArea * localMem[264] + 2 + i];
                  updateArrayLength(1, localMem[265], 0 + i);
                end
              end
              ip = 598;
        end

        598 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[267] = heapMem[localMem[255]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 599;
        end

        599 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[268] = localMem[267] + 1;
              updateArrayLength(2, 0, 0);
              ip = 600;
        end

        600 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[269] = heapMem[localMem[255]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 601;
        end

        601 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 602;
        end

        602 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[270] = 0;
              updateArrayLength(2, 0, 0);
              ip = 603;
        end

        603 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 604;
        end

        604 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[270] >= localMem[268] ? 610 : 605;
        end

        605 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[271] = heapMem[localMem[269]*8 + localMem[270]];
              updateArrayLength(2, 0, 0);
              ip = 606;
        end

        606 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[271]*8 + 2] = localMem[255];
              updateArrayLength(1, localMem[271], 2);
              ip = 607;
        end

        607 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 608;
        end

        608 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[270] = localMem[270] + 1;
              updateArrayLength(2, 0, 0);
              ip = 609;
        end

        609 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 603;
        end

        610 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 611;
        end

        611 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[272] = heapMem[localMem[250]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 612;
        end

        612 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[272]] = 2;
              ip = 613;
        end

        613 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 621;
        end

        614 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   614");
        end

        615 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   615");
        end

        616 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   616");
        end

        617 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   617");
        end

        618 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   618");
        end

        619 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   619");
        end

        620 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   620");
        end

        621 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 622;
        end

        622 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[250]*8 + 0] = 1;
              updateArrayLength(1, localMem[250], 0);
              ip = 623;
        end

        623 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[255]*8 + 2] = localMem[254];
              updateArrayLength(1, localMem[255], 2);
              ip = 624;
        end

        624 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[277] = heapMem[localMem[254]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 625;
        end

        625 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[278] = heapMem[localMem[254]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 626;
        end

        626 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[279] = heapMem[localMem[278]*8 + localMem[277]];
              updateArrayLength(2, 0, 0);
              ip = 627;
        end

        627 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[279] != localMem[250] ? 646 : 628;
        end

        628 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   628");
        end

        629 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   629");
        end

        630 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   630");
        end

        631 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   631");
        end

        632 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   632");
        end

        633 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   633");
        end

        634 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   634");
        end

        635 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   635");
        end

        636 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   636");
        end

        637 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   637");
        end

        638 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   638");
        end

        639 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   639");
        end

        640 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   640");
        end

        641 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   641");
        end

        642 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   642");
        end

        643 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   643");
        end

        644 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   644");
        end

        645 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   645");
        end

        646 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 647;
        end

        647 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 648;
        end

        648 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[290] = heapMem[localMem[254]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 649;
        end

        649 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[291] = 0; k = arraySizes[localMem[290]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[290] * NArea + i] == localMem[250]) localMem[291] = i + 1;
              end
              ip = 650;
        end

        650 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[291] = localMem[291] - 1;
              updateArrayLength(2, 0, 0);
              ip = 651;
        end

        651 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[292] = heapMem[localMem[250]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 652;
        end

        652 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[293] = heapMem[localMem[292]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 653;
        end

        653 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[294] = heapMem[localMem[250]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 654;
        end

        654 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[295] = heapMem[localMem[294]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 655;
        end

        655 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[296] = heapMem[localMem[250]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 656;
        end

        656 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[296]] = 1;
              ip = 657;
        end

        657 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[297] = heapMem[localMem[250]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 658;
        end

        658 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[297]] = 1;
              ip = 659;
        end

        659 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[298] = heapMem[localMem[254]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 660;
        end

        660 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[298] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[291], localMem[298], arraySizes[localMem[298]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[291] && i <= arraySizes[localMem[298]]) begin
                  heapMem[NArea * localMem[298] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[298] + localMem[291]] = localMem[293];                                    // Insert new value
              arraySizes[localMem[298]] = arraySizes[localMem[298]] + 1;                              // Increase array size
              ip = 661;
        end

        661 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[299] = heapMem[localMem[254]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 662;
        end

        662 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[299] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[291], localMem[299], arraySizes[localMem[299]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[291] && i <= arraySizes[localMem[299]]) begin
                  heapMem[NArea * localMem[299] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[299] + localMem[291]] = localMem[295];                                    // Insert new value
              arraySizes[localMem[299]] = arraySizes[localMem[299]] + 1;                              // Increase array size
              ip = 663;
        end

        663 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[300] = heapMem[localMem[254]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 664;
        end

        664 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[301] = localMem[291] + 1;
              updateArrayLength(2, 0, 0);
              ip = 665;
        end

        665 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[300] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[301], localMem[300], arraySizes[localMem[300]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[301] && i <= arraySizes[localMem[300]]) begin
                  heapMem[NArea * localMem[300] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[300] + localMem[301]] = localMem[255];                                    // Insert new value
              arraySizes[localMem[300]] = arraySizes[localMem[300]] + 1;                              // Increase array size
              ip = 666;
        end

        666 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[254]*8 + 0] = heapMem[localMem[254]*8 + 0] + 1;
              updateArrayLength(1, localMem[254], 0);
              ip = 667;
        end

        667 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 784;
        end

        668 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   668");
        end

        669 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   669");
        end

        670 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   670");
        end

        671 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   671");
        end

        672 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   672");
        end

        673 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   673");
        end

        674 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   674");
        end

        675 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   675");
        end

        676 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   676");
        end

        677 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   677");
        end

        678 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   678");
        end

        679 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   679");
        end

        680 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   680");
        end

        681 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   681");
        end

        682 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   682");
        end

        683 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   683");
        end

        684 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   684");
        end

        685 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   685");
        end

        686 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   686");
        end

        687 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   687");
        end

        688 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   688");
        end

        689 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   689");
        end

        690 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   690");
        end

        691 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   691");
        end

        692 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   692");
        end

        693 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   693");
        end

        694 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   694");
        end

        695 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   695");
        end

        696 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   696");
        end

        697 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   697");
        end

        698 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   698");
        end

        699 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   699");
        end

        700 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   700");
        end

        701 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   701");
        end

        702 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   702");
        end

        703 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   703");
        end

        704 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   704");
        end

        705 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   705");
        end

        706 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   706");
        end

        707 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   707");
        end

        708 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   708");
        end

        709 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   709");
        end

        710 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   710");
        end

        711 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   711");
        end

        712 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   712");
        end

        713 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   713");
        end

        714 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   714");
        end

        715 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   715");
        end

        716 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   716");
        end

        717 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   717");
        end

        718 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   718");
        end

        719 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   719");
        end

        720 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   720");
        end

        721 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   721");
        end

        722 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   722");
        end

        723 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   723");
        end

        724 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   724");
        end

        725 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   725");
        end

        726 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   726");
        end

        727 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   727");
        end

        728 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   728");
        end

        729 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   729");
        end

        730 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   730");
        end

        731 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   731");
        end

        732 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   732");
        end

        733 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   733");
        end

        734 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   734");
        end

        735 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   735");
        end

        736 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   736");
        end

        737 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   737");
        end

        738 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   738");
        end

        739 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   739");
        end

        740 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   740");
        end

        741 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   741");
        end

        742 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   742");
        end

        743 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   743");
        end

        744 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   744");
        end

        745 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   745");
        end

        746 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   746");
        end

        747 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   747");
        end

        748 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   748");
        end

        749 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   749");
        end

        750 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   750");
        end

        751 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   751");
        end

        752 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   752");
        end

        753 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   753");
        end

        754 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   754");
        end

        755 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   755");
        end

        756 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   756");
        end

        757 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   757");
        end

        758 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   758");
        end

        759 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   759");
        end

        760 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   760");
        end

        761 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   761");
        end

        762 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   762");
        end

        763 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   763");
        end

        764 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   764");
        end

        765 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   765");
        end

        766 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   766");
        end

        767 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   767");
        end

        768 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   768");
        end

        769 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   769");
        end

        770 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   770");
        end

        771 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   771");
        end

        772 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   772");
        end

        773 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   773");
        end

        774 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   774");
        end

        775 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   775");
        end

        776 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   776");
        end

        777 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   777");
        end

        778 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   778");
        end

        779 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   779");
        end

        780 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   780");
        end

        781 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   781");
        end

        782 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   782");
        end

        783 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   783");
        end

        784 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 785;
        end

        785 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[251] = 1;
              updateArrayLength(2, 0, 0);
              ip = 786;
        end

        786 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 789;
        end

        787 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 788;
        end

        788 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[251] = 0;
              updateArrayLength(2, 0, 0);
              ip = 789;
        end

        789 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 790;
        end

        790 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[251] != 0 ? 792 : 791;
        end

        791 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = localMem[250];
              updateArrayLength(2, 0, 0);
              ip = 792;
        end

        792 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 793;
        end

        793 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 794;
        end

        794 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[133] = localMem[133] + 1;
              updateArrayLength(2, 0, 0);
              ip = 795;
        end

        795 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 305;
        end

        796 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   796");
        end

        797 :
        begin                                                                   // assert
if (0) begin
  $display("AAAA %4d %4d assert", steps, ip);
end
           $display("Should not be executed   797");
        end

        798 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   798");
        end

        799 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   799");
        end

        800 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 801;
        end

        801 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[355] = heapMem[localMem[1]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 802;
        end

        802 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[356] = heapMem[localMem[1]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 803;
        end

        803 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[357] = heapMem[localMem[1]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 804;
        end

        804 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[356] != 1 ? 808 : 805;
        end

        805 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   805");
        end

        806 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   806");
        end

        807 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   807");
        end

        808 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 809;
        end

        809 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[356] != 2 ? 817 : 810;
        end

        810 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[359] = localMem[357] + 1;
              updateArrayLength(2, 0, 0);
              ip = 811;
        end

        811 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[360] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 812;
        end

        812 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[360] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[359], localMem[360], arraySizes[localMem[360]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[359] && i <= arraySizes[localMem[360]]) begin
                  heapMem[NArea * localMem[360] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[360] + localMem[359]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[360]] = arraySizes[localMem[360]] + 1;                              // Increase array size
              ip = 813;
        end

        813 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[361] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 814;
        end

        814 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[361] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[359], localMem[361], arraySizes[localMem[361]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[359] && i <= arraySizes[localMem[361]]) begin
                  heapMem[NArea * localMem[361] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[361] + localMem[359]] = localMem[5];                                    // Insert new value
              arraySizes[localMem[361]] = arraySizes[localMem[361]] + 1;                              // Increase array size
              ip = 815;
        end

        815 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[355]*8 + 0] = heapMem[localMem[355]*8 + 0] + 1;
              updateArrayLength(1, localMem[355], 0);
              ip = 816;
        end

        816 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 823;
        end

        817 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 818;
        end

        818 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[362] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 819;
        end

        819 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[362] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[357], localMem[362], arraySizes[localMem[362]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[357] && i <= arraySizes[localMem[362]]) begin
                  heapMem[NArea * localMem[362] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[362] + localMem[357]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[362]] = arraySizes[localMem[362]] + 1;                              // Increase array size
              ip = 820;
        end

        820 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[363] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 821;
        end

        821 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[363] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[357], localMem[363], arraySizes[localMem[363]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[357] && i <= arraySizes[localMem[363]]) begin
                  heapMem[NArea * localMem[363] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[363] + localMem[357]] = localMem[5];                                    // Insert new value
              arraySizes[localMem[363]] = arraySizes[localMem[363]] + 1;                              // Increase array size
              ip = 822;
        end

        822 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[355]*8 + 0] = heapMem[localMem[355]*8 + 0] + 1;
              updateArrayLength(1, localMem[355], 0);
              ip = 823;
        end

        823 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 824;
        end

        824 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 825;
        end

        825 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 826;
        end

        826 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[365] = heapMem[localMem[355]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 827;
        end

        827 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[365] <  3 ? 1045 : 828;
        end

        828 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[366] = heapMem[localMem[355]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 829;
        end

        829 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[367] = heapMem[localMem[355]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 830;
        end

        830 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[367] == 0 ? 927 : 831;
        end

        831 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[368] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[368] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[368]] = 0;
              ip = 832;
        end

        832 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 0] = 1;
              updateArrayLength(1, localMem[368], 0);
              ip = 833;
        end

        833 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 2] = 0;
              updateArrayLength(1, localMem[368], 2);
              ip = 834;
        end

        834 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[369] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[369] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[369]] = 0;
              ip = 835;
        end

        835 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 4] = localMem[369];
              updateArrayLength(1, localMem[368], 4);
              ip = 836;
        end

        836 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[370] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[370] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[370]] = 0;
              ip = 837;
        end

        837 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 5] = localMem[370];
              updateArrayLength(1, localMem[368], 5);
              ip = 838;
        end

        838 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 6] = 0;
              updateArrayLength(1, localMem[368], 6);
              ip = 839;
        end

        839 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 3] = localMem[366];
              updateArrayLength(1, localMem[368], 3);
              ip = 840;
        end

        840 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[366]*8 + 1] = heapMem[localMem[366]*8 + 1] + 1;
              updateArrayLength(1, localMem[366], 1);
              ip = 841;
        end

        841 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 1] = heapMem[localMem[366]*8 + 1];
              updateArrayLength(1, localMem[368], 1);
              ip = 842;
        end

        842 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[371] = !heapMem[localMem[355]*8 + 6];
              ip = 843;
        end

        843 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[371] != 0 ? 872 : 844;
        end

        844 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   844");
        end

        845 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   845");
        end

        846 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   846");
        end

        847 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   847");
        end

        848 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   848");
        end

        849 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   849");
        end

        850 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   850");
        end

        851 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   851");
        end

        852 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   852");
        end

        853 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   853");
        end

        854 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   854");
        end

        855 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   855");
        end

        856 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   856");
        end

        857 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   857");
        end

        858 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   858");
        end

        859 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   859");
        end

        860 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   860");
        end

        861 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   861");
        end

        862 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   862");
        end

        863 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   863");
        end

        864 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   864");
        end

        865 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   865");
        end

        866 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   866");
        end

        867 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   867");
        end

        868 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   868");
        end

        869 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   869");
        end

        870 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   870");
        end

        871 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   871");
        end

        872 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 873;
        end

        873 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[386] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 874;
        end

        874 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[387] = heapMem[localMem[368]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 875;
        end

        875 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[387] + 0 + i] = heapMem[NArea * localMem[386] + 2 + i];
                  updateArrayLength(1, localMem[387], 0 + i);
                end
              end
              ip = 876;
        end

        876 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[388] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 877;
        end

        877 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[389] = heapMem[localMem[368]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 878;
        end

        878 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 1) begin
                  heapMem[NArea * localMem[389] + 0 + i] = heapMem[NArea * localMem[388] + 2 + i];
                  updateArrayLength(1, localMem[389], 0 + i);
                end
              end
              ip = 879;
        end

        879 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 880;
        end

        880 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[355]*8 + 0] = 1;
              updateArrayLength(1, localMem[355], 0);
              ip = 881;
        end

        881 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[368]*8 + 2] = localMem[367];
              updateArrayLength(1, localMem[368], 2);
              ip = 882;
        end

        882 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[390] = heapMem[localMem[367]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 883;
        end

        883 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[391] = heapMem[localMem[367]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 884;
        end

        884 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[392] = heapMem[localMem[391]*8 + localMem[390]];
              updateArrayLength(2, 0, 0);
              ip = 885;
        end

        885 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[392] != localMem[355] ? 904 : 886;
        end

        886 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[393] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 887;
        end

        887 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[394] = heapMem[localMem[393]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 888;
        end

        888 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[395] = heapMem[localMem[367]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 889;
        end

        889 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[395]*8 + localMem[390]] = localMem[394];
              updateArrayLength(1, localMem[395], localMem[390]);
              ip = 890;
        end

        890 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[396] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 891;
        end

        891 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[397] = heapMem[localMem[396]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 892;
        end

        892 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[398] = heapMem[localMem[367]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 893;
        end

        893 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[398]*8 + localMem[390]] = localMem[397];
              updateArrayLength(1, localMem[398], localMem[390]);
              ip = 894;
        end

        894 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[399] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 895;
        end

        895 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[399]] = 1;
              ip = 896;
        end

        896 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[400] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 897;
        end

        897 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[400]] = 1;
              ip = 898;
        end

        898 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[401] = localMem[390] + 1;
              updateArrayLength(2, 0, 0);
              ip = 899;
        end

        899 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[367]*8 + 0] = localMem[401];
              updateArrayLength(1, localMem[367], 0);
              ip = 900;
        end

        900 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[402] = heapMem[localMem[367]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 901;
        end

        901 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[402]*8 + localMem[401]] = localMem[368];
              updateArrayLength(1, localMem[402], localMem[401]);
              ip = 902;
        end

        902 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1042;
        end

        903 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   903");
        end

        904 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 905;
        end

        905 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 906;
        end

        906 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[403] = heapMem[localMem[367]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 907;
        end

        907 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[404] = 0; k = arraySizes[localMem[403]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[403] * NArea + i] == localMem[355]) localMem[404] = i + 1;
              end
              ip = 908;
        end

        908 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[404] = localMem[404] - 1;
              updateArrayLength(2, 0, 0);
              ip = 909;
        end

        909 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[405] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 910;
        end

        910 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[406] = heapMem[localMem[405]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 911;
        end

        911 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[407] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 912;
        end

        912 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[408] = heapMem[localMem[407]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 913;
        end

        913 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[409] = heapMem[localMem[355]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 914;
        end

        914 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[409]] = 1;
              ip = 915;
        end

        915 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[410] = heapMem[localMem[355]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 916;
        end

        916 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[410]] = 1;
              ip = 917;
        end

        917 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[411] = heapMem[localMem[367]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 918;
        end

        918 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[411] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[404], localMem[411], arraySizes[localMem[411]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[404] && i <= arraySizes[localMem[411]]) begin
                  heapMem[NArea * localMem[411] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[411] + localMem[404]] = localMem[406];                                    // Insert new value
              arraySizes[localMem[411]] = arraySizes[localMem[411]] + 1;                              // Increase array size
              ip = 919;
        end

        919 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[412] = heapMem[localMem[367]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 920;
        end

        920 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[412] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[404], localMem[412], arraySizes[localMem[412]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[404] && i <= arraySizes[localMem[412]]) begin
                  heapMem[NArea * localMem[412] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[412] + localMem[404]] = localMem[408];                                    // Insert new value
              arraySizes[localMem[412]] = arraySizes[localMem[412]] + 1;                              // Increase array size
              ip = 921;
        end

        921 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[413] = heapMem[localMem[367]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 922;
        end

        922 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[414] = localMem[404] + 1;
              updateArrayLength(2, 0, 0);
              ip = 923;
        end

        923 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[413] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[414], localMem[413], arraySizes[localMem[413]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[414] && i <= arraySizes[localMem[413]]) begin
                  heapMem[NArea * localMem[413] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[413] + localMem[414]] = localMem[368];                                    // Insert new value
              arraySizes[localMem[413]] = arraySizes[localMem[413]] + 1;                              // Increase array size
              ip = 924;
        end

        924 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[367]*8 + 0] = heapMem[localMem[367]*8 + 0] + 1;
              updateArrayLength(1, localMem[367], 0);
              ip = 925;
        end

        925 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1042;
        end

        926 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   926");
        end

        927 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   927");
        end

        928 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   928");
        end

        929 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   929");
        end

        930 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   930");
        end

        931 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   931");
        end

        932 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   932");
        end

        933 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   933");
        end

        934 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   934");
        end

        935 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   935");
        end

        936 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   936");
        end

        937 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   937");
        end

        938 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   938");
        end

        939 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   939");
        end

        940 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   940");
        end

        941 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   941");
        end

        942 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   942");
        end

        943 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   943");
        end

        944 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   944");
        end

        945 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   945");
        end

        946 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   946");
        end

        947 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   947");
        end

        948 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   948");
        end

        949 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   949");
        end

        950 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   950");
        end

        951 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   951");
        end

        952 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   952");
        end

        953 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   953");
        end

        954 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   954");
        end

        955 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   955");
        end

        956 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   956");
        end

        957 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   957");
        end

        958 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   958");
        end

        959 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   959");
        end

        960 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   960");
        end

        961 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   961");
        end

        962 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   962");
        end

        963 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   963");
        end

        964 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   964");
        end

        965 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   965");
        end

        966 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   966");
        end

        967 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   967");
        end

        968 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   968");
        end

        969 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   969");
        end

        970 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   970");
        end

        971 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   971");
        end

        972 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   972");
        end

        973 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   973");
        end

        974 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   974");
        end

        975 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   975");
        end

        976 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   976");
        end

        977 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   977");
        end

        978 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   978");
        end

        979 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   979");
        end

        980 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   980");
        end

        981 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   981");
        end

        982 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   982");
        end

        983 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   983");
        end

        984 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   984");
        end

        985 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   985");
        end

        986 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   986");
        end

        987 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   987");
        end

        988 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   988");
        end

        989 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   989");
        end

        990 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   990");
        end

        991 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   991");
        end

        992 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   992");
        end

        993 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   993");
        end

        994 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   994");
        end

        995 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   995");
        end

        996 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   996");
        end

        997 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   997");
        end

        998 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   998");
        end

        999 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   999");
        end

       1000 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1000");
        end

       1001 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1001");
        end

       1002 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1002");
        end

       1003 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1003");
        end

       1004 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed  1004");
        end

       1005 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1005");
        end

       1006 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1006");
        end

       1007 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1007");
        end

       1008 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed  1008");
        end

       1009 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1009");
        end

       1010 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1010");
        end

       1011 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed  1011");
        end

       1012 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1012");
        end

       1013 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1013");
        end

       1014 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed  1014");
        end

       1015 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1015");
        end

       1016 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1016");
        end

       1017 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed  1017");
        end

       1018 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1018");
        end

       1019 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1019");
        end

       1020 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1020");
        end

       1021 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1021");
        end

       1022 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1022");
        end

       1023 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1023");
        end

       1024 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1024");
        end

       1025 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1025");
        end

       1026 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1026");
        end

       1027 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1027");
        end

       1028 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1028");
        end

       1029 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1029");
        end

       1030 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1030");
        end

       1031 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1031");
        end

       1032 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1032");
        end

       1033 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1033");
        end

       1034 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1034");
        end

       1035 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1035");
        end

       1036 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1036");
        end

       1037 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1037");
        end

       1038 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1038");
        end

       1039 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1039");
        end

       1040 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1040");
        end

       1041 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1041");
        end

       1042 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1043;
        end

       1043 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[364] = 1;
              updateArrayLength(2, 0, 0);
              ip = 1044;
        end

       1044 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1047;
        end

       1045 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1046;
        end

       1046 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[364] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1047;
        end

       1047 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1048;
        end

       1048 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1049;
        end

       1049 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1050;
        end

       1050 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1051;
        end

       1051 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 1052;
        end

       1052 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1053;
        end

       1053 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 6;
        end

       1054 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1055;
        end

       1055 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[468] = 1;
              updateArrayLength(2, 0, 0);
              ip = 1056;
        end

       1056 :
        begin                                                                   // shiftLeft
if (0) begin
  $display("AAAA %4d %4d shiftLeft", steps, ip);
end
              localMem[468] = localMem[468] << 31;
              ip = 1057;
        end

       1057 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[469] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 1058;
        end

       1058 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[470] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[470] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[470]] = 0;
              ip = 1059;
        end

       1059 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[471] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[471] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[471]] = 0;
              ip = 1060;
        end

       1060 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[469] != 0 ? 1065 : 1061;
        end

       1061 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1061");
        end

       1062 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1062");
        end

       1063 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1063");
        end

       1064 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1064");
        end

       1065 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1066;
        end

       1066 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1067;
        end

       1067 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[472] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1068;
        end

       1068 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1069;
        end

       1069 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[472] >= 99 ? 1078 : 1070;
        end

       1070 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[473] = !heapMem[localMem[469]*8 + 6];
              ip = 1071;
        end

       1071 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[473] != 0 ? 1078 : 1072;
        end

       1072 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[474] = heapMem[localMem[469]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1073;
        end

       1073 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[475] = heapMem[localMem[474]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1074;
        end

       1074 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[469] = localMem[475];
              updateArrayLength(2, 0, 0);
              ip = 1075;
        end

       1075 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1076;
        end

       1076 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[472] = localMem[472] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1077;
        end

       1077 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1068;
        end

       1078 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1079;
        end

       1079 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 0] = localMem[469];
              updateArrayLength(1, localMem[470], 0);
              ip = 1080;
        end

       1080 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 1] = 1;
              updateArrayLength(1, localMem[470], 1);
              ip = 1081;
        end

       1081 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 2] = 0;
              updateArrayLength(1, localMem[470], 2);
              ip = 1082;
        end

       1082 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1083;
        end

       1083 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1084;
        end

       1084 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[476] = heapMem[localMem[470]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 1085;
        end

       1085 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[476] == 3 ? 1230 : 1086;
        end

       1086 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 3) begin
                  heapMem[NArea * localMem[471] + 0 + i] = heapMem[NArea * localMem[470] + 0 + i];
                  updateArrayLength(1, localMem[471], 0 + i);
                end
              end
              ip = 1087;
        end

       1087 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[477] = heapMem[localMem[471]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1088;
        end

       1088 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[478] = heapMem[localMem[471]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1089;
        end

       1089 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[479] = heapMem[localMem[477]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 1090;
        end

       1090 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[480] = heapMem[localMem[479]*8 + localMem[478]];
              updateArrayLength(2, 0, 0);
              ip = 1091;
        end

       1091 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[480];
              outMemPos = outMemPos + 1;
              ip = 1092;
        end

       1092 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 1093;
        end

       1093 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1094;
        end

       1094 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[481] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 1095;
        end

       1095 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[481] != 0 ? 1100 : 1096;
        end

       1096 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1096");
        end

       1097 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1097");
        end

       1098 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1098");
        end

       1099 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1099");
        end

       1100 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1101;
        end

       1101 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1102;
        end

       1102 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[482] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1103;
        end

       1103 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1104;
        end

       1104 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[482] >= 99 ? 1142 : 1105;
        end

       1105 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[483] = heapMem[localMem[481]*8 + 0] - 1;
              updateArrayLength(2, 0, 0);
              ip = 1106;
        end

       1106 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[484] = heapMem[localMem[481]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 1107;
        end

       1107 :
        begin                                                                   // jLe
if (0) begin
  $display("AAAA %4d %4d jLe", steps, ip);
end
              ip = localMem[480] <= heapMem[localMem[484]*8 + localMem[483]] ? 1120 : 1108;
        end

       1108 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[485] = localMem[483] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1109;
        end

       1109 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[486] = !heapMem[localMem[481]*8 + 6];
              ip = 1110;
        end

       1110 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[486] == 0 ? 1115 : 1111;
        end

       1111 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1111");
        end

       1112 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1112");
        end

       1113 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1113");
        end

       1114 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1114");
        end

       1115 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1116;
        end

       1116 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[487] = heapMem[localMem[481]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1117;
        end

       1117 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[488] = heapMem[localMem[487]*8 + localMem[485]];
              updateArrayLength(2, 0, 0);
              ip = 1118;
        end

       1118 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[481] = localMem[488];
              updateArrayLength(2, 0, 0);
              ip = 1119;
        end

       1119 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1139;
        end

       1120 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1121;
        end

       1121 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[489] = 0; k = arraySizes[localMem[484]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[484] * NArea + i] == localMem[480]) localMem[489] = i + 1;
              end
              ip = 1122;
        end

       1122 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[489] == 0 ? 1127 : 1123;
        end

       1123 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = localMem[481];
              updateArrayLength(1, localMem[1], 0);
              ip = 1124;
        end

       1124 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 1] = 1;
              updateArrayLength(1, localMem[1], 1);
              ip = 1125;
        end

       1125 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              heapMem[localMem[1]*8 + 2] = localMem[489] - 1;
              updateArrayLength(1, localMem[1], 2);
              ip = 1126;
        end

       1126 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1146;
        end

       1127 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1128;
        end

       1128 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[484]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[484] * NArea + i] < localMem[480]) j = j + 1;
              end
              localMem[490] = j;
              ip = 1129;
        end

       1129 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[491] = !heapMem[localMem[481]*8 + 6];
              ip = 1130;
        end

       1130 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[491] == 0 ? 1135 : 1131;
        end

       1131 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1131");
        end

       1132 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1132");
        end

       1133 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1133");
        end

       1134 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1134");
        end

       1135 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1136;
        end

       1136 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[492] = heapMem[localMem[481]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1137;
        end

       1137 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[493] = heapMem[localMem[492]*8 + localMem[490]];
              updateArrayLength(2, 0, 0);
              ip = 1138;
        end

       1138 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[481] = localMem[493];
              updateArrayLength(2, 0, 0);
              ip = 1139;
        end

       1139 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1140;
        end

       1140 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[482] = localMem[482] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1141;
        end

       1141 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1103;
        end

       1142 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1142");
        end

       1143 :
        begin                                                                   // assert
if (0) begin
  $display("AAAA %4d %4d assert", steps, ip);
end
           $display("Should not be executed  1143");
        end

       1144 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1144");
        end

       1145 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1145");
        end

       1146 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1147;
        end

       1147 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 1148;
        end

       1148 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[494] = heapMem[localMem[1]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1149;
        end

       1149 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[495] = heapMem[localMem[1]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1150;
        end

       1150 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[496] = heapMem[localMem[494]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 1151;
        end

       1151 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[497] = heapMem[localMem[496]*8 + localMem[495]];
              updateArrayLength(2, 0, 0);
              ip = 1152;
        end

       1152 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[498] = localMem[480] + localMem[480];
              updateArrayLength(2, 0, 0);
              ip = 1153;
        end

       1153 :
        begin                                                                   // assertEq
if (0) begin
  $display("AAAA %4d %4d assertEq", steps, ip);
end
            ip = 1154;
        end

       1154 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1155;
        end

       1155 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[499] = heapMem[localMem[470]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1156;
        end

       1156 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[500] = !heapMem[localMem[499]*8 + 6];
              ip = 1157;
        end

       1157 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[500] == 0 ? 1197 : 1158;
        end

       1158 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[501] = heapMem[localMem[470]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1159;
        end

       1159 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[502] = heapMem[localMem[499]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1160;
        end

       1160 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[501] >= localMem[502] ? 1165 : 1161;
        end

       1161 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 0] = localMem[499];
              updateArrayLength(1, localMem[470], 0);
              ip = 1162;
        end

       1162 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 1] = 1;
              updateArrayLength(1, localMem[470], 1);
              ip = 1163;
        end

       1163 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 2] = localMem[501];
              updateArrayLength(1, localMem[470], 2);
              ip = 1164;
        end

       1164 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1226;
        end

       1165 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1166;
        end

       1166 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[503] = heapMem[localMem[499]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1167;
        end

       1167 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[503] == 0 ? 1192 : 1168;
        end

       1168 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1169;
        end

       1169 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[504] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1170;
        end

       1170 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1171;
        end

       1171 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[504] >= 99 ? 1191 : 1172;
        end

       1172 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[505] = heapMem[localMem[503]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1173;
        end

       1173 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 1174;
        end

       1174 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[506] = heapMem[localMem[503]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1175;
        end

       1175 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[507] = 0; k = arraySizes[localMem[506]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[506] * NArea + i] == localMem[499]) localMem[507] = i + 1;
              end
              ip = 1176;
        end

       1176 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[507] = localMem[507] - 1;
              updateArrayLength(2, 0, 0);
              ip = 1177;
        end

       1177 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[507] != localMem[505] ? 1182 : 1178;
        end

       1178 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[499] = localMem[503];
              updateArrayLength(2, 0, 0);
              ip = 1179;
        end

       1179 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[503] = heapMem[localMem[499]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1180;
        end

       1180 :
        begin                                                                   // jFalse
if (0) begin
  $display("AAAA %4d %4d jFalse", steps, ip);
end
              ip = localMem[503] == 0 ? 1191 : 1181;
        end

       1181 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1187;
        end

       1182 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1183;
        end

       1183 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 0] = localMem[503];
              updateArrayLength(1, localMem[470], 0);
              ip = 1184;
        end

       1184 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 1] = 1;
              updateArrayLength(1, localMem[470], 1);
              ip = 1185;
        end

       1185 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 2] = localMem[507];
              updateArrayLength(1, localMem[470], 2);
              ip = 1186;
        end

       1186 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1226;
        end

       1187 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1188;
        end

       1188 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1189;
        end

       1189 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[504] = localMem[504] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1190;
        end

       1190 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1170;
        end

       1191 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1192;
        end

       1192 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1193;
        end

       1193 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 0] = localMem[499];
              updateArrayLength(1, localMem[470], 0);
              ip = 1194;
        end

       1194 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 1] = 3;
              updateArrayLength(1, localMem[470], 1);
              ip = 1195;
        end

       1195 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 2] = 0;
              updateArrayLength(1, localMem[470], 2);
              ip = 1196;
        end

       1196 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1226;
        end

       1197 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1198;
        end

       1198 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[508] = heapMem[localMem[470]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1199;
        end

       1199 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[509] = heapMem[localMem[499]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1200;
        end

       1200 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[510] = heapMem[localMem[509]*8 + localMem[508]];
              updateArrayLength(2, 0, 0);
              ip = 1201;
        end

       1201 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[510] != 0 ? 1206 : 1202;
        end

       1202 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1202");
        end

       1203 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1203");
        end

       1204 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1204");
        end

       1205 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1205");
        end

       1206 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1207;
        end

       1207 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1208;
        end

       1208 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[511] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1209;
        end

       1209 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1210;
        end

       1210 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[511] >= 99 ? 1219 : 1211;
        end

       1211 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[512] = !heapMem[localMem[510]*8 + 6];
              ip = 1212;
        end

       1212 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[512] != 0 ? 1219 : 1213;
        end

       1213 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[513] = heapMem[localMem[510]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1214;
        end

       1214 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[514] = heapMem[localMem[513]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1215;
        end

       1215 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[510] = localMem[514];
              updateArrayLength(2, 0, 0);
              ip = 1216;
        end

       1216 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1217;
        end

       1217 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[511] = localMem[511] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1218;
        end

       1218 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1209;
        end

       1219 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1220;
        end

       1220 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 0] = localMem[510];
              updateArrayLength(1, localMem[470], 0);
              ip = 1221;
        end

       1221 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 1] = 1;
              updateArrayLength(1, localMem[470], 1);
              ip = 1222;
        end

       1222 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[470]*8 + 2] = 0;
              updateArrayLength(1, localMem[470], 2);
              ip = 1223;
        end

       1223 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1224;
        end

       1224 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1225;
        end

       1225 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1226;
        end

       1226 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1227;
        end

       1227 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1083;
        end

       1228 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1228");
        end

       1229 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1229");
        end

       1230 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1231;
        end

       1231 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[470]] = 0;
              freedArrays[freedArraysTop] = localMem[470];
              freedArraysTop = freedArraysTop + 1;
              ip = 1232;
        end

       1232 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[471]] = 0;
              freedArrays[freedArraysTop] = localMem[471];
              freedArraysTop = freedArraysTop + 1;
              ip = 1233;
        end

       1233 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 1234;
        end

       1234 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[515] = 1;
              updateArrayLength(2, 0, 0);
              ip = 1235;
        end

       1235 :
        begin                                                                   // shiftLeft
if (0) begin
  $display("AAAA %4d %4d shiftLeft", steps, ip);
end
              localMem[515] = localMem[515] << 31;
              ip = 1236;
        end

       1236 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[516] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 1237;
        end

       1237 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[517] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[517] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[517]] = 0;
              ip = 1238;
        end

       1238 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[518] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[518] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[518]] = 0;
              ip = 1239;
        end

       1239 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[516] != 0 ? 1244 : 1240;
        end

       1240 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1240");
        end

       1241 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1241");
        end

       1242 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1242");
        end

       1243 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1243");
        end

       1244 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1245;
        end

       1245 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1246;
        end

       1246 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[519] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1247;
        end

       1247 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1248;
        end

       1248 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[519] >= 99 ? 1257 : 1249;
        end

       1249 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[520] = !heapMem[localMem[516]*8 + 6];
              ip = 1250;
        end

       1250 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[520] != 0 ? 1257 : 1251;
        end

       1251 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[521] = heapMem[localMem[516]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1252;
        end

       1252 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[522] = heapMem[localMem[521]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1253;
        end

       1253 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[516] = localMem[522];
              updateArrayLength(2, 0, 0);
              ip = 1254;
        end

       1254 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1255;
        end

       1255 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[519] = localMem[519] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1256;
        end

       1256 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1247;
        end

       1257 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1258;
        end

       1258 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 0] = localMem[516];
              updateArrayLength(1, localMem[517], 0);
              ip = 1259;
        end

       1259 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 1] = 1;
              updateArrayLength(1, localMem[517], 1);
              ip = 1260;
        end

       1260 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 2] = 0;
              updateArrayLength(1, localMem[517], 2);
              ip = 1261;
        end

       1261 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1262;
        end

       1262 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1263;
        end

       1263 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[523] = heapMem[localMem[517]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 1264;
        end

       1264 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[523] == 3 ? 1342 : 1265;
        end

       1265 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 3) begin
                  heapMem[NArea * localMem[518] + 0 + i] = heapMem[NArea * localMem[517] + 0 + i];
                  updateArrayLength(1, localMem[518], 0 + i);
                end
              end
              ip = 1266;
        end

       1266 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1267;
        end

       1267 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[524] = heapMem[localMem[517]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1268;
        end

       1268 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[525] = !heapMem[localMem[524]*8 + 6];
              ip = 1269;
        end

       1269 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[525] == 0 ? 1309 : 1270;
        end

       1270 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[526] = heapMem[localMem[517]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1271;
        end

       1271 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[527] = heapMem[localMem[524]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1272;
        end

       1272 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[526] >= localMem[527] ? 1277 : 1273;
        end

       1273 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 0] = localMem[524];
              updateArrayLength(1, localMem[517], 0);
              ip = 1274;
        end

       1274 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 1] = 1;
              updateArrayLength(1, localMem[517], 1);
              ip = 1275;
        end

       1275 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 2] = localMem[526];
              updateArrayLength(1, localMem[517], 2);
              ip = 1276;
        end

       1276 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1338;
        end

       1277 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1278;
        end

       1278 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[528] = heapMem[localMem[524]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1279;
        end

       1279 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[528] == 0 ? 1304 : 1280;
        end

       1280 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1281;
        end

       1281 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[529] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1282;
        end

       1282 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1283;
        end

       1283 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[529] >= 99 ? 1303 : 1284;
        end

       1284 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[530] = heapMem[localMem[528]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1285;
        end

       1285 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 1286;
        end

       1286 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[531] = heapMem[localMem[528]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1287;
        end

       1287 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[532] = 0; k = arraySizes[localMem[531]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[531] * NArea + i] == localMem[524]) localMem[532] = i + 1;
              end
              ip = 1288;
        end

       1288 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[532] = localMem[532] - 1;
              updateArrayLength(2, 0, 0);
              ip = 1289;
        end

       1289 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[532] != localMem[530] ? 1294 : 1290;
        end

       1290 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[524] = localMem[528];
              updateArrayLength(2, 0, 0);
              ip = 1291;
        end

       1291 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[528] = heapMem[localMem[524]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1292;
        end

       1292 :
        begin                                                                   // jFalse
if (0) begin
  $display("AAAA %4d %4d jFalse", steps, ip);
end
              ip = localMem[528] == 0 ? 1303 : 1293;
        end

       1293 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1299;
        end

       1294 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1295;
        end

       1295 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 0] = localMem[528];
              updateArrayLength(1, localMem[517], 0);
              ip = 1296;
        end

       1296 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 1] = 1;
              updateArrayLength(1, localMem[517], 1);
              ip = 1297;
        end

       1297 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 2] = localMem[532];
              updateArrayLength(1, localMem[517], 2);
              ip = 1298;
        end

       1298 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1338;
        end

       1299 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1300;
        end

       1300 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1301;
        end

       1301 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[529] = localMem[529] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1302;
        end

       1302 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1282;
        end

       1303 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1304;
        end

       1304 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1305;
        end

       1305 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 0] = localMem[524];
              updateArrayLength(1, localMem[517], 0);
              ip = 1306;
        end

       1306 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 1] = 3;
              updateArrayLength(1, localMem[517], 1);
              ip = 1307;
        end

       1307 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 2] = 0;
              updateArrayLength(1, localMem[517], 2);
              ip = 1308;
        end

       1308 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1338;
        end

       1309 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1310;
        end

       1310 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[533] = heapMem[localMem[517]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1311;
        end

       1311 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[534] = heapMem[localMem[524]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1312;
        end

       1312 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[535] = heapMem[localMem[534]*8 + localMem[533]];
              updateArrayLength(2, 0, 0);
              ip = 1313;
        end

       1313 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[535] != 0 ? 1318 : 1314;
        end

       1314 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1314");
        end

       1315 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1315");
        end

       1316 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1316");
        end

       1317 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1317");
        end

       1318 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1319;
        end

       1319 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1320;
        end

       1320 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[536] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1321;
        end

       1321 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1322;
        end

       1322 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[536] >= 99 ? 1331 : 1323;
        end

       1323 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[537] = !heapMem[localMem[535]*8 + 6];
              ip = 1324;
        end

       1324 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[537] != 0 ? 1331 : 1325;
        end

       1325 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[538] = heapMem[localMem[535]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1326;
        end

       1326 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[539] = heapMem[localMem[538]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1327;
        end

       1327 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[535] = localMem[539];
              updateArrayLength(2, 0, 0);
              ip = 1328;
        end

       1328 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1329;
        end

       1329 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[536] = localMem[536] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1330;
        end

       1330 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1321;
        end

       1331 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1332;
        end

       1332 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 0] = localMem[535];
              updateArrayLength(1, localMem[517], 0);
              ip = 1333;
        end

       1333 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 1] = 1;
              updateArrayLength(1, localMem[517], 1);
              ip = 1334;
        end

       1334 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[517]*8 + 2] = 0;
              updateArrayLength(1, localMem[517], 2);
              ip = 1335;
        end

       1335 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1336;
        end

       1336 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1337;
        end

       1337 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1338;
        end

       1338 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1339;
        end

       1339 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1262;
        end

       1340 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1340");
        end

       1341 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1341");
        end

       1342 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1343;
        end

       1343 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[517]] = 0;
              freedArrays[freedArraysTop] = localMem[517];
              freedArraysTop = freedArraysTop + 1;
              ip = 1344;
        end

       1344 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[518]] = 0;
              freedArrays[freedArraysTop] = localMem[518];
              freedArraysTop = freedArraysTop + 1;
              ip = 1345;
        end

       1345 :
        begin                                                                   // tally
if (0) begin
  $display("AAAA %4d %4d tally", steps, ip);
end
            ip = 1346;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 1;
      success  = success && outMem[1] == 2;
      success  = success && outMem[2] == 3;
      success  = success && outMem[3] == 4;
      success  = success && outMem[4] == 5;
      success  = success && outMem[5] == 6;
      success  = success && outMem[6] == 7;
      success  = success && outMem[7] == 8;
      success  = success && outMem[8] == 9;
      success  = success && outMem[9] == 10;
      success  = success && outMem[10] == 11;
      success  = success && outMem[11] == 12;
      success  = success && outMem[12] == 13;
      success  = success && outMem[13] == 14;
      success  = success && outMem[14] == 15;
      success  = success && outMem[15] == 16;
      success  = success && outMem[16] == 17;
      success  = success && outMem[17] == 18;
      success  = success && outMem[18] == 19;
      success  = success && outMem[19] == 20;
      success  = success && outMem[20] == 21;
      success  = success && outMem[21] == 22;
      success  = success && outMem[22] == 23;
      success  = success && outMem[23] == 24;
      success  = success && outMem[24] == 25;
      success  = success && outMem[25] == 26;
      success  = success && outMem[26] == 27;
      success  = success && outMem[27] == 28;
      success  = success && outMem[28] == 29;
      success  = success && outMem[29] == 30;
      success  = success && outMem[30] == 31;
      success  = success && outMem[31] == 32;
      success  = success && outMem[32] == 33;
      success  = success && outMem[33] == 34;
      success  = success && outMem[34] == 35;
      success  = success && outMem[35] == 36;
      success  = success && outMem[36] == 37;
      success  = success && outMem[37] == 38;
      success  = success && outMem[38] == 39;
      success  = success && outMem[39] == 40;
      success  = success && outMem[40] == 41;
      success  = success && outMem[41] == 42;
      success  = success && outMem[42] == 43;
      success  = success && outMem[43] == 44;
      success  = success && outMem[44] == 45;
      success  = success && outMem[45] == 46;
      success  = success && outMem[46] == 47;
      success  = success && outMem[47] == 48;
      success  = success && outMem[48] == 49;
      success  = success && outMem[49] == 50;
      success  = success && outMem[50] == 51;
      success  = success && outMem[51] == 52;
      success  = success && outMem[52] == 53;
      success  = success && outMem[53] == 54;
      success  = success && outMem[54] == 55;
      success  = success && outMem[55] == 56;
      success  = success && outMem[56] == 57;
      success  = success && outMem[57] == 58;
      success  = success && outMem[58] == 59;
      success  = success && outMem[59] == 60;
      success  = success && outMem[60] == 61;
      success  = success && outMem[61] == 62;
      success  = success && outMem[62] == 63;
      success  = success && outMem[63] == 64;
      success  = success && outMem[64] == 65;
      success  = success && outMem[65] == 66;
      success  = success && outMem[66] == 67;
      success  = success && outMem[67] == 68;
      success  = success && outMem[68] == 69;
      success  = success && outMem[69] == 70;
      success  = success && outMem[70] == 71;
      success  = success && outMem[71] == 72;
      success  = success && outMem[72] == 73;
      success  = success && outMem[73] == 74;
      success  = success && outMem[74] == 75;
      success  = success && outMem[75] == 76;
      success  = success && outMem[76] == 77;
      success  = success && outMem[77] == 78;
      success  = success && outMem[78] == 79;
      success  = success && outMem[79] == 80;
      success  = success && outMem[80] == 81;
      success  = success && outMem[81] == 82;
      success  = success && outMem[82] == 83;
      success  = success && outMem[83] == 84;
      success  = success && outMem[84] == 85;
      success  = success && outMem[85] == 86;
      success  = success && outMem[86] == 87;
      success  = success && outMem[87] == 88;
      success  = success && outMem[88] == 89;
      success  = success && outMem[89] == 90;
      success  = success && outMem[90] == 91;
      success  = success && outMem[91] == 92;
      success  = success && outMem[92] == 93;
      success  = success && outMem[93] == 94;
      success  = success && outMem[94] == 95;
      success  = success && outMem[95] == 96;
      success  = success && outMem[96] == 97;
      success  = success && outMem[97] == 98;
      success  = success && outMem[98] == 99;
      success  = success && outMem[99] == 100;
      success  = success && outMem[100] == 101;
      success  = success && outMem[101] == 102;
      success  = success && outMem[102] == 103;
      success  = success && outMem[103] == 104;
      success  = success && outMem[104] == 105;
      success  = success && outMem[105] == 106;
      success  = success && outMem[106] == 107;
      finished = steps >  39369;
    end
  end

endmodule
