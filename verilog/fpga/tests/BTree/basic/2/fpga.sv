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
      //$display("    %2d %2d %2d", allocations[0], allocations[1], allocations[2]);
    end
  endtask

  always @(posedge clock) begin                                                 // Each transition
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
          allocations[array]          = 0;                                      // No longer allocated
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
  reg [       2-1:0] heapArray;                                         // The number of the array to work on
  reg [       2-1:0] heapIndex;                                         // Index within array
  reg [      12-1:0] heapIn;                                            // Input data
  reg [      12-1:0] heapOut;                                           // Output data
  reg [31        :0] heapError;                                                 // Error on heap operation if not zero

  Memory                                                                        // Memory module
   #(       2,        2,       12)                          // Address bits, index bits, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
  reg [      12-1:0] localMem[      31-1:0];                       // Local memory
  reg [      12-1:0]   outMem[       2  -1:0];                       // Out channel
  reg [      12-1:0]    inMem[       1   -1:0];                       // In channel

  integer inMemPos;                                                             // Current position in input channel
  integer outMemPos;                                                            // Position in output channel

  integer ip;                                                                   // Instruction pointer
  integer steps;                                                                // Number of steps executed so far
  integer i, j, k;                                                              // A useful counter

  always @(posedge clock) begin                                                 // Each instruction
    if (reset) begin
      ip             = 0;
      steps          = 0;
      inMemPos       = 0;
      outMemPos      = 0;
      finished       = 0;
      success        = 0;

    end
    else begin
      case(ip)

          0 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 1;
        end

          1 :
        begin                                                                   // start
          //$display("AAAA %4d %4d start", steps, ip);
              heapAction = `Reset;                                              // Reset heap memory
              ip = 2;
              heapClock = 1;
        end

          2 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 3;
        end

          3 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
              ip = 4;
              heapClock = 1;
        end

          4 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[0] = heapOut;
              ip = 5;
        end

          5 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 6;
        end

          6 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[5] = 3;
              ip = 7;
        end

          7 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[5];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 8;
              heapClock = 1;
        end

          8 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[6] = 0;
              ip = 10;
        end

         10 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[6];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 11;
              heapClock = 1;
        end

         11 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 12;
        end

         12 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[7] = 0;
              ip = 13;
        end

         13 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[7];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 14;
              heapClock = 1;
        end

         14 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 15;
        end

         15 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[8] = 0;
              ip = 16;
        end

         16 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[8];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 17;
              heapClock = 1;
        end

         17 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 18;
        end

         18 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 3;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 19;
              heapClock = 1;
        end

         19 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 20;
        end

         20 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[9] = heapOut;                                                     // Data retrieved from heap memory
              ip = 21;
              heapClock = 1;
        end

         21 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 22;
        end

         22 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[1] = localMem[9];
              ip = 23;
        end

         23 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[10] = 1;
              ip = 24;
        end

         24 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 3;                                                // Index of element to write to
              heapIn      = localMem[10];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 25;
              heapClock = 1;
        end

         25 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 26;
        end

         26 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 3;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 27;
              heapClock = 1;
        end

         27 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 28;
        end

         28 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[11] = heapOut;                                                     // Data retrieved from heap memory
              ip = 29;
              heapClock = 1;
        end

         29 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 30;
        end

         30 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[2] = localMem[11];
              ip = 31;
        end

         31 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 2;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 32;
              heapClock = 1;
        end

         32 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 33;
        end

         33 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[12] = heapOut;                                                     // Data retrieved from heap memory
              ip = 34;
              heapClock = 1;
        end

         34 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 35;
        end

         35 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[3] = localMem[12];
              ip = 36;
        end

         36 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 0;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 37;
              heapClock = 1;
        end

         37 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 38;
        end

         38 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[13] = heapOut;                                                     // Data retrieved from heap memory
              ip = 39;
              heapClock = 1;
        end

         39 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 40;
        end

         40 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[14] = localMem[13] + 1;
              ip = 41;
        end

         41 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[14];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 42;
              heapClock = 1;
        end

         42 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 43;
        end

         43 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 0;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 44;
              heapClock = 1;
        end

         44 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 45;
        end

         45 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[15] = heapOut;                                                     // Data retrieved from heap memory
              ip = 46;
              heapClock = 1;
        end

         46 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 47;
        end

         47 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[16] = localMem[15] + 1;
              ip = 48;
        end

         48 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[16];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 49;
              heapClock = 1;
        end

         49 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 50;
        end

         50 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 0;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 51;
              heapClock = 1;
        end

         51 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 52;
        end

         52 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[17] = heapOut;                                                     // Data retrieved from heap memory
              ip = 53;
              heapClock = 1;
        end

         53 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 54;
        end

         54 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[18] = localMem[17] + 1;
              ip = 55;
        end

         55 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[18];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 56;
              heapClock = 1;
        end

         56 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 57;
        end

         57 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 0;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 58;
              heapClock = 1;
        end

         58 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 59;
        end

         59 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[19] = heapOut;                                                     // Data retrieved from heap memory
              ip = 60;
              heapClock = 1;
        end

         60 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 61;
        end

         61 :
        begin                                                                   // out
          //$display("AAAA %4d %4d out", steps, ip);
              outMem[outMemPos] = localMem[19];
              outMemPos = outMemPos + 1;
              ip = 62;
        end

         62 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 63;
              heapClock = 1;
        end

         63 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 64;
        end

         64 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[20] = heapOut;                                                     // Data retrieved from heap memory
              ip = 65;
              heapClock = 1;
        end

         65 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 66;
        end

         66 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[21] = localMem[20] + 1;
              ip = 67;
        end

         67 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[21];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 68;
              heapClock = 1;
        end

         68 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 69;
        end

         69 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 70;
              heapClock = 1;
        end

         70 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 71;
        end

         71 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[22] = heapOut;                                                     // Data retrieved from heap memory
              ip = 72;
              heapClock = 1;
        end

         72 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 73;
        end

         73 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[23] = localMem[22] + 1;
              ip = 74;
        end

         74 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[23];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 75;
              heapClock = 1;
        end

         75 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 76;
        end

         76 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 77;
              heapClock = 1;
        end

         77 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 78;
        end

         78 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[24] = heapOut;                                                     // Data retrieved from heap memory
              ip = 79;
              heapClock = 1;
        end

         79 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 80;
        end

         80 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[25] = localMem[24] + 1;
              ip = 81;
        end

         81 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[25];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 82;
              heapClock = 1;
        end

         82 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 83;
        end

         83 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 84;
              heapClock = 1;
        end

         84 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 85;
        end

         85 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[26] = heapOut;                                                     // Data retrieved from heap memory
              ip = 86;
              heapClock = 1;
        end

         86 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 87;
        end

         87 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[27] = localMem[26] + 1;
              ip = 88;
        end

         88 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[27];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 89;
              heapClock = 1;
        end

         89 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 90;
        end

         90 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 91;
              heapClock = 1;
        end

         91 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 92;
        end

         92 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[28] = heapOut;                                                     // Data retrieved from heap memory
              ip = 93;
              heapClock = 1;
        end

         93 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 94;
        end

         94 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[29] = localMem[28] + 1;
              ip = 95;
        end

         95 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[0];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[29];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 96;
              heapClock = 1;
        end

         96 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 97;
        end

         97 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[0];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = 1;                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                           // Request a read, not a write
              ip = 98;
              heapClock = 1;
        end

         98 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 99;
        end

         99 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[30] = heapOut;                                                     // Data retrieved from heap memory
              ip = 100;
              heapClock = 1;
        end

        100 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 101;
        end

        101 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[4] = localMem[30];
              ip = 102;
        end

        102 :
        begin                                                                   // out
          //$display("AAAA %4d %4d out", steps, ip);
              outMem[outMemPos] = localMem[4];
              outMemPos = outMemPos + 1;
              ip = 103;
        end
      endcase
      success = outMem[0] == 3 && outMem[1] == 5;
      steps = steps + 1;
      finished = steps >    104;
    end
  end

endmodule
