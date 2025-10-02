module single_PE_rounded #(
  parameter DATA_WIDTH = 16,
  parameter Half_WIDTH = 8
)(
  input clk,
  input enable,
  input reset,
  input finish,
  input [DATA_WIDTH-1 : 0] i_up,
  input [DATA_WIDTH-1 : 0] i_left,
  output reg [DATA_WIDTH-1 : 0] o_down,
  output reg [DATA_WIDTH-1 : 0] o_right,
  output reg [DATA_WIDTH-1 : 0] o_result = 0  
);
  reg  [DATA_WIDTH-1 : 0] partial_sum = 0;
  wire [DATA_WIDTH-1 : 0] x;
  assign x = (i_up*i_left);
  always @(posedge clk) begin
  if (~reset) begin
      o_down <= 0;
      o_right <= 0;
      o_result <= 0;
      partial_sum <= 0;
   end else if(reset&&enable) begin
    o_down      <= i_up;
    o_right     <= i_left;
    o_result    <= finish ? partial_sum : o_result;
    partial_sum <= finish ? partial_sum : (partial_sum + x);
    end
    else begin
    o_down <= 0;
      o_right <= 0;
      o_result <= 0;
      partial_sum <= 0;
    end
    end
endmodule
