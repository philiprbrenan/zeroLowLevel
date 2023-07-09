// Check double frees, over allocation
// Check access to unallocated arrays or elements
// Check push overflow, pop underflow
module Memory
#(parameter integer ADDRESS_BITS =  8,                                          // Number of bits in an address
  parameter integer INDEX_BITS   =  3,                                          // Bits in in an index
  parameter integer DATA_BITS    = 16)                                          // Width of an element in bits
 (input wire                    clock,                                          // Clock to drive array operations
  input wire[7:0]               action,                                         // Operation to be performed on array
  input wire [ADDRESS_BITS-1:0] array,                                          // The number of the array to work on
  input wire [INDEX_BITS  -1:0] index,                                          // Index within array
  input wire [DATA_BITS   -1:0] in,                                             // Input data
  output reg [DATA_BITS   -1:0] out);                                           // Output data

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

  task checkWriteable();                                                        // Check a memory is writable
    begin
       if (array >= allocatedArrays) begin
         $display("Array has not been allocated, array %d", array);
         $finish();
       end
       if (!allocations[array]) begin
         $display("Array has been freed, array %d", array);
         $finish();
       end
    end
  endtask

  task checkReadable();                                                         // Check a memory locationis readable
    begin
       checkWriteable();
       if (index >= arraySizes[array]) begin
         $display("Access outside array bounds, array %d, size: %d, access: %d", array, arraySizes[array], index);
         $finish();
       end
    end
  endtask

  always @(posedge clock) begin
    case(action)                                                                // Decode request
      Reset: begin                                                              // Reset
        freedArraysTop = 0;                                                     // Free all arrays
        allocatedArrays = 0;
      end

      Write: begin                                                              // Write
        checkWriteable();
        memory[array][index] = in;
        if (index >= arraySizes[array] && index < ARRAY_LENGTH) begin
          arraySizes[array] = index + 1;
        end
        out = in;
      end

      Read: begin                                                               // Read
        checkReadable();
        out = memory[array][index];
      end

      Size: begin                                                               // Size
        checkWriteable();
        out = arraySizes[array];
      end

      Dec: begin                                                                // Decrement
        checkWriteable();
        if (arraySizes[array] > 0) arraySizes[array] = arraySizes[array] - 1;
        else begin
          $display("Attempt to decrement empty array, array %d", array); $finish();
        end
      end

      Inc: begin                                                                // Increment
        checkWriteable();
        if (arraySizes[array] < ARRAY_LENGTH) arraySizes[array] = arraySizes[array] + 1;
        else begin
          $display("Attempt to decrement full array, array %d", array); $finish();
        end
      end

      Index: begin                                                              // Index
        checkWriteable();
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
          if (i < size && memory[array][i] == in) result = i + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end

      Less: begin                                                               // Count less
        checkWriteable();
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
          if (i < size && memory[array][i] < in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end

      Greater: begin                                                            // Count greater
        checkWriteable();
        result = 0;
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
          if (i < size && memory[array][i] > in) result = result + 1;
//$display("AAAA %d %d %d %d %d", i, size, memory[array][i], in, result);
        end
        out = result;
      end

      Down: begin                                                               // Down
$display("Need Memory array down");
      end

      Up: begin                                                                 // Up
        checkWriteable();
        size   = arraySizes[array];
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) copy[i] = memory[array][i];     // Copy source array
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin                           // Move original array up
          if (i > index && i <= size) begin
            memory[array][i] = copy[i-1];
          end
        end
        memory[array][index] = in;                                              // Insert new value
        if (size < ARRAY_LENGTH) arraySizes[array] = arraySizes[array] + 1;     // Increase array size
      end

      Long1: begin                                                              // Move long start
        checkReadable();
        moveLongStartArray = array;
        moveLongStartIndex = index;
      end

      Long2: begin                                                              // Move long finish
        checkWriteable();
        for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin                           // Copy from source to target
          if (i < in && index + i < ARRAY_LENGTH && moveLongStartIndex+i < ARRAY_LENGTH) begin
            memory[array][index+i] = memory[moveLongStartArray][moveLongStartIndex+i];
            if (index+i >= arraySizes[array]) arraySizes[array] = index+i+1;
          end
        end
      end

      Push: begin                                                               // Push
        checkWriteable();
        if (arraySizes[array] < ARRAY_LENGTH) begin
          memory[array][arraySizes[array]] = in;
          arraySizes[array] = arraySizes[array] + 1;
        end
        else begin
          $display("Attempt to push to full array, array %d, value %d", array, in); $finish();
        end
      end

      Pop: begin                                                                // Pop
        checkWriteable();
        if (arraySizes[array] > 0) begin
          arraySizes[array] = arraySizes[array] - 1;
          out = memory[array][arraySizes[array]];
        end
        else begin
          $display("Attempt to pop empty array, array %d", array); $finish();
        end
      end

      Dump: begin                                                               // Dump
        $display("    %2d %2d %2d", arraySizes[0], arraySizes[1], arraySizes[2]);
        for(i = 0; i < ARRAY_LENGTH; ++i) $display("%2d  %2d %2d %2d", i, memory[0][i], memory[1][i], memory[2][i]);
      end

      Resize: begin                                                             // Resize
        checkWriteable();
        if (in <= ARRAY_LENGTH) arraySizes[array] = in;
        else begin
          $display("Attempt to make an array too large, array %d, max %d, size %d", array, ARRAY_LENGTH, in); $finish();
        end
      end

      Alloc: begin                                                              // Allocate an array
         if (freedArraysTop > 0) begin                                          // Reuse a freed array
           freedArraysTop = freedArraysTop - 1;
           result = freedArrays[freedArraysTop];
         end
         else begin                                                             // Allocate a new array - assumes enough memory
           result          = allocatedArrays;
           allocatedArrays = allocatedArrays + 1;
         end
         allocations[result] = 1;                                               // Allocated
         arraySizes[result] = 0;                                                // Empty array
         out = result;
      end

      Free: begin                                                               // Free an array
        checkWriteable();
        freedArrays[freedArraysTop] = array;                                    // Relies on the user not re freeing a freed array - we should probably hve another array to prevent this
        allocations[freedArraysTop] = 0;                                        // No longer allocated
        freedArraysTop = freedArraysTop + 1;
      end

      Add: begin                                                                // Add to an element
        checkReadable();
        memory[array][index] = memory[array][index] + in;
        out = memory[array][index];
      end
      AddAfter: begin                                                           // Add to an element after putting the content of the element on out
        checkReadable();
        out = memory[array][index];
        memory[array][index] = memory[array][index] + in;
      end

      Subtract: begin                                                           // Subtract from an element
        checkReadable();
        memory[array][index] = memory[array][index] - in;
        out = memory[array][index];
      end
      SubAfter: begin                                                           // Subtract from an element after putting the content of the element on out
        checkReadable();
        out = memory[array][index];
        memory[array][index] = memory[array][index] - in;
      end

      ShiftLeft: begin                                                          // Shift left
        checkReadable();
        memory[array][index] = memory[array][index] << in;
        out = memory[array][index];
      end
      ShiftRight: begin                                                         // Shift right
        checkReadable();
        memory[array][index] = memory[array][index] >> in;
        out = memory[array][index];
      end
      NotLogical: begin                                                         // Not logical
        checkReadable();
        if (memory[array][index] == 0) memory[array][index] = 1;
        else                           memory[array][index] = 0;
        out = memory[array][index];
      end
      Not: begin                                                                // Not
        checkReadable();
        memory[array][index] = ~memory[array][index];
        out = memory[array][index];
      end
      Or: begin                                                                 // Or
        checkReadable();
        memory[array][index] = memory[array][index] | in;
        out = memory[array][index];
      end
      Xor: begin                                                                // Xor
        checkReadable();
        memory[array][index] = memory[array][index] ^ in;
        out = memory[array][index];
      end
      And: begin                                                                // And
        checkReadable();
        memory[array][index] = memory[array][index] & in;
        out = memory[array][index];
      end
    endcase
  end
endmodule
