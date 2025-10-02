module weight_buffer(
    output reg  [127:0] Q,
    input  wire         CLK,
    input  wire         CEN,
    input  wire         WEN,
    input  wire [15:0]   A, //10
    input  wire         RESET,  // 假设低有效复位
    input  wire [127:0] D,
    input  wire         RETN
);
    integer i;
    parameter DEPTH = 50000;
    (* ram_style = "block" *) reg [127:0] mem [0:DEPTH-1];  // 推断为 BRAM

    always @(posedge CLK) begin
        if (~RESET) begin
//            for (i = 0; i < DEPTH; i=i+1) 
//                mem[i] <= 128'b0;
            Q <= 128'd0;
        end
        else if (~WEN & RETN) begin
            if (A < DEPTH) 
                mem[A] <= D;  // 全字写入
            Q <= 128'd0;
        end
        else if (~CEN & RETN) begin
            Q <= mem[A];     // 读取
        end
        else begin
            Q <= 128'd0;     // 默认输出
        end
    end
endmodule