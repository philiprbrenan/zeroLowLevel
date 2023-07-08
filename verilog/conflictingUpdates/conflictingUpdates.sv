//-----------------------------------------------------------------------------
// Resolve conflicting updates
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module conflictingUpdates
 (input wire      clock1,
  input wire      clock2,
  input wire[1:0] in,
  output wire[1:0] ipw
 );

  reg[1:0]ip = 0;
  assign ipw = ip;

  always @(posedge clock1) begin
    case(in)
      0 : ip = 1;
      1 : ip = 2;
      2 : ip = 3;
      default : ip = 0;
    endcase
    $display("AAAA %2d", ip);
  end

  always @(posedge clock2) begin
    case(in)
      0 : ip = 3;
      1 : ip = 2;
      2 : ip = 1;
      default : ip = 0;
    endcase
    $display("BBBB %2d", ip);
  end
endmodule
