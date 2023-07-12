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
  reg [       4-1:0] heapArray;                                         // The number of the array to work on
  reg [       3-1:0] heapIndex;                                         // Index within array
  reg [      12-1:0] heapIn;                                            // Input data
  reg [      12-1:0] heapOut;                                           // Output data
  reg [31        :0] heapError;                                                 // Error on heap operation if not zero

  Memory                                                                        // Memory module
   #(       4,        3,       12)                          // Address bits, index buts, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
  reg [      12-1:0] localMem[     180-1:0];                       // Local memory
  reg [      12-1:0]   outMem[       1  -1:0];                       // Out channel
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
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[60] = 7;
              ip = 5;
        end

          5 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[60];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 6;
              heapClock = ~ heapClock;
        end

          6 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[61] = 0;
              ip = 7;
        end

          7 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[61];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 8;
              heapClock = ~ heapClock;
        end

          8 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[62] = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[62];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 10;
              heapClock = ~ heapClock;
        end

         10 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[63] = 0;
              ip = 11;
        end

         11 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[63];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 12;
              heapClock = ~ heapClock;
        end

         12 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 13;
              heapClock = ~ heapClock;
        end

         13 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[1] = heapOut;
              ip = 14;
        end

         14 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[64] = 0;
              ip = 15;
        end

         15 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[64];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 16;
              heapClock = ~ heapClock;
        end

         16 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[65] = 0;
              ip = 17;
        end

         17 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[65];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 18;
              heapClock = ~ heapClock;
        end

         18 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 19;
              heapClock = ~ heapClock;
        end

         19 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[2] = heapOut;
              ip = 20;
        end

         20 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[66] = localMem[2];
              ip = 21;
        end

         21 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[66];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 22;
              heapClock = ~ heapClock;
        end

         22 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 23;
              heapClock = ~ heapClock;
        end

         23 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[3] = heapOut;
              ip = 24;
        end

         24 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[67] = localMem[3];
              ip = 25;
        end

         25 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[67];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 26;
              heapClock = ~ heapClock;
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[68] = 0;
              ip = 27;
        end

         27 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[68];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 28;
              heapClock = ~ heapClock;
        end

         28 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[69] = localMem[0];
              ip = 29;
        end

         29 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[69];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 30;
              heapClock = ~ heapClock;
        end

         30 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 31;
              heapClock = ~ heapClock;
        end

         31 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[70] = heapOut;                                                     // Data retrieved from heap memory
              ip = 32;
              heapClock = ~ heapClock;
        end

         32 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[71] = localMem[70] + 1;
              ip = 33;
        end

         33 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[71];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 34;
              heapClock = ~ heapClock;
        end

         34 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 35;
              heapClock = ~ heapClock;
        end

         35 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[72] = heapOut;                                                     // Data retrieved from heap memory
              ip = 36;
              heapClock = ~ heapClock;
        end

         36 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[73] = localMem[72];
              ip = 37;
        end

         37 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[73];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 38;
              heapClock = ~ heapClock;
        end

         38 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 39;
              heapClock = ~ heapClock;
        end

         39 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[4] = heapOut;
              ip = 40;
        end

         40 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[74] = localMem[4];
              ip = 41;
        end

         41 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[74];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 42;
              heapClock = ~ heapClock;
        end

         42 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 43;
              heapClock = ~ heapClock;
        end

         43 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[5] = heapOut;
              ip = 44;
        end

         44 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[75] = 0;
              ip = 45;
        end

         45 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[75];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 46;
              heapClock = ~ heapClock;
        end

         46 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[76] = 0;
              ip = 47;
        end

         47 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[76];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 48;
              heapClock = ~ heapClock;
        end

         48 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 49;
              heapClock = ~ heapClock;
        end

         49 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[6] = heapOut;
              ip = 50;
        end

         50 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[77] = localMem[6];
              ip = 51;
        end

         51 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[77];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 52;
              heapClock = ~ heapClock;
        end

         52 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 53;
              heapClock = ~ heapClock;
        end

         53 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[7] = heapOut;
              ip = 54;
        end

         54 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[78] = localMem[7];
              ip = 55;
        end

         55 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[78];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 56;
              heapClock = ~ heapClock;
        end

         56 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[79] = 0;
              ip = 57;
        end

         57 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[79];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 58;
              heapClock = ~ heapClock;
        end

         58 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[80] = localMem[0];
              ip = 59;
        end

         59 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[80];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 60;
              heapClock = ~ heapClock;
        end

         60 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 61;
              heapClock = ~ heapClock;
        end

         61 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[81] = heapOut;                                                     // Data retrieved from heap memory
              ip = 62;
              heapClock = ~ heapClock;
        end

         62 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[82] = localMem[81] + 1;
              ip = 63;
        end

         63 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[82];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 64;
              heapClock = ~ heapClock;
        end

         64 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 65;
              heapClock = ~ heapClock;
        end

         65 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[83] = heapOut;                                                     // Data retrieved from heap memory
              ip = 66;
              heapClock = ~ heapClock;
        end

         66 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[84] = localMem[83];
              ip = 67;
        end

         67 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[84];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 68;
              heapClock = ~ heapClock;
        end

         68 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              heapAction = heap.Alloc;
              ip = 69;
              heapClock = ~ heapClock;
        end

         69 :
        begin                                                                   // movHeapOut
