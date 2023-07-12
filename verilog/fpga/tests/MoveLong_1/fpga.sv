//-----------------------------------------------------------------------------
// Fpga test
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga                                                                     // Run test programs
 (input  wire clock,                                                            // Driving clock
  input  wire reset,                                                            // Restart program
  output reg  finished,                                                         // Goes high when the program has finished
  output reg  success);                                                         // Goes high on finish if all the tests passed

  reg                heapClock;                                                 // Clock to drive array operations
  reg [7:0]          heapAction;                                                // Operation to be performed on array
  reg [       2-1:0] heapArray;                                         // The number of the array to work on
  reg [       3-1:0] heapIndex;                                         // Index within array
  reg [      12-1:0] heapIn;                                            // Input data
  reg [      12-1:0] heapOut;                                           // Output data
  reg [31        :0] heapError;                                                 // Error on heap operation if not zero

  Memory                                                                        // Memory module
   #(       2,        3,       12)                          // Address bits, index buts, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
  reg [      12-1:0] localMem[      22-1:0];                       // Local memory
  reg [      12-1:0]   outMem[      32  -1:0];                       // Out channel
  reg [      12-1:0]    inMem[       1   -1:0];                       // In channel

  integer inMemPos;                                                             // Current position in input channel
  integer outMemPos;                                                            // Position in output channel

  integer ip;                                                                   // Instruction pointer
  integer steps;                                                                // Number of steps executed so far
  integer i, j, k;                                                              // A useful counter

  always @(posedge clock, negedge clock) begin                                  // Each instruction
    if (reset) begin
      ip             = 0;
      steps          = 0;
      inMemPos       = 0;
      outMemPos      = 0;
      finished       = 0;
      success        = 0;

      if (0 && 0) begin                                                  // Clear memory
        for(i = 0; i < NHeap;   i = i + 1)    heapMem[i] = 0;
        for(i = 0; i < NLocal;  i = i + 1)   localMem[i] = 0;
        for(i = 0; i < NArrays; i = i + 1) arraySizes[i] = 0;
      end
    end
    else begin
      steps = steps + 1;
      case(ip)

          0 :
        begin                                                                   // start
