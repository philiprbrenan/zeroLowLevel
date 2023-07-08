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
  parameter integer NArrays =        5;                                         // Maximum number of arrays
  parameter integer NHeap   =       40;                                         // Amount of heap memory
  parameter integer NLocal  =       27;                                         // Size of local memory
  parameter integer NOut    =        0;                                         // Size of output area
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[0]*8 + 2] = 7;
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = 0;
              updateArrayLength(1, localMem[1], 0);
              ip = 7;
        end

          7 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 2] = 0;
              updateArrayLength(1, localMem[1], 2);
              ip = 8;
        end

          8 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[2] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[2] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[2]] = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 4] = localMem[2];
              updateArrayLength(1, localMem[1], 4);
              ip = 10;
        end

         10 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[3] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[3] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[3]] = 0;
              ip = 11;
        end

         11 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 5] = localMem[3];
              updateArrayLength(1, localMem[1], 5);
              ip = 12;
        end

         12 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 6] = 0;
              updateArrayLength(1, localMem[1], 6);
              ip = 13;
        end

         13 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 3] = localMem[0];
              updateArrayLength(1, localMem[1], 3);
              ip = 14;
        end

         14 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = heapMem[localMem[0]*8 + 1] + 1;
              updateArrayLength(1, localMem[0], 1);
              ip = 15;
        end

         15 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 1] = heapMem[localMem[0]*8 + 1];
              updateArrayLength(1, localMem[1], 1);
              ip = 16;
        end

         16 :
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
              ip = 17;
        end

         17 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 6] = localMem[4];
              updateArrayLength(1, localMem[1], 6);
              ip = 18;
        end

         18 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = 7;
              updateArrayLength(1, localMem[1], 0);
              ip = 19;
        end

         19 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[5] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 20;
        end

         20 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 0] = 10;
              updateArrayLength(1, localMem[5], 0);
              ip = 21;
        end

         21 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[6] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 22;
        end

         22 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[6]*8 + 0] = 10;
              updateArrayLength(1, localMem[6], 0);
              ip = 23;
        end

         23 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[7] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 24;
        end

         24 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[7]*8 + 0] = 5;
              updateArrayLength(1, localMem[7], 0);
              ip = 25;
        end

         25 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[8] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 26;
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[8]*8 + 1] = 20;
              updateArrayLength(1, localMem[8], 1);
              ip = 27;
        end

         27 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 28;
        end

         28 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[9]*8 + 1] = 20;
              updateArrayLength(1, localMem[9], 1);
              ip = 29;
        end

         29 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 30;
        end

         30 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[10]*8 + 1] = 15;
              updateArrayLength(1, localMem[10], 1);
              ip = 31;
        end

         31 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 32;
        end

         32 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[11]*8 + 2] = 30;
              updateArrayLength(1, localMem[11], 2);
              ip = 33;
        end

         33 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 34;
        end

         34 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[12]*8 + 2] = 30;
              updateArrayLength(1, localMem[12], 2);
              ip = 35;
        end

         35 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 36;
        end

         36 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[13]*8 + 2] = 25;
              updateArrayLength(1, localMem[13], 2);
              ip = 37;
        end

         37 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 38;
        end

         38 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[14]*8 + 3] = 40;
              updateArrayLength(1, localMem[14], 3);
              ip = 39;
        end

         39 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 40;
        end

         40 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[15]*8 + 3] = 40;
              updateArrayLength(1, localMem[15], 3);
              ip = 41;
        end

         41 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 42;
        end

         42 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[16]*8 + 3] = 35;
              updateArrayLength(1, localMem[16], 3);
              ip = 43;
        end

         43 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 44;
        end

         44 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[17]*8 + 4] = 50;
              updateArrayLength(1, localMem[17], 4);
              ip = 45;
        end

         45 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[18] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 46;
        end

         46 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[18]*8 + 4] = 50;
              updateArrayLength(1, localMem[18], 4);
              ip = 47;
        end

         47 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[19] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 48;
        end

         48 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[19]*8 + 4] = 45;
              updateArrayLength(1, localMem[19], 4);
              ip = 49;
        end

         49 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[20] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 50;
        end

         50 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[20]*8 + 5] = 60;
              updateArrayLength(1, localMem[20], 5);
              ip = 51;
        end

         51 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[21] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 52;
        end

         52 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[21]*8 + 5] = 60;
              updateArrayLength(1, localMem[21], 5);
              ip = 53;
        end

         53 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[22] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 54;
        end

         54 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[22]*8 + 5] = 55;
              updateArrayLength(1, localMem[22], 5);
              ip = 55;
        end

         55 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 56;
        end

         56 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[23]*8 + 6] = 70;
              updateArrayLength(1, localMem[23], 6);
              ip = 57;
        end

         57 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[24] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 58;
        end

         58 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[24]*8 + 6] = 70;
              updateArrayLength(1, localMem[24], 6);
              ip = 59;
        end

         59 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[25] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 60;
        end

         60 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[25]*8 + 6] = 65;
              updateArrayLength(1, localMem[25], 6);
              ip = 61;
        end

         61 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[26] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 62;
        end

         62 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[26]*8 + 7] = 75;
              updateArrayLength(1, localMem[26], 7);
              ip = 63;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      finished = steps >     64;
    end
  end

endmodule