if (0) begin
  $display("AAAA %4d %4d movHeapOut", steps, ip);
end
              localMem[8] = heapOut;
              ip = 70;
        end

         70 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[85] = localMem[8];
              ip = 71;
        end

         71 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[85];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 72;
              heapClock = ~ heapClock;
        end

         72 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 73;
              heapClock = ~ heapClock;
        end

         73 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[86] = heapOut;                                                     // Data retrieved from heap memory
              ip = 74;
              heapClock = ~ heapClock;
        end

         74 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = localMem[86];
              ip = 75;
        end

         75 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[87] = 11;
              ip = 76;
        end

         76 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[9];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[87];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 77;
              heapClock = ~ heapClock;
        end

         77 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 78;
              heapClock = ~ heapClock;
        end

         78 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[88] = heapOut;                                                     // Data retrieved from heap memory
              ip = 79;
              heapClock = ~ heapClock;
        end

         79 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = localMem[88];
              ip = 80;
        end

         80 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[89] = 21;
              ip = 81;
        end

         81 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[10];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[89];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 82;
              heapClock = ~ heapClock;
        end

         82 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 83;
              heapClock = ~ heapClock;
        end

         83 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[90] = heapOut;                                                     // Data retrieved from heap memory
              ip = 84;
              heapClock = ~ heapClock;
        end

         84 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[11] = localMem[90];
              ip = 85;
        end

         85 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[91] = 31;
              ip = 86;
        end

         86 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[11];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[91];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 87;
              heapClock = ~ heapClock;
        end

         87 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 88;
              heapClock = ~ heapClock;
        end

         88 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[92] = heapOut;                                                     // Data retrieved from heap memory
              ip = 89;
              heapClock = ~ heapClock;
        end

         89 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = localMem[92];
              ip = 90;
        end

         90 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[93] = 41;
              ip = 91;
        end

         91 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[12];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[93];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 92;
              heapClock = ~ heapClock;
        end

         92 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 93;
              heapClock = ~ heapClock;
        end

         93 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[94] = heapOut;                                                     // Data retrieved from heap memory
              ip = 94;
              heapClock = ~ heapClock;
        end

         94 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = localMem[94];
              ip = 95;
        end

         95 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[95] = 51;
              ip = 96;
        end

         96 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[13];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[95];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 97;
              heapClock = ~ heapClock;
        end

         97 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 98;
              heapClock = ~ heapClock;
        end

         98 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[96] = heapOut;                                                     // Data retrieved from heap memory
              ip = 99;
              heapClock = ~ heapClock;
        end

         99 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = localMem[96];
              ip = 100;
        end

        100 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[97] = 61;
              ip = 101;
        end

        101 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[14];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[97];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 102;
              heapClock = ~ heapClock;
        end

        102 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 103;
              heapClock = ~ heapClock;
        end

        103 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[98] = heapOut;                                                     // Data retrieved from heap memory
              ip = 104;
              heapClock = ~ heapClock;
        end

        104 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = localMem[98];
              ip = 105;
        end

        105 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[99] = 12;
              ip = 106;
        end

        106 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[15];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[99];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 107;
              heapClock = ~ heapClock;
        end

        107 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 108;
              heapClock = ~ heapClock;
        end

        108 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[100] = heapOut;                                                     // Data retrieved from heap memory
              ip = 109;
              heapClock = ~ heapClock;
        end

        109 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = localMem[100];
              ip = 110;
        end

        110 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[101] = 22;
              ip = 111;
        end

        111 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[16];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[101];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 112;
              heapClock = ~ heapClock;
        end

        112 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 113;
              heapClock = ~ heapClock;
        end

        113 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[102] = heapOut;                                                     // Data retrieved from heap memory
              ip = 114;
              heapClock = ~ heapClock;
        end

        114 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = localMem[102];
              ip = 115;
        end

        115 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[103] = 32;
              ip = 116;
        end

        116 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[17];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[103];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 117;
              heapClock = ~ heapClock;
        end

        117 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 118;
              heapClock = ~ heapClock;
        end

        118 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[104] = heapOut;                                                     // Data retrieved from heap memory
              ip = 119;
              heapClock = ~ heapClock;
        end

        119 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[18] = localMem[104];
              ip = 120;
        end

        120 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[105] = 42;
              ip = 121;
        end

        121 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[18];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[105];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 122;
              heapClock = ~ heapClock;
        end

        122 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 123;
              heapClock = ~ heapClock;
        end

        123 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[106] = heapOut;                                                     // Data retrieved from heap memory
              ip = 124;
              heapClock = ~ heapClock;
        end

        124 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[19] = localMem[106];
              ip = 125;
        end

        125 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[107] = 52;
              ip = 126;
        end

        126 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[19];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[107];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 127;
              heapClock = ~ heapClock;
        end

        127 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 128;
              heapClock = ~ heapClock;
        end

        128 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[108] = heapOut;                                                     // Data retrieved from heap memory
              ip = 129;
              heapClock = ~ heapClock;
        end

        129 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[20] = localMem[108];
              ip = 130;
        end

        130 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[109] = 62;
              ip = 131;
        end

        131 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[20];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[109];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 132;
              heapClock = ~ heapClock;
        end

        132 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 133;
              heapClock = ~ heapClock;
        end

        133 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[110] = heapOut;                                                     // Data retrieved from heap memory
              ip = 134;
              heapClock = ~ heapClock;
        end

        134 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[21] = localMem[110];
              ip = 135;
        end

        135 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[111] = 13;
              ip = 136;
        end

        136 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[21];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[111];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 137;
              heapClock = ~ heapClock;
        end

        137 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 138;
              heapClock = ~ heapClock;
        end

        138 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[112] = heapOut;                                                     // Data retrieved from heap memory
              ip = 139;
              heapClock = ~ heapClock;
        end

        139 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[22] = localMem[112];
              ip = 140;
        end

        140 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[113] = 23;
              ip = 141;
        end

        141 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[22];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[113];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 142;
              heapClock = ~ heapClock;
        end

        142 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 143;
              heapClock = ~ heapClock;
        end

        143 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[114] = heapOut;                                                     // Data retrieved from heap memory
              ip = 144;
              heapClock = ~ heapClock;
        end

        144 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = localMem[114];
              ip = 145;
        end

        145 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[115] = 33;
              ip = 146;
        end

        146 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[23];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[115];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 147;
              heapClock = ~ heapClock;
        end

        147 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 148;
              heapClock = ~ heapClock;
        end

        148 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[116] = heapOut;                                                     // Data retrieved from heap memory
              ip = 149;
              heapClock = ~ heapClock;
        end

        149 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[24] = localMem[116];
              ip = 150;
        end

        150 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[117] = 43;
              ip = 151;
        end

        151 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[24];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[117];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 152;
              heapClock = ~ heapClock;
        end

        152 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 153;
              heapClock = ~ heapClock;
        end

        153 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[118] = heapOut;                                                     // Data retrieved from heap memory
              ip = 154;
              heapClock = ~ heapClock;
        end

        154 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[25] = localMem[118];
              ip = 155;
        end

        155 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[119] = 53;
              ip = 156;
        end

        156 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[25];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[119];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 157;
              heapClock = ~ heapClock;
        end

        157 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 158;
              heapClock = ~ heapClock;
        end

        158 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[120] = heapOut;                                                     // Data retrieved from heap memory
              ip = 159;
              heapClock = ~ heapClock;
        end

        159 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[26] = localMem[120];
              ip = 160;
        end

        160 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[121] = 63;
              ip = 161;
        end

        161 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[26];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[121];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 162;
              heapClock = ~ heapClock;
        end

        162 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 163;
              heapClock = ~ heapClock;
        end

        163 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[122] = heapOut;                                                     // Data retrieved from heap memory
              ip = 164;
              heapClock = ~ heapClock;
        end

        164 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[27] = localMem[122];
              ip = 165;
        end

        165 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[123] = 14;
              ip = 166;
        end

        166 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[27];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[123];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 167;
              heapClock = ~ heapClock;
        end

        167 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 168;
              heapClock = ~ heapClock;
        end

        168 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[124] = heapOut;                                                     // Data retrieved from heap memory
              ip = 169;
              heapClock = ~ heapClock;
        end

        169 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[28] = localMem[124];
              ip = 170;
        end

        170 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[125] = 24;
              ip = 171;
        end

        171 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[28];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[125];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 172;
              heapClock = ~ heapClock;
        end

        172 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 173;
              heapClock = ~ heapClock;
        end

        173 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[126] = heapOut;                                                     // Data retrieved from heap memory
              ip = 174;
              heapClock = ~ heapClock;
        end

        174 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[29] = localMem[126];
              ip = 175;
        end

        175 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[127] = 34;
              ip = 176;
        end

        176 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[29];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[127];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 177;
              heapClock = ~ heapClock;
        end

        177 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 178;
              heapClock = ~ heapClock;
        end

        178 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[128] = heapOut;                                                     // Data retrieved from heap memory
              ip = 179;
              heapClock = ~ heapClock;
        end

        179 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[30] = localMem[128];
              ip = 180;
        end

        180 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[129] = 44;
              ip = 181;
        end

        181 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[30];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[129];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 182;
              heapClock = ~ heapClock;
        end

        182 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 183;
              heapClock = ~ heapClock;
        end

        183 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[130] = heapOut;                                                     // Data retrieved from heap memory
              ip = 184;
              heapClock = ~ heapClock;
        end

        184 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[31] = localMem[130];
              ip = 185;
        end

        185 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[131] = 54;
              ip = 186;
        end

        186 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[31];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[131];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 187;
              heapClock = ~ heapClock;
        end

        187 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 188;
              heapClock = ~ heapClock;
        end

        188 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[132] = heapOut;                                                     // Data retrieved from heap memory
              ip = 189;
              heapClock = ~ heapClock;
        end

        189 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[32] = localMem[132];
              ip = 190;
        end

        190 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[133] = 64;
              ip = 191;
        end

        191 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[32];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[133];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 192;
              heapClock = ~ heapClock;
        end

        192 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 193;
              heapClock = ~ heapClock;
        end

        193 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[134] = heapOut;                                                     // Data retrieved from heap memory
              ip = 194;
              heapClock = ~ heapClock;
        end

        194 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[33] = localMem[134];
              ip = 195;
        end

        195 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[135] = 15;
              ip = 196;
        end

        196 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[33];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[135];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 197;
              heapClock = ~ heapClock;
        end

        197 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 198;
              heapClock = ~ heapClock;
        end

        198 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[136] = heapOut;                                                     // Data retrieved from heap memory
              ip = 199;
              heapClock = ~ heapClock;
        end

        199 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[34] = localMem[136];
              ip = 200;
        end

        200 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[137] = 25;
              ip = 201;
        end

        201 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[34];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[137];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 202;
              heapClock = ~ heapClock;
        end

        202 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 203;
              heapClock = ~ heapClock;
        end

        203 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[138] = heapOut;                                                     // Data retrieved from heap memory
              ip = 204;
              heapClock = ~ heapClock;
        end

        204 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[35] = localMem[138];
              ip = 205;
        end

        205 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[139] = 35;
              ip = 206;
        end

        206 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[35];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[139];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 207;
              heapClock = ~ heapClock;
        end

        207 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 208;
              heapClock = ~ heapClock;
        end

        208 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[140] = heapOut;                                                     // Data retrieved from heap memory
              ip = 209;
              heapClock = ~ heapClock;
        end

        209 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[36] = localMem[140];
              ip = 210;
        end

        210 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[141] = 45;
              ip = 211;
        end

        211 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[36];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[141];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 212;
              heapClock = ~ heapClock;
        end

        212 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 213;
              heapClock = ~ heapClock;
        end

        213 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[142] = heapOut;                                                     // Data retrieved from heap memory
              ip = 214;
              heapClock = ~ heapClock;
        end

        214 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[37] = localMem[142];
              ip = 215;
        end

        215 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[143] = 55;
              ip = 216;
        end

        216 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[37];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[143];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 217;
              heapClock = ~ heapClock;
        end

        217 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 218;
              heapClock = ~ heapClock;
        end

        218 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[144] = heapOut;                                                     // Data retrieved from heap memory
              ip = 219;
              heapClock = ~ heapClock;
        end

        219 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[38] = localMem[144];
              ip = 220;
        end

        220 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[145] = 65;
              ip = 221;
        end

        221 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[38];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[145];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 222;
              heapClock = ~ heapClock;
        end

        222 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 223;
              heapClock = ~ heapClock;
        end

        223 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[146] = heapOut;                                                     // Data retrieved from heap memory
              ip = 224;
              heapClock = ~ heapClock;
        end

        224 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[39] = localMem[146];
              ip = 225;
        end

        225 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[147] = 16;
              ip = 226;
        end

        226 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[39];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[147];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 227;
              heapClock = ~ heapClock;
        end

        227 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 228;
              heapClock = ~ heapClock;
        end

        228 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[148] = heapOut;                                                     // Data retrieved from heap memory
              ip = 229;
              heapClock = ~ heapClock;
        end

        229 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[40] = localMem[148];
              ip = 230;
        end

        230 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[149] = 26;
              ip = 231;
        end

        231 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[40];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[149];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 232;
              heapClock = ~ heapClock;
        end

        232 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 233;
              heapClock = ~ heapClock;
        end

        233 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[150] = heapOut;                                                     // Data retrieved from heap memory
              ip = 234;
              heapClock = ~ heapClock;
        end

        234 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[41] = localMem[150];
              ip = 235;
        end

        235 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[151] = 36;
              ip = 236;
        end

        236 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[41];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[151];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 237;
              heapClock = ~ heapClock;
        end

        237 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 238;
              heapClock = ~ heapClock;
        end

        238 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[152] = heapOut;                                                     // Data retrieved from heap memory
              ip = 239;
              heapClock = ~ heapClock;
        end

        239 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[42] = localMem[152];
              ip = 240;
        end

        240 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[153] = 46;
              ip = 241;
        end

        241 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[42];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[153];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 242;
              heapClock = ~ heapClock;
        end

        242 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 243;
              heapClock = ~ heapClock;
        end

        243 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[154] = heapOut;                                                     // Data retrieved from heap memory
              ip = 244;
              heapClock = ~ heapClock;
        end

        244 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[43] = localMem[154];
              ip = 245;
        end

        245 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[155] = 56;
              ip = 246;
        end

        246 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[43];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[155];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 247;
              heapClock = ~ heapClock;
        end

        247 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 248;
              heapClock = ~ heapClock;
        end

        248 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[156] = heapOut;                                                     // Data retrieved from heap memory
              ip = 249;
              heapClock = ~ heapClock;
        end

        249 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[44] = localMem[156];
              ip = 250;
        end

        250 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[157] = 66;
              ip = 251;
        end

        251 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[44];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[157];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 252;
              heapClock = ~ heapClock;
        end

        252 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 253;
              heapClock = ~ heapClock;
        end

        253 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[158] = heapOut;                                                     // Data retrieved from heap memory
              ip = 254;
              heapClock = ~ heapClock;
        end

        254 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[45] = localMem[158];
              ip = 255;
        end

        255 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[159] = 17;
              ip = 256;
        end

        256 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[45];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[159];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 257;
              heapClock = ~ heapClock;
        end

        257 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 258;
              heapClock = ~ heapClock;
        end

        258 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[160] = heapOut;                                                     // Data retrieved from heap memory
              ip = 259;
              heapClock = ~ heapClock;
        end

        259 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[46] = localMem[160];
              ip = 260;
        end

        260 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[161] = 27;
              ip = 261;
        end

        261 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[46];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[161];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 262;
              heapClock = ~ heapClock;
        end

        262 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 263;
              heapClock = ~ heapClock;
        end

        263 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[162] = heapOut;                                                     // Data retrieved from heap memory
              ip = 264;
              heapClock = ~ heapClock;
        end

        264 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[47] = localMem[162];
              ip = 265;
        end

        265 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[163] = 37;
              ip = 266;
        end

        266 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[47];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[163];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 267;
              heapClock = ~ heapClock;
        end

        267 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 268;
              heapClock = ~ heapClock;
        end

        268 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[164] = heapOut;                                                     // Data retrieved from heap memory
              ip = 269;
              heapClock = ~ heapClock;
        end

        269 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[48] = localMem[164];
              ip = 270;
        end

        270 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[165] = 47;
              ip = 271;
        end

        271 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[48];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[165];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 272;
              heapClock = ~ heapClock;
        end

        272 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 273;
              heapClock = ~ heapClock;
        end

        273 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[166] = heapOut;                                                     // Data retrieved from heap memory
              ip = 274;
              heapClock = ~ heapClock;
        end

        274 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[49] = localMem[166];
              ip = 275;
        end

        275 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[167] = 57;
              ip = 276;
        end

        276 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[49];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[167];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 277;
              heapClock = ~ heapClock;
        end

        277 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 278;
              heapClock = ~ heapClock;
        end

        278 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[168] = heapOut;                                                     // Data retrieved from heap memory
              ip = 279;
              heapClock = ~ heapClock;
        end

        279 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[50] = localMem[168];
              ip = 280;
        end

        280 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[169] = 67;
              ip = 281;
        end

        281 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[50];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[169];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 282;
              heapClock = ~ heapClock;
        end

        282 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 283;
              heapClock = ~ heapClock;
        end

        283 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[170] = heapOut;                                                     // Data retrieved from heap memory
              ip = 284;
              heapClock = ~ heapClock;
        end

        284 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[51] = localMem[170];
              ip = 285;
        end

        285 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[171] = 97;
              ip = 286;
        end

        286 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[51];                                                // Array to write to
              heapIndex   = 7;                                                // Index of element to write to
              heapIn      = localMem[171];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 287;
              heapClock = ~ heapClock;
        end

        287 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 288;
              heapClock = ~ heapClock;
        end

        288 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[172] = heapOut;                                                     // Data retrieved from heap memory
              ip = 289;
              heapClock = ~ heapClock;
        end

        289 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[52] = localMem[172];
              ip = 290;
        end

        290 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[173] = 99;
              ip = 291;
        end

        291 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapArray   = localMem[52];                                                // Array to write to
              heapIndex   = 7;                                                // Index of element to write to
              heapIn      = localMem[173];                                                 // Data to write
              heapAction  = heap.Write;                                         // Request a write
              ip = 292;
              heapClock = ~ heapClock;
        end

        292 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 293;
              heapClock = ~ heapClock;
        end

        293 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[174] = heapOut;                                                     // Data retrieved from heap memory
              ip = 294;
              heapClock = ~ heapClock;
        end

        294 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[53] = localMem[174];
              ip = 295;
        end

        295 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 296;
              heapClock = ~ heapClock;
        end

        296 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[175] = heapOut;                                                     // Data retrieved from heap memory
              ip = 297;
              heapClock = ~ heapClock;
        end

        297 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[54] = localMem[175];
              ip = 298;
        end

        298 :
        begin                                                                   // moveLong1
