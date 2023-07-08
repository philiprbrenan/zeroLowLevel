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
  parameter integer NArrays =        2;                                         // Maximum number of arrays
  parameter integer NHeap   =        8;                                         // Amount of heap memory
  parameter integer NLocal  =        9;                                         // Size of local memory
  parameter integer NOut    =        1;                                         // Size of output area

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
              localMem[3] = 11;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 3;
        end

          3 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*4 + 0;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[3];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 4;                                                          // Next instruction
        end

          4 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 5;                                                          // Next instruction
        end

          5 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[4] = 22;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 6;
        end

          6 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*4 + 1;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[4];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 7;                                                          // Next instruction
        end

          7 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 8;                                                          // Next instruction
        end

          8 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[1]*4 + 1;                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 9;                                                          // Next instruction
        end

          9 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[5] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 10;                                                          // Next instruction
        end

         10 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[1]*4 + 0;                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 11;                                                          // Next instruction
        end

         11 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[6] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 12;                                                          // Next instruction
        end

         12 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[7] = localMem[5] + localMem[6];
              updateArrayLength(2, 0, 0);
              ip = 13;
        end

         13 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*4 + 2;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[7];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 14;                                                          // Next instruction
        end

         14 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 15;                                                          // Next instruction
        end

         15 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[2] = localMem[1];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 16;
        end

         16 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[2]*4 + 2;                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 17;                                                          // Next instruction
        end

         17 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[8] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 18;                                                          // Next instruction
        end

         18 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[8];
              outMemPos = outMemPos + 1;
              ip = 19;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 33;
      finished = steps >     20;
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
