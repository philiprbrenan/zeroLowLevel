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
  parameter integer NArrays =        9;                                         // Maximum number of arrays
  parameter integer NHeap   =       72;                                         // Amount of heap memory
  parameter integer NLocal  =       54;                                         // Size of local memory
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
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[5] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[5] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[5]] = 0;
              ip = 19;
        end

         19 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 0] = 0;
              updateArrayLength(1, localMem[5], 0);
              ip = 20;
        end

         20 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 2] = 0;
              updateArrayLength(1, localMem[5], 2);
              ip = 21;
        end

         21 :
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
              ip = 22;
        end

         22 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 4] = localMem[6];
              updateArrayLength(1, localMem[5], 4);
              ip = 23;
        end

         23 :
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
              ip = 24;
        end

         24 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 5] = localMem[7];
              updateArrayLength(1, localMem[5], 5);
              ip = 25;
        end

         25 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 6] = 0;
              updateArrayLength(1, localMem[5], 6);
              ip = 26;
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 3] = localMem[0];
              updateArrayLength(1, localMem[5], 3);
              ip = 27;
        end

         27 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              heapMem[localMem[0]*8 + 1] = heapMem[localMem[0]*8 + 1] + 1;
              updateArrayLength(1, localMem[0], 1);
              ip = 28;
        end

         28 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 1] = heapMem[localMem[0]*8 + 1];
              updateArrayLength(1, localMem[5], 1);
              ip = 29;
        end

         29 :
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
              ip = 30;
        end

         30 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 6] = localMem[8];
              updateArrayLength(1, localMem[5], 6);
              ip = 31;
        end

         31 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[1]*8 + 0] = 7;
              updateArrayLength(1, localMem[1], 0);
              ip = 32;
        end

         32 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 0] = 7;
              updateArrayLength(1, localMem[5], 0);
              ip = 33;
        end

         33 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 34;
        end

         34 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[9]*8 + 0] = 1000;
              updateArrayLength(1, localMem[9], 0);
              ip = 35;
        end

         35 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 36;
        end

         36 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[10]*8 + 0] = 2010;
              updateArrayLength(1, localMem[10], 0);
              ip = 37;
        end

         37 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 38;
        end

         38 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[11]*8 + 0] = 1000;
              updateArrayLength(1, localMem[11], 0);
              ip = 39;
        end

         39 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 40;
        end

         40 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[12]*8 + 0] = 2010;
              updateArrayLength(1, localMem[12], 0);
              ip = 41;
        end

         41 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 42;
        end

         42 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[13]*8 + 0] = 50;
              updateArrayLength(1, localMem[13], 0);
              ip = 43;
        end

         43 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 44;
        end

         44 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[14]*8 + 0] = 2005;
              updateArrayLength(1, localMem[14], 0);
              ip = 45;
        end

         45 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 46;
        end

         46 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[15]*8 + 1] = 2000;
              updateArrayLength(1, localMem[15], 1);
              ip = 47;
        end

         47 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 48;
        end

         48 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[16]*8 + 1] = 2020;
              updateArrayLength(1, localMem[16], 1);
              ip = 49;
        end

         49 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 50;
        end

         50 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[17]*8 + 1] = 2000;
              updateArrayLength(1, localMem[17], 1);
              ip = 51;
        end

         51 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[18] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 52;
        end

         52 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[18]*8 + 1] = 2020;
              updateArrayLength(1, localMem[18], 1);
              ip = 53;
        end

         53 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[19] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 54;
        end

         54 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[19]*8 + 1] = 1050;
              updateArrayLength(1, localMem[19], 1);
              ip = 55;
        end

         55 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[20] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 56;
        end

         56 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[20]*8 + 1] = 2015;
              updateArrayLength(1, localMem[20], 1);
              ip = 57;
        end

         57 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[21] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 58;
        end

         58 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[21]*8 + 2] = 3000;
              updateArrayLength(1, localMem[21], 2);
              ip = 59;
        end

         59 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[22] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 60;
        end

         60 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[22]*8 + 2] = 2030;
              updateArrayLength(1, localMem[22], 2);
              ip = 61;
        end

         61 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 62;
        end

         62 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[23]*8 + 2] = 3000;
              updateArrayLength(1, localMem[23], 2);
              ip = 63;
        end

         63 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[24] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 64;
        end

         64 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[24]*8 + 2] = 2030;
              updateArrayLength(1, localMem[24], 2);
              ip = 65;
        end

         65 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[25] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 66;
        end

         66 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[25]*8 + 2] = 2050;
              updateArrayLength(1, localMem[25], 2);
              ip = 67;
        end

         67 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[26] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 68;
        end

         68 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[26]*8 + 2] = 2025;
              updateArrayLength(1, localMem[26], 2);
              ip = 69;
        end

         69 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 70;
        end

         70 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[27]*8 + 3] = 4000;
              updateArrayLength(1, localMem[27], 3);
              ip = 71;
        end

         71 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 72;
        end

         72 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[28]*8 + 3] = 2040;
              updateArrayLength(1, localMem[28], 3);
              ip = 73;
        end

         73 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[29] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 74;
        end

         74 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[29]*8 + 3] = 4000;
              updateArrayLength(1, localMem[29], 3);
              ip = 75;
        end

         75 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[30] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 76;
        end

         76 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[30]*8 + 3] = 2040;
              updateArrayLength(1, localMem[30], 3);
              ip = 77;
        end

         77 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[31] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 78;
        end

         78 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[31]*8 + 3] = 3050;
              updateArrayLength(1, localMem[31], 3);
              ip = 79;
        end

         79 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[32] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 80;
        end

         80 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[32]*8 + 3] = 2035;
              updateArrayLength(1, localMem[32], 3);
              ip = 81;
        end

         81 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[33] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 82;
        end

         82 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[33]*8 + 4] = 5000;
              updateArrayLength(1, localMem[33], 4);
              ip = 83;
        end

         83 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[34] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 84;
        end

         84 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[34]*8 + 4] = 2050;
              updateArrayLength(1, localMem[34], 4);
              ip = 85;
        end

         85 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[35] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 86;
        end

         86 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[35]*8 + 4] = 5000;
              updateArrayLength(1, localMem[35], 4);
              ip = 87;
        end

         87 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[36] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 88;
        end

         88 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[36]*8 + 4] = 2050;
              updateArrayLength(1, localMem[36], 4);
              ip = 89;
        end

         89 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[37] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 90;
        end

         90 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[37]*8 + 4] = 4050;
              updateArrayLength(1, localMem[37], 4);
              ip = 91;
        end

         91 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[38] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 92;
        end

         92 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[38]*8 + 4] = 2045;
              updateArrayLength(1, localMem[38], 4);
              ip = 93;
        end

         93 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[39] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 94;
        end

         94 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[39]*8 + 5] = 6000;
              updateArrayLength(1, localMem[39], 5);
              ip = 95;
        end

         95 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[40] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 96;
        end

         96 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[40]*8 + 5] = 2060;
              updateArrayLength(1, localMem[40], 5);
              ip = 97;
        end

         97 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[41] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 98;
        end

         98 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[41]*8 + 5] = 6000;
              updateArrayLength(1, localMem[41], 5);
              ip = 99;
        end

         99 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[42] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 100;
        end

        100 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[42]*8 + 5] = 2060;
              updateArrayLength(1, localMem[42], 5);
              ip = 101;
        end

        101 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[43] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 102;
        end

        102 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[43]*8 + 5] = 5050;
              updateArrayLength(1, localMem[43], 5);
              ip = 103;
        end

        103 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[44] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 104;
        end

        104 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[44]*8 + 5] = 2055;
              updateArrayLength(1, localMem[44], 5);
              ip = 105;
        end

        105 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[45] = heapMem[localMem[1]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 106;
        end

        106 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[45]*8 + 6] = 7000;
              updateArrayLength(1, localMem[45], 6);
              ip = 107;
        end

        107 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[46] = heapMem[localMem[5]*8 + 4];
              updateArrayLength(2, 0, 0);
              ip = 108;
        end

        108 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[46]*8 + 6] = 2070;
              updateArrayLength(1, localMem[46], 6);
              ip = 109;
        end

        109 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[47] = heapMem[localMem[1]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 110;
        end

        110 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[47]*8 + 6] = 7000;
              updateArrayLength(1, localMem[47], 6);
              ip = 111;
        end

        111 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[48] = heapMem[localMem[5]*8 + 5];
              updateArrayLength(2, 0, 0);
              ip = 112;
        end

        112 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[48]*8 + 6] = 2070;
              updateArrayLength(1, localMem[48], 6);
              ip = 113;
        end

        113 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[49] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 114;
        end

        114 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[49]*8 + 6] = 6050;
              updateArrayLength(1, localMem[49], 6);
              ip = 115;
        end

        115 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[50] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 116;
        end

        116 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[50]*8 + 6] = 2065;
              updateArrayLength(1, localMem[50], 6);
              ip = 117;
        end

        117 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[5]*8 + 2] = localMem[1];
              updateArrayLength(1, localMem[5], 2);
              ip = 118;
        end

        118 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[51] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 119;
        end

        119 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[51]*8 + 7] = 7500;
              updateArrayLength(1, localMem[51], 7);
              ip = 120;
        end

        120 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[52] = heapMem[localMem[1]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 121;
        end

        121 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[52]*8 + 0] = 6;
              updateArrayLength(1, localMem[52], 0);
              ip = 122;
        end

        122 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[53] = heapMem[localMem[5]*8 + 6];
              updateArrayLength(2, 0, 0);
              ip = 123;
        end

        123 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              heapMem[localMem[53]*8 + 7] = 2075;
              updateArrayLength(1, localMem[53], 7);
              ip = 124;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      finished = steps >    125;
    end
  end

endmodule
