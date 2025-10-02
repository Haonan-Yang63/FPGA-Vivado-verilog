

module tb_whole();

    // Clock and reset signals
    reg clk;
    reg reset;
    
    // Module inputs
    reg EN;
    reg [12:0] IADDR;
    reg [12:0] WADDR;
    reg [12:0] OADDR;
    reg [127:0] input_data;
    reg [127:0] weight_data;
    
    // Module outputs
    wire input_done;
    wire [127:0] input_Q;
    wire weight_Q;
    wire [127:0] output_Q;
    wire [384*8*16-1:0] matrix_C1_reg;
    wire [32*8*16-1:0] matrix_C1;
   wire [16*4*16-1:0]matrix_C2;
wire [1*8*16-1:0] matrix_C3;
wire [1*271*16-1:0]matrix_C4;
    wire [384*16*16-1:0] matrix_C2_reg;
    wire [1*256*16-1:0] matrix_C3_reg;
    wire [1*271*16-1:0] matrix_C4_reg;
//    wire [32*16-1:0] a_rows_delayed;
//   wire [8*16-1:0] b_cols_delayed;
    integer i;
    // Instantiate the DUT
    whole dut (
        .clk(clk),
        .reset(reset),
        .EN(EN),
        .IADDR(IADDR),
        .WADDR(WADDR),
        .OADDR(OADDR),
        .input_data(input_data),
        .weight_data(weight_data),
        .matrix_C1_reg(matrix_C1_reg),
        .matrix_C1(matrix_C1),
        .matrix_C2(matrix_C2),
        .matrix_C3(matrix_C3),
        .matrix_C4(matrix_C4),
        .matrix_C2_reg(matrix_C2_reg),
        .matrix_C3_reg(matrix_C3_reg),
        .matrix_C4_reg(matrix_C4_reg),
//        .a_rows_delayed(a_rows_delayed),
//.b_cols_delayed(b_cols_delayed),
        .input_done(input_done),
        .input_Q(input_Q),
        .weight_Q(weight_Q),
        .output_Q(output_Q)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Reset generation
    initial begin
        reset = 0;
        #10 reset = 1;
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        EN = 0;
        IADDR = 0;
        WADDR = 0;
        OADDR = 0;
        input_data = 0;
        weight_data = 0;
        
        // Wait for reset to complete
        #50;
        
        // Enable the accelerator
        EN = 1;
        
        // Load input data (simplified - in real test you'd load actual matrices)
        for (i = 0; i < 100; i=i+1) begin
            @(posedge clk);
            IADDR = i;
            input_data = $random; // Random data for simulation
        end
        
        // Load weight data
        for (i = 0; i < 100; i=i+1) begin
            @(posedge clk);
            WADDR = i;
            weight_data = $random; // Random data for simulation
        end
        
        // Wait for computation to complete
        
        // Read output data
        for (i = 0; i < 20; i=i+1) begin
            @(posedge clk);
            OADDR = i;
        end
        
    end
    
    // Monitor state changes
    
    // Waveform dumping
    initial begin
        $dumpfile("whole_tb.vcd");
        $dumpvars(0, tb_whole);
    end
    
endmodule