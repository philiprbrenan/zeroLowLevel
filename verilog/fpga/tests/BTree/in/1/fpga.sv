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
  parameter integer NArrays =       30;                                         // Maximum number of arrays
  parameter integer NHeap   =      240;                                         // Amount of heap memory
  parameter integer NLocal  =      508;                                         // Size of local memory
  parameter integer NOut    =       10;                                         // Size of output area
  parameter integer NIn     =       10;                                         // Size of input area
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

      inMem[0] = 1;
      inMem[1] = 8;
      inMem[2] = 5;
      inMem[3] = 6;
      inMem[4] = 3;
      inMem[5] = 4;
      inMem[6] = 7;
      inMem[7] = 2;
      inMem[8] = 9;
      inMem[9] = 0;
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 6;
        end

          6 :
        begin                                                                   // inSize
if (0) begin
  $display("AAAA %4d %4d inSize", steps, ip);
end
              localMem[1] = NIn - inMemPos;
              ip = 7;
        end

          7 :
        begin                                                                   // jFalse
if (0) begin
  $display("AAAA %4d %4d jFalse", steps, ip);
end
              ip = localMem[1] == 0 ? 1068 : 8;
        end

          8 :
        begin                                                                   // in
if (0) begin
  $display("AAAA %4d %4d in", steps, ip);
end
              if (inMemPos < NIn) begin
                localMem[2] = inMem[inMemPos];
                inMemPos = inMemPos + 1;
              end
              ip = 9;
        end

          9 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[3] = localMem[2] + localMem[2];
              updateArrayLength(2, 0, 0);
              ip = 10;
        end

         10 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[4] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[4] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[4]] = 0;
              ip = 11;
        end

         11 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 12;
        end

         12 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[5] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 13;
        end

         13 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[5] != 0 ? 36 : 14;
        end

         14 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[6] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[6] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[6]] = 0;
              ip = 15;
        end

         15 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 0] = 1;
              updateArrayLength(1, localMem[6], 0);
              ip = 16;
        end

         16 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 2] = 0;
              updateArrayLength(1, localMem[6], 2);
              ip = 17;
        end

         17 :
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
              ip = 18;
        end

         18 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 4] = localMem[7];
              updateArrayLength(1, localMem[6], 4);
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
              heapMem[localMem[6]*8 + 5] = localMem[8];
              updateArrayLength(1, localMem[6], 5);
              ip = 21;
        end

         21 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 6] = 0;
              updateArrayLength(1, localMem[6], 6);
              ip = 22;
        end

         22 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 3] = localMem[0];
              updateArrayLength(1, localMem[6], 3);
              ip = 23;
        end

         23 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = heapMem[localMem[0]*8 + 1] + 1;
              updateArrayLength(1, localMem[0], 1);
              ip = 24;
        end

         24 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 1] = heapMem[localMem[0]*8 + 1];
              updateArrayLength(1, localMem[6], 1);
              ip = 25;
        end

         25 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = heapMem[localMem[6]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 26;
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[9]*8 + 0] = localMem[2];
              updateArrayLength(1, localMem[9], 0);
              ip = 27;
        end

         27 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = heapMem[localMem[6]*8 + 5];
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 30;
        end

         30 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 3] = localMem[6];
              updateArrayLength(1, localMem[0], 3);
              ip = 31;
        end

         31 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = heapMem[localMem[6]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 32;
        end

         32 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[11]] = 1;
              ip = 33;
        end

         33 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = heapMem[localMem[6]*8 + 5];
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
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1064;
        end

         36 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 37;
        end

         37 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = heapMem[localMem[5]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 38;
        end

         38 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = heapMem[localMem[0]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 39;
        end

         39 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[13] >= localMem[14] ? 75 : 40;
        end

         40 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = heapMem[localMem[5]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 41;
        end

         41 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[15] != 0 ? 74 : 42;
        end

         42 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[16] = !heapMem[localMem[5]*8 + 6];
              ip = 43;
        end

         43 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[16] == 0 ? 73 : 44;
        end

         44 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 45;
        end

         45 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[18] = 0; k = arraySizes[localMem[17]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[17] * NArea + i] == localMem[2]) localMem[18] = i + 1;
              end
              ip = 46;
        end

         46 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[18] == 0 ? 51 : 47;
        end

         47 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed    47");
        end

         48 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    48");
        end

         49 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    49");
        end

         50 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed    50");
        end

         51 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 52;
        end

         52 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[17]] = localMem[13];
              ip = 53;
        end

         53 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[20] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 54;
        end

         54 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[20]] = localMem[13];
              ip = 55;
        end

         55 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[17]];
