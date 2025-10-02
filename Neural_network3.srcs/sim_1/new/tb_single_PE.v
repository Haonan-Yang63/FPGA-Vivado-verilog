`timescale 1ns/1ps

module tb_single_PE();
  // Parameters
  parameter DATA_WIDTH = 16;
  parameter Half_WIDTH = 8;
  
  // Testbench variables
  reg clk;
  reg reset;
  reg enable;
  reg finish;
  reg [DATA_WIDTH-1:0] i_up;
  reg [DATA_WIDTH-1:0] i_left;
  wire [DATA_WIDTH-1:0] o_down;
  wire [DATA_WIDTH-1:0] o_right;
  wire [DATA_WIDTH-1:0] o_result;
//  wire [DATA_WIDTH-1:0] partial_sum;
  // Instantiate the DUT
  single_PE_rounded #(
    .DATA_WIDTH(DATA_WIDTH),
    .Half_WIDTH(Half_WIDTH)
  ) dut (
    .clk(clk),
    .enable(enable),
    .reset(reset),
    .finish(finish),
    .i_up(i_up),
    .i_left(i_left),
    .o_down(o_down),
    .o_right(o_right),
//    .partial_sum(partial_sum),
    .o_result(o_result)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    reset=1;
    forever #5 clk = ~clk; // 100MHz clock
  end
  
  // Test stimulus
  initial begin
    // Initialize inputs
    finish = 0;
    i_up = 0;
    i_left = 0;
    enable=1;
    // Wait for reset (if any) - not in this design but good practice
    #20;
    
    // Test Case 1: Simple multiplication (4 * 5)
    i_up = 16'h0001;   // 4
    i_left = 16'h0002; // 5
    finish = 0;
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // After 1 clock cycle, the result should be (4*5)>>4 = 1 (with partial_sum=1)
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // Test Case 2: New inputs (8 * 3)
    i_up = 16'h0003;   // 8
    i_left = 16'h0004; // 3
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // After 1 clock cycle, partial_sum should be 1 + (8*3)>>4 = 1 + 1 = 2
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // Test Case 3: Finish signal asserted
    i_up = 16'h0003;   // 16
    i_left = 16'h0004; // 2
    finish = 1;
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // After finish, partial_sum should reset to (16*2)>>4 = 2
    // and o_result should capture the previous partial_sum (2)
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // Test Case 4: Continue after finish
    i_up = 16'h000A;   // 10
    i_left = 16'h000A; // 10
    finish = 0;
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // After 1 clock cycle, partial_sum should be 2 + (10*10)>>4 = 2 + 6 = 8
    #10;
    $display("Time: %0t, i_up=%d, i_left=%d, partial_sum=%d, o_result=%d", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // Test Case 5: Edge case with maximum values
    i_up = 16'hFFFF;   // -1 or 65535 depending on interpretation
    i_left = 16'hFFFF; // -1 or 65535
    finish = 1;
    #10;
    $display("Time: %0t, i_up=%h, i_left=%h, partial_sum=%h, o_result=%h", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    #10;
    $display("Time: %0t, i_up=%h, i_left=%h, partial_sum=%h, o_result=%h", 
             $time, i_up, i_left, dut.partial_sum, o_result);
    
    // End simulation
    #20;
    $display("Simulation completed");
    $finish;
  end
  
  // Monitor changes
  initial begin
    $monitor("Time: %0t, clk=%b, finish=%b, i_up=%h, i_left=%h, o_down=%h, o_right=%h, o_result=%h",
             $time, clk, finish, i_up, i_left, o_down, o_right, o_result);
  end
  
  // VCD dump for waveform viewing
  initial begin
    $dumpfile("tb_single_PE_rounded.vcd");
    $dumpvars(0, tb_single_PE);
  end
endmodule