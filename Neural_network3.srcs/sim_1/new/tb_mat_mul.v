`timescale 1ns / 1ps

module tb_mat_mul();

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter COL = 4;
    parameter ROW = 3;
    
    // Clock and reset
    reg clk;
    reg reset;
    reg start;
    // Inputs
    reg [COL*DATA_WIDTH-1:0] matrix1;
    reg [COL*ROW*DATA_WIDTH-1:0] matrix2;
    
    // Output
    wire [ROW*DATA_WIDTH-1:0] result;
    
    // Instantiate the DUT
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
        .result(result)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test vectors
    integer i, j;
    reg [DATA_WIDTH-1:0] expected_result [0:ROW-1];
    
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 0;
        start=0;
        matrix1 = 0;
        matrix2 = 0;
        
        // Apply reset
        #10 reset = 1;
        #10 reset = 0;
        #10 reset = 1;
        
        // Test Case 1: Simple test with small values
        $display("Test Case 1: Simple test");
        for (i = 0; i < COL; i = i + 1) begin
            matrix1[i*DATA_WIDTH +: DATA_WIDTH] = 1;  // All elements = 1
            for (j = 0; j < ROW; j = j + 1) begin
                matrix2[(i*ROW + j)*DATA_WIDTH +: DATA_WIDTH] = j + 1;
            end
        end
        
        // Calculate expected results
        for (j = 0; j < ROW; j = j + 1) begin
            expected_result[j] = COL * (j + 1);
        end
        
        // Wait for computation
        #100;
        
        
        // Test Case 2: Random values test
        $display("\nTest Case 2: Random values test");
        for (i = 0; i < COL; i = i + 1) begin
            matrix1[i*DATA_WIDTH +: DATA_WIDTH] = $random % 16;  // Random values 0-15
            for (j = 0; j < ROW; j = j + 1) begin
                matrix2[(i*ROW + j)*DATA_WIDTH +: DATA_WIDTH] = $random % 16;
            end
        end
        
        // Calculate expected results
        for (j = 0; j < ROW; j = j + 1) begin
            expected_result[j] = 0;
            for (i = 0; i < COL; i = i + 1) begin
                expected_result[j] = expected_result[j] + 
                                    (matrix1[i*DATA_WIDTH +: DATA_WIDTH] * 
                                     matrix2[(i*ROW + j)*DATA_WIDTH +: DATA_WIDTH]);
            end
            expected_result[j] = expected_result[j];
        end
        
        // Wait for computation
        #100;
        
       
        // Test Case 3: Edge case with maximum values
        $display("\nTest Case 3: Maximum values test");
        for (i = 0; i < COL; i = i + 1) begin
            matrix1[i*DATA_WIDTH +: DATA_WIDTH] = {DATA_WIDTH{1'b1}};  // All bits 1
            for (j = 0; j < ROW; j = j + 1) begin
                matrix2[(i*ROW + j)*DATA_WIDTH +: DATA_WIDTH] = {DATA_WIDTH{1'b1}};
            end
        end
        
        // Calculate expected results
        for (j = 0; j < ROW; j = j + 1) begin
            expected_result[j] = (COL * ((2**DATA_WIDTH-1) * (2**DATA_WIDTH-1)));
        end
        
        // Wait for computation
        #100;
        
       
        
        // End simulation
        #100;
        $display("Simulation completed");
        $finish;
    end
    
    // Monitor changes
    initial begin
        $monitor("At time %0t: reset = %b", $time, reset);
    end
    
endmodule