// Check double frees, over allocation
// Check access to unallocated arrays or elements
// Check push overflow, pop underflow
// Next Message 10000280
`define Reset        1  /* Zero all memory sizes                               */
`define Write        2  /* Write an element                                    */
`define Read         3  /* Read an element                                     */
`define Size         4  /* Size of array                                       */
`define Inc          5  /* Increment size of array if possible                 */
`define Dec          6  /* Decrement size of array if possible                 */
`define Index        7  /* Index of element in array                           */
`define Less         8  /* Elements of array less than in                      */
`define Greater      9  /* Elements of array greater than in                   */
`define Up          10  /* Move array up                                       */
`define Down        11  /* Move array down                                     */
`define Long1       12  /* Move long first step                                */
`define Long2       13  /* Move long last  step                                */
`define Push        14  /* Push if possible                                    */
`define Pop         15  /* Pop if possible                                     */
`define Dump        16  /* Dump                                                */
`define Resize      17  /* Resize an array                                     */
`define Alloc       18  /* Allocate a new array before using it                */
`define Free        19  /* Free an array for reuse                             */
`define Add         20  /* Add to an element returning the new value           */
`define AddAfter    21  /* Add to an element returning the previous value      */
`define Subtract    22  /* Subtract to an element returning the new value      */
`define SubAfter    23  /* Subtract to an element returning the previous value */
`define ShiftLeft   24  /* Shift left                                          */
`define ShiftRight  25  /* Shift right                                         */
`define NotLogical  26  /* Not - logical                                       */
`define Not         27  /* Not - bitwise                                       */
`define Or          28  /* Or                                                  */
`define Xor         29  /* Xor                                                 */
`define And         30  /* And                                                 */

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
         //$display("Array has not been allocated, array %d", array);
         error = err;
       end
       if (!allocations[array]) begin
         //$display("Array has been freed, array %d", array);
         error = err + 1;
       end
    end
  endtask

  task checkReadable(input integer err);                                        // Check a memory locationis readable
    begin
       checkWriteable(err);
       if (index >= arraySizes[array]) begin
         //$display("Access outside array bounds, array %d, size: %d, access: %d", array, arraySizes[array], index);
         error = err + 2;
       end
    end
  endtask

  task dump;                                                                    // Dump some memory
    begin
      //$display("    %2d %2d %2d", arraySizes[0], arraySizes[1], arraySizes[2]);
      for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
        //$display("%2d  %2d %2d %2d", i, memory[0][i], memory[1][i], memory[2][i]);
      end
    end
  endtask

  always @(clock) begin                                                             // Each transition
    case(action)                                                                // Decode request
      `Reset: begin                                                             // Reset
        freedArraysTop = 0;                                                     // Free all arrays
        allocatedArrays = 0;
      end

      `Write: begin                                                             // Write
        checkWriteable(10000010);
        if (!error) begin
          memory[array][index] = in;
          if (index >= arraySizes[array] && index < ARRAY_LENGTH) begin
            arraySizes[array] = index + 1;
          end
          out = in;
        end
      end

      `Read: begin                                                              // Read
        checkReadable(10000020);
        if (!error) begin
          out = memory[array][index];
        end
      end

      `Size: begin                                                              // Size
        checkWriteable(10000030);
        if (!error) begin
          out = arraySizes[array];
        end
      end

      `Dec: begin                                                               // Decrement
        checkWriteable(10000040);
        if (!error) begin
          if (arraySizes[array] > 0) arraySizes[array] = arraySizes[array] - 1;
          else begin
            //$display("Attempt to decrement empty array, array %d", array); error = 10000044;
          end
        end
      end

      `Inc: begin                                                               // Increment
        checkWriteable(10000050);
        if (!error) begin
          if (arraySizes[array] < ARRAY_LENGTH) arraySizes[array] = arraySizes[array] + 1;
          else begin
            //$display("Attempt to decrement full array, array %d", array);  error = 10000054;
          end
        end
      end

      `Index: begin                                                             // Index
        checkWriteable(10000060);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] == in) result = i + 1;
////$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      `Less: begin                                                              // Count less
        checkWriteable(10000070);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] < in) result = result + 1;
