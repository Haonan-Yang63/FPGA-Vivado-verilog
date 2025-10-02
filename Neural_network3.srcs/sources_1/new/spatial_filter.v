module spatial_filter #(
    parameter DATA_WIDTH = 16,
    parameter COL = 64,
    parameter ROW = 8
)(
    input clk,
    input reset,
    input start,
    input [COL*DATA_WIDTH-1:0] matrix1,
    input [COL*ROW*DATA_WIDTH-1:0] matrix2,
    output wire [ROW*DATA_WIDTH-1:0] result,
    output wire done
);


 mut_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .COL(COL),
        .ROW(ROW))
    uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .matrix1(matrix1),
        .matrix2(matrix2),
        .result(result),
        .done(done)
    );
endmodule