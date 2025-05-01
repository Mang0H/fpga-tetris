`timescale 1ns/1ps

module game_logic_tb;

    // Signals
    logic clk = 0;
    logic reset = 1;
    logic [9:0] drawX = 0;
    logic [9:0] drawY = 0;
    logic vde = 0;
    logic [3:0] red, green, blue;
    logic [2:0] count;
    logic [2:0] state;
    logic [2:0] current_piece, next_piece;
    logic [31:0] timer;
    logic e;
    logic [5:0] cur_y;
    logic [4:0] cur_x;
    logic moveD;
    logic [2:0] rand_val;

    // Display parameters
    localparam DISPLAY_WIDTH  = 640;
    localparam DISPLAY_HEIGHT = 480;

    // Bitmap array for 640x480, 24-bit RGB
    logic [23:0] bitmap [0:DISPLAY_WIDTH-1][0:DISPLAY_HEIGHT-1];

    // Instantiate DUT
    game_logic dut (
        .clk(clk),
        .reset(reset),
        .drawX(drawX),
        .drawY(drawY),
        .vde(vde),
        .red(red),
        .green(green),
        .blue(blue)
    );
    assign count = dut.count;
    assign state = dut.game_state;
    assign current_piece = dut.current_piece;
    assign next_piece = dut.next_piece;
    assign timer = dut.drop_timer;
    assign e = dut.drop_event;
    assign cur_y = dut.current_y;
    assign cur_x = dut.current_x;
    assign moveD = dut.debug;
    assign rand_val = dut.rand_val;

    // Clock generation: 50 MHz (20 ns period)
    always #10 clk = ~clk;

    // Task to save 640x480 BMP
    task save_bmp(input string filename);
        integer file, i, j;
        // BMP header for 640x480, 24-bit
        logic [7:0] header [0:53] = {
            // File header (14 bytes)
            8'h42, 8'h4D,             // "BM"
            8'h36, 8'hE1, 8'h00, 8'h00, // File size (54 + 640*480*3 = 921654 bytes)
            8'h00, 8'h00, 8'h00, 8'h00, // Reserved
            8'h36, 8'h00, 8'h00, 8'h00, // Pixel data offset (54 bytes)
            // DIB header (40 bytes)
            8'h28, 8'h00, 8'h00, 8'h00, // Header size (40)
            8'h80, 8'h02, 8'h00, 8'h00, // Width (640)
            8'hE0, 8'h01, 8'h00, 8'h00, // Height (480)
            8'h01, 8'h00,             // Planes (1)
            8'h18, 8'h00,             // Bits per pixel (24)
            8'h00, 8'h00, 8'h00, 8'h00, // Compression (none)
            8'h00, 8'hE1, 8'h00, 8'h00, // Image size (640*480*3 = 921600)
            8'h00, 8'h00, 8'h00, 8'h00, // X pixels per meter
            8'h00, 8'h00, 8'h00, 8'h00, // Y pixels per meter
            8'h00, 8'h00, 8'h00, 8'h00, // Colors used
            8'h00, 8'h00, 8'h00, 8'h00  // Important colors
        };
        begin
            file = $fopen(filename, "wb");
            if (file == 0) begin
                $display("Error: Could not open %s", filename);
                $finish;
            end

            // Write BMP header
            for (i = 0; i < 54; i++) begin
                $fwrite(file, "%c", header[i]);
            end

            // Write pixel data (bottom-up, BGR order)
            for (j = DISPLAY_HEIGHT-1; j >= 0; j--) begin
                for (i = 0; i < DISPLAY_WIDTH; i++) begin
                    // Convert 4-bit RGB to 8-bit BGR
                    $fwrite(file, "%c%c%c",
                        {bitmap[i][j][7:4], 4'h0},   // Blue
                        {bitmap[i][j][15:12], 4'h0}, // Green
                        {bitmap[i][j][23:20], 4'h0}); // Red
                end
            end

            $fclose(file);
            $display("Saved BMP to %s", filename);
        end
    endtask

    // Test stimulus
    initial begin
        // Reset
        reset = 1;
        #20;
        @(posedge clk);
        reset = 0;

        // Scan 640x480 display
        for (int y = 0; y < DISPLAY_HEIGHT; y++) begin
            for (int x = 0; x < DISPLAY_WIDTH; x++) begin
                drawX = x;
                drawY = y;
                vde   = 1; // Enable for entire visible area
                @(posedge clk);
                #1; // Wait for outputs to settle
                // Capture colors (4-bit to 24-bit RGB)
                bitmap[x][y] = {{red, 4'h0}, {green, 4'h0}, {blue, 4'h0}};
            end
        end

        // Save output
        save_bmp("game_logic_sim.bmp");
        $display("Simulation complete");
        $finish;
    end

endmodule