////$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      `Greater: begin                                                           // Count greater
        checkWriteable(10000080);
        if (!error) begin
          result = 0;
          size   = arraySizes[array];
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] > in) result = result + 1;
////$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
          end
          out = result;
        end
      end

      `Down: begin                                                              // Down
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

      `Up: begin                                                                // Up
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

      `Long1: begin                                                             // Move long start
        checkReadable(10000100);
        if (!error) begin
          moveLongStartArray = array;                                           // Record source
          moveLongStartIndex = index;
        end
      end

      `Long2: begin                                                             // Move long finish
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

      `Push: begin                                                              // Push
        checkWriteable(10000120);
        if (!error) begin
          if (arraySizes[array] < ARRAY_LENGTH) begin
            memory[array][arraySizes[array]] = in;
            arraySizes[array] = arraySizes[array] + 1;
          end
          else begin
            //$display("Attempt to push to full array, array %d, value %d", array, in);  error = 10000124;
          end
        end
      end

      `Pop: begin                                                               // Pop
        checkWriteable(10000130);
        if (!error) begin
          if (arraySizes[array] > 0) begin
            arraySizes[array] = arraySizes[array] - 1;
            out = memory[array][arraySizes[array]];
          end
          else begin
            //$display("Attempt to pop empty array, array %d", array); error = 10000134;
          end
        end
      end

      `Dump: begin                                                              // Dump
        dump();
      end

      `Resize: begin                                                            // Resize
        checkWriteable(10000140);
        if (!error) begin
          if (in <= ARRAY_LENGTH) arraySizes[array] = in;
          else begin
            //$display("Attempt to make an array too large, array %d, max %d, size %d", array, ARRAY_LENGTH, in); error = 10000144;
          end
        end
      end

      `Alloc: begin                                                             // Allocate an array
        if (freedArraysTop > 0) begin                                           // Reuse a freed array
          freedArraysTop = freedArraysTop - 1;
          result = freedArrays[freedArraysTop];
        end
        else if (allocatedArrays < ARRAYS-1) begin                              // Allocate a new array - assumes enough memory
          result          = allocatedArrays;
          allocatedArrays = allocatedArrays + 1;
        end
        else begin
          //$display("Out of memory, cannot allocate a new array"); error = 10000270;
        end
        allocations[result] = 1;                                                // Allocated
        arraySizes[result] = 0;                                                 // Empty array
        out = result;
      end

      `Free: begin                                                              // Free an array
        checkWriteable(10000150);
        if (!error) begin
          freedArrays[freedArraysTop] = array;                                  // Relies on the user not re freeing a freed array - we should probably hve another array to prevent this
          allocations[freedArraysTop] = 0;                                      // No longer allocated
          freedArraysTop = freedArraysTop + 1;
        end
      end

      `Add: begin                                                               // Add to an element
        checkReadable(10000160);
        if (!error) begin
          memory[array][index] = memory[array][index] + in;
          out = memory[array][index];
        end
      end

      `AddAfter: begin                                                          // Add to an element after putting the content of the element on out
        checkReadable(10000170);
        if (!error) begin
        out = memory[array][index];
        memory[array][index] = memory[array][index] + in;
        end
      end

      `Subtract: begin                                                          // Subtract from an element
        checkReadable(10000180);
        if (!error) begin
          memory[array][index] = memory[array][index] - in;
          out = memory[array][index];
        end
      end

      `SubAfter: begin                                                          // Subtract from an element after putting the content of the element on out
        checkReadable(10000190);
        if (!error) begin
          out = memory[array][index];
          memory[array][index] = memory[array][index] - in;
        end
      end

      `ShiftLeft: begin                                                         // Shift left
        checkReadable(10000200);
        if (!error) begin
          memory[array][index] = memory[array][index] << in;
          out = memory[array][index];
        end
      end

      `ShiftRight: begin                                                        // Shift right
        checkReadable(10000210);
        if (!error) begin
          memory[array][index] = memory[array][index] >> in;
          out = memory[array][index];
        end
      end

      `NotLogical: begin                                                        // Not logical
        checkReadable(10000220);
        if (!error) begin
          memory[array][index] = !memory[array][index];
          out = memory[array][index];
        end
      end

      `Not: begin                                                               // Not
        checkReadable(10000230);
        if (!error) begin
          memory[array][index] = ~memory[array][index];
          out = memory[array][index];
        end
      end

      `Or: begin                                                                // Or
        checkReadable(10000240);
        if (!error) begin
          memory[array][index] = memory[array][index] | in;
          out = memory[array][index];
        end
      end

      `Xor: begin                                                               // Xor
        checkReadable(10000250);
        if (!error) begin
          memory[array][index] = memory[array][index] ^ in;
          out = memory[array][index];
        end
      end

      `And: begin                                                               // And
        checkReadable(10000260);
        if (!error) begin
          memory[array][index] = memory[array][index] & in;
          out = memory[array][index];
        end
      end
    endcase
  end
endmodule
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
   #(       4,        3,       12)                          // Address bits, index bits, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
  reg [      12-1:0] localMem[     173-1:0];                       // Local memory
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

    end
    else begin
      steps = steps + 1;
      case(ip)

          0 :
        begin                                                                   // start
          //$display("AAAA %4d %4d start", steps, ip);
              heapClock = 0;                                                    // Ready for next operation
              ip = 1;
        end

          1 :
        begin                                                                   // start2
          //$display("AAAA %4d %4d start2", steps, ip);
              heapAction = `Reset;                                          // Ready for next operation
              ip = 2;
              heapClock = ~ heapClock;
        end

          2 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 3;
              heapClock = ~ heapClock;
        end

          3 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[0] = heapOut;
              ip = 4;
        end

          4 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[54] = 7;
              ip = 5;
        end

          5 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[54];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 6;
              heapClock = ~ heapClock;
        end

          6 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[55] = 0;
              ip = 7;
        end

          7 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[55];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 8;
              heapClock = ~ heapClock;
        end

          8 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[56] = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[56];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 10;
              heapClock = ~ heapClock;
        end

         10 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[57] = 0;
              ip = 11;
        end

         11 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[57];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 12;
              heapClock = ~ heapClock;
        end

         12 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 13;
              heapClock = ~ heapClock;
        end

         13 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[1] = heapOut;
              ip = 14;
        end

         14 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[58] = 0;
              ip = 15;
        end

         15 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[58];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 16;
              heapClock = ~ heapClock;
        end

         16 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[59] = 0;
              ip = 17;
        end

         17 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[59];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 18;
              heapClock = ~ heapClock;
        end

         18 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 19;
              heapClock = ~ heapClock;
        end

         19 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[2] = heapOut;
              ip = 20;
        end

         20 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[60] = localMem[2];
              ip = 21;
        end

         21 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[60];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 22;
              heapClock = ~ heapClock;
        end

         22 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 23;
              heapClock = ~ heapClock;
        end

         23 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[3] = heapOut;
              ip = 24;
        end

         24 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[61] = localMem[3];
              ip = 25;
        end

         25 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[61];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 26;
              heapClock = ~ heapClock;
        end

         26 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[62] = 0;
              ip = 27;
        end

         27 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[62];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 28;
              heapClock = ~ heapClock;
        end

         28 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[63] = localMem[0];
              ip = 29;
        end

         29 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[63];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 30;
              heapClock = ~ heapClock;
        end

         30 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 31;
              heapClock = ~ heapClock;
        end

         31 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[64] = heapOut;                                                     // Data retrieved from heap memory
              ip = 32;
              heapClock = ~ heapClock;
        end

         32 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[65] = localMem[64] + 1;
              ip = 33;
        end

         33 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[65];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 34;
              heapClock = ~ heapClock;
        end

         34 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 35;
              heapClock = ~ heapClock;
        end

         35 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[66] = heapOut;                                                     // Data retrieved from heap memory
              ip = 36;
              heapClock = ~ heapClock;
        end

         36 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[67] = localMem[66];
              ip = 37;
        end

         37 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[67];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 38;
              heapClock = ~ heapClock;
        end

         38 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 39;
              heapClock = ~ heapClock;
        end

         39 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[4] = heapOut;
              ip = 40;
        end

         40 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[68] = localMem[4];
              ip = 41;
        end

         41 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[68];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 42;
              heapClock = ~ heapClock;
        end

         42 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 43;
              heapClock = ~ heapClock;
        end

         43 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[5] = heapOut;
              ip = 44;
        end

         44 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[69] = 0;
              ip = 45;
        end

         45 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[69];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 46;
              heapClock = ~ heapClock;
        end

         46 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[70] = 0;
              ip = 47;
        end

         47 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[70];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 48;
              heapClock = ~ heapClock;
        end

         48 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 49;
              heapClock = ~ heapClock;
        end

         49 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[6] = heapOut;
              ip = 50;
        end

         50 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[71] = localMem[6];
              ip = 51;
        end

         51 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[71];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 52;
              heapClock = ~ heapClock;
        end

         52 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 53;
              heapClock = ~ heapClock;
        end

         53 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[7] = heapOut;
              ip = 54;
        end

         54 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[72] = localMem[7];
              ip = 55;
        end

         55 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[72];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 56;
              heapClock = ~ heapClock;
        end

         56 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[73] = 0;
              ip = 57;
        end

         57 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[73];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 58;
              heapClock = ~ heapClock;
        end

         58 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[74] = localMem[0];
              ip = 59;
        end

         59 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[74];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 60;
              heapClock = ~ heapClock;
        end

         60 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 61;
              heapClock = ~ heapClock;
        end

         61 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[75] = heapOut;                                                     // Data retrieved from heap memory
              ip = 62;
              heapClock = ~ heapClock;
        end

         62 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[76] = localMem[75] + 1;
              ip = 63;
        end

         63 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[76];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 64;
              heapClock = ~ heapClock;
        end

         64 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 65;
              heapClock = ~ heapClock;
        end

         65 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[77] = heapOut;                                                     // Data retrieved from heap memory
              ip = 66;
              heapClock = ~ heapClock;
        end

         66 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[78] = localMem[77];
              ip = 67;
        end

         67 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[78];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 68;
              heapClock = ~ heapClock;
        end

         68 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `heapAlloc;
              ip = 69;
              heapClock = ~ heapClock;
        end

         69 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[8] = heapOut;
              ip = 70;
        end

         70 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[79] = localMem[8];
              ip = 71;
        end

         71 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[79];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 72;
              heapClock = ~ heapClock;
        end

         72 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[80] = 7;
              ip = 73;
        end

         73 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[80];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 74;
              heapClock = ~ heapClock;
        end

         74 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[81] = 7;
              ip = 75;
        end

         75 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[81];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 76;
              heapClock = ~ heapClock;
        end

         76 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 77;
              heapClock = ~ heapClock;
        end

         77 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[82] = heapOut;                                                     // Data retrieved from heap memory
              ip = 78;
              heapClock = ~ heapClock;
        end

         78 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[9] = localMem[82];
              ip = 79;
        end

         79 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[83] = 1000;
              ip = 80;
        end

         80 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[9];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[83];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 81;
              heapClock = ~ heapClock;
        end

         81 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 82;
              heapClock = ~ heapClock;
        end

         82 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[84] = heapOut;                                                     // Data retrieved from heap memory
              ip = 83;
              heapClock = ~ heapClock;
        end

         83 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[10] = localMem[84];
              ip = 84;
        end

         84 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[85] = 2010;
              ip = 85;
        end

         85 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[10];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[85];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 86;
              heapClock = ~ heapClock;
        end

         86 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 87;
              heapClock = ~ heapClock;
        end

         87 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[86] = heapOut;                                                     // Data retrieved from heap memory
              ip = 88;
              heapClock = ~ heapClock;
        end

         88 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[11] = localMem[86];
              ip = 89;
        end

         89 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[87] = 1000;
              ip = 90;
        end

         90 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[11];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[87];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 91;
              heapClock = ~ heapClock;
        end

         91 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 92;
              heapClock = ~ heapClock;
        end

         92 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[88] = heapOut;                                                     // Data retrieved from heap memory
              ip = 93;
              heapClock = ~ heapClock;
        end

         93 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[12] = localMem[88];
              ip = 94;
        end

         94 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[89] = 2010;
              ip = 95;
        end

         95 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[12];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[89];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 96;
              heapClock = ~ heapClock;
        end

         96 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 97;
              heapClock = ~ heapClock;
        end

         97 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[90] = heapOut;                                                     // Data retrieved from heap memory
              ip = 98;
              heapClock = ~ heapClock;
        end

         98 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[13] = localMem[90];
              ip = 99;
        end

         99 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[91] = 50;
              ip = 100;
        end

        100 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[13];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[91];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 101;
              heapClock = ~ heapClock;
        end

        101 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 102;
              heapClock = ~ heapClock;
        end

        102 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[92] = heapOut;                                                     // Data retrieved from heap memory
              ip = 103;
              heapClock = ~ heapClock;
        end

        103 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[14] = localMem[92];
              ip = 104;
        end

        104 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[93] = 2005;
              ip = 105;
        end

        105 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[14];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[93];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 106;
              heapClock = ~ heapClock;
        end

        106 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 107;
              heapClock = ~ heapClock;
        end

        107 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[94] = heapOut;                                                     // Data retrieved from heap memory
              ip = 108;
              heapClock = ~ heapClock;
        end

        108 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[15] = localMem[94];
              ip = 109;
        end

        109 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[95] = 2000;
              ip = 110;
        end

        110 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[15];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[95];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 111;
              heapClock = ~ heapClock;
        end

        111 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 112;
              heapClock = ~ heapClock;
        end

        112 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[96] = heapOut;                                                     // Data retrieved from heap memory
              ip = 113;
              heapClock = ~ heapClock;
        end

        113 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[16] = localMem[96];
              ip = 114;
        end

        114 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[97] = 2020;
              ip = 115;
        end

        115 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[16];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[97];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 116;
              heapClock = ~ heapClock;
        end

        116 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 117;
              heapClock = ~ heapClock;
        end

        117 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[98] = heapOut;                                                     // Data retrieved from heap memory
              ip = 118;
              heapClock = ~ heapClock;
        end

        118 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[17] = localMem[98];
              ip = 119;
        end

        119 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[99] = 2000;
              ip = 120;
        end

        120 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[17];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[99];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 121;
              heapClock = ~ heapClock;
        end

        121 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 122;
              heapClock = ~ heapClock;
        end

        122 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[100] = heapOut;                                                     // Data retrieved from heap memory
              ip = 123;
              heapClock = ~ heapClock;
        end

        123 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[18] = localMem[100];
              ip = 124;
        end

        124 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[101] = 2020;
              ip = 125;
        end

        125 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[18];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[101];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 126;
              heapClock = ~ heapClock;
        end

        126 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 127;
              heapClock = ~ heapClock;
        end

        127 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[102] = heapOut;                                                     // Data retrieved from heap memory
              ip = 128;
              heapClock = ~ heapClock;
        end

        128 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[19] = localMem[102];
              ip = 129;
        end

        129 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[103] = 1050;
              ip = 130;
        end

        130 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[19];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[103];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 131;
              heapClock = ~ heapClock;
        end

        131 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 132;
              heapClock = ~ heapClock;
        end

        132 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[104] = heapOut;                                                     // Data retrieved from heap memory
              ip = 133;
              heapClock = ~ heapClock;
        end

        133 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[20] = localMem[104];
              ip = 134;
        end

        134 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[105] = 2015;
              ip = 135;
        end

        135 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[20];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[105];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 136;
              heapClock = ~ heapClock;
        end

        136 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 137;
              heapClock = ~ heapClock;
        end

        137 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[106] = heapOut;                                                     // Data retrieved from heap memory
              ip = 138;
              heapClock = ~ heapClock;
        end

        138 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[21] = localMem[106];
              ip = 139;
        end

        139 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[107] = 3000;
              ip = 140;
        end

        140 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[21];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[107];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 141;
              heapClock = ~ heapClock;
        end

        141 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 142;
              heapClock = ~ heapClock;
        end

        142 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[108] = heapOut;                                                     // Data retrieved from heap memory
              ip = 143;
              heapClock = ~ heapClock;
        end

        143 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[22] = localMem[108];
              ip = 144;
        end

        144 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[109] = 2030;
              ip = 145;
        end

        145 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[22];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[109];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 146;
              heapClock = ~ heapClock;
        end

        146 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 147;
              heapClock = ~ heapClock;
        end

        147 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[110] = heapOut;                                                     // Data retrieved from heap memory
              ip = 148;
              heapClock = ~ heapClock;
        end

        148 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[23] = localMem[110];
              ip = 149;
        end

        149 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[111] = 3000;
              ip = 150;
        end

        150 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[23];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[111];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 151;
              heapClock = ~ heapClock;
        end

        151 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 152;
              heapClock = ~ heapClock;
        end

        152 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[112] = heapOut;                                                     // Data retrieved from heap memory
              ip = 153;
              heapClock = ~ heapClock;
        end

        153 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[24] = localMem[112];
              ip = 154;
        end

        154 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[113] = 2030;
              ip = 155;
        end

        155 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[24];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[113];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 156;
              heapClock = ~ heapClock;
        end

        156 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 157;
              heapClock = ~ heapClock;
        end

        157 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[114] = heapOut;                                                     // Data retrieved from heap memory
              ip = 158;
              heapClock = ~ heapClock;
        end

        158 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[25] = localMem[114];
              ip = 159;
        end

        159 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[115] = 2050;
              ip = 160;
        end

        160 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[25];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[115];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 161;
              heapClock = ~ heapClock;
        end

        161 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 162;
              heapClock = ~ heapClock;
        end

        162 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[116] = heapOut;                                                     // Data retrieved from heap memory
              ip = 163;
              heapClock = ~ heapClock;
        end

        163 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[26] = localMem[116];
              ip = 164;
        end

        164 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[117] = 2025;
              ip = 165;
        end

        165 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[26];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[117];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 166;
              heapClock = ~ heapClock;
        end

        166 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 167;
              heapClock = ~ heapClock;
        end

        167 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[118] = heapOut;                                                     // Data retrieved from heap memory
              ip = 168;
              heapClock = ~ heapClock;
        end

        168 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[27] = localMem[118];
              ip = 169;
        end

        169 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[119] = 4000;
              ip = 170;
        end

        170 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[27];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[119];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 171;
              heapClock = ~ heapClock;
        end

        171 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 172;
              heapClock = ~ heapClock;
        end

        172 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[120] = heapOut;                                                     // Data retrieved from heap memory
              ip = 173;
              heapClock = ~ heapClock;
        end

        173 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[28] = localMem[120];
              ip = 174;
        end

        174 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[121] = 2040;
              ip = 175;
        end

        175 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[28];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[121];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 176;
              heapClock = ~ heapClock;
        end

        176 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 177;
              heapClock = ~ heapClock;
        end

        177 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[122] = heapOut;                                                     // Data retrieved from heap memory
              ip = 178;
              heapClock = ~ heapClock;
        end

        178 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[29] = localMem[122];
              ip = 179;
        end

        179 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[123] = 4000;
              ip = 180;
        end

        180 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[29];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[123];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 181;
              heapClock = ~ heapClock;
        end

        181 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 182;
              heapClock = ~ heapClock;
        end

        182 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[124] = heapOut;                                                     // Data retrieved from heap memory
              ip = 183;
              heapClock = ~ heapClock;
        end

        183 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[30] = localMem[124];
              ip = 184;
        end

        184 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[125] = 2040;
              ip = 185;
        end

        185 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[30];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[125];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 186;
              heapClock = ~ heapClock;
        end

        186 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 187;
              heapClock = ~ heapClock;
        end

        187 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[126] = heapOut;                                                     // Data retrieved from heap memory
              ip = 188;
              heapClock = ~ heapClock;
        end

        188 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[31] = localMem[126];
              ip = 189;
        end

        189 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[127] = 3050;
              ip = 190;
        end

        190 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[31];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[127];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 191;
              heapClock = ~ heapClock;
        end

        191 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 192;
              heapClock = ~ heapClock;
        end

        192 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[128] = heapOut;                                                     // Data retrieved from heap memory
              ip = 193;
              heapClock = ~ heapClock;
        end

        193 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[32] = localMem[128];
              ip = 194;
        end

        194 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[129] = 2035;
              ip = 195;
        end

        195 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[32];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[129];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 196;
              heapClock = ~ heapClock;
        end

        196 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 197;
              heapClock = ~ heapClock;
        end

        197 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[130] = heapOut;                                                     // Data retrieved from heap memory
              ip = 198;
              heapClock = ~ heapClock;
        end

        198 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[33] = localMem[130];
              ip = 199;
        end

        199 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[131] = 5000;
              ip = 200;
        end

        200 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[33];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[131];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 201;
              heapClock = ~ heapClock;
        end

        201 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 202;
              heapClock = ~ heapClock;
        end

        202 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[132] = heapOut;                                                     // Data retrieved from heap memory
              ip = 203;
              heapClock = ~ heapClock;
        end

        203 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[34] = localMem[132];
              ip = 204;
        end

        204 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[133] = 2050;
              ip = 205;
        end

        205 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[34];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[133];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 206;
              heapClock = ~ heapClock;
        end

        206 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 207;
              heapClock = ~ heapClock;
        end

        207 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[134] = heapOut;                                                     // Data retrieved from heap memory
              ip = 208;
              heapClock = ~ heapClock;
        end

        208 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[35] = localMem[134];
              ip = 209;
        end

        209 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[135] = 5000;
              ip = 210;
        end

        210 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[35];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[135];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 211;
              heapClock = ~ heapClock;
        end

        211 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 212;
              heapClock = ~ heapClock;
        end

        212 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[136] = heapOut;                                                     // Data retrieved from heap memory
              ip = 213;
              heapClock = ~ heapClock;
        end

        213 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[36] = localMem[136];
              ip = 214;
        end

        214 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[137] = 2050;
              ip = 215;
        end

        215 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[36];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[137];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 216;
              heapClock = ~ heapClock;
        end

        216 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 217;
              heapClock = ~ heapClock;
        end

        217 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[138] = heapOut;                                                     // Data retrieved from heap memory
              ip = 218;
              heapClock = ~ heapClock;
        end

        218 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[37] = localMem[138];
              ip = 219;
        end

        219 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[139] = 4050;
              ip = 220;
        end

        220 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[37];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[139];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 221;
              heapClock = ~ heapClock;
        end

        221 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 222;
              heapClock = ~ heapClock;
        end

        222 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[140] = heapOut;                                                     // Data retrieved from heap memory
              ip = 223;
              heapClock = ~ heapClock;
        end

        223 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[38] = localMem[140];
              ip = 224;
        end

        224 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[141] = 2045;
              ip = 225;
        end

        225 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[38];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[141];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 226;
              heapClock = ~ heapClock;
        end

        226 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 227;
              heapClock = ~ heapClock;
        end

        227 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[142] = heapOut;                                                     // Data retrieved from heap memory
              ip = 228;
              heapClock = ~ heapClock;
        end

        228 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[39] = localMem[142];
              ip = 229;
        end

        229 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[143] = 6000;
              ip = 230;
        end

        230 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[39];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[143];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 231;
              heapClock = ~ heapClock;
        end

        231 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 232;
              heapClock = ~ heapClock;
        end

        232 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[144] = heapOut;                                                     // Data retrieved from heap memory
              ip = 233;
              heapClock = ~ heapClock;
        end

        233 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[40] = localMem[144];
              ip = 234;
        end

        234 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[145] = 2060;
              ip = 235;
        end

        235 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[40];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[145];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 236;
              heapClock = ~ heapClock;
        end

        236 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 237;
              heapClock = ~ heapClock;
        end

        237 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[146] = heapOut;                                                     // Data retrieved from heap memory
              ip = 238;
              heapClock = ~ heapClock;
        end

        238 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[41] = localMem[146];
              ip = 239;
        end

        239 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[147] = 6000;
              ip = 240;
        end

        240 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[41];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[147];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 241;
              heapClock = ~ heapClock;
        end

        241 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 242;
              heapClock = ~ heapClock;
        end

        242 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[148] = heapOut;                                                     // Data retrieved from heap memory
              ip = 243;
              heapClock = ~ heapClock;
        end

        243 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[42] = localMem[148];
              ip = 244;
        end

        244 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[149] = 2060;
              ip = 245;
        end

        245 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[42];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[149];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 246;
              heapClock = ~ heapClock;
        end

        246 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 247;
              heapClock = ~ heapClock;
        end

        247 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[150] = heapOut;                                                     // Data retrieved from heap memory
              ip = 248;
              heapClock = ~ heapClock;
        end

        248 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[43] = localMem[150];
              ip = 249;
        end

        249 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[151] = 5050;
              ip = 250;
        end

        250 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[43];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[151];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 251;
              heapClock = ~ heapClock;
        end

        251 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 252;
              heapClock = ~ heapClock;
        end

        252 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[152] = heapOut;                                                     // Data retrieved from heap memory
              ip = 253;
              heapClock = ~ heapClock;
        end

        253 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[44] = localMem[152];
              ip = 254;
        end

        254 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[153] = 2055;
              ip = 255;
        end

        255 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[44];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[153];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 256;
              heapClock = ~ heapClock;
        end

        256 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 257;
              heapClock = ~ heapClock;
        end

        257 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[154] = heapOut;                                                     // Data retrieved from heap memory
              ip = 258;
              heapClock = ~ heapClock;
        end

        258 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[45] = localMem[154];
              ip = 259;
        end

        259 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[155] = 7000;
              ip = 260;
        end

        260 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[45];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[155];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 261;
              heapClock = ~ heapClock;
        end

        261 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 262;
              heapClock = ~ heapClock;
        end

        262 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[156] = heapOut;                                                     // Data retrieved from heap memory
              ip = 263;
              heapClock = ~ heapClock;
        end

        263 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[46] = localMem[156];
              ip = 264;
        end

        264 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[157] = 2070;
              ip = 265;
        end

        265 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[46];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[157];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 266;
              heapClock = ~ heapClock;
        end

        266 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 267;
              heapClock = ~ heapClock;
        end

        267 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[158] = heapOut;                                                     // Data retrieved from heap memory
              ip = 268;
              heapClock = ~ heapClock;
        end

        268 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[47] = localMem[158];
              ip = 269;
        end

        269 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[159] = 7000;
              ip = 270;
        end

        270 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[47];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[159];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 271;
              heapClock = ~ heapClock;
        end

        271 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 272;
              heapClock = ~ heapClock;
        end

        272 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[160] = heapOut;                                                     // Data retrieved from heap memory
              ip = 273;
              heapClock = ~ heapClock;
        end

        273 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[48] = localMem[160];
              ip = 274;
        end

        274 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[161] = 2070;
              ip = 275;
        end

        275 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[48];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[161];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 276;
              heapClock = ~ heapClock;
        end

        276 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 277;
              heapClock = ~ heapClock;
        end

        277 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[162] = heapOut;                                                     // Data retrieved from heap memory
              ip = 278;
              heapClock = ~ heapClock;
        end

        278 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[49] = localMem[162];
              ip = 279;
        end

        279 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[163] = 6050;
              ip = 280;
        end

        280 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[49];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[163];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 281;
              heapClock = ~ heapClock;
        end

        281 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 282;
              heapClock = ~ heapClock;
        end

        282 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[164] = heapOut;                                                     // Data retrieved from heap memory
              ip = 283;
              heapClock = ~ heapClock;
        end

        283 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[50] = localMem[164];
              ip = 284;
        end

        284 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[165] = 2065;
              ip = 285;
        end

        285 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[50];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[165];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 286;
              heapClock = ~ heapClock;
        end

        286 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[166] = localMem[1];
              ip = 287;
        end

        287 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[166];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 288;
              heapClock = ~ heapClock;
        end

        288 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 289;
              heapClock = ~ heapClock;
        end

        289 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[167] = heapOut;                                                     // Data retrieved from heap memory
              ip = 290;
              heapClock = ~ heapClock;
        end

        290 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[51] = localMem[167];
              ip = 291;
        end

        291 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[168] = 7500;
              ip = 292;
        end

        292 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[51];                                                // Array to write to
              heapIndex   = 7;                                                // Index of element to write to
              heapIn      = localMem[168];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 293;
              heapClock = ~ heapClock;
        end

        293 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 294;
              heapClock = ~ heapClock;
        end

        294 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[169] = heapOut;                                                     // Data retrieved from heap memory
              ip = 295;
              heapClock = ~ heapClock;
        end

        295 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[52] = localMem[169];
              ip = 296;
        end

        296 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[170] = 6;
              ip = 297;
        end

        297 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[52];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[170];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 298;
              heapClock = ~ heapClock;
        end

        298 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[5];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 299;
              heapClock = ~ heapClock;
        end

        299 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[171] = heapOut;                                                     // Data retrieved from heap memory
              ip = 300;
              heapClock = ~ heapClock;
        end

        300 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[53] = localMem[171];
              ip = 301;
        end

        301 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[172] = 2075;
              ip = 302;
        end

        302 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[53];                                                // Array to write to
              heapIndex   = 7;                                                // Index of element to write to
              heapIn      = localMem[172];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 303;
              heapClock = ~ heapClock;
        end
      endcase
      success  = 1;
      finished = steps >    304;
    end
  end

endmodule
