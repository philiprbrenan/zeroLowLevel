//-----------------------------------------------------------------------------
// Mutex - returns the number of the highest active pin.
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module Mutex                                                                    // The input pins are read on the rising clock edge and the number of the highest active pin is placed on the output pins and held there until the next rising clock edge.
 (input  wire clock,                                                            // Clock which drives both input and output
  input  wire[NIn :0] in,                                                       // Input pins
  output wire         outValid,                                                 // Output is valid if true
  output wire[NOut:0] out);                                                     // Output channel

  parameter integer NIn  = 8;                                                   // Number of inoput pins
  parameter integer NOut = 3;                                                   // Number of highest pin

  reg[NIn  : 0] In;                                                             // Buffer input pins
  reg           OutValid;                                                       // Output represents the highest pin if true
  reg[NOut : 0] Out;                                                            // Output driver

  assign outValid = OutValid;                                                   // Whether there is a highest pin
  assign out      = Out;                                                        // Output

  integer n;                                                                    // Highest pin
  integer p;                                                                    // Pin being tested
  integer c;                                                                    // Number of pins active

  always @(posedge clock) begin                                                 // Next clock action
    In = in;                                                                    // Buffer input pins
    c  = 0;                                                                     // Number of active pins seen
    for(p = 0; p < NIn; ++p) begin                                              // Each pin
      if (In[p] == 1) fork                                                      // Check this pin is high
        n = p;                                                                  // Record highest pin seen so far
        c++;                                                                    // Count number of active pins
      join
    end

    if (c == 0) OutValid = 0;                                                   // No pin is high
    else fork                                                                   // at least one pin is high
      OutValid = 1;
      Out      = n;
    join
  end
endmodule
