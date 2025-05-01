`timescale 1ns / 1ps

module tetris_tb();

    // Testbench parameters
    parameter CLK_PERIOD = 10;     // 100 MHz clock (10 ns period)
    parameter FRAME_TIME = 16666667; // ~16.67ms for 60Hz frame
    parameter RESET_DURATION = 1000; // 1us reset pulse
    
    // DUT signals
    logic clk_100MHz;
    logic reset_rtl_0;
    
    // HDMI outputs
    wire TMDS_CLK_P;
    wire TMDS_CLK_N;
    wire [2:0] TMDS_DATA_P;
    wire [2:0] TMDS_DATA_N;
    
    // Instantiate the DUT
    tetris_top dut (
        .clk_100MHz(clk_100MHz),
        .reset_rtl_0(reset_rtl_0),
        .TMDS_CLK_P(TMDS_CLK_P),
        .TMDS_CLK_N(TMDS_CLK_N),
        .TMDS_DATA_P(TMDS_DATA_P),
        .TMDS_DATA_N(TMDS_DATA_N)
    );
    
    // Clock generation
    initial begin
        clk_100MHz = 0;
        forever #(CLK_PERIOD/2) clk_100MHz = ~clk_100MHz;
    end
    
    // Reset generation with proper timing
    initial begin
        reset_rtl_0 = 1;
        #RESET_DURATION;
        reset_rtl_0 = 0;
        $display("Reset released at %t", $time);
    end
    
    // Monitor clock locking
    always @(posedge clk_100MHz) begin
        if (dut.locked) begin
            $display("PLL locked at %t", $time);
            // Stop monitoring after lock
            disable monitor_pll;
        end
    end
    
    initial begin : monitor_pll
        #(RESET_DURATION + 1000);
        if (!dut.locked) begin
            $display("Warning: PLL failed to lock!");
        end
    end
    
    // Main simulation control
    initial begin
        // Wait for PLL lock
        #(RESET_DURATION + 2000);
        
        if (!dut.locked) begin
            $display("Error: Simulation cannot continue without PLL lock");
            $finish;
        end
        
        // Run for several frames
        #(10 * FRAME_TIME);
        
        // Check final state
        $display("Simulation completed successfully at %t", $time);
        $finish;
    end
    
    // Monitor HDMI signals
    always @(posedge clk_100MHz) begin
        if (!reset_rtl_0 && dut.locked) begin
            if (TMDS_CLK_P === 1'bx || TMDS_CLK_N === 1'bx) begin
                $display("Warning: Undefined HDMI clock at %t", $time);
            end
            if (^TMDS_DATA_P === 1'bx || ^TMDS_DATA_N === 1'bx) begin
                $display("Warning: Undefined HDMI data at %t", $time);
            end
        end
    end
    
    // VCD dump with improved signal selection
    initial begin
        $dumpfile("tetris_tb.vcd");
        $dumpvars(0, tetris_tb);
        // Monitor all clocks and resets
        $dumpvars(1, dut.clk_100MHz, dut.clk_25MHz, dut.clk_125MHz);
        $dumpvars(1, dut.reset_rtl_0, dut.game_reset, dut.locked);
        // Monitor HDMI signals
        $dumpvars(2, dut.TMDS_CLK_P, dut.TMDS_CLK_N);
        $dumpvars(2, dut.TMDS_DATA_P, dut.TMDS_DATA_N);
        // Monitor game state
        $dumpvars(3, dut.game_logic_inst);
    end

endmodule