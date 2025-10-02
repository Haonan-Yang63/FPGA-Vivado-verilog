`timescale 1ns/1ps

module tb_single_kernel();

// 参数定义
parameter ROW = 2;
parameter COL = 2;
parameter DATA_WIDTH = 16;

// 时钟和复位
reg clk;
reg reset;
reg enable;
// 输入信号
reg [ROW*COL-1:0] finish;
reg [COL*DATA_WIDTH-1:0] in_up;
reg [ROW*DATA_WIDTH-1:0] in_left;

// 输出信号
wire [COL*DATA_WIDTH-1:0] pass_down;
wire [ROW*DATA_WIDTH-1:0] pass_right;
wire [ROW*COL*DATA_WIDTH-1:0] out_matrix;

// 实例化被测设计
single_kernel #(
    .ROW(ROW),
    .COL(COL),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .finish(finish),
    .in_up(in_up),
    .in_left(in_left),
    .pass_down(pass_down),
    .pass_right(pass_right),
    .out_matrix(out_matrix)
);

// 时钟生成（100MHz）
always #5 clk = ~clk;

// 测试序列
initial begin
    // 初始化
    clk = 0;
    reset = 0;
    finish = 0;
    in_up = 0;
    in_left = 0;
    enable=1;
    // 复位
    #10 reset = 1;
    #20 reset = 0;
    #10 reset = 1;
    
    // 第一组数据输入（周期1）
    // 矩阵A第一行 [1, 2]
    // 矩阵B第一列 [1, 0]^T
    in_up = {16'd0, 16'd4};    // A的行数据
    in_left = {16'd0, 16'd1};  // B的列数据
    $display("[%0t] 输入第一组数据: A_row=[%d %d], B_col=[%d %d]", 
             $time, 4, 0, 1, 0);
    // 第二组数据输入（周期2）
    // 矩阵A第二行 [3, 4]
    // 矩阵B第二列 [0, 1]^T
//    #10;
//    in_up = {16'd3, 16'd2};    // A的行数据
//    in_left = {16'd1, 16'd2};  // B的列数据
//    $display("[%0t] 输入第二组数据: A_row=[%d %d], B_col=[%d %d]", 
//             $time, 2, 3, 2, 1);
     //finish = 4'b0001;
    // 第三周期激活finish
    #10;
    in_up = {16'd2, 16'd0};    // A的行数据
    in_left = {16'd2, 16'd0};  // B的列数据
    $display("[%0t] 输入第二组数据: A_row=[%d %d], B_col=[%d %d]", 
             $time, 0, 2, 0, 2);
    //finish = 4'b0111;  // 所有PE同时完成
    $display("[%0t] 激活finish信号", $time);
    #20
    finish = 4'b1111;  // 所有PE同时完成
    // 第四周期读取结果
    #20;
    $display("[%0t] 最终结果:", $time);
    $display("C[0][0] = %d (期望: 4)", out_matrix[0*DATA_WIDTH +: DATA_WIDTH]);
    $display("C[0][1] = %d (期望: 2)", out_matrix[1*DATA_WIDTH +: DATA_WIDTH]);
    $display("C[1][0] = %d (期望: 8)", out_matrix[2*DATA_WIDTH +: DATA_WIDTH]);
    $display("C[1][1] = %d (期望: 4)", out_matrix[3*DATA_WIDTH +: DATA_WIDTH]);
    
    // 结束仿真
    #100;
    $display("仿真完成");
    $finish;
end

// 波形记录
initial begin
    $dumpfile("single_kernel.vcd");
    $dumpvars(0, tb_single_kernel);
end

endmodule