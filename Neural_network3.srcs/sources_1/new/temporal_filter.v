module temporal_filter #(
  parameter M = 32,  // A的行数
  parameter K = 15,  // A的列数（B的行数）
  parameter N = 8,   // B的列数
  parameter DATA_WIDTH = 16
)(
   input clk,
  input reset,
  input start,      // 启动计算
  input [M*K*DATA_WIDTH-1:0] matrix_A, // A (M×K)
  input [N*K*DATA_WIDTH-1:0] matrix_B, // B (K×N)
  output wire[M*N*DATA_WIDTH-1:0] matrix_C, // C = A×B (M×N)
  output wire done       // 计算完成
);

systolic_array #(
    .M(M),
    .K(K),
    .N(N),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .matrix_A(matrix_A),
    .matrix_B(matrix_B),
    .matrix_C(matrix_C),
    .done(done)
);
endmodule