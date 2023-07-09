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

  parameter integer NArea   =        4;                                         // Size of each area on the heap
  parameter integer NArrays =        1;                                         // Maximum number of arrays
  parameter integer NHeap   =        4;                                         // Amount of heap memory
  parameter integer NLocal  =       16;                                         // Size of local memory
  parameter integer NOut    =       12;                                         // Size of output area

  heapMemory heap(                                                              // Create heap memory
    .clk    (heapClock),
    .write  (heapWrite),
    .address(heapAddress),
    .in     (heapIn),
    .out    (heapOut)
  );

  defparam heap.MEM_SIZE   = NHeap;                                             // Size of heap
  defparam heap.DATA_WIDTH = MemoryElementWidth;

  reg                         heapClock;                                        // Heap ports
  reg                         heapWrite;
  reg[NHeap-1:0]              heapAddress;
  reg[MemoryElementWidth-1:0] heapIn;
  reg[MemoryElementWidth-1:0] heapOut;

  parameter integer NIn     =        0;                                         // Size of input area
  reg [MemoryElementWidth-1:0]   arraySizes[NArrays-1:0];                       // Size of each array
//reg [MemoryElementWidth-1:0]      heapMem[NHeap-1  :0];                       // Heap memory
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
              localMem[13] = 10;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 2;
        end

          2 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*4 + 0;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[13];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 3;                                                          // Next instruction
        end

          3 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 4;                                                          // Next instruction
        end

          4 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = 20;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 5;
        end

          5 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*4 + 1;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[14];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 6;                                                          // Next instruction
        end

          6 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 7;                                                          // Next instruction
        end

          7 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = 30;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 8;
        end

          8 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*4 + 2;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[15];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 9;                                                          // Next instruction
        end

          9 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 10;                                                          // Next instruction
        end

         10 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[0]] = 3;
              ip = 11;
        end

         11 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[1] = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] == 30) localMem[1] = i + 1;
              end
              ip = 12;
        end

         12 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[1];
              outMemPos = outMemPos + 1;
              ip = 13;
        end

         13 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[2] = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] == 20) localMem[2] = i + 1;
              end
              ip = 14;
        end

         14 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[2];
              outMemPos = outMemPos + 1;
              ip = 15;
        end

         15 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[3] = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] == 10) localMem[3] = i + 1;
              end
              ip = 16;
        end

         16 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[3];
              outMemPos = outMemPos + 1;
              ip = 17;
        end

         17 :
        begin                                                                   // arrayIndex
if (0) begin
  $display("AAAA %4d %4d arrayIndex", steps, ip);
end
              localMem[4] = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] == 15) localMem[4] = i + 1;
              end
              ip = 18;
        end

         18 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[4];
              outMemPos = outMemPos + 1;
              ip = 19;
        end

         19 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] < 35) j = j + 1;
              end
              localMem[5] = j;
              ip = 20;
        end

         20 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[5];
              outMemPos = outMemPos + 1;
              ip = 21;
        end

         21 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] < 25) j = j + 1;
              end
              localMem[6] = j;
              ip = 22;
        end

         22 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[6];
              outMemPos = outMemPos + 1;
              ip = 23;
        end

         23 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] < 15) j = j + 1;
              end
              localMem[7] = j;
              ip = 24;
        end

         24 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[7];
              outMemPos = outMemPos + 1;
              ip = 25;
        end

         25 :
        begin                                                                   // arrayCountLess
if (0) begin
  $display("AAAA %4d %4d arrayCountLess", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[localMem[0] * NArea + i] < 5) j = j + 1;
              end
              localMem[8] = j;
              ip = 26;
        end

         26 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[8];
              outMemPos = outMemPos + 1;
              ip = 27;
        end

         27 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
//$display("AAAAA k=%d  source2=%d", k, 35);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[0] * NArea + i]);
                if (i < k && heapMem[localMem[0] * NArea + i] > 35) j = j + 1;
              end
              localMem[9] = j;
              ip = 28;
        end

         28 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[9];
              outMemPos = outMemPos + 1;
              ip = 29;
        end

         29 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
//$display("AAAAA k=%d  source2=%d", k, 25);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[0] * NArea + i]);
                if (i < k && heapMem[localMem[0] * NArea + i] > 25) j = j + 1;
              end
              localMem[10] = j;
              ip = 30;
        end

         30 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[10];
              outMemPos = outMemPos + 1;
              ip = 31;
        end

         31 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
//$display("AAAAA k=%d  source2=%d", k, 15);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[0] * NArea + i]);
                if (i < k && heapMem[localMem[0] * NArea + i] > 15) j = j + 1;
              end
              localMem[11] = j;
              ip = 32;
        end

         32 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[11];
              outMemPos = outMemPos + 1;
              ip = 33;
        end

         33 :
        begin                                                                   // arrayCountGreater
if (0) begin
  $display("AAAA %4d %4d arrayCountGreater", steps, ip);
end
              j = 0; k = arraySizes[localMem[0]];
//$display("AAAAA k=%d  source2=%d", k, 5);
              for(i = 0; i < NArea; i = i + 1) begin
//$display("AAAAA i=%d  value=%d", i, heapMem[localMem[0] * NArea + i]);
                if (i < k && heapMem[localMem[0] * NArea + i] > 5) j = j + 1;
              end
              localMem[12] = j;
              ip = 34;
        end

         34 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[12];
              outMemPos = outMemPos + 1;
              ip = 35;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 3;
      success  = success && outMem[1] == 2;
      success  = success && outMem[2] == 1;
      success  = success && outMem[3] == 0;
      success  = success && outMem[4] == 3;
      success  = success && outMem[5] == 2;
      success  = success && outMem[6] == 1;
      success  = success && outMem[7] == 0;
      success  = success && outMem[8] == 0;
      success  = success && outMem[9] == 1;
      success  = success && outMem[10] == 2;
      success  = success && outMem[11] == 3;
      finished = steps >     36;
    end
  end

endmodule

module heapMemory
 (input wire clk,
  input wire write,
  input wire [MEM_SIZE-1:0] address,
  input wire [DATA_WIDTH-1:0] in,
  output reg [DATA_WIDTH-1:0] out);

  parameter integer MEM_SIZE   = 12;
  parameter integer DATA_WIDTH = 12;

  reg [DATA_WIDTH-1:0] memory [2**MEM_SIZE:0];

  always @(posedge clk) begin
    if (write) begin
      memory[address] = in;
      out = in;
    end
    else out = memory[address];
  end
endmodule