if (0) begin
  $display("AAAA %4d %4d start", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 1;
        end

          1 :
        begin                                                                   // start2
if (0) begin
  $display("AAAA %4d %4d start2", steps, ip);
end
              heapAction = heap.Reset;                                          // Ready for next operation
              ip = 2;
              heapClock = ~ heapClock;
        end

          2 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 3;
              heapClock = ~ heapClock;
        end

          3 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[0] = heapOut;
              ip = 4;
        end

          4 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 5;
              heapClock = ~ heapClock;
        end

          5 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[1] = heapOut;
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
              ip = localMem[2] >= 8 ? 18 : 10;
        end

         10 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = localMem[2];
              ip = 11;
        end

         11 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = localMem[2];                                                // Index of element to write to
              heapIn      = localMem[16];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 12;
              heapClock = ~ heapClock;
        end

         12 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[3] = localMem[2] + 100;
              ip = 13;
        end

         13 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = localMem[3];
              ip = 14;
        end

         14 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = localMem[2];                                                // Index of element to write to
              heapIn      = localMem[17];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 15;
              heapClock = ~ heapClock;
        end

         15 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 16;
        end

         16 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[2] = localMem[2] + 1;
              ip = 17;
        end

         17 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 8;
        end

         18 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 19;
        end

         19 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              heapAction = heap.Size;
              heapArray  = localMem[0];
              ip = 20;
              heapClock = ~ heapClock;
        end

         20 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[4] = heapOut;
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[5] = 0;
              ip = 23;
        end

         23 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 24;
        end

         24 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[5] >= localMem[4] ? 32 : 25;
        end

         25 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 26;
              heapClock = ~ heapClock;
        end

         26 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[18] = heapOut;                                                     // Data retrieved from heap memory
              ip = 27;
              heapClock = ~ heapClock;
        end

         27 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[6] = localMem[18];
              ip = 28;
        end

         28 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[6];
              outMemPos = outMemPos + 1;
              ip = 29;
        end

         29 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 30;
        end

         30 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[5] = localMem[5] + 1;
              ip = 31;
        end

         31 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 23;
        end

         32 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 33;
        end

         33 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              heapAction = heap.Size;
              heapArray  = localMem[1];
              ip = 34;
              heapClock = ~ heapClock;
        end

         34 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[7] = heapOut;
              ip = 35;
        end

         35 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 36;
        end

         36 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[8] = 0;
              ip = 37;
        end

         37 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 38;
        end

         38 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[8] >= localMem[7] ? 46 : 39;
        end

         39 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = localMem[8];                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 40;
              heapClock = ~ heapClock;
        end

         40 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[19] = heapOut;                                                     // Data retrieved from heap memory
              ip = 41;
              heapClock = ~ heapClock;
        end

         41 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = localMem[19];
              ip = 42;
        end

         42 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[9];
              outMemPos = outMemPos + 1;
              ip = 43;
        end

         43 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 44;
        end

         44 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[8] = localMem[8] + 1;
              ip = 45;
        end

         45 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 37;
        end

         46 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 47;
        end

         47 :
        begin                                                                   // moveLong1
if (0) begin
  $display("AAAA %4d %4d moveLong1", steps, ip);
end
              heapArray  = localMem[0];                                                 // Array to write to
              heapIndex  = 4;                                                 // Index of element to write to
              heapAction = heap.Long1;                                          // Request a write
              ip = 48;
              heapClock = ~ heapClock;
        end

         48 :
        begin                                                                   // moveLong2
if (0) begin
  $display("AAAA %4d %4d moveLong2", steps, ip);
end
              heapArray  = localMem[1];                                                 // Array to write to
              heapIndex  = 2;                                                 // Index of element to write to
              heapIn     = 3;                                                  // Index of element to write to
              heapAction = heap.Long2;                                          // Request a write
              ip = 49;
              heapClock = ~ heapClock;
        end

         49 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              heapAction = heap.Size;
              heapArray  = localMem[0];
              ip = 50;
              heapClock = ~ heapClock;
        end

         50 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[10] = heapOut;
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = 0;
              ip = 53;
        end

         53 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 54;
        end

         54 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[11] >= localMem[10] ? 62 : 55;
        end

         55 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = localMem[11];                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 56;
              heapClock = ~ heapClock;
        end

         56 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[20] = heapOut;                                                     // Data retrieved from heap memory
              ip = 57;
              heapClock = ~ heapClock;
        end

         57 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = localMem[20];
              ip = 58;
        end

         58 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[12];
              outMemPos = outMemPos + 1;
              ip = 59;
        end

         59 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 60;
        end

         60 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[11] = localMem[11] + 1;
              ip = 61;
        end

         61 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 53;
        end

         62 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 63;
        end

         63 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              heapAction = heap.Size;
              heapArray  = localMem[1];
              ip = 64;
              heapClock = ~ heapClock;
        end

         64 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[13] = heapOut;
              ip = 65;
        end

         65 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 66;
        end

         66 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = 0;
              ip = 67;
        end

         67 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 68;
        end

         68 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[14] >= localMem[13] ? 76 : 69;
        end

         69 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = localMem[14];                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 70;
              heapClock = ~ heapClock;
        end

         70 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[21] = heapOut;                                                     // Data retrieved from heap memory
              ip = 71;
              heapClock = ~ heapClock;
        end

         71 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = localMem[21];
              ip = 72;
        end

         72 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[15];
              outMemPos = outMemPos + 1;
              ip = 73;
        end

         73 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 74;
        end

         74 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[14] = localMem[14] + 1;
              ip = 75;
        end

         75 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 67;
        end

         76 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 77;
        end
      endcase
      if (0 && 0) begin
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
      success  = success && outMem[8] == 100;
      success  = success && outMem[9] == 101;
      success  = success && outMem[10] == 102;
      success  = success && outMem[11] == 103;
      success  = success && outMem[12] == 104;
      success  = success && outMem[13] == 105;
      success  = success && outMem[14] == 106;
      success  = success && outMem[15] == 107;
      success  = success && outMem[16] == 0;
      success  = success && outMem[17] == 1;
      success  = success && outMem[18] == 2;
      success  = success && outMem[19] == 3;
      success  = success && outMem[20] == 4;
      success  = success && outMem[21] == 5;
      success  = success && outMem[22] == 6;
      success  = success && outMem[23] == 7;
      success  = success && outMem[24] == 100;
      success  = success && outMem[25] == 101;
      success  = success && outMem[26] == 4;
      success  = success && outMem[27] == 5;
      success  = success && outMem[28] == 6;
      success  = success && outMem[29] == 105;
      success  = success && outMem[30] == 106;
      success  = success && outMem[31] == 107;
      finished = steps >    410;
    end
  end

endmodule
// Check double frees, over allocation
// Check access to unallocated arrays or elements
// Check push overflow, pop underflow
// Next Message 10000280
module Memory
#(parameter integer ADDRESS_BITS =  8,                                          // Number of bits in an address
  parameter integer INDEX_BITS   =  3,                                          // Bits in in an index
  parameter integer DATA_BITS    = 16)                                          // Width of an element in bits
 (input wire                    clock,                                          // Clock to drive array operations
  input wire[7:0]               action,                                         // Operation to be performed on array
  input wire [ADDRESS_BITS-1:0] array,                                          // The number of the array to work on
  input wire [INDEX_BITS  -1:0] index,                                          // Index within array
  input wire [DATA_BITS   -1:0] in,                                             // Input data
  output reg [DATA_BITS   -1:0] out,                                            // Output data
  output reg [31:0]             error);                                         // Error

  parameter integer ARRAY_LENGTH = 2**INDEX_BITS;                               // Maximum index
  parameter integer ARRAYS       = 2**ADDRESS_BITS;                             // Number of memory elements for both arrays and elements

  parameter integer Reset       =  1;                                           // Zero all memory sizes
  parameter integer Write       =  2;                                           // Write an element
  parameter integer Read        =  3;                                           // Read an element
  parameter integer Size        =  4;                                           // Size of array
  parameter integer Inc         =  5;                                           // Increment size of array if possible
  parameter integer Dec         =  6;                                           // Decrement size of array if possible
  parameter integer Index       =  7;                                           // Index of element in array
  parameter integer Less        =  8;                                           // Elements of array less than in
  parameter integer Greater     =  9;                                           // Elements of array greater than in
  parameter integer Up          = 10;                                           // Move array up
  parameter integer Down        = 11;                                           // Move array down
  parameter integer Long1       = 12;                                           // Move long first step
  parameter integer Long2       = 13;                                           // Move long last  step
  parameter integer Push        = 14;                                           // Push if possible
  parameter integer Pop         = 15;                                           // Pop if possible
  parameter integer Dump        = 16;                                           // Dump
  parameter integer Resize      = 17;                                           // Resize an array
  parameter integer Alloc       = 18;                                           // Allocate a new array before using it
  parameter integer Free        = 19;                                           // Free an array for reuse
  parameter integer Add         = 20;                                           // Add to an element returning the new value
  parameter integer AddAfter    = 21;                                           // Add to an element returning the previous value
  parameter integer Subtract    = 22;                                           // Subtract to an element returning the new value
  parameter integer SubAfter    = 23;                                           // Subtract to an element returning the previous value
  parameter integer ShiftLeft   = 24;                                           // Shift left
  parameter integer ShiftRight  = 25;                                           // Shift right
  parameter integer NotLogical  = 26;                                           // Not - logical
  parameter integer Not         = 27;                                           // Not - bitwise
  parameter integer Or          = 28;                                           // Or
  parameter integer Xor         = 29;                                           // Xor
  parameter integer And         = 30;                                           // And

  reg [DATA_BITS   -1:0] memory     [ARRAYS-1:0][ARRAY_LENGTH-1:0];             // Memory containing arrays in fixed blocks
  reg [DATA_BITS   -1:0] copy                   [ARRAY_LENGTH-1:0];             // Copy of one array
  reg [INDEX_BITS    :0] arraySizes [ARRAYS-1:0];                               // Current size of each array
  reg [ADDRESS_BITS-1:0] freedArrays[ARRAYS-1:0];                               // Currently freed arrays
  reg                    allocations[ARRAYS-1:0];                               // Currently allocated arrays

  integer allocatedArrays;                                                      // Arrays allocated
  integer freedArraysTop;                                                       // Top of the freed arrays stack
  integer result;                                                               // Result of each array operation
  integer size;                                                                 // Size of current array
  integer moveLongStartArray;                                                   // Source array of move long
  integer moveLongStartIndex;                                                   // Source index of move long
  integer i, a, b;                                                              // Index

  task checkWriteable(integer input err);                                       // Check a memory is writable
    begin
       error = 0;
       if (array >= allocatedArrays) begin
         $display("Array has not been allocated, array %d", array);
         error = err;
       end
       if (!allocations[array]) begin
         $display("Array has been freed, array %d", array);
         error = err + 1;
       end
    end
  endtask

  task checkReadable(integer input err);                                        // Check a memory locationis readable
    begin
       checkWriteable(err);
       if (index >= arraySizes[array]) begin
         $display("Access outside array bounds, array %d, size: %d, access: %d", array, arraySizes[array], index);
         error = err + 2;
       end
    end
  endtask

  task dump();                                                                  // Dump some memory
    begin
      $display("    %2d %2d %2d", arraySizes[0], arraySizes[1], arraySizes[2]);
      for(i = 0; i < ARRAY_LENGTH; ++i) $display("%2d  %2d %2d %2d", i, memory[0][i], memory[1][i], memory[2][i]);
    end
  endtask

  always @(clock) begin                                                         // Each transition
    case(action)                                                                // Decode request
      Reset: begin                                                              // Reset
        freedArraysTop = 0;                                                     // Free all arrays
        allocatedArrays = 0;
      end

      Write: begin                                                              // Write
        checkWriteable(10000010);
        if (!error) begin
          memory[array][index] = in;
          if (index >= arraySizes[array] && index < ARRAY_LENGTH) begin
            arraySizes[array] = index + 1;
          end
          out = in;
        end
      end

      Read: begin                                                               // Read
        checkReadable(10000020);
        if (!error) begin
          out = memory[array][index];
        end
      end

      Size: begin                                                               // Size
        checkWriteable(10000030);
        if (!error) begin
          out = arraySizes[array];
        end
      end

      Dec: begin                                                                // Decrement
        checkWriteable(10000040);
        if (!error) begin
          if (arraySizes[array] > 0) arraySizes[array] = arraySizes[array] - 1;
          else begin
            $display("Attempt to decrement empty array, array %d", array); error = 10000044;
          end
        end
      end

      Inc: begin                                                                // Increment
        checkWriteable(10000050);
        if (!error) begin
          if (arraySizes[array] < ARRAY_LENGTH) arraySizes[array] = arraySizes[array] + 1;
          else begin
            $display("Attempt to decrement full array, array %d", array);  error = 10000054;
          end
        end
      end

      Index: begin                                                              // Index
        checkWriteable(10000060);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] == in) result = i + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      Less: begin                                                               // Count less
        checkWriteable(10000070);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] < in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      Greater: begin                                                            // Count greater
        checkWriteable(10000080);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] > in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      Down: begin                                                               // Down
        checkWriteable(10000270);
        if (!error) begin
          size   = arraySizes[array];
          if (size > 0) begin
            for(i = 0; i < ARRAY_LENGTH; i = i + 1) copy[i] = memory[array][i]; // Copy source array
            for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin                       // Move original array up
              if (i > index && i <= size) begin
                memory[array][i-1] = copy[i];
              end
            end
            out = copy[index];                                                  // Return replaced value
            arraySizes[array] = arraySizes[array] - 1;                          // Decrease array size
          end
          else error = 100000274;                                               // Orignal array was emoty so we cannot shift it down
        end
      end

      Up: begin                                                                 // Up
        checkWriteable(10000090);
        if (!error) begin
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) copy[i] = memory[array][i];   // Copy source array
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin                         // Move original array up
            if (i > index && i <= size) begin
              memory[array][i] = copy[i-1];
            end
          end
          memory[array][index] = in;                                            // Insert new value
          if (size < ARRAY_LENGTH) arraySizes[array] = arraySizes[array] + 1;   // Increase array size
        end
      end

      Long1: begin                                                              // Move long start
        checkReadable(10000100);
        if (!error) begin
          moveLongStartArray = array;                                           // Record source
          moveLongStartIndex = index;
        end
      end

      Long2: begin                                                              // Move long finish
        checkWriteable(10000110);
        if (!error) begin
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin                         // Copy from source to target
            if (i < in && index + i < ARRAY_LENGTH && moveLongStartIndex+i < ARRAY_LENGTH) begin
              memory[array][index+i] = memory[moveLongStartArray][moveLongStartIndex+i];
              if (index+i >= arraySizes[array]) arraySizes[array] = index+i+1;
            end
          end
        end
      end

      Push: begin                                                               // Push
        checkWriteable(10000120);
        if (!error) begin
          if (arraySizes[array] < ARRAY_LENGTH) begin
            memory[array][arraySizes[array]] = in;
            arraySizes[array] = arraySizes[array] + 1;
          end
          else begin
            $display("Attempt to push to full array, array %d, value %d", array, in);  error = 10000124;
          end
        end
      end

      Pop: begin                                                                // Pop
        checkWriteable(10000130);
        if (!error) begin
          if (arraySizes[array] > 0) begin
            arraySizes[array] = arraySizes[array] - 1;
            out = memory[array][arraySizes[array]];
          end
          else begin
            $display("Attempt to pop empty array, array %d", array); error = 10000134;
          end
        end
      end

      Dump: begin                                                               // Dump
        dump();
      end

      Resize: begin                                                             // Resize
        checkWriteable(10000140);
        if (!error) begin
          if (in <= ARRAY_LENGTH) arraySizes[array] = in;
          else begin
            $display("Attempt to make an array too large, array %d, max %d, size %d", array, ARRAY_LENGTH, in); error = 10000144;
          end
        end
      end

      Alloc: begin                                                              // Allocate an array
        if (freedArraysTop > 0) begin                                           // Reuse a freed array
          freedArraysTop = freedArraysTop - 1;
          result = freedArrays[freedArraysTop];
        end
        else if (allocatedArrays < ARRAYS-1) begin                              // Allocate a new array - assumes enough memory
          result          = allocatedArrays;
          allocatedArrays = allocatedArrays + 1;
        end
        else begin
          $display("Out of memory, cannot allocate a new array"); error = 10000270;
        end
        allocations[result] = 1;                                                // Allocated
        arraySizes[result] = 0;                                                 // Empty array
        out = result;
      end

      Free: begin                                                               // Free an array
        checkWriteable(10000150);
        if (!error) begin
          freedArrays[freedArraysTop] = array;                                  // Relies on the user not re freeing a freed array - we should probably hve another array to prevent this
          allocations[freedArraysTop] = 0;                                      // No longer allocated
          freedArraysTop = freedArraysTop + 1;
        end
      end

      Add: begin                                                                // Add to an element
        checkReadable(10000160);
        if (!error) begin
          memory[array][index] = memory[array][index] + in;
          out = memory[array][index];
        end
      end
      AddAfter: begin                                                           // Add to an element after putting the content of the element on out
        checkReadable(10000170);
        if (!error) begin
        out = memory[array][index];
        memory[array][index] = memory[array][index] + in;
        end
      end

      Subtract: begin                                                           // Subtract from an element
        checkReadable(10000180);
        if (!error) begin
          memory[array][index] = memory[array][index] - in;
          out = memory[array][index];
        end
      end
      SubAfter: begin                                                           // Subtract from an element after putting the content of the element on out
        checkReadable(10000190);
        if (!error) begin
          out = memory[array][index];
          memory[array][index] = memory[array][index] - in;
        end
      end

      ShiftLeft: begin                                                          // Shift left
        checkReadable(10000200);
        if (!error) begin
          memory[array][index] = memory[array][index] << in;
          out = memory[array][index];
        end
      end
      ShiftRight: begin                                                         // Shift right
        checkReadable(10000210);
        if (!error) begin
          memory[array][index] = memory[array][index] >> in;
          out = memory[array][index];
        end
      end
      NotLogical: begin                                                         // Not logical
        checkReadable(10000220);
        if (!error) begin
          if (memory[array][index] == 0) memory[array][index] = 1;
          else                           memory[array][index] = 0;
          out = memory[array][index];
        end
      end
      Not: begin                                                                // Not
        checkReadable(10000230);
        if (!error) begin
          memory[array][index] = ~memory[array][index];
          out = memory[array][index];
        end
      end
      Or: begin                                                                 // Or
        checkReadable(10000240);
        if (!error) begin
          memory[array][index] = memory[array][index] | in;
          out = memory[array][index];
        end
      end
      Xor: begin                                                                // Xor
        checkReadable(10000250);
        if (!error) begin
          memory[array][index] = memory[array][index] ^ in;
          out = memory[array][index];
        end
      end
      And: begin                                                                // And
        checkReadable(10000260);
        if (!error) begin
          memory[array][index] = memory[array][index] & in;
          out = memory[array][index];
        end
      end
    endcase
  end
endmodule
