//-----------------------------------------------------------------------------
// Circular buffer
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module CircularBuffer                                                           // Circular buffer with options to clear the buffer, add an element to the buffer or remove an element from the buffer in first in, first out order. If there is  room in the buffer as shown by the "inRemainder" pins, the buffer will accept another element fron the "in" pins when "inEnable" is high and the "clock" goes high. Likewise if the "outEnable" pin is high and there is an element in the buffer as shown by the "outRemainder" pins, then an element will be removed from the buffer and placed on the "out" pins when the "clock" goes high. In the event that the buffer would run the input request is ignored - the caller must check that there is space in the buffer by checking the "inRemainder" pins first.  Likewise, if no output element is available the "out" pins will continue to hold their last value unless the "outRemainder" pins were not all zero.
 (input  wire           clock,                                                  // Clock which drives both input and output
  input  wire[1:0]      action,                                                 // 0 - do nothing, 1 - reset, 2 - add an element, 2 - remove an eleemnt
  input  wire[NWidth:0] in,                                                     // Input channel
  output wire[NSize :0] inRemainder,                                            // Remaining free space in buffer
  output wire[NWidth:0] out,                                                    // Output channel
  output wire[NSize :0] outRemainder);                                          // Data available in buffer. This field plus inRemainder equals the size of the buffer

  parameter integer NSize  = 3;                                                 // Log2(Size of buffer)
  parameter integer NWidth = 6;                                                 // Width of each buffer element

  reg [NWidth:0] buffer[(1<<NSize)];                                            // Buffer

  reg[1:0]      action2;                                                        // Buffer requested action
  reg[NWidth:0] inR;
  reg[NSize :0]  inRemainderR;                                                  // Drive output wires
  reg[NSize :0] outRemainderR;
  reg[NWidth:0] outR;
  reg[NSize-1:0] pos1, pos2;                                                     // Start of active buffer
  reg[NSize-1:0] end1, end2;                                                     // Finish of active buffer

  assign inRemainder   = inRemainderR;                                          // Connect results registers to output pins
  assign out           = outR;
  assign outRemainder  = outRemainderR;

  always @(posedge clock) begin                                                 // Capture current input on positive edge
    action2    <= action;
    inR        <= in;
    pos2       <= pos1;
    end2       <= end1;
  end

  always @(negedge clock) begin                                                 // Reset
    if (action2 == 1) begin                                                     // Clear buffer
      pos1 <= 0;
      end1 <= 0;
      outRemainderR <= 0;
      inRemainderR  <= 1'b1 << NSize;
    end
    else if (action2 == 2  && ((end2 + 1'b1) & ((1'b1<<NSize)-1'b1)) != pos2) begin
      buffer[end2]   <= inR;
      end1           <=       ((end2 + 1'b1) & ((1'b1<<NSize)-1'b1));
      outRemainderR  <= end2 >= pos2 ? end2+1'b1 - pos2 : (1'b1<<NSize) - pos2 + end2 - 1'b1;
       inRemainderR  <= end2 <= pos2 ? (1'b1<<NSize)- end2 + pos2 - 1'b1 : (1'b1<<NSize) - end2 + pos2 - 1'b1;
    end
    else if (action2 == 3 && ((pos2 + 1'b1)  & ((1'b1<<NSize)-1)) != end2) begin
      outR           <= buffer[pos2  & ((1'b1<<NSize)-1'b1)];
      pos1           <=  (pos2 + 1'b1)  & ((1'b1<<NSize)-1'b1);
      outRemainderR  <= end2 >= pos2 ? end2 - pos2 - 1'b1 : (1'b1<<NSize) - pos2 + end2 - 1'b1;
       inRemainderR  <= end2 <= pos2 ? (1'b1<<NSize) - end2 + pos2 - 1'b1 : (1'b1<<NSize) - end2 + pos2 + 1'b1;
    end
  end
endmodule
