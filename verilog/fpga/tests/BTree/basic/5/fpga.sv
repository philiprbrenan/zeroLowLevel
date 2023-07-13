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
  reg [       3-1:0] heapArray;                                         // The number of the array to work on
  reg [       4-1:0] heapIndex;                                         // Index within array
  reg [      12-1:0] heapIn;                                            // Input data
  reg [      12-1:0] heapOut;                                           // Output data
  reg [31        :0] heapError;                                                 // Error on heap operation if not zero

  Memory                                                                        // Memory module
   #(       3,        4,       12)                          // Address bits, index bits, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
  reg [      12-1:0] localMem[      96-1:0];                       // Local memory
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
              heapAction = `Alloc;
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
              localMem[31] = 7;
              ip = 5;
        end

          5 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[31];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 6;
              heapClock = ~ heapClock;
        end

          6 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[32] = 0;
              ip = 7;
        end

          7 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[32];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 8;
              heapClock = ~ heapClock;
        end

          8 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[33] = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[33];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 10;
              heapClock = ~ heapClock;
        end

         10 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[34] = 0;
              ip = 11;
        end

         11 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[34];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 12;
              heapClock = ~ heapClock;
        end

         12 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
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
              localMem[35] = 0;
              ip = 15;
        end

         15 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[35];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 16;
              heapClock = ~ heapClock;
        end

         16 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[36] = 0;
              ip = 17;
        end

         17 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[36];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 18;
              heapClock = ~ heapClock;
        end

         18 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
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
              localMem[37] = localMem[2];
              ip = 21;
        end

         21 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[37];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 22;
              heapClock = ~ heapClock;
        end

         22 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
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
              localMem[38] = localMem[3];
              ip = 25;
        end

         25 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[38];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 26;
              heapClock = ~ heapClock;
        end

         26 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[39] = 0;
              ip = 27;
        end

         27 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[39];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 28;
              heapClock = ~ heapClock;
        end

         28 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[40] = localMem[0];
              ip = 29;
        end

         29 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[40];                                                 // Data to write
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
              localMem[41] = heapOut;                                                     // Data retrieved from heap memory
              ip = 32;
              heapClock = ~ heapClock;
        end

         32 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[42] = localMem[41] + 1;
              ip = 33;
        end

         33 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[42];                                                 // Data to write
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
              localMem[43] = heapOut;                                                     // Data retrieved from heap memory
              ip = 36;
              heapClock = ~ heapClock;
        end

         36 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[44] = localMem[43];
              ip = 37;
        end

         37 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[44];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 38;
              heapClock = ~ heapClock;
        end

         38 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
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
              localMem[45] = localMem[4];
              ip = 41;
        end

         41 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[45];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 42;
              heapClock = ~ heapClock;
        end

         42 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[46] = 7;
              ip = 43;
        end

         43 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[46];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 44;
              heapClock = ~ heapClock;
        end

         44 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 45;
              heapClock = ~ heapClock;
        end

         45 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[47] = heapOut;                                                     // Data retrieved from heap memory
              ip = 46;
              heapClock = ~ heapClock;
        end

         46 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[5] = localMem[47];
              ip = 47;
        end

         47 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[48] = 10;
              ip = 48;
        end

         48 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[5];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[48];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 49;
              heapClock = ~ heapClock;
        end

         49 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 50;
              heapClock = ~ heapClock;
        end

         50 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[49] = heapOut;                                                     // Data retrieved from heap memory
              ip = 51;
              heapClock = ~ heapClock;
        end

         51 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[6] = localMem[49];
              ip = 52;
        end

         52 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[50] = 10;
              ip = 53;
        end

         53 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[6];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[50];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 54;
              heapClock = ~ heapClock;
        end

         54 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 55;
              heapClock = ~ heapClock;
        end

         55 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[51] = heapOut;                                                     // Data retrieved from heap memory
              ip = 56;
              heapClock = ~ heapClock;
        end

         56 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[7] = localMem[51];
              ip = 57;
        end

         57 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[52] = 5;
              ip = 58;
        end

         58 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[7];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[52];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 59;
              heapClock = ~ heapClock;
        end

         59 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 60;
              heapClock = ~ heapClock;
        end

         60 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[53] = heapOut;                                                     // Data retrieved from heap memory
              ip = 61;
              heapClock = ~ heapClock;
        end

         61 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[8] = localMem[53];
              ip = 62;
        end

         62 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[54] = 20;
              ip = 63;
        end

         63 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[8];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[54];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 64;
              heapClock = ~ heapClock;
        end

         64 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 65;
              heapClock = ~ heapClock;
        end

         65 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[55] = heapOut;                                                     // Data retrieved from heap memory
              ip = 66;
              heapClock = ~ heapClock;
        end

         66 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[9] = localMem[55];
              ip = 67;
        end

         67 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[56] = 20;
              ip = 68;
        end

         68 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[9];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[56];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 69;
              heapClock = ~ heapClock;
        end

         69 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 70;
              heapClock = ~ heapClock;
        end

         70 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[57] = heapOut;                                                     // Data retrieved from heap memory
              ip = 71;
              heapClock = ~ heapClock;
        end

         71 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[10] = localMem[57];
              ip = 72;
        end

         72 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[58] = 15;
              ip = 73;
        end

         73 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[10];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[58];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 74;
              heapClock = ~ heapClock;
        end

         74 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 75;
              heapClock = ~ heapClock;
        end

         75 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[59] = heapOut;                                                     // Data retrieved from heap memory
              ip = 76;
              heapClock = ~ heapClock;
        end

         76 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[11] = localMem[59];
              ip = 77;
        end

         77 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[60] = 30;
              ip = 78;
        end

         78 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[11];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[60];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 79;
              heapClock = ~ heapClock;
        end

         79 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 80;
              heapClock = ~ heapClock;
        end

         80 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[61] = heapOut;                                                     // Data retrieved from heap memory
              ip = 81;
              heapClock = ~ heapClock;
        end

         81 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[12] = localMem[61];
              ip = 82;
        end

         82 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[62] = 30;
              ip = 83;
        end

         83 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[12];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[62];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 84;
              heapClock = ~ heapClock;
        end

         84 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 85;
              heapClock = ~ heapClock;
        end

         85 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[63] = heapOut;                                                     // Data retrieved from heap memory
              ip = 86;
              heapClock = ~ heapClock;
        end

         86 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[13] = localMem[63];
              ip = 87;
        end

         87 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[64] = 25;
              ip = 88;
        end

         88 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[13];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[64];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 89;
              heapClock = ~ heapClock;
        end

         89 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 90;
              heapClock = ~ heapClock;
        end

         90 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[65] = heapOut;                                                     // Data retrieved from heap memory
              ip = 91;
              heapClock = ~ heapClock;
        end

         91 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[14] = localMem[65];
              ip = 92;
        end

         92 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[66] = 40;
              ip = 93;
        end

         93 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[14];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[66];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 94;
              heapClock = ~ heapClock;
        end

         94 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 95;
              heapClock = ~ heapClock;
        end

         95 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[67] = heapOut;                                                     // Data retrieved from heap memory
              ip = 96;
              heapClock = ~ heapClock;
        end

         96 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[15] = localMem[67];
              ip = 97;
        end

         97 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[68] = 40;
              ip = 98;
        end

         98 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[15];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[68];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 99;
              heapClock = ~ heapClock;
        end

         99 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 100;
              heapClock = ~ heapClock;
        end

        100 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[69] = heapOut;                                                     // Data retrieved from heap memory
              ip = 101;
              heapClock = ~ heapClock;
        end

        101 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[16] = localMem[69];
              ip = 102;
        end

        102 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[70] = 35;
              ip = 103;
        end

        103 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[16];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[70];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 104;
              heapClock = ~ heapClock;
        end

        104 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 105;
              heapClock = ~ heapClock;
        end

        105 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[71] = heapOut;                                                     // Data retrieved from heap memory
              ip = 106;
              heapClock = ~ heapClock;
        end

        106 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[17] = localMem[71];
              ip = 107;
        end

        107 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[72] = 50;
              ip = 108;
        end

        108 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[17];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[72];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 109;
              heapClock = ~ heapClock;
        end

        109 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 110;
              heapClock = ~ heapClock;
        end

        110 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[73] = heapOut;                                                     // Data retrieved from heap memory
              ip = 111;
              heapClock = ~ heapClock;
        end

        111 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[18] = localMem[73];
              ip = 112;
        end

        112 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[74] = 50;
              ip = 113;
        end

        113 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[18];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[74];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 114;
              heapClock = ~ heapClock;
        end

        114 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 115;
              heapClock = ~ heapClock;
        end

        115 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[75] = heapOut;                                                     // Data retrieved from heap memory
              ip = 116;
              heapClock = ~ heapClock;
        end

        116 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[19] = localMem[75];
              ip = 117;
        end

        117 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[76] = 45;
              ip = 118;
        end

        118 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[19];                                                // Array to write to
              heapIndex   = 4;                                                // Index of element to write to
              heapIn      = localMem[76];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 119;
              heapClock = ~ heapClock;
        end

        119 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 120;
              heapClock = ~ heapClock;
        end

        120 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[77] = heapOut;                                                     // Data retrieved from heap memory
              ip = 121;
              heapClock = ~ heapClock;
        end

        121 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[20] = localMem[77];
              ip = 122;
        end

        122 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[78] = 60;
              ip = 123;
        end

        123 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[20];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[78];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 124;
              heapClock = ~ heapClock;
        end

        124 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 125;
              heapClock = ~ heapClock;
        end

        125 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[79] = heapOut;                                                     // Data retrieved from heap memory
              ip = 126;
              heapClock = ~ heapClock;
        end

        126 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[21] = localMem[79];
              ip = 127;
        end

        127 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[80] = 60;
              ip = 128;
        end

        128 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[21];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[80];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 129;
              heapClock = ~ heapClock;
        end

        129 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 130;
              heapClock = ~ heapClock;
        end

        130 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[81] = heapOut;                                                     // Data retrieved from heap memory
              ip = 131;
              heapClock = ~ heapClock;
        end

        131 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[22] = localMem[81];
              ip = 132;
        end

        132 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[82] = 55;
              ip = 133;
        end

        133 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[22];                                                // Array to write to
              heapIndex   = 5;                                                // Index of element to write to
              heapIn      = localMem[82];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 134;
              heapClock = ~ heapClock;
        end

        134 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 135;
              heapClock = ~ heapClock;
        end

        135 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[83] = heapOut;                                                     // Data retrieved from heap memory
              ip = 136;
              heapClock = ~ heapClock;
        end

        136 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[23] = localMem[83];
              ip = 137;
        end

        137 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[84] = 70;
              ip = 138;
        end

        138 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[23];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[84];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 139;
              heapClock = ~ heapClock;
        end

        139 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 140;
              heapClock = ~ heapClock;
        end

        140 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[85] = heapOut;                                                     // Data retrieved from heap memory
              ip = 141;
              heapClock = ~ heapClock;
        end

        141 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[24] = localMem[85];
              ip = 142;
        end

        142 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[86] = 70;
              ip = 143;
        end

        143 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[24];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[86];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 144;
              heapClock = ~ heapClock;
        end

        144 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 145;
              heapClock = ~ heapClock;
        end

        145 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[87] = heapOut;                                                     // Data retrieved from heap memory
              ip = 146;
              heapClock = ~ heapClock;
        end

        146 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[25] = localMem[87];
              ip = 147;
        end

        147 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[88] = 65;
              ip = 148;
        end

        148 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[25];                                                // Array to write to
              heapIndex   = 6;                                                // Index of element to write to
              heapIn      = localMem[88];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 149;
              heapClock = ~ heapClock;
        end

        149 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 150;
              heapClock = ~ heapClock;
        end

        150 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[89] = heapOut;                                                     // Data retrieved from heap memory
              ip = 151;
              heapClock = ~ heapClock;
        end

        151 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[26] = localMem[89];
              ip = 152;
        end

        152 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[90] = 75;
              ip = 153;
        end

        153 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[26];                                                // Array to write to
              heapIndex   = 7;                                                // Index of element to write to
              heapIn      = localMem[90];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 154;
              heapClock = ~ heapClock;
        end

        154 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 4;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 155;
              heapClock = ~ heapClock;
        end

        155 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[91] = heapOut;                                                     // Data retrieved from heap memory
              ip = 156;
              heapClock = ~ heapClock;
        end

        156 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[27] = localMem[91];
              ip = 157;
        end

        157 :
        begin                                                                   // shiftUp
          //$display("AAAA %4d %4d shiftUp", steps, ip);
              heapAction = `Up;
              heapIn     = 26;
              heapArray  = localMem[27];
              heapIndex  = 2;
              ip = 158;
              heapClock = ~ heapClock;
        end

        158 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 5;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 159;
              heapClock = ~ heapClock;
        end

        159 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[92] = heapOut;                                                     // Data retrieved from heap memory
              ip = 160;
              heapClock = ~ heapClock;
        end

        160 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[28] = localMem[92];
              ip = 161;
        end

        161 :
        begin                                                                   // shiftUp
          //$display("AAAA %4d %4d shiftUp", steps, ip);
              heapAction = `Up;
              heapIn     = 26;
              heapArray  = localMem[28];
              heapIndex  = 2;
              ip = 162;
              heapClock = ~ heapClock;
        end

        162 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 6;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 163;
              heapClock = ~ heapClock;
        end

        163 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[93] = heapOut;                                                     // Data retrieved from heap memory
              ip = 164;
              heapClock = ~ heapClock;
        end

        164 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[29] = localMem[93];
              ip = 165;
        end

        165 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[30] = 2 + 1;
              ip = 166;
        end

        166 :
        begin                                                                   // shiftUp
          //$display("AAAA %4d %4d shiftUp", steps, ip);
              heapAction = `Up;
              heapIn     = 26;
              heapArray  = localMem[29];
              heapIndex  = localMem[30];
              ip = 167;
              heapClock = ~ heapClock;
        end

        167 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 0;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 168;
              heapClock = ~ heapClock;
        end

        168 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[94] = heapOut;                                                     // Data retrieved from heap memory
              ip = 169;
              heapClock = ~ heapClock;
        end

        169 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[95] = localMem[94] + 1;
              ip = 170;
        end

        170 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[95];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 171;
              heapClock = ~ heapClock;
        end
      endcase
      success  = 1;
      finished = steps >    172;
    end
  end

endmodule
