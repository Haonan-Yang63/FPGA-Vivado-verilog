module whole(
    input  clk,
    input  reset,
    input wire EN,                          // enable signal for the accelerator, high for active

    input wire [12:0] IADDR,                // input address for shared SRAM
    input wire [12:0] WADDR,                // weight address for shared SRAM
    input wire [12:0] OADDR,                // output address for shared SRAM
    input wire [127:0] input_data,
     input wire [127:0] weight_data,
    // 输入缓冲区接口
    output reg [384*8*16-1:0] matrix_C1_reg,
    output wire [32*8*16-1:0] matrix_C1,
    output wire [16*4*16-1:0]matrix_C2,
output wire [1*8*16-1:0] matrix_C3,
output wire [1*271*16-1:0]matrix_C4,
    output reg [384*16*16-1:0] matrix_C2_reg,
    output reg  [1*256*16-1:0] matrix_C3_reg,
    output reg  [1*271*16-1:0]matrix_C4_reg,
//  output wire [32*16-1:0] a_rows_delayed,
//   output  wire [8*16-1:0] b_cols_delayed,
    output wire        input_done,
    output wire [127:0] input_Q,
    output wire        weight_Q,
    output wire [127:0] output_Q
     
);

//------------------------------------------------------------------------------
// 缓冲区实例化
//------------------------------------------------------------------------------
wire [5:0] STATE;
wire weight_ren;
wire weight_cen;
wire weight_wen;
wire [12:0] weight_addr;
wire input_ren;
wire input_cen;
wire input_wen;
wire [12:0] input_addr;
wire output_ren;
wire output_cen;
wire output_wen;
wire [12:0] output_addr;
reg[127:0] output_data;
control controller(
        .CLK(CLK),
        .RESET(RESET),
        .EN(EN),
        .STATE(STATE),
        .weight_wen(weight_wen),
        .weight_ren(weight_ren),
        .weight_cen(weight_cen),
        .weight_addr(weight_addr),
        .input_wen(input_wen),
        .input_ren(input_ren),
        .input_cen(input_cen),
        .input_addr(input_addr),
        .output_wen(output_wen),
        .output_ren(output_ren),
        .output_cen(output_cen),
        .output_addr(output_addr),
        .IADDR(IADDR),
        .WADDR(WADDR),
        .OADDR(OADDR)
    );


input_buffer input_buffer (
    .done(input_done),
    .Q(input_Q),
    .CLK(clk),
    .CEN(input_cen),
    .WEN(input_wen),
    .A(input_addr),
    .RESET(reset),
    .D(input_data),
    .RETN(input_ren)
);

weight_buffer weight_buffer (
    .Q(weight_Q),
    .CLK(clk),
    .CEN(weight_cen),
    .WEN(weight_wen),
    .A(weight_addr),
    .RESET(reset),
    .D(weight_data),
    .RETN(weight_ren)
);

output_buffer output_buffer (
    .Q(output_Q),
    .CLK(clk),
    .CEN(output_cen),
    .WEN(output_wen),
    .A(output_addr[10:0]), 
    .RESET(reset),
    .D(output_data), 
    .RETN(output_ren)
);


//------------------------------------------------------------------------------
// 计算模块驱动逻辑
//------------------------------------------------------------------------------
parameter IDLE = 6'd0;      
parameter INPUT = 6'd1;   

parameter CALCULATE1 = 6'd2;
parameter CALCULATE2 = 6'd3;
parameter CALCULATE3 = 6'd4;
parameter CALCULATE4 = 6'd5;
parameter OUTPUT = 6'd6;
parameter RETURN = 6'd7;

reg [5:0]state=0;
reg start1, start2,start3,start4;
//wire [32*8*16-1:0] matrix_C1;
//wire [16*4*16-1:0]matrix_C2;
//wire [1*8*16-1:0] matrix_C3;
//wire [1*271*16-1:0]matrix_C4;
wire done1,done2,done3,done4;

// 从缓冲区加载数据到计算模块
reg [32*15*16-1:0] matrix_A1;  // 32x15矩阵 (每个元素16-bit)
reg [15*8*16-1:0]  matrix_B1;   // 15x8矩阵
reg [16*4*16-1:0] matrix_A2;
reg [4*8*16-1:0]  matrix_B2;
reg [1*64*16-1:0] matrix_A3;
reg [64*8*16-1:0]  matrix_B3;
reg [2*1*16-1:0] matrix_A4;
reg [271*2*16-1:0]  matrix_B4;
////------------------------------------------------------------------------------

