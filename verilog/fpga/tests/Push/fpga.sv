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
  parameter integer NLocal  =        5;                                         // Size of local memory
  parameter integer NOut    =        2;                                         // Size of output area

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
        begin                                                                   // push
if (0) begin
  $display("AAAA %4d %4d push", steps, ip);
end
              heapMem[localMem[0] * NArea + arraySizes[localMem[0]]] = 1;
              arraySizes[localMem[0]]    = arraySizes[localMem[0]] + 1;
              ip = 2;
        end

          2 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 3;                                                          // Next instruction
        end

          3 :
        begin                                                                   // push
if (0) begin
  $display("AAAA %4d %4d push", steps, ip);
end
              heapMem[localMem[0] * NArea + arraySizes[localMem[0]]] = 2;
              arraySizes[localMem[0]]    = arraySizes[localMem[0]] + 1;
              ip = 4;
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
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[1] = arraySizes[localMem[0]];
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[2] = 0;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 8;
        end

          8 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 9;
        end

          9 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[2] >= localMem[1] ? 17 : 10;
        end

         10 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[0]*4 + localMem[2];                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 11;                                                          // Next instruction
        end

         11 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[4] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 12;                                                          // Next instruction
        end

         12 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[3] = localMem[4];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 13;
        end

         13 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[3];
              outMemPos = outMemPos + 1;
              ip = 14;
        end

         14 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 15;
        end

         15 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[2] = localMem[2] + 1;
              updateArrayLength(2, 0, 0);
              ip = 16;
        end

         16 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 8;
        end

         17 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 18;
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
      finished = steps >     30;
    end
  end

endmodule
module Memory
#(parameter integer ARRAYS     =  2**16,                                        // Number of memory elements for both arrays and elements
  parameter integer INDEX_BITS =  3,                                            // Log2 width of an element in bits
  parameter integer DATA_BITS  = 16)                                            // Log2 width of an element in bits
 (input wire                   clock,                                           // Clock to drive array operations
  input wire[7:0]              action,                                          // Operation to be performed on array
  input wire [ARRAYS     -1:0] array,                                           // The number of the array to work on
  input wire [INDEX_BITS -1:0] index,                                           // Index within array
  input wire [DATA_BITS  -1:0] in,                                              // Input data
  output reg [DATA_BITS  -1:0] out);                                            // Output data

  parameter integer ARRAY_MAX_SIZE   = 2**INDEX_BITS;                           // Maximum index

  parameter integer Reset   =  1;                                               // Zero all memory sizes
  parameter integer Write   =  2;                                               // Write an element
  parameter integer Read    =  3;                                               // Read an element
  parameter integer Size    =  4;                                               // Size of array
  parameter integer Inc     =  5;                                               // Increment size of array if possible
  parameter integer Dec     =  6;                                               // Decrement size of array if possible
  parameter integer Index   =  7;                                               // Index of element in array
  parameter integer Less    =  8;                                               // Elements of array less than in
  parameter integer Greater =  9;                                               // Elements of array greater than in
  parameter integer Up      = 10;                                               // Move array up
  parameter integer Down    = 11;                                               // Move array down
  parameter integer Long1   = 12;                                               // Move long first step
  parameter integer Long2   = 13;                                               // Move long last  step
  parameter integer Push    = 14;                                               // Push if possible
  parameter integer Pop     = 15;                                               // Pop if possible
  parameter integer Dump    = 16;                                               // Dump
  parameter integer Resize  = 17;                                               // Resize an array

  reg [DATA_BITS -1:0] memory     [ARRAYS-1:0][ARRAY_MAX_SIZE-1:0];             // Memory containing arrays in fixed blocks
  reg [DATA_BITS -1:0] copy                   [ARRAY_MAX_SIZE-1:0];             // Copy of one array
  reg [INDEX_BITS  :0] arraySizes [ARRAYS-1:0];                                 // Current size of each array

  integer result;                                                               // Result of each array operation
  integer size;                                                                 // Size of current array
  integer moveLongStartArray;                                                   // Source array of move long
  integer moveLongStartIndex;                                                   // Source index of move long
  integer i;                                                                    // Index

  always @(posedge clock) begin
    case(action)                                                                // Decode request
      Reset: begin                                                              // Reset
        for(i = 0; i < ARRAYS; i = i + 1) arraySizes[i] = 0;
      end
      Write: begin                                                              // Write
        memory[array][index] = in;
        if (index >= arraySizes[array] && index < ARRAY_MAX_SIZE) begin
          arraySizes[array] = index + 1;
        end
        out = in;
      end
      Read: begin                                                               // Read
        out = memory[array][index];
      end
      Size: begin                                                               // Size
        out = arraySizes[array];
      end
      Dec: begin                                                                // Decrement
        if (arraySizes[array] > 0) arraySizes[array] = arraySizes[array] - 1;
      end
      Inc: begin                                                                // Increment
        if (arraySizes[array] < ARRAY_MAX_SIZE) arraySizes[array] = arraySizes[array] + 1;
      end
      Index: begin                                                              // Index
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) begin
          if (i < size && memory[array][i] == in) result = i + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end
      Less: begin                                                               // Count less
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) begin
          if (i < size && memory[array][i] < in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end
      Greater: begin                                                            // Count greater
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) begin
          if (i < size && memory[array][i] > in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end
      Down: begin                                                               // Down
$display("Need Memory array down");
      end
      Up: begin                                                                 // Up
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) copy[i] = memory[array][i];   // Copy source array
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) begin                         // Move original array up
          if (i > index && i <= size) begin
            memory[array][i] = copy[i-1];
          end
        end
        memory[array][index] = in;                                              // Insert new value
        if (size < ARRAY_MAX_SIZE) arraySizes[array] = arraySizes[array] + 1;   // Increase array size
      end
      Long1: begin                                                              // Move long start
        moveLongStartArray = array;
        moveLongStartIndex = index;
      end
      Long2: begin                                                              // Move long finish
        for(i = 0; i < ARRAY_MAX_SIZE; i = i + 1) begin                         // Copy from source to target
          if (i < in && index + i < ARRAY_MAX_SIZE && moveLongStartIndex+i < ARRAY_MAX_SIZE) begin
            memory[array][index+i] = memory[moveLongStartArray][moveLongStartIndex+i];
            if (index+i >= arraySizes[array]) arraySizes[array] = index+i+1;
          end
        end
      end
      Push: begin                                                               // Push
        if (arraySizes[array] < 2**INDEX_BITS) begin
          memory[array][arraySizes[array]] = in;
          arraySizes[array] = arraySizes[array] + 1;
        end
      end
      Pop: begin                                                                // Pop
        if (arraySizes[array] > 0) begin
          arraySizes[array] = arraySizes[array] - 1;
          out = memory[array][arraySizes[array]];
        end
      end
      Dump: begin                                                               // Dump
        for(i = 0; i < ARRAY_MAX_SIZE; ++i) $display("%2d  %2d %2d", i, memory[1][i], memory[2][i]);
      end
      Resize: begin                                                             // Resize
        if (in <= ARRAY_MAX_SIZE) arraySizes[array] = in;
      end
    endcase
  end
endmodule
