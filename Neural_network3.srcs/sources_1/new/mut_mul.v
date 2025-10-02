module mut_mul #(
    parameter DATA_WIDTH = 16,
    parameter COL = 64,
    parameter ROW = 8
)(
    input clk,
    input reset,
    input start,                  // Added start signal
    input [COL*DATA_WIDTH-1:0] matrix1,
    input [COL*ROW*DATA_WIDTH-1:0] matrix2,
    output reg [ROW*DATA_WIDTH-1:0] result,
    output reg done
);

// 使用二维数组存储乘积结果
(* use_dsp = "yes", keep = "true" *) 
wire [DATA_WIDTH-1:0] products [0:COL-1][0:ROW-1];

// 计算加法树级数（纯Verilog方式）
`define LOG2(n) ((n) <= 1 ? 0 : (n) <= 2 ? 1 : (n) <= 4 ? 2 : (n) <= 8 ? 3 : \
                 (n) <= 16 ? 4 : (n) <= 32 ? 5 : (n) <= 64 ? 6 : (n) <= 128 ? 7 : (n) <=256 ?8 :9)

localparam STAGES = `LOG2(COL);  // 使用宏计算log2

// 加法树存储器（使用更通用的声明方式）
reg [DATA_WIDTH-1:0] sum_tree [0:STAGES][0:ROW-1][0:COL-1];

// 并行乘法计算（纯Verilog generate语法）
genvar i, j;
generate
    for (i = 0; i < COL; i = i + 1) begin : GEN_ROW
        for (j = 0; j < ROW; j = j + 1) begin : GEN_COL
            (* use_dsp = "yes" *)
            assign products[i][j] = matrix1[i*DATA_WIDTH +: DATA_WIDTH] * 
                                  matrix2[(i*ROW + j)*DATA_WIDTH +: DATA_WIDTH];
        end
    end
endgenerate

integer col, k, stage;
integer PREV_SIZE, CURR_SIZE;

always @(posedge clk) begin
    if (~reset) begin
        // 需要初始化所有中间寄存器！
        result <= 0;
        done <= 0;
        for (stage = 0; stage <= STAGES; stage = stage + 1) begin
            for (col = 0; col < ROW; col = col + 1) begin
                for (k = 0; k < COL; k = k + 1) begin
                    sum_tree[stage][col][k] <= 0;
                end
            end
        end
    end
    else if (start) begin  // Only compute when start is high
        // 初始化第一级（直接使用乘法结果）
        for (col = 0; col < ROW; col = col + 1) begin
            for (k = 0; k < COL; k = k + 1) begin
                sum_tree[0][col][k] <= products[k][col];
            end
        end
        
        // 动态生成加法树各级
        for (stage = 1; stage <= STAGES; stage = stage + 1) begin
            PREV_SIZE = COL >> (stage-1);
            CURR_SIZE = COL >> stage;
            
            for (col = 0; col < ROW; col = col + 1) begin
                for (k = 0; k < CURR_SIZE; k = k + 1) begin
                    sum_tree[stage][col][k] <= 
                        sum_tree[stage-1][col][2*k] + 
                        sum_tree[stage-1][col][2*k+1];
                end
            end
        end
        
        // 最终结果输出
        for (col = 0; col < ROW; col = col + 1) begin
            result[col*DATA_WIDTH +: DATA_WIDTH] <= sum_tree[STAGES][col][0];
        end
        done <= 1;
    end
    else begin
        done <= 0;  // Clear done when not computing
    end
end

endmodule