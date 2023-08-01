module TopModule (
  // Top module ports and signals
  input wire clk,
  input wire [7:0] data_in,
  output wire [7:0] data_out
);

  // Define the array size
  parameter ARRAY_SIZE = 4;

  // Array of MyModule instances
  generate
    genvar i;
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : module_array
      $display("AAAA %d", i);
      //MyModule instance (
      //  .clk(clk),
      //  .data_in(data_in),
      //  .data_out(data_out[i])
      //);
    end
  endgenerate

endmodule