integer cnt=0;
always @(posedge clk) begin
    if (~reset) begin
        matrix_A1 <= {32*15{16'h0001}};
        matrix_B1 <= {15*8{16'h0001}};
        matrix_A2 <= {16*4{16'h0001}};
        matrix_B2 <= {4*8{16'h0001}};
        matrix_A3 <= {1*64{16'h0001}};
        matrix_B3 <= {64*8{16'h0001}};
        matrix_A4 <= {2*1{16'h0001}};
        matrix_B4 <= {271*2{16'h0001}};
        matrix_C1_reg<=0;
        matrix_C2_reg<=0;
        matrix_C3_reg<=0;
        matrix_C4_reg<=0;
        start1 <= 0;
        start2 <= 0;
        start3 <= 0;
        state<=INPUT;
        start4 <= 0;
    end else if(EN)begin
        // 使用 case 语句替代多个 if 条件
        case (state) // 通过 case 模拟优先级逻辑
            INPUT: begin          
                start1 <= 1'b1;
                state<=CALCULATE1;           
            end
            
            CALCULATE1:begin
            if(done1==1) begin
               cnt<=cnt+1;
               if(cnt%4==0)begin
                    matrix_C1_reg[(cnt/4)*32*8*16+:32*8*16]<=matrix_C1;
                end
                else begin
                   matrix_C1_reg[(cnt/4)*32*8*16+:32*8*16]<=matrix_C1+ matrix_C1_reg[(cnt/4)*32*8*16+:32*8*16];
                end
            if(cnt>47)begin
               start1 <= 1'b0;
               start2<=1'b1;
               state<=CALCULATE2;
               matrix_A2 <= {16*4{matrix_C1_reg[15:0]}};
               cnt<=0;
               end
              end
            end
            
            CALCULATE2:begin
            if(done2==1) begin
               cnt<=cnt+1;
               if(cnt%2==0)begin
                    matrix_C2_reg[(cnt/2)*16*8*16+:16*8*16]<=matrix_C2;
                end
                else begin
                   matrix_C2_reg[(cnt/2)*16*8*16+:16*8*16]<=matrix_C2+ matrix_C2_reg[(cnt/2)*16*8*16+:16*8*16];
                end
            if(cnt>95)begin
               start2 <= 1'b0;
               start3<=1'b1;
               state<=CALCULATE3;
               matrix_A3 <= {64{16'h1}};
               cnt<=0;
               end
              end        
            end
            // 可以添加更多条件分支
            CALCULATE3:begin
             if(done3==1) begin
               cnt<=cnt+1;
               if(cnt%96==0)begin
                    matrix_C3_reg[(cnt/96)*1*8*16+:1*8*16]<=matrix_C3;
                end
                else begin
                   matrix_C3_reg[(cnt/96)*1*8*16+:1*8*16]<=matrix_C3+ matrix_C3_reg[(cnt/96)*1*8*16+:1*8*16];
                end
            if(cnt>(96*32-1))begin
               start3 <= 1'b0;
               start4<=1'b1;
               state<=CALCULATE4;
               matrix_A4 <= {2{16'h2}};
               cnt<=0;
               end
              end             
            end
            
            CALCULATE4:begin
            if(done4==1&&matrix_C4!=0) begin
               cnt<=cnt+1;
               if(cnt%128==0)begin
                    matrix_C4_reg[(cnt/128)*1*271*16+:1*271*16]<=matrix_C4;
                end
                else begin
                   matrix_C4_reg[(cnt/128)*1*271*16+:1*271*16]<=matrix_C4+ matrix_C4_reg[(cnt/128)*1*271*16+:1*271*16];
                end
                end
            if(cnt>(127))begin
               start4 <= 1'b0;
               state<=OUTPUT;
               cnt<=0;
               end        
            end
            
            OUTPUT:begin
                output_data<=matrix_C4_reg[15:0];
                state<=INPUT;
            end
            default: begin
                start1 <= 1'b0;
                start2 <= 1'b0;
                start3<=1'b0;
                start4<=1'b0;
            end
        endcase
    end
    else begin
        matrix_A1 <= {32*15{16'h0001}};
        matrix_B1 <= {15*8{16'h0001}};
        matrix_A2 <= {16*4{16'h0001}};
        matrix_B2 <= {4*8{16'h0001}};
        matrix_A3 <= {1*64{16'h0001}};
        matrix_B3 <= {64*8{16'h0001}};
        matrix_A4 <= {2*1{16'h0001}};
        matrix_B4 <= {271*2{16'h0001}};
        matrix_C1_reg<=0;
        matrix_C2_reg<=0;
        matrix_C3_reg<=0;
        matrix_C4_reg<=0;
        start1 <= 0;
        start2 <= 0;
        start3 <= 0;
        state<=INPUT;
        start4 <= 0;
    end
end

//------------------------------------------------------------------------------
// 计算模块实例化
//------------------------------------------------------------------------------
temporal_filter #(
    .M(32),
    .K(15),
    .N(8),
    .DATA_WIDTH(16)
) dut1 (
    .clk(clk),
    .reset(reset),
    .start(start1),
    .matrix_A(matrix_A1),
    .matrix_B(matrix_B1),
    .matrix_C(matrix_C1),
//    .a_rows_delayed(a_rows_delayed),
//.b_cols_delayed(b_cols_delayed),
    .done(done1)
);

temporal_filter #(
    .M(16),
    .K(4),
    .N(8),
    .DATA_WIDTH(16)
) dut2 (
    .clk(clk),
    .reset(reset),
    .start(start2),
    .matrix_A(matrix_A2),
    .matrix_B(matrix_B2),
    .matrix_C(matrix_C2),
    .done(done2)  
);

 spatial_filter #(
        .DATA_WIDTH(16),
        .COL(64),
        .ROW(8))
    uut (
        .clk(clk),
        .reset(reset),
         .start(start3),
        .matrix1(matrix_A3),
        .matrix2(matrix_B3),
        .result(matrix_C3),
        .done(done3)
    );
 classifier #(
        .DATA_WIDTH(16),
        .COL(2),
        .ROW(271))
    uut2 (
        .clk(clk),
        .reset(reset),
         .start(start4),
        .matrix1(matrix_A4),
        .matrix2(matrix_B4),
        .result(matrix_C4),
        .done(done4)
    );


endmodule