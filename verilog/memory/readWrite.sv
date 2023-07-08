module readWrite
 (input  wire clk,
  input  wire reset,
  output reg finished,
  output reg success);

  parameter integer  MEM_SIZE   = 8;
  parameter integer  DATA_WIDTH = 8;

  memory m(
    .clk    (m_clk),
    .write  (m_write),
    .address(m_address),
    .in     (m_in),
    .out    (m_out)
  );

  defparam m.MEM_SIZE   = MEM_SIZE;
  defparam m.DATA_WIDTH = DATA_WIDTH;

  reg                 m_clk;
  reg                 m_write;
  reg[MEM_SIZE-1:0]   m_address;
  reg[DATA_WIDTH-1:0] m_in;
  reg[DATA_WIDTH-1:0] m_out;
  integer steps;

  always @(posedge clk) begin
    if (reset) begin
      m_clk     = 0;
      m_write   = 0;
      m_address = 0;
      m_in      = 0;
      steps     = 0;
      finished  = 0;
      success   = 0;
    end
    else begin
      case(steps)
        1: begin m_in = 2; m_address = 1; m_write = 1; m_clk = 1; end  2: m_clk = 0;
        3: begin m_in = 3; m_address = 2; m_write = 1; m_clk = 1; end  4: m_clk = 0;
        5: begin m_in = 5; m_address = 3; m_write = 1; m_clk = 1; end  6: m_clk = 0;
        7: begin           m_address = 2; m_write = 0; m_clk = 1; end  8: m_clk = 0;
        9: begin finished = 1; success = m_out == 3; end
      endcase
      steps = steps + 1;
    end
  end
endmodule

`include "memory.sv"
