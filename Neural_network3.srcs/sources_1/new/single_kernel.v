module single_kernel #(
  parameter ROW = 32,
  parameter COL = 8,
  parameter DATA_WIDTH = 16
) (
  input clk,
  input reset,
  input enable,
  input [ROW*COL-1:0] finish,                   //  编号规则：                     
  input [COL*DATA_WIDTH-1:0] in_up,              //          0_0 ---- 0_COL-1                        
  input [ROW*DATA_WIDTH-1:0] in_left,            //           |        |      
  output [COL*DATA_WIDTH-1:0] pass_down,         //           |        |        
  output [ROW*DATA_WIDTH-1:0] pass_right,        //          ROW-1_0 ----ROW-1_COL-1              
  output [ROW*COL*DATA_WIDTH-1:0] out_matrix   //  
);
  genvar i,j,k;
  wire [ROW*COL*DATA_WIDTH-1:0] inner_pass_down;
  wire [ROW*COL*DATA_WIDTH-1:0] inner_pass_right;
  generate
    for (i=0; i<ROW; i=i+1) begin
      for (j=0; j<COL; j=j+1) begin
        if (i==0 && j==0) begin           // 左上角。the upper-left PE
          single_PE_rounded # (DATA_WIDTH, DATA_WIDTH/2) 
          pe (clk,enable,reset,finish      [i*COL+j], 
              in_up            [j*DATA_WIDTH                +:DATA_WIDTH], 
              in_left          [i*DATA_WIDTH                +:DATA_WIDTH],
              inner_pass_down  [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH], 
              inner_pass_right [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH],
              out_matrix       [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH]);
        end else if (i==0 && j!=0) begin  // 最上一行。PEs in the upper-most row
          single_PE_rounded # (DATA_WIDTH, DATA_WIDTH/2) 
          pe (clk, enable,reset,finish      [i*COL+j], 
              in_up            [j*DATA_WIDTH +:DATA_WIDTH], 
              inner_pass_right [(i*COL+j-1)*DATA_WIDTH +:DATA_WIDTH],
              inner_pass_down  [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH],
              inner_pass_right [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH],
              out_matrix       [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH]);
        end else if (i!=0&& j==0) begin  // 最左一列。PEs in the left-most column
          single_PE_rounded # (DATA_WIDTH, DATA_WIDTH/2) 
          pe (clk, enable,reset,finish      [i*COL+j], 
              inner_pass_down  [((i-1)*COL+j)*DATA_WIDTH +:DATA_WIDTH], 
              in_left          [i*DATA_WIDTH                +:DATA_WIDTH],
              inner_pass_down  [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH], 
              inner_pass_right [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH],
              out_matrix       [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH]);
        end else begin                          // 其他PE。all other PEs
          single_PE_rounded # (DATA_WIDTH, DATA_WIDTH/2) 
          pe (clk, enable,reset,finish      [i*COL+j], 
              inner_pass_down  [((i-1)*COL+j)*DATA_WIDTH +:DATA_WIDTH], 
              inner_pass_right [(i*COL+j-1)*DATA_WIDTH +:DATA_WIDTH],
              inner_pass_down  [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH], 
              inner_pass_right [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH],
              out_matrix       [(i*COL+j)*DATA_WIDTH   +:DATA_WIDTH]);
        end end end
  endgenerate
  
// 向下侧阵列传递。pass data downward to other PE arays
// 向下侧阵列传递。pass data rightward to other PE arays
  generate
    for (k=0; k<COL; k=k+1) begin              
      assign  pass_down        [k*DATA_WIDTH              +:DATA_WIDTH]
            = inner_pass_down  [((ROW-1)*COL+k)*DATA_WIDTH +:DATA_WIDTH];
    end
    for (k=0; k<ROW; k=k+1) begin
      assign  pass_right       [k*DATA_WIDTH              +:DATA_WIDTH] 
            = inner_pass_right [(k*COL+COL-1)*DATA_WIDTH +:DATA_WIDTH];     
    end      
  endgenerate
endmodule