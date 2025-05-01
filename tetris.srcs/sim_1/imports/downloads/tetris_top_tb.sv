// `timescale 1ns / 1ps

// module tetris_tb();

//     // Testbench parameters
//     parameter CLK_PERIOD = 10;      // 100 MHz clock (10 ns period)
//     parameter PLL_LOCK_TIME = 1000; // 1us for PLL to lock
//     parameter RESET_DURATION = 2000; // 2us reset pulse
//     parameter FRAME_TIME = 16666667; // ~16.67ms for 60Hz frame
    
//     // DUT signals
//     logic Clk;              // 100 MHz system clock
//     logic reset_rtl_0;      // Active-high reset
    
//     // HDMI outputs
//     logic hdmi_tmds_clk_p;
//     logic hdmi_tmds_clk_n;
//     logic [2:0] hdmi_tmds_data_p;
//     logic [2:0] hdmi_tmds_data_n;
    
//     // Debug signals
//     logic [7:0] red, green, blue;
//     logic frame_update;
//     logic locked;
//     logic [2:0] dbg_state;
    
//     // Instantiate the DUT
//     tetris_top dut (
//         .Clk(Clk),
//         .reset_rtl_0(reset_rtl_0),
//         .hdmi_tmds_clk_p(hdmi_tmds_clk_p),
//         .hdmi_tmds_clk_n(hdmi_tmds_clk_n),
//         .hdmi_tmds_data_p(hdmi_tmds_data_p),
//         .hdmi_tmds_data_n(hdmi_tmds_data_n)
//     );
    
//     // Connect to internal signals for monitoring
//     assign red = dut.game_logic_inst.red;
//     assign green = dut.game_logic_inst.green;
//     assign blue = dut.game_logic_inst.blue;
//     assign frame_update = dut.game_logic_inst.frame_update;
//     assign locked = dut.locked;
//     assign dbg_state = dut.game_logic_inst.state;

//     // Clock generation
//     initial begin
//         Clk = 0;
//         forever #(CLK_PERIOD/2) Clk = ~Clk;
//     end
    
//     // Reset generation with proper timing
//     initial begin
//         reset_rtl_0 = 1;
//         #RESET_DURATION;
//         reset_rtl_0 = 0;
//         $display("[%t] Reset released", $time);
//     end
    
//     // Main test sequence
//     initial begin
//         $display("Starting Tetris simulation");
        
//         // Wait for PLL lock
//         wait(locked);
//         $display("[%t] PLL locked", $time);
        
//         // Verify initial state
//         if (dbg_state != 0) begin // 0 = IDLE state
//             $error("Initial state incorrect: %0d", dbg_state);
//         end
        
//         // Monitor first frame
//         @(posedge frame_update);
//         $display("[%t] First frame update", $time);
        
//         // Run for several frames
//         repeat(10) @(posedge frame_update);
        
//         // Check grid state
//         $display("Final grid state:");
//         for (int row = 0; row < 20; row++) begin
//             $write("Row %2d: ", row);
//             for (int col = 0; col < 10; col++) begin
//                 $write("%b", dut.game_logic_inst.grid[row][col]);
//             end
//             $display("");
//         end
        
//         // Verify HDMI signals
//         if (hdmi_tmds_clk_p === 1'bx) begin
//             $error("HDMI clock is undefined!");
//         end
        
//         $display("Simulation completed successfully");
//         $finish;
//     end
    
//     // Monitor for errors
//     always @(posedge Clk) begin
//         if (!reset_rtl_0 && locked) begin
//             // Check for undefined HDMI signals
//             if (^hdmi_tmds_data_p === 1'bx) begin
//                 $error("[%t] Undefined HDMI data detected!", $time);
//             end
            
//             // Check for valid clock differential pair
//             if (hdmi_tmds_clk_p === hdmi_tmds_clk_n) begin
//                 $error("[%t] Invalid HDMI clock differential pair!", $time);
//             end
//         end
//     end
    
//     // VCD dump for waveform viewing
//     initial begin
//         $dumpfile("tetris_tb.vcd");
//         $dumpvars(0, tetris_tb);
        
//         // Monitor all clocks and resets
//         $dumpvars(1, dut.Clk, dut.clk_25MHz, dut.clk_125MHz);
//         $dumpvars(1, dut.reset_rtl_0, dut.reset_ah, dut.locked);
        
