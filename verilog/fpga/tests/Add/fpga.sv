module Memory
 (input wire                    clock,                                          // Clock to drive array operations
  input wire[7:0]               action);                                         // Operation to be performed on array

  integer allocatedArrays;                                                      // Arrays allocated

  always @(clock) begin                                                             // Each transition
    case(action)                                                                // Decode request
      1: begin                                                                  // Reset
        allocatedArrays = 0;
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

  Memory                                                                        // Memory module
    heap(                                                                       // Create heap memory
    .clock  (heapClock),
    .action (heapAction)
  );
  reg [      12-1:0] localMem[       1-1:0];                       // Local memory
  reg [      12-1:0]   outMem[       1  -1:0];                       // Out channel
  reg [      12-1:0]    inMem[       1   -1:0];                       // In channel

  integer inMemPos;                                                             // Current position in input channel
  integer outMemPos;                                                            // Position in output channel

  integer ip;                                                                   // Instruction pointer
  integer steps;                                                                // Number of steps executed so far
  integer i, j, k;                                                              // A useful counter

  always @(posedge clock) begin                                  // Each instruction
    begin
      case(ip)
          0 :
        begin                                                                   // start
              heapClock = 0;                                                    // Ready for next operation
        end
      endcase
    end
  end
endmodule
