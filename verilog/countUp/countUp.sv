//-----------------------------------------------------------------------------
// Count up
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module countUp
 (input  wire     clk,
  input  wire     reset,
  output reg[7:0] out);

  always @(posedge clk) begin
    if (reset) begin
      out <=  0;
    end
    else begin
      out <= out + 1;
    end
    $display("Count=  %d", out);
  end
endmodule
