module fpga
 (input wire clk,
  input wire write,
  input wire [MEM_SIZE-1:0] address,
  input wire [DATA_WIDTH-1:0] in,
  output reg [DATA_WIDTH-1:0] out);

  parameter integer MEM_SIZE   = 8;
  parameter integer DATA_WIDTH = 8;

  reg [DATA_WIDTH-1:0] memory [2**MEM_SIZE:0];

  initial begin
    memory[0] = 11;
    memory[1] = 22;
    memory[2] = 33;
  end

  always @(posedge clk) begin
    // Read operation
    if (write) begin
      memory[address] = in;
      out = in;
    end
    else begin
      out = memory[address];
    end
  end
endmodule