if (0) begin
  $display("AAAA %4d %4d moveLong1", steps, ip);
end
              heapArray  = localMem[53];                                                 // Array to write to
              heapIndex  = 3;                                                 // Index of element to write to
              heapAction = heap.Long1;                                          // Request a write
              ip = 299;
              heapClock = ~ heapClock;
        end

        299 :
        begin                                                                   // moveLong2
if (0) begin
  $display("AAAA %4d %4d moveLong2", steps, ip);
end
              heapArray  = localMem[54];                                                 // Array to write to
              heapIndex  = 0;                                                 // Index of element to write to
              heapIn     = 2;                                                  // Index of element to write to
              heapAction = heap.Long2;                                          // Request a write
              ip = 300;
              heapClock = ~ heapClock;
        end

        300 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 301;
              heapClock = ~ heapClock;
        end

        301 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[176] = heapOut;                                                     // Data retrieved from heap memory
              ip = 302;
              heapClock = ~ heapClock;
        end

        302 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[55] = localMem[176];
              ip = 303;
        end

        303 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 304;
              heapClock = ~ heapClock;
        end

        304 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[177] = heapOut;                                                     // Data retrieved from heap memory
              ip = 305;
              heapClock = ~ heapClock;
        end

        305 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[56] = localMem[177];
              ip = 306;
        end

        306 :
        begin                                                                   // moveLong1
