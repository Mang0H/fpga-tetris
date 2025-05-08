module text_renderer #(parameter COLS         = 16,
                       parameter LINES        = 2,
                       parameter BASE_X       = 440,   // GRID_X_OFFSET+GRID_WIDTH+20
                       parameter BASE_Y       = 40,    // align with grid top
                       parameter FG_R         = 4'hF,  // white text
                       parameter FG_G         = 4'hF,
                       parameter FG_B         = 4'hF)
    ( input  logic             clk,
      input  logic             vde,
      input  logic [9:0]       drawX,
      input  logic [9:0]       drawY,
      input  logic [8*COLS*LINES-1:0] text, // packed left‑to‑right, top‑to‑bottom
      output logic             pixel_on,
      output logic [3:0]       red,
      output logic [3:0]       green,
      output logic [3:0]       blue  );

    // working signals ---------------------------------------------------------
    logic        in_region;
    logic [9:0]  relX, relY;        // relative to BASE
    logic [3:0]  bitX;              // 0‑7
    logic [3:0]  bitY;              // 0‑15
    logic [7:0]  char_code;
    logic [10:0] rom_addr;          // 8×16 font → 11 bits
    logic [7:0]  rom_data;

    // Static font ROM instance -----------------------------------------------
    font_rom font (.addr(rom_addr), .data(rom_data));

    // Combinational pixel decode ---------------------------------------------
    always_comb begin
        red = 0; green = 0; blue = 0; pixel_on = 0;

        // Detect SCORE/LEVEL window (two text rows high)
        in_region = (drawX >= BASE_X) && (drawX < BASE_X + COLS*8) &&
                    (drawY >= BASE_Y) && (drawY < BASE_Y + LINES*16) && vde;

        if (in_region) begin
            relX  = drawX - BASE_X;
            relY  = drawY - BASE_Y;
            bitX  = relX[2:0];            // modulo 8 → 0‑7
            bitY  = relY[3:0];            // modulo 16

            // Select character index ----------------------------------------
            int char_col = relX / 8;      // 0‑(COLS-1)
            int char_row = relY / 16;     // 0‑(LINES-1)
            int char_idx = char_row*COLS + char_col;
            char_code    = text >> (8*char_idx);

            // Font ROM address = char*16 + row
            rom_addr = {char_code, bitY};

            // Font bit (MSbit = leftmost)
            if (rom_data[7-bitX]) begin
                red = FG_R; green = FG_G; blue = FG_B; pixel_on = 1;
            end
        end
    end
endmodule