//$display("AAAAA k=%d  source2=%d", k, localMem[2]);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[17] * NArea + i]);
                if (i < k && heapMem[localMem[17] * NArea + i] > localMem[2]) j = j + 1;
              end
              localMem[21] = j;
              ip = 56;
        end

         56 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[21] != 0 ? 64 : 57;
        end

         57 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[22] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 58;
        end

         58 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[22]*8 + localMem[13]] = localMem[2];
              updateArrayLength(1, localMem[22], localMem[13]);
              ip = 59;
        end

         59 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 60;
        end

         60 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[23]*8 + localMem[13]] = localMem[3];
              updateArrayLength(1, localMem[23], localMem[13]);
              ip = 61;
        end

         61 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[5]*8 + 0] = localMem[13] + 1;
              updateArrayLength(1, localMem[5], 0);
              ip = 62;
        end

         62 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 63;
        end

         63 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1064;
        end

         64 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 65;
        end

         65 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[17]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[17] * NArea + i] < localMem[2]) j = j + 1;
              end
              localMem[24] = j;
              ip = 66;
        end

         66 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[25] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 67;
        end

         67 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[25] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[24], localMem[25], arraySizes[localMem[25]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[24] && i <= arraySizes[localMem[25]]) begin
                  heapMem[NArea * localMem[25] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[25] + localMem[24]] = localMem[2];                                    // Insert new value
              arraySizes[localMem[25]] = arraySizes[localMem[25]] + 1;                              // Increase array size
              ip = 68;
        end

         68 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[26] = heapMem[localMem[5]*8 + 5];
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
//$display("BBBB pos=%d array=%d length=%d", localMem[24], localMem[26], arraySizes[localMem[26]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[24] && i <= arraySizes[localMem[26]]) begin
                  heapMem[NArea * localMem[26] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[26] + localMem[24]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[26]] = arraySizes[localMem[26]] + 1;                              // Increase array size
              ip = 70;
        end

         70 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[5]*8 + 0] = heapMem[localMem[5]*8 + 0] + 1;
              updateArrayLength(1, localMem[5], 0);
              ip = 71;
        end

         71 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 72;
        end

         72 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1064;
        end

         73 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 74;
        end

         74 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 75;
        end

         75 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 76;
        end

         76 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
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
              localMem[29] = heapMem[localMem[27]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 79;
        end

         79 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[30] = heapMem[localMem[27]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 80;
        end

         80 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[31] = heapMem[localMem[30]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 81;
        end

         81 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[29] <  localMem[31] ? 301 : 82;
        end

         82 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[32] = localMem[31];
              updateArrayLength(2, 0, 0);
              ip = 83;
        end

         83 :
        begin                                                                   // shiftRight
if (0) begin
  $display("AAAA %4d %4d shiftRight", steps, ip);
end
              localMem[32] = localMem[32] >> 1;
              ip = 84;
        end

         84 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[33] = localMem[32] + 1;
              updateArrayLength(2, 0, 0);
              ip = 85;
        end

         85 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[34] = heapMem[localMem[27]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 86;
        end

         86 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[34] == 0 ? 183 : 87;
        end

         87 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed    87");
        end

         88 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed    96");
        end

         97 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed    97");
        end

         98 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed    98");
        end

         99 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed    99");
        end

        100 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   104");
        end

        105 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   107");
        end

        108 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   108");
        end

        109 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   109");
        end

        110 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   110");
        end

        111 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   116");
        end

        117 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   117");
        end

        118 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   118");
        end

        119 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   119");
        end

        120 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   120");
        end

        121 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   121");
        end

        122 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   122");
        end

        123 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   123");
        end

        124 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   124");
        end

        125 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   125");
        end

        126 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   126");
        end

        127 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   127");
        end

        128 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   128");
        end

        129 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   131");
        end

        132 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   132");
        end

        133 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   133");
        end

        134 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   134");
        end

        135 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   152");
        end

        153 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   153");
        end

        154 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   156");
        end

        157 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   157");
        end

        158 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   158");
        end

        159 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   159");
        end

        160 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   160");
        end

        161 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
           $display("Should not be executed   161");
        end

        162 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   162");
        end

        163 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
           $display("Should not be executed   163");
        end

        164 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
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
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   176");
        end

        177 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   179");
        end

        180 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   180");
        end

        181 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   181");
        end

        182 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   182");
        end

        183 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 184;
        end

        184 :
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
              ip = 185;
        end

        185 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 0] = localMem[32];
              updateArrayLength(1, localMem[82], 0);
              ip = 186;
        end

        186 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 2] = 0;
              updateArrayLength(1, localMem[82], 2);
              ip = 187;
        end

        187 :
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
              ip = 188;
        end

        188 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 4] = localMem[83];
              updateArrayLength(1, localMem[82], 4);
              ip = 189;
        end

        189 :
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
              ip = 190;
        end

        190 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 5] = localMem[84];
              updateArrayLength(1, localMem[82], 5);
              ip = 191;
        end

        191 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 6] = 0;
              updateArrayLength(1, localMem[82], 6);
              ip = 192;
        end

        192 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 3] = localMem[30];
              updateArrayLength(1, localMem[82], 3);
              ip = 193;
        end

        193 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[30]*8 + 1] = heapMem[localMem[30]*8 + 1] + 1;
              updateArrayLength(1, localMem[30], 1);
              ip = 194;
        end

        194 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 1] = heapMem[localMem[30]*8 + 1];
              updateArrayLength(1, localMem[82], 1);
              ip = 195;
        end

        195 :
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
              ip = 196;
        end

        196 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 0] = localMem[32];
              updateArrayLength(1, localMem[85], 0);
              ip = 197;
        end

        197 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 2] = 0;
              updateArrayLength(1, localMem[85], 2);
              ip = 198;
        end

        198 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[86] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[86] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[86]] = 0;
              ip = 199;
        end

        199 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 4] = localMem[86];
              updateArrayLength(1, localMem[85], 4);
              ip = 200;
        end

        200 :
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
              ip = 201;
        end

        201 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 5] = localMem[87];
              updateArrayLength(1, localMem[85], 5);
              ip = 202;
        end

        202 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 6] = 0;
              updateArrayLength(1, localMem[85], 6);
              ip = 203;
        end

        203 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 3] = localMem[30];
              updateArrayLength(1, localMem[85], 3);
              ip = 204;
        end

        204 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[30]*8 + 1] = heapMem[localMem[30]*8 + 1] + 1;
              updateArrayLength(1, localMem[30], 1);
              ip = 205;
        end

        205 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 1] = heapMem[localMem[30]*8 + 1];
              updateArrayLength(1, localMem[85], 1);
              ip = 206;
        end

        206 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[88] = !heapMem[localMem[27]*8 + 6];
              ip = 207;
        end

        207 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[88] != 0 ? 259 : 208;
        end

        208 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[89] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[89] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[89]] = 0;
              ip = 209;
        end

        209 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 6] = localMem[89];
              updateArrayLength(1, localMem[82], 6);
              ip = 210;
        end

        210 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[90] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[90] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[90]] = 0;
              ip = 211;
        end

        211 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 6] = localMem[90];
              updateArrayLength(1, localMem[85], 6);
              ip = 212;
        end

        212 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[91] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 213;
        end

        213 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[92] = heapMem[localMem[82]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 214;
        end

        214 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[92] + 0 + i] = heapMem[NArea * localMem[91] + 0 + i];
                  updateArrayLength(1, localMem[92], 0 + i);
                end
              end
              ip = 215;
        end

        215 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[93] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 216;
        end

        216 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[94] = heapMem[localMem[82]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 217;
        end

        217 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[94] + 0 + i] = heapMem[NArea * localMem[93] + 0 + i];
                  updateArrayLength(1, localMem[94], 0 + i);
                end
              end
              ip = 218;
        end

        218 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[95] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 219;
        end

        219 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[96] = heapMem[localMem[82]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 220;
        end

        220 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[97] = localMem[32] + 1;
              updateArrayLength(2, 0, 0);
              ip = 221;
        end

        221 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[97]) begin
                  heapMem[NArea * localMem[96] + 0 + i] = heapMem[NArea * localMem[95] + 0 + i];
                  updateArrayLength(1, localMem[96], 0 + i);
                end
              end
              ip = 222;
        end

        222 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[98] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 223;
        end

        223 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[99] = heapMem[localMem[85]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 224;
        end

        224 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[99] + 0 + i] = heapMem[NArea * localMem[98] + localMem[33] + i];
                  updateArrayLength(1, localMem[99], 0 + i);
                end
              end
              ip = 225;
        end

        225 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[100] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 226;
        end

        226 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[101] = heapMem[localMem[85]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 227;
        end

        227 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[101] + 0 + i] = heapMem[NArea * localMem[100] + localMem[33] + i];
                  updateArrayLength(1, localMem[101], 0 + i);
                end
              end
              ip = 228;
        end

        228 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[102] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 229;
        end

        229 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[103] = heapMem[localMem[85]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 230;
        end

        230 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[104] = localMem[32] + 1;
              updateArrayLength(2, 0, 0);
              ip = 231;
        end

        231 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[104]) begin
                  heapMem[NArea * localMem[103] + 0 + i] = heapMem[NArea * localMem[102] + localMem[33] + i];
                  updateArrayLength(1, localMem[103], 0 + i);
                end
              end
              ip = 232;
        end

        232 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[105] = heapMem[localMem[82]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 233;
        end

        233 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[106] = localMem[105] + 1;
              updateArrayLength(2, 0, 0);
              ip = 234;
        end

        234 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[107] = heapMem[localMem[82]*8 + 6];
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[108] = 0;
              updateArrayLength(2, 0, 0);
              ip = 237;
        end

        237 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 238;
        end

        238 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[108] >= localMem[106] ? 244 : 239;
        end

        239 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[109] = heapMem[localMem[107]*8 + localMem[108]];
              updateArrayLength(2, 0, 0);
              ip = 240;
        end

        240 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[109]*8 + 2] = localMem[82];
              updateArrayLength(1, localMem[109], 2);
              ip = 241;
        end

        241 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 242;
        end

        242 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[108] = localMem[108] + 1;
              updateArrayLength(2, 0, 0);
              ip = 243;
        end

        243 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 237;
        end

        244 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 245;
        end

        245 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[110] = heapMem[localMem[85]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 246;
        end

        246 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[111] = localMem[110] + 1;
              updateArrayLength(2, 0, 0);
              ip = 247;
        end

        247 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[112] = heapMem[localMem[85]*8 + 6];
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[113] = 0;
              updateArrayLength(2, 0, 0);
              ip = 250;
        end

        250 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 251;
        end

        251 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[113] >= localMem[111] ? 257 : 252;
        end

        252 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[114] = heapMem[localMem[112]*8 + localMem[113]];
              updateArrayLength(2, 0, 0);
              ip = 253;
        end

        253 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[114]*8 + 2] = localMem[85];
              updateArrayLength(1, localMem[114], 2);
              ip = 254;
        end

        254 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 255;
        end

        255 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[113] = localMem[113] + 1;
              updateArrayLength(2, 0, 0);
              ip = 256;
        end

        256 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 250;
        end

        257 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 258;
        end

        258 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 274;
        end

        259 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 260;
        end

        260 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[115] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[115] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[115]] = 0;
              ip = 261;
        end

        261 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[27]*8 + 6] = localMem[115];
              updateArrayLength(1, localMem[27], 6);
              ip = 262;
        end

        262 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[116] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 263;
        end

        263 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[117] = heapMem[localMem[82]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 264;
        end

        264 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[117] + 0 + i] = heapMem[NArea * localMem[116] + 0 + i];
                  updateArrayLength(1, localMem[117], 0 + i);
                end
              end
              ip = 265;
        end

        265 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[118] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 266;
        end

        266 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[119] = heapMem[localMem[82]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 267;
        end

        267 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[119] + 0 + i] = heapMem[NArea * localMem[118] + 0 + i];
                  updateArrayLength(1, localMem[119], 0 + i);
                end
              end
              ip = 268;
        end

        268 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[120] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 269;
        end

        269 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[121] = heapMem[localMem[85]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 270;
        end

        270 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[121] + 0 + i] = heapMem[NArea * localMem[120] + localMem[33] + i];
                  updateArrayLength(1, localMem[121], 0 + i);
                end
              end
              ip = 271;
        end

        271 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[122] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 272;
        end

        272 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[123] = heapMem[localMem[85]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 273;
        end

        273 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[32]) begin
                  heapMem[NArea * localMem[123] + 0 + i] = heapMem[NArea * localMem[122] + localMem[33] + i];
                  updateArrayLength(1, localMem[123], 0 + i);
                end
              end
              ip = 274;
        end

        274 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 275;
        end

        275 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[82]*8 + 2] = localMem[27];
              updateArrayLength(1, localMem[82], 2);
              ip = 276;
        end

        276 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[85]*8 + 2] = localMem[27];
              updateArrayLength(1, localMem[85], 2);
              ip = 277;
        end

        277 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[124] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 278;
        end

        278 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[125] = heapMem[localMem[124]*8 + localMem[32]];
              updateArrayLength(2, 0, 0);
              ip = 279;
        end

        279 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[126] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 280;
        end

        280 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[127] = heapMem[localMem[126]*8 + localMem[32]];
              updateArrayLength(2, 0, 0);
              ip = 281;
        end

        281 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[128] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 282;
        end

        282 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[128]*8 + 0] = localMem[125];
              updateArrayLength(1, localMem[128], 0);
              ip = 283;
        end

        283 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[129] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 284;
        end

        284 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[129]*8 + 0] = localMem[127];
              updateArrayLength(1, localMem[129], 0);
              ip = 285;
        end

        285 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[130] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 286;
        end

        286 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[130]*8 + 0] = localMem[82];
              updateArrayLength(1, localMem[130], 0);
              ip = 287;
        end

        287 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[131] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 288;
        end

        288 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[131]*8 + 1] = localMem[85];
              updateArrayLength(1, localMem[131], 1);
              ip = 289;
        end

        289 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[27]*8 + 0] = 1;
              updateArrayLength(1, localMem[27], 0);
              ip = 290;
        end

        290 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[132] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 291;
        end

        291 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[132]] = 1;
              ip = 292;
        end

        292 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[133] = heapMem[localMem[27]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 293;
        end

        293 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[133]] = 1;
              ip = 294;
        end

        294 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[134] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 295;
        end

        295 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[134]] = 2;
              ip = 296;
        end

        296 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 298;
        end

        297 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   297");
        end

        298 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 299;
        end

        299 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = 1;
              updateArrayLength(2, 0, 0);
              ip = 300;
        end

        300 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 303;
        end

        301 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 302;
        end

        302 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = 0;
              updateArrayLength(2, 0, 0);
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[135] = 0;
              updateArrayLength(2, 0, 0);
              ip = 307;
        end

        307 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 308;
        end

        308 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[135] >= 99 ? 806 : 309;
        end

        309 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[136] = heapMem[localMem[27]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 310;
        end

        310 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[137] = localMem[136] - 1;
              updateArrayLength(2, 0, 0);
              ip = 311;
        end

        311 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[138] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 312;
        end

        312 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[139] = heapMem[localMem[138]*8 + localMem[137]];
              updateArrayLength(2, 0, 0);
              ip = 313;
        end

        313 :
        begin                                                                   // jLe
if (0) begin
  $display("AAAA %4d %4d jLe", steps, ip);
end
              ip = localMem[2] <= localMem[139] ? 554 : 314;
        end

        314 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[140] = !heapMem[localMem[27]*8 + 6];
              ip = 315;
        end

        315 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[140] == 0 ? 320 : 316;
        end

        316 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[4]*8 + 0] = localMem[27];
              updateArrayLength(1, localMem[4], 0);
              ip = 317;
        end

        317 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[4]*8 + 1] = 2;
              updateArrayLength(1, localMem[4], 1);
              ip = 318;
        end

        318 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              heapMem[localMem[4]*8 + 2] = localMem[136] - 1;
              updateArrayLength(1, localMem[4], 2);
              ip = 319;
        end

        319 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 810;
        end

        320 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 321;
        end

        321 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[141] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 322;
        end

        322 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[142] = heapMem[localMem[141]*8 + localMem[136]];
              updateArrayLength(2, 0, 0);
              ip = 323;
        end

        323 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 324;
        end

        324 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[144] = heapMem[localMem[142]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 325;
        end

        325 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[145] = heapMem[localMem[142]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 326;
        end

        326 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[146] = heapMem[localMem[145]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 327;
        end

        327 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[144] <  localMem[146] ? 547 : 328;
        end

        328 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   328");
        end

        329 :
        begin                                                                   // shiftRight
if (0) begin
  $display("AAAA %4d %4d shiftRight", steps, ip);
end
           $display("Should not be executed   329");
        end

        330 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   330");
        end

        331 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   331");
        end

        332 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
           $display("Should not be executed   332");
        end

        333 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   333");
        end

        334 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   334");
        end

        335 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   335");
        end

        336 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   336");
        end

        337 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   337");
        end

        338 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   338");
        end

        339 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   339");
        end

        340 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   340");
        end

        341 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   341");
        end

        342 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   342");
        end

        343 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   343");
        end

        344 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   344");
        end

        345 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   345");
        end

        346 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   346");
        end

        347 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   347");
        end

        348 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   348");
        end

        349 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   349");
        end

        350 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   350");
        end

        351 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   351");
        end

        352 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   352");
        end

        353 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   353");
        end

        354 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   354");
        end

        355 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   355");
        end

        356 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   356");
        end

        357 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   357");
        end

        358 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   358");
        end

        359 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   359");
        end

        360 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   360");
        end

        361 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   361");
        end

        362 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   362");
        end

        363 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   363");
        end

        364 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   364");
        end

        365 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   365");
        end

        366 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   366");
        end

        367 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   367");
        end

        368 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   368");
        end

        369 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   369");
        end

        370 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   370");
        end

        371 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   371");
        end

        372 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   372");
        end

        373 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   373");
        end

        374 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   374");
        end

        375 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   375");
        end

        376 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   376");
        end

        377 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   377");
        end

        378 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   378");
        end

        379 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   379");
        end

        380 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   380");
        end

        381 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   381");
        end

        382 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   382");
        end

        383 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   383");
        end

        384 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   384");
        end

        385 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   385");
        end

        386 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   386");
        end

        387 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   387");
        end

        388 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   388");
        end

        389 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   389");
        end

        390 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   390");
        end

        391 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   391");
        end

        392 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   392");
        end

        393 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   393");
        end

        394 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   394");
        end

        395 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   395");
        end

        396 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   396");
        end

        397 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   397");
        end

        398 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   398");
        end

        399 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   399");
        end

        400 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   400");
        end

        401 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   403");
        end

        404 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   404");
        end

        405 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   405");
        end

        406 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   406");
        end

        407 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
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
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
           $display("Should not be executed   409");
        end

        410 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
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
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   418");
        end

        419 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   419");
        end

        420 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   420");
        end

        421 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   421");
        end

        422 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   422");
        end

        423 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   423");
        end

        424 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   424");
        end

        425 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   425");
        end

        426 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   426");
        end

        427 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   427");
        end

        428 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   428");
        end

        429 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   429");
        end

        430 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   438");
        end

        439 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   439");
        end

        440 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   440");
        end

        441 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   446");
        end

        447 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   447");
        end

        448 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   452");
        end

        453 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   453");
        end

        454 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   456");
        end

        457 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   460");
        end

        461 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   463");
        end

        464 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   470");
        end

        471 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   475");
        end

        476 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   476");
        end

        477 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   477");
        end

        478 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   478");
        end

        479 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   482");
        end

        483 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   483");
        end

        484 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   486");
        end

        487 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   487");
        end

        488 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   488");
        end

        489 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   491");
        end

        492 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   495");
        end

        496 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   496");
        end

        497 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   497");
        end

        498 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   498");
        end

        499 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   499");
        end

        500 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   500");
        end

        501 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   501");
        end

        502 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   502");
        end

        503 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   503");
        end

        504 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   504");
        end

        505 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   505");
        end

        506 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   506");
        end

        507 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   519");
        end

        520 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   535");
        end

        536 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   536");
        end

        537 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   537");
        end

        538 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   538");
        end

        539 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   539");
        end

        540 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   540");
        end

        541 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   541");
        end

        542 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   542");
        end

        543 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   543");
        end

        544 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   544");
        end

        545 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   545");
        end

        546 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   546");
        end

        547 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 548;
        end

        548 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[143] = 0;
              updateArrayLength(2, 0, 0);
              ip = 549;
        end

        549 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 550;
        end

        550 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[143] != 0 ? 552 : 551;
        end

        551 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = localMem[142];
              updateArrayLength(2, 0, 0);
              ip = 552;
        end

        552 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 553;
        end

        553 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 803;
        end

        554 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 555;
        end

        555 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[250] = heapMem[localMem[27]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 556;
        end

        556 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[251] = 0; k = arraySizes[localMem[250]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[250] * NArea + i] == localMem[2]) localMem[251] = i + 1;
              end
              ip = 557;
        end

        557 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[251] == 0 ? 562 : 558;
        end

        558 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   558");
        end

        559 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   559");
        end

        560 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed   560");
        end

        561 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   561");
        end

        562 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 563;
        end

        563 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[250]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[250] * NArea + i] < localMem[2]) j = j + 1;
              end
              localMem[252] = j;
              ip = 564;
        end

        564 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[253] = !heapMem[localMem[27]*8 + 6];
              ip = 565;
        end

        565 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[253] == 0 ? 570 : 566;
        end

        566 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[4]*8 + 0] = localMem[27];
              updateArrayLength(1, localMem[4], 0);
              ip = 567;
        end

        567 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[4]*8 + 1] = 0;
              updateArrayLength(1, localMem[4], 1);
              ip = 568;
        end

        568 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[4]*8 + 2] = localMem[252];
              updateArrayLength(1, localMem[4], 2);
              ip = 569;
        end

        569 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 810;
        end

        570 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 571;
        end

        571 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[254] = heapMem[localMem[27]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 572;
        end

        572 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[255] = heapMem[localMem[254]*8 + localMem[252]];
              updateArrayLength(2, 0, 0);
              ip = 573;
        end

        573 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 574;
        end

        574 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[257] = heapMem[localMem[255]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 575;
        end

        575 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[258] = heapMem[localMem[255]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 576;
        end

        576 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[259] = heapMem[localMem[258]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 577;
        end

        577 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[257] <  localMem[259] ? 797 : 578;
        end

        578 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   578");
        end

        579 :
        begin                                                                   // shiftRight
if (0) begin
  $display("AAAA %4d %4d shiftRight", steps, ip);
end
           $display("Should not be executed   579");
        end

        580 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   580");
        end

        581 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   581");
        end

        582 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
           $display("Should not be executed   582");
        end

        583 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   583");
        end

        584 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   584");
        end

        585 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   585");
        end

        586 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   586");
        end

        587 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   587");
        end

        588 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   588");
        end

        589 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   589");
        end

        590 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   590");
        end

        591 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   591");
        end

        592 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   592");
        end

        593 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   593");
        end

        594 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   594");
        end

        595 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   595");
        end

        596 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   596");
        end

        597 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   597");
        end

        598 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   598");
        end

        599 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   599");
        end

        600 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   600");
        end

        601 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   601");
        end

        602 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   602");
        end

        603 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   603");
        end

        604 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   604");
        end

        605 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   605");
        end

        606 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   606");
        end

        607 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   607");
        end

        608 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   608");
        end

        609 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   609");
        end

        610 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   610");
        end

        611 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   611");
        end

        612 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   612");
        end

        613 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   613");
        end

        614 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   617");
        end

        618 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   618");
        end

        619 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   619");
        end

        620 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   620");
        end

        621 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   621");
        end

        622 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   622");
        end

        623 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   623");
        end

        624 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   624");
        end

        625 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   625");
        end

        626 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   626");
        end

        627 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   627");
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   630");
        end

        631 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   639");
        end

        640 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   644");
        end

        645 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   645");
        end

        646 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   646");
        end

        647 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   647");
        end

        648 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   648");
        end

        649 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   649");
        end

        650 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   650");
        end

        651 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   651");
        end

        652 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   652");
        end

        653 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   653");
        end

        654 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   654");
        end

        655 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   655");
        end

        656 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   656");
        end

        657 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
           $display("Should not be executed   657");
        end

        658 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   658");
        end

        659 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
           $display("Should not be executed   659");
        end

        660 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
           $display("Should not be executed   660");
        end

        661 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   661");
        end

        662 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   662");
        end

        663 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   663");
        end

        664 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   664");
        end

        665 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   665");
        end

        666 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   666");
        end

        667 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   667");
        end

        668 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   668");
        end

        669 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   669");
        end

        670 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
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
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   672");
        end

        673 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   673");
        end

        674 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   674");
        end

        675 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
           $display("Should not be executed   675");
        end

        676 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   676");
        end

        677 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   677");
        end

        678 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   678");
        end

        679 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   679");
        end

        680 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   680");
        end

        681 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   683");
        end

        684 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   684");
        end

        685 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   685");
        end

        686 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   689");
        end

        690 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   690");
        end

        691 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   691");
        end

        692 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   692");
        end

        693 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   702");
        end

        703 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   703");
        end

        704 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   706");
        end

        707 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   719");
        end

        720 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   720");
        end

        721 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   723");
        end

        724 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   726");
        end

        727 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   727");
        end

        728 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   728");
        end

        729 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   729");
        end

        730 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   730");
        end

        731 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   731");
        end

        732 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   732");
        end

        733 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   733");
        end

        734 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   736");
        end

        737 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   737");
        end

        738 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   738");
        end

        739 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   741");
        end

        742 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   742");
        end

        743 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   743");
        end

        744 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   744");
        end

        745 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   745");
        end

        746 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   746");
        end

        747 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   750");
        end

        751 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   751");
        end

        752 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   752");
        end

        753 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   753");
        end

        754 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   754");
        end

        755 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   755");
        end

        756 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   759");
        end

        760 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   769");
        end

        770 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   781");
        end

        782 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   782");
        end

        783 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   783");
        end

        784 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   784");
        end

        785 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   785");
        end

        786 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   786");
        end

        787 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   787");
        end

        788 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   788");
        end

        789 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   789");
        end

        790 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   790");
        end

        791 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   791");
        end

        792 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   792");
        end

        793 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   793");
        end

        794 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   794");
        end

        795 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   795");
        end

        796 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   796");
        end

        797 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 798;
        end

        798 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[256] = 0;
              updateArrayLength(2, 0, 0);
              ip = 799;
        end

        799 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 800;
        end

        800 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[256] != 0 ? 802 : 801;
        end

        801 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = localMem[255];
              updateArrayLength(2, 0, 0);
              ip = 802;
        end

        802 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 803;
        end

        803 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 804;
        end

        804 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[135] = localMem[135] + 1;
              updateArrayLength(2, 0, 0);
              ip = 805;
        end

        805 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 307;
        end

        806 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   806");
        end

        807 :
        begin                                                                   // assert
if (0) begin
  $display("AAAA %4d %4d assert", steps, ip);
end
           $display("Should not be executed   807");
        end

        808 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   808");
        end

        809 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   809");
        end

        810 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 811;
        end

        811 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[363] = heapMem[localMem[4]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 812;
        end

        812 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[364] = heapMem[localMem[4]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 813;
        end

        813 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[365] = heapMem[localMem[4]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 814;
        end

        814 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[364] != 1 ? 818 : 815;
        end

        815 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   815");
        end

        816 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   816");
        end

        817 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   817");
        end

        818 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 819;
        end

        819 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[364] != 2 ? 827 : 820;
        end

        820 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[367] = localMem[365] + 1;
              updateArrayLength(2, 0, 0);
              ip = 821;
        end

        821 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[368] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 822;
        end

        822 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[368] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[367], localMem[368], arraySizes[localMem[368]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[367] && i <= arraySizes[localMem[368]]) begin
                  heapMem[NArea * localMem[368] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[368] + localMem[367]] = localMem[2];                                    // Insert new value
              arraySizes[localMem[368]] = arraySizes[localMem[368]] + 1;                              // Increase array size
              ip = 823;
        end

        823 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[369] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 824;
        end

        824 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[369] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[367], localMem[369], arraySizes[localMem[369]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[367] && i <= arraySizes[localMem[369]]) begin
                  heapMem[NArea * localMem[369] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[369] + localMem[367]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[369]] = arraySizes[localMem[369]] + 1;                              // Increase array size
              ip = 825;
        end

        825 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[363]*8 + 0] = heapMem[localMem[363]*8 + 0] + 1;
              updateArrayLength(1, localMem[363], 0);
              ip = 826;
        end

        826 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 833;
        end

        827 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 828;
        end

        828 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[370] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 829;
        end

        829 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[370] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[365], localMem[370], arraySizes[localMem[370]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[365] && i <= arraySizes[localMem[370]]) begin
                  heapMem[NArea * localMem[370] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[370] + localMem[365]] = localMem[2];                                    // Insert new value
              arraySizes[localMem[370]] = arraySizes[localMem[370]] + 1;                              // Increase array size
              ip = 830;
        end

        830 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[371] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 831;
        end

        831 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[371] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[365], localMem[371], arraySizes[localMem[371]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[365] && i <= arraySizes[localMem[371]]) begin
                  heapMem[NArea * localMem[371] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[371] + localMem[365]] = localMem[3];                                    // Insert new value
              arraySizes[localMem[371]] = arraySizes[localMem[371]] + 1;                              // Increase array size
              ip = 832;
        end

        832 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[363]*8 + 0] = heapMem[localMem[363]*8 + 0] + 1;
              updateArrayLength(1, localMem[363], 0);
              ip = 833;
        end

        833 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 834;
        end

        834 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = heapMem[localMem[0]*8 + 0] + 1;
              updateArrayLength(1, localMem[0], 0);
              ip = 835;
        end

        835 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 836;
        end

        836 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[373] = heapMem[localMem[363]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 837;
        end

        837 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[374] = heapMem[localMem[363]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 838;
        end

        838 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[375] = heapMem[localMem[374]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 839;
        end

        839 :
        begin                                                                   // jLt
if (0) begin
  $display("AAAA %4d %4d jLt", steps, ip);
end
              ip = localMem[373] <  localMem[375] ? 1059 : 840;
        end

        840 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[376] = localMem[375];
              updateArrayLength(2, 0, 0);
              ip = 841;
        end

        841 :
        begin                                                                   // shiftRight
if (0) begin
  $display("AAAA %4d %4d shiftRight", steps, ip);
end
              localMem[376] = localMem[376] >> 1;
              ip = 842;
        end

        842 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[377] = localMem[376] + 1;
              updateArrayLength(2, 0, 0);
              ip = 843;
        end

        843 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[378] = heapMem[localMem[363]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 844;
        end

        844 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[378] == 0 ? 941 : 845;
        end

        845 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[379] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[379] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[379]] = 0;
              ip = 846;
        end

        846 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 0] = localMem[376];
              updateArrayLength(1, localMem[379], 0);
              ip = 847;
        end

        847 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 2] = 0;
              updateArrayLength(1, localMem[379], 2);
              ip = 848;
        end

        848 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[380] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[380] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[380]] = 0;
              ip = 849;
        end

        849 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 4] = localMem[380];
              updateArrayLength(1, localMem[379], 4);
              ip = 850;
        end

        850 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[381] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[381] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[381]] = 0;
              ip = 851;
        end

        851 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 5] = localMem[381];
              updateArrayLength(1, localMem[379], 5);
              ip = 852;
        end

        852 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 6] = 0;
              updateArrayLength(1, localMem[379], 6);
              ip = 853;
        end

        853 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 3] = localMem[374];
              updateArrayLength(1, localMem[379], 3);
              ip = 854;
        end

        854 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[374]*8 + 1] = heapMem[localMem[374]*8 + 1] + 1;
              updateArrayLength(1, localMem[374], 1);
              ip = 855;
        end

        855 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 1] = heapMem[localMem[374]*8 + 1];
              updateArrayLength(1, localMem[379], 1);
              ip = 856;
        end

        856 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[382] = !heapMem[localMem[363]*8 + 6];
              ip = 857;
        end

        857 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[382] != 0 ? 886 : 858;
        end

        858 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   858");
        end

        859 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   861");
        end

        862 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   865");
        end

        866 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   866");
        end

        867 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   867");
        end

        868 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   868");
        end

        869 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   869");
        end

        870 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   870");
        end

        871 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   871");
        end

        872 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   872");
        end

        873 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   873");
        end

        874 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   874");
        end

        875 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   875");
        end

        876 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
           $display("Should not be executed   876");
        end

        877 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   877");
        end

        878 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   878");
        end

        879 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   879");
        end

        880 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   880");
        end

        881 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   881");
        end

        882 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   882");
        end

        883 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   883");
        end

        884 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed   884");
        end

        885 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   885");
        end

        886 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 887;
        end

        887 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[397] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 888;
        end

        888 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[398] = heapMem[localMem[379]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 889;
        end

        889 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[376]) begin
                  heapMem[NArea * localMem[398] + 0 + i] = heapMem[NArea * localMem[397] + localMem[377] + i];
                  updateArrayLength(1, localMem[398], 0 + i);
                end
              end
              ip = 890;
        end

        890 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[399] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 891;
        end

        891 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[400] = heapMem[localMem[379]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 892;
        end

        892 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < localMem[376]) begin
                  heapMem[NArea * localMem[400] + 0 + i] = heapMem[NArea * localMem[399] + localMem[377] + i];
                  updateArrayLength(1, localMem[400], 0 + i);
                end
              end
              ip = 893;
        end

        893 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 894;
        end

        894 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[363]*8 + 0] = localMem[376];
              updateArrayLength(1, localMem[363], 0);
              ip = 895;
        end

        895 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[379]*8 + 2] = localMem[378];
              updateArrayLength(1, localMem[379], 2);
              ip = 896;
        end

        896 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[401] = heapMem[localMem[378]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 897;
        end

        897 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[402] = heapMem[localMem[378]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 898;
        end

        898 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[403] = heapMem[localMem[402]*8 + localMem[401]];
              updateArrayLength(2, 0, 0);
              ip = 899;
        end

        899 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[403] != localMem[363] ? 918 : 900;
        end

        900 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[404] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 901;
        end

        901 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[405] = heapMem[localMem[404]*8 + localMem[376]];
              updateArrayLength(2, 0, 0);
              ip = 902;
        end

        902 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[406] = heapMem[localMem[378]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 903;
        end

        903 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[406]*8 + localMem[401]] = localMem[405];
              updateArrayLength(1, localMem[406], localMem[401]);
              ip = 904;
        end

        904 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[407] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 905;
        end

        905 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[408] = heapMem[localMem[407]*8 + localMem[376]];
              updateArrayLength(2, 0, 0);
              ip = 906;
        end

        906 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[409] = heapMem[localMem[378]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 907;
        end

        907 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[409]*8 + localMem[401]] = localMem[408];
              updateArrayLength(1, localMem[409], localMem[401]);
              ip = 908;
        end

        908 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[410] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 909;
        end

        909 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[410]] = localMem[376];
              ip = 910;
        end

        910 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[411] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 911;
        end

        911 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[411]] = localMem[376];
              ip = 912;
        end

        912 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[412] = localMem[401] + 1;
              updateArrayLength(2, 0, 0);
              ip = 913;
        end

        913 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[378]*8 + 0] = localMem[412];
              updateArrayLength(1, localMem[378], 0);
              ip = 914;
        end

        914 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[413] = heapMem[localMem[378]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 915;
        end

        915 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[413]*8 + localMem[412]] = localMem[379];
              updateArrayLength(1, localMem[413], localMem[412]);
              ip = 916;
        end

        916 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1056;
        end

        917 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed   917");
        end

        918 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 919;
        end

        919 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 920;
        end

        920 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[414] = heapMem[localMem[378]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 921;
        end

        921 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[415] = 0; k = arraySizes[localMem[414]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[414] * NArea + i] == localMem[363]) localMem[415] = i + 1;
              end
              ip = 922;
        end

        922 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[415] = localMem[415] - 1;
              updateArrayLength(2, 0, 0);
              ip = 923;
        end

        923 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[416] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 924;
        end

        924 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[417] = heapMem[localMem[416]*8 + localMem[376]];
              updateArrayLength(2, 0, 0);
              ip = 925;
        end

        925 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[418] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 926;
        end

        926 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[419] = heapMem[localMem[418]*8 + localMem[376]];
              updateArrayLength(2, 0, 0);
              ip = 927;
        end

        927 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[420] = heapMem[localMem[363]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 928;
        end

        928 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[420]] = localMem[376];
              ip = 929;
        end

        929 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[421] = heapMem[localMem[363]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 930;
        end

        930 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[421]] = localMem[376];
              ip = 931;
        end

        931 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[422] = heapMem[localMem[378]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 932;
        end

        932 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[422] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[415], localMem[422], arraySizes[localMem[422]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[415] && i <= arraySizes[localMem[422]]) begin
                  heapMem[NArea * localMem[422] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[422] + localMem[415]] = localMem[417];                                    // Insert new value
              arraySizes[localMem[422]] = arraySizes[localMem[422]] + 1;                              // Increase array size
              ip = 933;
        end

        933 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[423] = heapMem[localMem[378]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 934;
        end

        934 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[423] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[415], localMem[423], arraySizes[localMem[423]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[415] && i <= arraySizes[localMem[423]]) begin
                  heapMem[NArea * localMem[423] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[423] + localMem[415]] = localMem[419];                                    // Insert new value
              arraySizes[localMem[423]] = arraySizes[localMem[423]] + 1;                              // Increase array size
              ip = 935;
        end

        935 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[424] = heapMem[localMem[378]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 936;
        end

        936 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[425] = localMem[415] + 1;
              updateArrayLength(2, 0, 0);
              ip = 937;
        end

        937 :
        begin                                                                   // shiftUp
if (0) begin
  $display("AAAA %4d %4d shiftUp", steps, ip);
end
//$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * localMem[424] + i]; // Copy source array
//$display("BBBB pos=%d array=%d length=%d", localMem[425], localMem[424], arraySizes[localMem[424]]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > localMem[425] && i <= arraySizes[localMem[424]]) begin
                  heapMem[NArea * localMem[424] + i] = arrayShift[i-1];
//$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * localMem[424] + localMem[425]] = localMem[379];                                    // Insert new value
              arraySizes[localMem[424]] = arraySizes[localMem[424]] + 1;                              // Increase array size
              ip = 938;
        end

        938 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[378]*8 + 0] = heapMem[localMem[378]*8 + 0] + 1;
              updateArrayLength(1, localMem[378], 0);
              ip = 939;
        end

        939 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1056;
        end

        940 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   940");
        end

        941 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   944");
        end

        945 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   947");
        end

        948 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   950");
        end

        951 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   951");
        end

        952 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   952");
        end

        953 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
           $display("Should not be executed   953");
        end

        954 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   961");
        end

        962 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
           $display("Should not be executed   964");
        end

        965 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
           $display("Should not be executed   965");
        end

        966 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   971");
        end

        972 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   977");
        end

        978 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   978");
        end

        979 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   981");
        end

        982 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   985");
        end

        986 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   986");
        end

        987 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   987");
        end

        988 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   988");
        end

        989 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed   989");
        end

        990 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   990");
        end

        991 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed   991");
        end

        992 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   992");
        end

        993 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   993");
        end

        994 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   994");
        end

        995 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   995");
        end

        996 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed   998");
        end

        999 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed   999");
        end

       1000 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed  1000");
        end

       1001 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1001");
        end

       1002 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1002");
        end

       1003 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1003");
        end

       1004 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1008");
        end

       1009 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1011");
        end

       1012 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1012");
        end

       1013 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
           $display("Should not be executed  1013");
        end

       1014 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1014");
        end

       1015 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1015");
        end

       1016 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1016");
        end

       1017 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1017");
        end

       1018 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
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
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
           $display("Should not be executed  1031");
        end

       1032 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1039");
        end

       1040 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1040");
        end

       1041 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1041");
        end

       1042 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1042");
        end

       1043 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1043");
        end

       1044 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1044");
        end

       1045 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1045");
        end

       1046 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1046");
        end

       1047 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1047");
        end

       1048 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1048");
        end

       1049 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1049");
        end

       1050 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1050");
        end

       1051 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1051");
        end

       1052 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1052");
        end

       1053 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
           $display("Should not be executed  1053");
        end

       1054 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1054");
        end

       1055 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1055");
        end

       1056 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1057;
        end

       1057 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[372] = 1;
              updateArrayLength(2, 0, 0);
              ip = 1058;
        end

       1058 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1061;
        end

       1059 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1060;
        end

       1060 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[372] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1061;
        end

       1061 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1062;
        end

       1062 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1063;
        end

       1063 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1064;
        end

       1064 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1065;
        end

       1065 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[4]] = 0;
              freedArrays[freedArraysTop] = localMem[4];
              freedArraysTop = freedArraysTop + 1;
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
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 5;
        end

       1068 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1069;
        end

       1069 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[479] = 1;
              updateArrayLength(2, 0, 0);
              ip = 1070;
        end

       1070 :
        begin                                                                   // shiftLeft
if (0) begin
  $display("AAAA %4d %4d shiftLeft", steps, ip);
end
              localMem[479] = localMem[479] << 31;
              ip = 1071;
        end

       1071 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[480] = heapMem[localMem[0]*8 + 3];
              updateArrayLength(2, 0, 0);
              ip = 1072;
        end

       1072 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[481] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[481] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[481]] = 0;
              ip = 1073;
        end

       1073 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[482] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[482] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[482]] = 0;
              ip = 1074;
        end

       1074 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[480] != 0 ? 1079 : 1075;
        end

       1075 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1075");
        end

       1076 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1076");
        end

       1077 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1077");
        end

       1078 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1078");
        end

       1079 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1080;
        end

       1080 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1081;
        end

       1081 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[483] = 0;
              updateArrayLength(2, 0, 0);
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
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[483] >= 99 ? 1092 : 1084;
        end

       1084 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[484] = !heapMem[localMem[480]*8 + 6];
              ip = 1085;
        end

       1085 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[484] != 0 ? 1092 : 1086;
        end

       1086 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[485] = heapMem[localMem[480]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1087;
        end

       1087 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[486] = heapMem[localMem[485]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1088;
        end

       1088 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[480] = localMem[486];
              updateArrayLength(2, 0, 0);
              ip = 1089;
        end

       1089 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1090;
        end

       1090 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[483] = localMem[483] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1091;
        end

       1091 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1082;
        end

       1092 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1093;
        end

       1093 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 0] = localMem[480];
              updateArrayLength(1, localMem[481], 0);
              ip = 1094;
        end

       1094 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 1] = 1;
              updateArrayLength(1, localMem[481], 1);
              ip = 1095;
        end

       1095 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 2] = 0;
              updateArrayLength(1, localMem[481], 2);
              ip = 1096;
        end

       1096 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1097;
        end

       1097 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1098;
        end

       1098 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[487] = heapMem[localMem[481]*8 + 1];
              updateArrayLength(2, 0, 0);
              ip = 1099;
        end

       1099 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[487] == 3 ? 1182 : 1100;
        end

       1100 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 3) begin
                  heapMem[NArea * localMem[482] + 0 + i] = heapMem[NArea * localMem[481] + 0 + i];
                  updateArrayLength(1, localMem[482], 0 + i);
                end
              end
              ip = 1101;
        end

       1101 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[488] = heapMem[localMem[482]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1102;
        end

       1102 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[489] = heapMem[localMem[482]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1103;
        end

       1103 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[490] = heapMem[localMem[488]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 1104;
        end

       1104 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[491] = heapMem[localMem[490]*8 + localMem[489]];
              updateArrayLength(2, 0, 0);
              ip = 1105;
        end

       1105 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[491];
              outMemPos = outMemPos + 1;
              ip = 1106;
        end

       1106 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1107;
        end

       1107 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[492] = heapMem[localMem[481]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1108;
        end

       1108 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[493] = !heapMem[localMem[492]*8 + 6];
              ip = 1109;
        end

       1109 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[493] == 0 ? 1149 : 1110;
        end

       1110 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[494] = heapMem[localMem[481]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1111;
        end

       1111 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[495] = heapMem[localMem[492]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1112;
        end

       1112 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[494] >= localMem[495] ? 1117 : 1113;
        end

       1113 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 0] = localMem[492];
              updateArrayLength(1, localMem[481], 0);
              ip = 1114;
        end

       1114 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 1] = 1;
              updateArrayLength(1, localMem[481], 1);
              ip = 1115;
        end

       1115 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 2] = localMem[494];
              updateArrayLength(1, localMem[481], 2);
              ip = 1116;
        end

       1116 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1178;
        end

       1117 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1118;
        end

       1118 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[496] = heapMem[localMem[492]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1119;
        end

       1119 :
        begin                                                                   // jEq
if (0) begin
  $display("AAAA %4d %4d jEq", steps, ip);
end
              ip = localMem[496] == 0 ? 1144 : 1120;
        end

       1120 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1121;
        end

       1121 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[497] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1122;
        end

       1122 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1123;
        end

       1123 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[497] >= 99 ? 1143 : 1124;
        end

       1124 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[498] = heapMem[localMem[496]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1125;
        end

       1125 :
        begin                                                                   // assertNe
if (0) begin
  $display("AAAA %4d %4d assertNe", steps, ip);
end
            ip = 1126;
        end

       1126 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[499] = heapMem[localMem[496]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1127;
        end

       1127 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[500] = 0; k = arraySizes[localMem[499]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[499] * NArea + i] == localMem[492]) localMem[500] = i + 1;
              end
              ip = 1128;
        end

       1128 :
        begin                                                                   // subtract
if (0) begin
  $display("AAAA %4d %4d subtract", steps, ip);
end
              localMem[500] = localMem[500] - 1;
              updateArrayLength(2, 0, 0);
              ip = 1129;
        end

       1129 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[500] != localMem[498] ? 1134 : 1130;
        end

       1130 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[492] = localMem[496];
              updateArrayLength(2, 0, 0);
              ip = 1131;
        end

       1131 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[496] = heapMem[localMem[492]*8 + 2];
              updateArrayLength(2, 0, 0);
              ip = 1132;
        end

       1132 :
        begin                                                                   // jFalse
if (0) begin
  $display("AAAA %4d %4d jFalse", steps, ip);
end
              ip = localMem[496] == 0 ? 1143 : 1133;
        end

       1133 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1139;
        end

       1134 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1135;
        end

       1135 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 0] = localMem[496];
              updateArrayLength(1, localMem[481], 0);
              ip = 1136;
        end

       1136 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 1] = 1;
              updateArrayLength(1, localMem[481], 1);
              ip = 1137;
        end

       1137 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 2] = localMem[500];
              updateArrayLength(1, localMem[481], 2);
              ip = 1138;
        end

       1138 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1178;
        end

       1139 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1140;
        end

       1140 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1141;
        end

       1141 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[497] = localMem[497] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1142;
        end

       1142 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1122;
        end

       1143 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1144;
        end

       1144 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1145;
        end

       1145 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 0] = localMem[492];
              updateArrayLength(1, localMem[481], 0);
              ip = 1146;
        end

       1146 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 1] = 3;
              updateArrayLength(1, localMem[481], 1);
              ip = 1147;
        end

       1147 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 2] = 0;
              updateArrayLength(1, localMem[481], 2);
              ip = 1148;
        end

       1148 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1178;
        end

       1149 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1150;
        end

       1150 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[501] = heapMem[localMem[481]*8 + 2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1151;
        end

       1151 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[502] = heapMem[localMem[492]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1152;
        end

       1152 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[503] = heapMem[localMem[502]*8 + localMem[501]];
              updateArrayLength(2, 0, 0);
              ip = 1153;
        end

       1153 :
        begin                                                                   // jNe
if (0) begin
  $display("AAAA %4d %4d jNe", steps, ip);
end
              ip = localMem[503] != 0 ? 1158 : 1154;
        end

       1154 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1154");
        end

       1155 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1155");
        end

       1156 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
           $display("Should not be executed  1156");
        end

       1157 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
           $display("Should not be executed  1157");
        end

       1158 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1159;
        end

       1159 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1160;
        end

       1160 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[504] = 0;
              updateArrayLength(2, 0, 0);
              ip = 1161;
        end

       1161 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1162;
        end

       1162 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[504] >= 99 ? 1171 : 1163;
        end

       1163 :
        begin                                                                   // not
if (0) begin
  $display("AAAA %4d %4d not", steps, ip);
end
              localMem[505] = !heapMem[localMem[503]*8 + 6];
              ip = 1164;
        end

       1164 :
        begin                                                                   // jTrue
if (0) begin
  $display("AAAA %4d %4d jTrue", steps, ip);
end
              ip = localMem[505] != 0 ? 1171 : 1165;
        end

       1165 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[506] = heapMem[localMem[503]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 1166;
        end

       1166 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[507] = heapMem[localMem[506]*8 + 0];
              updateArrayLength(2, 0, 0);
              ip = 1167;
        end

       1167 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[503] = localMem[507];
              updateArrayLength(2, 0, 0);
              ip = 1168;
        end

       1168 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1169;
        end

       1169 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[504] = localMem[504] + 1;
              updateArrayLength(2, 0, 0);
              ip = 1170;
        end

       1170 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1161;
        end

       1171 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1172;
        end

       1172 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 0] = localMem[503];
              updateArrayLength(1, localMem[481], 0);
              ip = 1173;
        end

       1173 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 1] = 1;
              updateArrayLength(1, localMem[481], 1);
              ip = 1174;
        end

       1174 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[481]*8 + 2] = 0;
              updateArrayLength(1, localMem[481], 2);
              ip = 1175;
        end

       1175 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1176;
        end

       1176 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1177;
        end

       1177 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1178;
        end

       1178 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1179;
        end

       1179 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 1097;
        end

       1180 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1180");
        end

       1181 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
           $display("Should not be executed  1181");
        end

       1182 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 1183;
        end

       1183 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[481]] = 0;
              freedArrays[freedArraysTop] = localMem[481];
              freedArraysTop = freedArraysTop + 1;
              ip = 1184;
        end

       1184 :
        begin                                                                   // free
if (0) begin
  $display("AAAA %4d %4d free", steps, ip);
end
                                 arraySizes[localMem[482]] = 0;
              freedArrays[freedArraysTop] = localMem[482];
              freedArraysTop = freedArraysTop + 1;
              ip = 1185;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 0;
      success  = success && outMem[1] == 1;
      success  = success && outMem[2] == 2;
      success  = success && outMem[3] == 3;
      success  = success && outMem[4] == 4;
      success  = success && outMem[5] == 5;
      success  = success && outMem[6] == 6;
      success  = success && outMem[7] == 7;
      success  = success && outMem[8] == 8;
      success  = success && outMem[9] == 9;
      finished = steps >   1729;
    end
  end

endmodule
