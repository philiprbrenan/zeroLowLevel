//-----------------------------------------------------------------------------
// Step
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module step
 (input  wire in);

  integer count;
  integer clock;

  always @(posedge in) begin
    $display("AAAA");
    count = 0;
    clock = 1;
  end
  always @(posedge clock, negedge clock) begin
    count = count + 1;
    $display("BBBB %d", count);
    if (count >= 10) $finish();
    clock <= ~ clock;
  end
endmodule
