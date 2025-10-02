module systolic_array#(
  parameter M = 32,  // A的行数
  parameter K = 15,  // A的列数（B的行数）
  parameter N = 8,   // B的列数
  parameter DATA_WIDTH = 16
) (
  input clk,
  input reset,
  input start,      // 启动计算
  input [M*K*DATA_WIDTH-1:0] matrix_A, // A (M×K)
  input [N*K*DATA_WIDTH-1:0] matrix_B, // B (K×N)
  output reg[M*N*DATA_WIDTH-1:0] matrix_C, // C = A×B (M×N)
//  output reg [M*DATA_WIDTH-1:0] a_rows_delayed,
//   output  reg [N*DATA_WIDTH-1:0] b_cols_delayed,
//   output wire [M*N*DATA_WIDTH-1:0] pe_out_matrix,
//    output wire [M*N*DATA_WIDTH-1:0] inner_pass_down,
//  output  wire [M*N*DATA_WIDTH-1:0] inner_pass_right, 
  output reg done       // 计算完成
);
  reg [M*N-1:0] finish;
reg enable=0;
  // ===== 数据输入延迟控制 =====
reg [M*DATA_WIDTH-1:0] a_rows_delayed;
reg [N*DATA_WIDTH-1:0] b_cols_delayed;
  reg [DATA_WIDTH-1:0] tempa[0:M-1][0:M+K-2];
  reg [DATA_WIDTH-1:0] tempb[0:N-1][0:N+K-2];
  wire [N*DATA_WIDTH-1:0] pass_down;
  wire [M*DATA_WIDTH-1:0] pass_right;
  wire [M*N*DATA_WIDTH-1:0] pe_out_matrix;
  // ===== 控制逻辑 =====
  localparam READY = 0;
  localparam START = 1;
  localparam DONE = 2;
  reg[1:0] state;
  integer cnt;
  integer i, j;


// ===== PE阵列实例化 =====
  single_kernel #(
    .ROW(M),
    .COL(N),
    .DATA_WIDTH(DATA_WIDTH)
  ) pe_array (
    .clk(clk),
    .enable(enable),
    .reset(reset),
    .finish(finish),
    .in_up(b_cols_delayed),
    .in_left(a_rows_delayed),
    .pass_down(pass_down),
    .pass_right(pass_right),
    .out_matrix(pe_out_matrix)
  );
  
  // ===== 复位与初始化 =====
  always @(negedge clk) begin
   
     if (~reset) begin
      cnt <= 0;
      enable<=0;
      done <= 0;
      finish <= {M*N{1'b0}};
      a_rows_delayed <= 0;
      b_cols_delayed <= 0;
      state <= READY;
      matrix_C<=0;
      // 清空延迟线
      for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < M+K-1; j = j + 1) begin
          tempa[i][j] <= 0;
        end
      end
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N+K-1; j = j + 1) begin
          tempb[i][j] <= 0;
        end
      end
    end
    
    else begin
      case (state)
        READY: begin
         cnt <= 0;
      done <= 0;
      enable<=0;
      finish <= {M*N{1'b0}};
      a_rows_delayed <= 0;
      b_cols_delayed <= 0;
      state <= READY;
      
      // 清空延迟线
      for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < M+K-1; j = j + 1) begin
          tempa[i][j] <= 0;
        end
      end
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N+K-1; j = j + 1) begin
          tempb[i][j] <= 0;
        end
      end
          if (start) begin
            // 预加载矩阵数据到延迟线
            for (i = 0; i < M; i = i + 1) begin
              for (j = 0; j < M+K-1; j = j + 1) begin
                tempa[i][j] <= (j > i-1 && j < K+i) ? 
                              matrix_A[(i*K + j-i)*DATA_WIDTH +: DATA_WIDTH] : 0;
              end
            end
            
            for (i = 0; i < N; i = i + 1) begin
              for (j = 0; j < N+K-1; j = j + 1) begin
               tempb[i][j] <= (j >= i && j < K+i) ? 
                  matrix_B[((j-i)*N + i)*DATA_WIDTH +: DATA_WIDTH] : 0;
              end
            end
            
            cnt <= 0;
            state <= START;
          end
        end
        
        START: begin
        enable<=1;
          // 传递数据到PE阵列
          for (i = 0; i < M; i = i + 1) begin
            a_rows_delayed[i*DATA_WIDTH +: DATA_WIDTH] <= tempa[i][cnt];
          end
          for (i = 0; i < N; i = i + 1) begin
            b_cols_delayed[i*DATA_WIDTH +: DATA_WIDTH] <= tempb[i][cnt];
          end
          
          if(cnt>M+K-2) a_rows_delayed<=0;
          if(cnt>N+K-2) b_cols_delayed<=0;
          cnt <= cnt + 1;
          
          // 计算完成条件
          if (cnt > K + M + N-1) begin
            finish <= {M*N{1'b1}}; // matrix_C <= pe_out_matrix;
            state <= DONE;
          end
        end
        
        DONE: begin
          done <= 1;
           matrix_C <= pe_out_matrix;
          enable<=0;
          state <= READY;
        end
      endcase
    end
  end


endmodule