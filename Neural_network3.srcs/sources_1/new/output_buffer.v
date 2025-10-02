// output buffer, ref: shared_buffer
// input buffer, ref: shared_buffer\
//10kb
module output_buffer(
    output reg  [127:0] Q,
    input  wire         CLK,
    input  wire         CEN,  //读取
    input  wire         WEN, //写入
    input  wire    [10:0]     A,
    input  wire         RESET,  // 假设低有效复位
    input  wire [127:0] D,
    input  wire         RETN
    );
integer i;
integer j;
//reg [12:0] count;
reg [127:0] mem[0:271];
always @(posedge CLK)
begin
        if (~RESET) begin
//            for (i = 0; i < DEPTH; i=i+1) 
//                mem[i] <= 128'b0;
            Q <= 127'd0;
        end
    else if(~WEN & RETN) begin
        Q <= 127'd0;
        mem[A]<=D;
    end 
    else if(~CEN & RETN) begin
        Q <= mem[A];
    end 
    else begin
        Q <= 127'd0;
    end
end

endmodule