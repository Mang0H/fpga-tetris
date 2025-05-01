module game_logic_tb;

    logic clk = 0;
    logic reset = 0;
    logic [9:0] drawX, drawY;
    logic [3:0] red, green, blue;
    logic frame_update;

    localparam WIDTH = 100;
    localparam HEIGHT = 200;

    byte framebuffer[0:HEIGHT-1][0:WIDTH-1][2:0]; // RGB

    game_logic uut (
        .clk(clk),
        .reset(reset),
        .drawX(drawX),
        .drawY(drawY),
        .red(red),
        .green(green),
        .blue(blue),
        .frame_update(frame_update)
    );

    always #10 clk = ~clk; // 50 MHz

    initial begin
        $display("Running BMP framebuffer dump...");

        for (int y = 0; y < HEIGHT; y++) begin
            for (int x = 0; x < WIDTH; x++) begin
                drawX = x;
                drawY = y;
                #20;

                framebuffer[y][x][0] = {red, 0};   // Red (upper 4 bits, 0 padded)
                framebuffer[y][x][1] = {green, 0}; // Green
                framebuffer[y][x][2] = {blue, 0};  // Blue
            end
        end

        write_bmp("output.bmp", framebuffer, WIDTH, HEIGHT);
        $display("BMP image written to output.bmp");
        $finish;
    end

    task write_bmp(string filename, byte data[][][2:0], int w, int h);
        int file, i, j;
        int pad = (4 - (3*w)%4)%4;
        int size = 54 + (3*w + pad) * h;

        file = $fopen(filename, "wb");
        if (!file) begin
            $display("Error: could not open file %s", filename);
            $finish;
        end

        // --- BMP HEADER ---
        // Signature
        $fwrite(file, "%c%c", "B", "M");
        $fwrite(file, "%u", size);
        $fwrite(file, "%u", 0); // reserved
        $fwrite(file, "%u", 54); // offset

        // DIB Header
        $fwrite(file, "%u", 40); // DIB header size
        $fwrite(file, "%d", w); // width
        $fwrite(file, "%d", -h); // height (negative for top-down)
        $fwrite(file, "%u", 1 | (24 << 16)); // planes + bits per pixel
        $fwrite(file, "%u", 0); // no compression
        $fwrite(file, "%u", (3*w + pad) * h); // image size
        $fwrite(file, "%u", 2835); // horizontal resolution (px/m)
        $fwrite(file, "%u", 2835); // vertical resolution
        $fwrite(file, "%u", 0); // palette colors
        $fwrite(file, "%u", 0); // important colors

        // --- Pixel Data ---
        for (i = 0; i < h; i++) begin
            for (j = 0; j < w; j++) begin
                $fwrite(file, "%c%c%c", data[i][j][2], data[i][j][1], data[i][j][0]);
            end
            for (j = 0; j < pad; j++) $fwrite(file, "%c", 8'h00);
        end

        $fclose(file);
    endtask

endmodule
