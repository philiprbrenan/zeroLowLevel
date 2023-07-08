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
