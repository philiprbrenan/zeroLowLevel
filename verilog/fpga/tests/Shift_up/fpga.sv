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
  reg [      12-1:0] localMem[       9-1:0];                       // Local memory
  reg [      12-1:0]   outMem[       4  -1:0];                       // Out channel
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
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 4;
        end

          4 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
              ip = 5;
              heapClock = 1;
        end

          5 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 6;
        end

          6 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[0] = heapOut;
              ip = 7;
        end

          7 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 8;
        end

          8 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 9;
        end

          9 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 10;
        end

         10 :
        begin                                                                   // array
          //$display("AAAA %4d %4d array", steps, ip);
              heapAction = `Alloc;
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
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[1] = heapOut;
              ip = 13;
        end

         13 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 14;
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
              localMem[5] = 0;
              ip = 16;
        end

         16 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 17;
        end

         17 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 0;                                                // Index of element to write to
              heapIn      = localMem[5];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 18;
              heapClock = 1;
        end

         18 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 19;
        end

         19 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[6] = 1;
              ip = 20;
        end

         20 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 21;
        end

         21 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 1;                                                // Index of element to write to
              heapIn      = localMem[6];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 22;
              heapClock = 1;
        end

         22 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 23;
        end

         23 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[7] = 2;
              ip = 24;
        end

         24 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 25;
        end

         25 :
        begin                                                                   // movWrite1
          //$display("AAAA %4d %4d movWrite1", steps, ip);
              heapArray   = localMem[1];                                                // Array to write to
              heapIndex   = 2;                                                // Index of element to write to
              heapIn      = localMem[7];                                                 // Data to write
              heapAction  = `Write;                                         // Request a write
              ip = 26;
              heapClock = 1;
        end

         26 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 27;
        end

         27 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 28;
        end

         28 :
        begin                                                                   // resize
          //$display("AAAA %4d %4d resize", steps, ip);
              heapAction = `Resize;
              heapIn     = 3;
              heapArray  = localMem[1];
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
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 31;
        end

         31 :
        begin                                                                   // shiftUp
          //$display("AAAA %4d %4d shiftUp", steps, ip);
              heapAction = `Up;
              heapIn     = 99;
              heapArray  = localMem[1];
              heapIndex  = 0;
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
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 34;
        end

         34 :
        begin                                                                   // arraySize
          //$display("AAAA %4d %4d arraySize", steps, ip);
              heapAction = `Size;
              heapArray  = localMem[1];
              ip = 35;
              heapClock = 1;
        end

         35 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 36;
        end

         36 :
        begin                                                                   // movHeapOut
          //$display("AAAA %4d %4d movHeapOut", steps, ip);
              localMem[2] = heapOut;
              ip = 37;
        end

         37 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 38;
        end

         38 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 39;
        end

         39 :
        begin                                                                   // label
          //$display("AAAA %4d %4d label", steps, ip);
              ip = 40;
        end

         40 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[3] = 0;
              ip = 41;
        end

         41 :
        begin                                                                   // label
          //$display("AAAA %4d %4d label", steps, ip);
              ip = 42;
        end

         42 :
        begin                                                                   // jGe
          //$display("AAAA %4d %4d jGe", steps, ip);
              ip = localMem[3] >= localMem[2] ? 53 : 43;
        end

         43 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 44;
        end

         44 :
        begin                                                                   // movRead1
          //$display("AAAA %4d %4d movRead1", steps, ip);
              heapArray  = localMem[1];                                                  // Address of the item we wish to read from heap memory
              heapIndex  = localMem[3];                                                  // Address of the item we wish to read from heap memory
              heapAction = `Read;                                               // Request a read, not a write
              ip = 45;
              heapClock = 1;
        end

         45 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 46;
        end

         46 :
        begin                                                                   // movRead2
          //$display("AAAA %4d %4d movRead2", steps, ip);
              localMem[8] = heapOut;                                                     // Data retrieved from heap memory
              ip = 47;
              heapClock = 1;
        end

         47 :
        begin                                                                   // resetHeapClock
          //$display("AAAA %4d %4d resetHeapClock", steps, ip);
              heapClock = 0;
              ip = 48;
        end

         48 :
        begin                                                                   // mov
          //$display("AAAA %4d %4d mov", steps, ip);
              localMem[4] = localMem[8];
              ip = 49;
        end

         49 :
        begin                                                                   // out
          //$display("AAAA %4d %4d out", steps, ip);
              outMem[outMemPos] = localMem[4];
              outMemPos = outMemPos + 1;
              ip = 50;
        end

         50 :
        begin                                                                   // label
          //$display("AAAA %4d %4d label", steps, ip);
              ip = 51;
        end

         51 :
        begin                                                                   // add
          //$display("AAAA %4d %4d add", steps, ip);
              localMem[3] = localMem[3] + 1;
              ip = 52;
        end

         52 :
        begin                                                                   // jmp
          //$display("AAAA %4d %4d jmp", steps, ip);
              ip = 41;
        end

         53 :
        begin                                                                   // label
          //$display("AAAA %4d %4d label", steps, ip);
              ip = 54;
        end
      endcase
      success = outMem[0] == 99 && outMem[1] == 0 && outMem[2] == 1 && outMem[3] == 2;
      steps = steps + 1;
      finished = steps >     93;
    end
  end

endmodule