//         // Monitor HDMI signals
//         $dumpvars(2, dut.hdmi_tmds_clk_p, dut.hdmi_tmds_clk_n);
//         $dumpvars(2, dut.hdmi_tmds_data_p, dut.hdmi_tmds_data_n);
        
//         // Monitor game state
//         $dumpvars(3, dut.game_logic_inst);
//     end

// endmodule
`timescale 1ns / 1ps

module tetris_tb();

    // Testbench parameters
    parameter CLK_PERIOD = 10;       // 100 MHz clock (10 ns period)
    parameter RUNTIME = 9_500_000;   // 9.5ms simulation
    
    // DUT signals
    logic Clk;
    logic reset_rtl_0;
    
    // Instantiate the DUT
    tetris_top dut (
        .Clk(Clk),
        .reset_rtl_0(reset_rtl_0),
        .hdmi_tmds_clk_p(),
        .hdmi_tmds_clk_n(),
        .hdmi_tmds_data_p(),
        .hdmi_tmds_data_n()
    );

    // Clock generation
    initial begin
        Clk = 0;
        forever #(CLK_PERIOD/2) Clk = ~Clk;
    end
    
    // Track previous row for movement detection
    integer previous_row = -1;
    
    // Initialize game state rapidly
    initial begin
        // Reset and immediately initialize
        reset_rtl_0 = 1;
        #1000; // 1us reset
        
        // Pre-load first block (O-block at bottom)
        force dut.game_logic_inst.grid[18] = 10'b0000110000;
        force dut.game_logic_inst.grid[19] = 10'b0000110000;
        
        // Force second block (T-block) to spawn mid-fall
        force dut.game_logic_inst.current_shape = 3'b010; // T-block
        force dut.game_logic_inst.current_row = 3;  // Start at row 3
        force dut.game_logic_inst.current_col = 4;  // Center position
        previous_row = 3; // Initialize tracking
        
        reset_rtl_0 = 0;
        $display("[%t] Game initialized with pre-loaded blocks", $time);
        
        // Speed up falling by pre-loading counter
        force dut.game_logic_inst.fall_counter = 24'd999_000;
    end

    // Print grid on every row movement
    always @(posedge Clk) begin
        if (!reset_rtl_0 && dut.locked) begin
            if (dut.game_logic_inst.current_row != previous_row) begin
                previous_row = dut.game_logic_inst.current_row;
                print_grid();
            end
            
            // Detect and display collisions
            if (dut.game_logic_inst.collision) begin
                $display("[%t] COLLISION DETECTED!", $time);
                print_grid();
            end
        end
    end

    task print_grid;
        automatic string grid_display [0:19];
        automatic string row_display;
        $display("\n[%t] Block at row %0d:", $time, dut.game_logic_inst.current_row);
        $display("    0 1 2 3 4 5 6 7 8 9");
        
        // Initialize grid display
        for (int row = 0; row < 20; row++) begin
            row_display = "";
            for (int col = 0; col < 10; col++) begin
                row_display = {row_display, dut.game_logic_inst.grid[row][col] ? "■ " : "□ "};
            end
            grid_display[row] = row_display;
        end
        
        // Overlay falling piece (using separate display logic)
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (dut.game_logic_inst.tetromino_shape[i][j] && 
                    (dut.game_logic_inst.current_row + i < 20) &&
                    (dut.game_logic_inst.current_col + j < 10)) begin
                    automatic int r = dut.game_logic_inst.current_row + i;
                    automatic int c = dut.game_logic_inst.current_col + j;
                    // Rebuild the row string with the falling block
                    row_display = "";
                    for (int k = 0; k < 10; k++) begin
                        if (k == c && (r == dut.game_logic_inst.current_row + i)) begin
                            row_display = {row_display, "■ "};
                        end else begin
                            row_display = {row_display, grid_display[r].substr(2*k, 2*k+1)};
                        end
                    end
                    grid_display[r] = row_display;
                end
            end
        end
        
        // Print final grid
        for (int row = 0; row < 20; row++) begin
            $write("%2d: %s", row, grid_display[row]);
            $display("");
        end
    endtask

    // Simulation control
    initial begin
        #RUNTIME;
        $display("\n[%t] Final State (%.1fms):", $time, $time/1_000_000.0);
        print_grid();
        $finish;
    end
endmodule