//-----------------------------------------------------------------------------
// Advance the clock and query the results in memory at a specified location
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module ClockAndQuery                                                            // Advance the clock and respond to a pseudo request to see memory
 (input  wire clock,                                                            // Clock
  input  wire reset,                                                            // Restart ip
  input  wire inw,                                                              // Memory byte address to be read as 8 bits
  output reg out);                                                             // 8 bits representing the byte in memory corresponding. Visible after 8 bits clocked into in

  parameter integer NSize = 4;                                                  // Log2(Size of memory)

  reg[NSize:0] ip      = 0;                                                     // Instruction pointer which we will advance
  integer      state   = 0;                                                     // Clock divder
  reg[NSize:0] address = 0;                                                     // Input address
  reg[NSize:0] got     = 0;                                                     // What we got from memory

 `define nextState (reset ? 0 : (state + 1) % (1 + NSize))                      // Next state

  always @(posedge(clock)) begin                                                // Start ip address
    state <= `nextState;                                                        // Divide the clock so we can read in the address and write the contents as a single bit stream after simulating executing the instruction
    got   <= 11;
    if (reset) begin                                                            // Restart
      ip  <= 0;
      //$display("                             At 11 reset=%2d in=%2d ip=%2d state=%2d address=%2d got=%2d", reset, in, ip, state, address, got);
    end
    else if (`nextState == NSize) begin                                         // Next instruction
      ip  <= ip + 1'b1;
      //$display("                             At 22 reset=%2d in=%2d ip=%2d state=%2d address=%2d got=%2d", reset, in, ip, state, address, got);
    end
    else begin                                                                  // Read address on 0 - NSize-1
      address[`nextState] <= inw;
      out                 <= got[`nextState];
      //$display("                             At 33 reset=%2d in=%2d ip=%2d state=%2d address=%2d got=%2d", reset, in, ip, state, address, got);
    end
  end
endmodule
// 0 - execute instruction, read first address, write first got bit
// 1,2,3 - read rest of in and send rest of got
// 4 read memory, increment ip