if (0) begin
  $display("AAAA %4d %4d moveLong1", steps, ip);
end
              heapArray  = localMem[55];                                                 // Array to write to
              heapIndex  = 3;                                                 // Index of element to write to
              heapAction = heap.Long1;                                          // Request a write
              ip = 307;
              heapClock = ~ heapClock;
        end

        307 :
        begin                                                                   // moveLong2
if (0) begin
  $display("AAAA %4d %4d moveLong2", steps, ip);
end
              heapArray  = localMem[56];                                                 // Array to write to
              heapIndex  = 0;                                                 // Index of element to write to
              heapIn     = 2;                                                  // Index of element to write to
              heapAction = heap.Long2;                                          // Request a write
              ip = 308;
              heapClock = ~ heapClock;
        end

        308 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 309;
              heapClock = ~ heapClock;
        end

        309 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[178] = heapOut;                                                     // Data retrieved from heap memory
              ip = 310;
              heapClock = ~ heapClock;
        end

        310 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[57] = localMem[178];
              ip = 311;
        end

        311 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = heap.Read;                                           // Request a read, not a write
              ip = 312;
              heapClock = ~ heapClock;
        end

        312 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[179] = heapOut;                                                     // Data retrieved from heap memory
              ip = 313;
              heapClock = ~ heapClock;
        end

        313 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[58] = localMem[179];
              ip = 314;
        end

        314 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[59] = 2 + 1;
              ip = 315;
        end

        315 :
        begin                                                                   // moveLong1
if (0) begin
  $display("AAAA %4d %4d moveLong1", steps, ip);
end
              heapArray  = localMem[57];                                                 // Array to write to
              heapIndex  = 3;                                                 // Index of element to write to
              heapAction = heap.Long1;                                          // Request a write
              ip = 316;
              heapClock = ~ heapClock;
        end

        316 :
        begin                                                                   // moveLong2
if (0) begin
  $display("AAAA %4d %4d moveLong2", steps, ip);
end
              heapArray  = localMem[58];                                                 // Array to write to
              heapIndex  = 0;                                                 // Index of element to write to
              heapIn     = localMem[59];                                                  // Index of element to write to
              heapAction = heap.Long2;                                          // Request a write
              ip = 317;
              heapClock = ~ heapClock;
        end
      endcase
      if (0 && 0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      finished = steps >    318;
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

  task checkWriteable(input integer err);                                       // Check a memory is writable
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

  task checkReadable(input integer err);                                        // Check a memory locationis readable
    begin
       checkWriteable(err);
       if (index >= arraySizes[array]) begin
         $display("Access outside array bounds, array %d, size: %d, access: %d", array, arraySizes[array], index);
         error = err + 2;
       end
    end
  endtask

  task dump;                                                                    // Dump some memory
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
