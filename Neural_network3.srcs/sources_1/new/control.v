`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2025 07:56:26 AM
// Design Name: 
// Module Name: control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module control(
    // interface to system
    input wire CLK,                         // CLK
    input wire RESET,                       // RESET, Negedge is active
    input wire EN,                          // enable signal for the accelerator, high for active
  
    output reg [5:0] STATE,                // output state for the tb to check the runtime...
    

    // interface to buffers (control)
    input wire [10:0] IADDR,                // input address for shared SRAM
    input wire [15:0] WADDR,                // weight address for shared SRAM
    input wire [12:0] OADDR,                // output address for shared SRAM
//    //input buffer
    output reg input_wen,
    output reg input_ren,
    output reg input_cen,
    output reg input_addr,
    // input wire [127:0] input_data
    // weight buffer
    output reg weight_wen,
    output reg weight_ren,
    output reg weight_cen,
    output reg [12:0] weight_addr,

    // output buffer
    output reg output_wen,
    output reg output_ren,
    output reg output_cen,
    output reg [15:0] output_addr
    );
parameter IDLE = 6'd0;      
parameter INPUT = 6'd1;   

parameter CALCULATE = 6'd2;
parameter OUTPUT = 6'd3;
parameter RETURN = 6'd4;
parameter OUTPUTTOSHARE = 6'd4;
//parameter 
// reg [12:0] input_addr;
// reg [12:0] weight_addr;
// reg [12:0] output_addr;
// reg [12:0] count;
always @(posedge CLK or negedge RESET) begin
    if(~RESET) begin
        // reset
        STATE <= IDLE;
        // interface to buffers (control)
        // input_addr <= 0;
        // output_addr <= 0;
        //input buffer
        input_wen <= 1;//高电平不允许写入
        input_ren <= 0;//
        input_cen <= 1;//高电平不允许读取
        input_addr <= 0;//
        // weight buffer
        weight_wen <= 1;
        weight_ren <= 0;
        weight_cen <= 1;
        weight_addr <= 0;
        // output buffer
        output_wen <= 1;
        output_ren <= 0;
        output_cen <= 1;
        output_addr <= 0;
    end else if (EN) begin
        // state transform logic
        if (STATE == IDLE) begin
            STATE <= INPUT;
            input_wen <= 0;//允许写入
            input_ren <= 1;
            input_cen <= 1;//不允许读取
            input_addr <= 0;//读取第一个地址的数据
            weight_wen <= 0;//允许读取
            weight_ren <= 1;
            weight_cen <= 1;//不允许读取权重

        end
        else if(STATE == INPUT)begin
            //输入weight进入weight buffer
            input_addr <= input_addr +1;//读取下一个地址的数据
            weight_addr<=weight_addr+1;
            if(input_addr > IADDR-1&&weight_addr > WADDR-1)begin
                input_addr <= 0;//超出地址范围，地址回到第一个地址
                STATE <= CALCULATE;//所有的数据已经被读取，开始计算
                weight_addr <= 0;
            end
        end
   

        else if (STATE == CALCULATE)begin
           
            weight_wen <= 1;
            weight_ren <= 1;
            weight_cen <= 0;

            
            if(weight_addr > WADDR-1)begin
                STATE <= OUTPUT;
                weight_wen <= 1;
                weight_ren <= 0;
                weight_cen <= 1;
                //OUTPUT BUFFER OPEN
                output_addr <= 0;
                output_wen <= 0;
                output_ren <= 1;
                output_cen <= 1;
            end
        end
        else if (STATE == OUTPUT)begin
            output_addr <= output_addr + 1;
            if(output_addr == 34)begin//一次送128/16=8个数据，一共271个数据，要送34次
                STATE <= RETURN;
            end
        end
        else if (STATE == RETURN)begin
            STATE <= IDLE;
        end
    end

end

endmodule
