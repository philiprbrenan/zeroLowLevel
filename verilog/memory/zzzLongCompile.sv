module Memory
 (input wire       clock,                                                       // Clock to drive array operations
  input wire [7:0] array,                                                       // The number of the array to work on
  input wire [3:0] index,                                                       //Index within array
  input wire [7:0] in,                                                          // Input data
  input wire [7:0] out);                                                        // Input data

  reg [7:0] memory[327:0][3:0];                                                 // Memory containing arrays in fixed blocks

  always @(posedge clock) begin                                                 // Each transition
    memory[array][index] = memory[array][index] & in;                           // read_verilog_ seems to loop endlessly
    out = out & in;                                                             // read_verilog compiles this quickly
  end
endmodule
