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
  parameter integer NArrays =        2;                                         // Maximum number of arrays
  parameter integer NHeap   =       16;                                         // Amount of heap memory
  parameter integer NLocal  =       14;                                         // Size of local memory
  parameter integer NOut    =       20;                                         // Size of output area
  parameter integer NIn     =        0;                                         // Size of input area
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
              ip = 2;
        end

          2 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 0] = 11;
              updateArrayLength(1, localMem[0], 0);
              ip = 3;
        end

          3 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = 22;
              updateArrayLength(1, localMem[0], 1);
              ip = 4;
        end

          4 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 2] = 33;
              updateArrayLength(1, localMem[0], 2);
              ip = 5;
        end

          5 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 3] = 44;
              updateArrayLength(1, localMem[0], 3);
              ip = 6;
        end

          6 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 4] = 55;
              updateArrayLength(1, localMem[0], 4);
              ip = 7;
        end

          7 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = 66;
              updateArrayLength(1, localMem[1], 0);
              ip = 8;
        end

          8 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 1] = 77;
              updateArrayLength(1, localMem[1], 1);
              ip = 9;
        end

          9 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 2] = 88;
              updateArrayLength(1, localMem[1], 2);
              ip = 10;
        end

         10 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 3] = 99;
              updateArrayLength(1, localMem[1], 3);
              ip = 11;
        end

         11 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 4] = 101;
              updateArrayLength(1, localMem[1], 4);
              ip = 12;
        end

         12 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[0]] = 5;
              ip = 13;
        end

         13 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[1]] = 5;
              ip = 14;
        end

         14 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[2] = arraySizes[localMem[0]];
              ip = 15;
        end

         15 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 16;
        end

         16 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[3] = 0;
              updateArrayLength(2, 0, 0);
              ip = 17;
        end

         17 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 18;
        end

         18 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[3] >= localMem[2] ? 24 : 19;
        end

         19 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[4] = heapMem[localMem[0]*8 + localMem[3]];
              updateArrayLength(2, 0, 0);
              ip = 20;
        end

         20 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[4];
              outMemPos = outMemPos + 1;
              ip = 21;
        end

         21 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 22;
        end

         22 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[3] = localMem[3] + 1;
              updateArrayLength(2, 0, 0);
              ip = 23;
        end

         23 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 17;
        end

         24 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 25;
        end

         25 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[5] = arraySizes[localMem[1]];
              ip = 26;
        end

         26 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 27;
        end

         27 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[6] = 0;
              updateArrayLength(2, 0, 0);
              ip = 28;
        end

         28 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 29;
        end

         29 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[6] >= localMem[5] ? 35 : 30;
        end

         30 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[7] = heapMem[localMem[1]*8 + localMem[6]];
              updateArrayLength(2, 0, 0);
              ip = 31;
        end

         31 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[7];
              outMemPos = outMemPos + 1;
              ip = 32;
        end

         32 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 33;
        end

         33 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[6] = localMem[6] + 1;
              updateArrayLength(2, 0, 0);
              ip = 34;
        end

         34 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 28;
        end

         35 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 36;
        end

         36 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 2) begin
                  heapMem[NArea * localMem[0] + 1 + i] = heapMem[NArea * localMem[1] + 2 + i];
                  updateArrayLength(1, localMem[0], 1 + i);
                end
              end
              ip = 37;
        end

         37 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[8] = arraySizes[localMem[0]];
              ip = 38;
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
              localMem[9] = 0;
              updateArrayLength(2, 0, 0);
              ip = 40;
        end

         40 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 41;
        end

         41 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[9] >= localMem[8] ? 47 : 42;
        end

         42 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = heapMem[localMem[0]*8 + localMem[9]];
              updateArrayLength(2, 0, 0);
              ip = 43;
        end

         43 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[10];
              outMemPos = outMemPos + 1;
              ip = 44;
        end

         44 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 45;
        end

         45 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[9] = localMem[9] + 1;
              updateArrayLength(2, 0, 0);
              ip = 46;
        end

         46 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 40;
        end

         47 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 48;
        end

         48 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[11] = arraySizes[localMem[1]];
              ip = 49;
        end

         49 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 50;
        end

         50 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = 0;
              updateArrayLength(2, 0, 0);
              ip = 51;
        end

         51 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 52;
        end

         52 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[12] >= localMem[11] ? 58 : 53;
        end

         53 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = heapMem[localMem[1]*8 + localMem[12]];
              updateArrayLength(2, 0, 0);
              ip = 54;
        end

         54 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[13];
              outMemPos = outMemPos + 1;
              ip = 55;
        end

         55 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 56;
        end

         56 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[12] = localMem[12] + 1;
              updateArrayLength(2, 0, 0);
              ip = 57;
        end

         57 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 51;
        end

         58 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 59;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 11;
      success  = success && outMem[1] == 22;
      success  = success && outMem[2] == 33;
      success  = success && outMem[3] == 44;
      success  = success && outMem[4] == 55;
      success  = success && outMem[5] == 66;
      success  = success && outMem[6] == 77;
      success  = success && outMem[7] == 88;
      success  = success && outMem[8] == 99;
      success  = success && outMem[9] == 101;
      success  = success && outMem[10] == 11;
      success  = success && outMem[11] == 88;
      success  = success && outMem[12] == 99;
      success  = success && outMem[13] == 44;
      success  = success && outMem[14] == 55;
      success  = success && outMem[15] == 66;
      success  = success && outMem[16] == 77;
      success  = success && outMem[17] == 88;
      success  = success && outMem[18] == 99;
      success  = success && outMem[19] == 101;
      finished = steps >    180;
    end
  end

endmodule
