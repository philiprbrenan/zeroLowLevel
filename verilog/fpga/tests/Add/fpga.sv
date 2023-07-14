//-----------------------------------------------------------------------------
// Fpga test
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga                                                                     // Run test programs
 (input  wire clock);                                                            // Driving clock

  integer ip;                                                                   // Instruction pointer

  always @(posedge clock, negedge clock) begin                                  // Each instruction
    ip = 0;
  end

endmodule
