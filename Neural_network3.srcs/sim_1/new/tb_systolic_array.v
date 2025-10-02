`timescale 1ns / 1ps

module tb_systolic_array();

// Parameters
parameter M = 2;
parameter K = 1;
parameter N = 2;
parameter DATA_WIDTH = 16;

// Clock and Reset
reg clk;
reg reset;
reg start;
// Input Matrices
reg [M*K*DATA_WIDTH-1:0] matrix_A;
reg [N*K*DATA_WIDTH-1:0] matrix_B;
// Outputs
wire [M*N*DATA_WIDTH-1:0] matrix_C;
//wire [M*N*DATA_WIDTH-1:0] pe_out_matrix;
wire done;

// Instantiate DUT
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
//    .pe_out_matrix(pe_out_matrix),
    .done(done)
);

// Clock generation (100MHz)
always #5 clk = ~clk;

// Golden reference model
reg [DATA_WIDTH-1:0] ref_A [0:M-1][0:K-1];
reg [DATA_WIDTH-1:0] ref_B [0:K-1][0:N-1];
reg [DATA_WIDTH-1:0] ref_C [0:M-1][0:N-1];

// Test control
integer test_case;
integer errors;
integer i, j, k;

task automatic load_matrices;
    input integer a_val;
    input integer b_val;
    begin
        // Load matrix A (MxK)
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < K; j = j + 1) begin
                ref_A[i][j] = a_val + i*K + j;
                matrix_A[(i*K + j)*DATA_WIDTH +: DATA_WIDTH] = ref_A[i][j];
            end
        end
        
        // Load matrix B (KxN)
        for (i = 0; i < K; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                ref_B[i][j] = b_val + i*N + j;
                matrix_B[(i*N + j)*DATA_WIDTH +: DATA_WIDTH] = ref_B[i][j];
            end
        end
    end
endtask

task automatic calculate_reference;
    begin
        // Compute reference result
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                ref_C[i][j] = 0;
                for (k = 0; k < K; k = k + 1) begin
                    ref_C[i][j] = ref_C[i][j] + ref_A[i][k] * ref_B[k][j];
                end
            end
        end
    end
endtask



initial begin
    // Initialize
    clk = 0;
    reset = 0;
    start = 0;
    matrix_A = 0;
    matrix_B = 0;
    errors = 0;
    // Reset sequence
    #10 reset = 1;
    #20 reset = 0;
    #10 reset = 1;
    
    // Test Case 1: Simple sequential values
    test_case = 1;
    $display("\n=== Test Case %0d: Sequential values ===", test_case);
    load_matrices(1, 1);  // A starts at 1, B starts at 1
    calculate_reference();
    
    #10 start = 1;
    #10 start = 0;
    
    wait(done == 1);
    #20 ;
    
    // Test Case 2: Random values
    test_case = 2;
    $display("\n=== Test Case %0d: Random values ===", test_case);
    for (i = 0; i < M*K; i = i + 1) begin
        matrix_A[i*DATA_WIDTH +: DATA_WIDTH] = $random % 256;
    end
    for (i = 0; i < K*N; i = i + 1) begin
        matrix_B[i*DATA_WIDTH +: DATA_WIDTH] = $random % 256;
    end
    
    // Load to reference model
    for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < K; j = j + 1) begin
            ref_A[i][j] = matrix_A[(i*K + j)*DATA_WIDTH +: DATA_WIDTH];
        end
    end
    for (i = 0; i < K; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
            ref_B[i][j] = matrix_B[(i*N + j)*DATA_WIDTH +: DATA_WIDTH];
        end
    end
    calculate_reference();
    
    #10 start = 1;
    #10 start = 0;
    
    wait(done == 1);
    #20 ;
    
    // Test Case 3: Edge case (zero matrices)
    test_case = 3;
    $display("\n=== Test Case %0d: Zero matrices ===", test_case);
    matrix_A = 0;
    matrix_B = 0;
    load_matrices(0, 0);
    calculate_reference();
    
    #10 start = 1;
    #10 start = 0;
    
    wait(done == 1);
    #20 ;
    
    // Summary
    $display("\n=== Simulation Summary ===");
    $display("Total test cases: %0d", test_case);
    $display("Total errors: %0d", errors);
    
    if (errors == 0) begin
        $display("PASS: All test cases passed!");
    end else begin
        $display("FAIL: Found %0d errors!", errors);
    end
    
    #100 $finish;
end

// Waveform dumping (for debugging)
initial begin
    $dumpfile("systolic_array.vcd");
    $dumpvars(0, tb_systolic_array);
end

endmodule
