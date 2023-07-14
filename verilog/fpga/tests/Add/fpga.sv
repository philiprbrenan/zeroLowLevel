`define Size         4  /* Size of array                                       */
`define Greater      9  /* Elements of array greater than in                   */

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
  reg [INDEX_BITS    :0] arraySizes [ARRAYS-1:0];                               // Current size of each array

  integer result;                                                               // Result of each array operation
  integer size;                                                                 // Size of current array
  integer i;                                                                    // Index

  always @(clock) begin                                                         // Each transition
    case(action)                                                                // Decode request
      `Size: begin                                                              // Size
        out = arraySizes[array];
      end

      `Greater: begin                                                           // Count greater
          result = 0;
          for(i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            if (i < size && memory[array][i] > in) result = result + 1;
          end
          out = result;
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
  reg [       1-1:0] heapIndex;                                         // Index within array
  reg [      12-1:0] heapIn;                                            // Input data
  reg [      12-1:0] heapOut;                                           // Output data
  reg [31        :0] heapError;                                                 // Error on heap operation if not zero

  Memory                                                                        // Memory module
   #(       2,        1,       12)                          // Address bits, index bits, data bits
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction),
    .array  (heapArray),
    .index  (heapIndex),
    .in     (heapIn),
    .out    (heapOut),
    .error  (heapError)
  );
endmodule
