//-----------------------------------------------------------------------------
// Clock divider
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module ClockDivider                                                             // Clock divider
 (input  wire            clock,                                                 // Clock which drives both input and output
  output wire[NSize-1:0] out);                                                  // Output channel

  parameter integer NSize  = 3;                                                 // Log2(Size of clock divider)

  reg [NSize-1:0] outR = 0;                                                     // Out driver
  assign out = outR;

  always @(posedge clock) begin                                                 // Capture current input on positive edge
    outR <= outR + 1;                                                            // Count up
  end
endmodule
