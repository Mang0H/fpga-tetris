

module game_logic (
    input  logic clk,
    input  logic reset,
    input  logic [9:0] drawX,
    input  logic [9:0] drawY,
    input  logic vde, // active video enable
    input  logic [7:0] keycode,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);

    // Parameters
    localparam GRID_COLS = 12;
    localparam GRID_ROWS = 20;
    localparam CELL_SIZE = 20;

    localparam GRID_WIDTH  = (GRID_COLS-2)* CELL_SIZE; // 200
    localparam GRID_HEIGHT = GRID_ROWS * CELL_SIZE; // 400

    localparam GRID_X_OFFSET = 220; // Starting x-coordinate
    localparam GRID_Y_OFFSET = 40;  // Starting y-coordinate

        // Color definitions
    localparam BLACK  = 4'h0;
    localparam WHITE  = 4'h1;
    localparam CYAN   = 4'h2;
    localparam BLUE   = 4'h3;
    localparam ORANGE = 4'h4;
    localparam YELLOW = 4'h5;
    localparam GREEN  = 4'h6;
    localparam PURPLE = 4'h7;
    localparam RED    = 4'h8;

     // Game states
    typedef enum logic [2:0] {
        INIT,
        SPAWN_PIECE,
        FALLING,
        WIGGLE,
        LOCK_PIECE,
        CLEAR_LINES,
        GAME_OVER
    } game_state_t;

    // Tetramino types
    typedef enum logic [2:0] {
        PIECE_I,
        PIECE_J,
        PIECE_L,
        PIECE_O,
        PIECE_S,
        PIECE_T,
        PIECE_Z
    } piece_type_t;

// Game variables
    game_state_t game_state, next_state;
    piece_type_t current_piece, next_piece;
    logic [4:0] vram [0:19][0:11];
    logic [1:0] current_rotation;
    logic [4:0] current_x; // 0-9
    logic [5:0] current_y; // 0-19
    logic [3:0] current_color, next_color;
    logic [15:0] score;
    logic [15:0] level;
    logic [15:0] lines_cleared;
    logic [2:0] rand_val;
    logic [15:0] lfsr_reg;
    logic lfsr_feedback;
    
    // Timing and controls
    logic [31:0] drop_timer;
    logic [31:0] delay_timer;
    logic [31:0] rot_timer;
    logic [31:0] wiggle_timer;
    logic drop_event;
    logic delay_event;
    logic rot_event;
    logic wiggle_event;

    localparam INITIAL_DROP_TIME = 25000000; // Adjust for your clock speed
    localparam SOFT_DROP_TIME = 1000000;
    localparam X_DELAY = 5000000;
    localparam R_DELAY = 5000000;
    localparam WIGGLE_DELAY = 5000000;
    // localparam INITIAL_DROP_TIME = 1000;
    // localparam SOFT_DROP_TIME = 100;
    // localparam X_DELAY = 200;
    // localparam R_DELAY = 200;
    // localparam WIGGLE_DELAY = 200;
    localparam LEVEL_DROP_DECREMENT = 50_000;

    // Tetramino ROM interface
    logic [35:0] piece_data [0:3];
    
    // Calculate coordinates relative to grid's top-left corner
    logic [9:0] gridX, gridY;
    logic [4:0] cellX, cellY;
    logic [4:0] grid_cellX, grid_cellY; // Grid cell coordinates (0-9, 0-19)
    logic [3:0] block_x_offset [0:3];
    logic [4:0] block_y_offset [0:3];
    logic [3:0] count;

    assign gridX = (drawX >= GRID_X_OFFSET) ? (drawX - GRID_X_OFFSET) : 10'h3FF;
    assign gridY = (drawY >= GRID_Y_OFFSET) ? (drawY - GRID_Y_OFFSET) : 10'h3FF;
    assign cellX = gridX % CELL_SIZE; // Pixel within cell
    assign cellY = gridY % CELL_SIZE;
    assign grid_cellX = (gridX / CELL_SIZE) + 2; // X grid coordinate (0-9)
    assign grid_cellY = gridY / CELL_SIZE; // Y grid coordinate (0-19)
    

always_comb begin
        case ({current_piece, current_rotation})
            // I piece (0) - 4 rotations
            {PIECE_I, 2'b11}: piece_data[3] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2, 4'd1, 5'd3}; // Horizontal
            {PIECE_I, 2'b10}: piece_data[2] = {4'd0, 5'd2, 4'd1, 5'd2, 4'd2, 5'd2, 4'd3, 5'd2}; // Vertical
            {PIECE_I, 2'b01}: piece_data[1] = {4'd2, 5'd0, 4'd2, 5'd1, 4'd2, 5'd2, 4'd2, 5'd3}; // Horizontal (mirrored)
            {PIECE_I, 2'b00}: piece_data[0] = {4'd0, 5'd1, 4'd1, 5'd1, 4'd2, 5'd1, 4'd3, 5'd1}; // Vertical (mirrored)

            // J piece (1)
            {PIECE_J, 2'b11}: piece_data[3] = {4'd0, 5'd2, 4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2};
            {PIECE_J, 2'b10}: piece_data[2] = {4'd0, 5'd1, 4'd1, 5'd1, 4'd2, 5'd1, 4'd2, 5'd2};
            {PIECE_J, 2'b01}: piece_data[1] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd0};
            {PIECE_J, 2'b00}: piece_data[0] = {4'd0, 5'd0, 4'd0, 5'd1, 4'd1, 5'd1, 4'd2, 5'd1};
            
            // L piece (2)
            {PIECE_L, 2'b11}: piece_data[3] = {4'd0, 5'd0, 4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2};
            {PIECE_L, 2'b10}: piece_data[2] = {4'd0, 5'd1, 4'd0, 5'd2, 4'd1, 5'd1, 4'd2, 5'd1};
            {PIECE_L, 2'b01}: piece_data[1] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd2};
            {PIECE_L, 2'b00}: piece_data[0] = {4'd0, 5'd1, 4'd1, 5'd1, 4'd2, 5'd0, 4'd2, 5'd1};

            // O piece (3) - same for all rotations
            {PIECE_O, 2'b00}: piece_data[0] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd0, 4'd2, 5'd1};
            {PIECE_O, 2'b01}: piece_data[1] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd0, 4'd2, 5'd1};
            {PIECE_O, 2'b10}: piece_data[2] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd0, 4'd2, 5'd1};
            {PIECE_O, 2'b11}: piece_data[3] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd0, 4'd2, 5'd1};
            
            // S piece (4)
            {PIECE_S, 2'b11}: piece_data[3] = {4'd0, 5'd0, 4'd0, 5'd1, 4'd1, 5'd1, 4'd1, 5'd2};
            {PIECE_S, 2'b10}: piece_data[2] = {4'd0, 5'd2, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd1};
            {PIECE_S, 2'b01}: piece_data[1] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd1, 4'd2, 5'd2};
            {PIECE_S, 2'b00}: piece_data[0] = {4'd0, 5'd1, 4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd0};

            // T piece (5)
            {PIECE_T, 2'b11}: piece_data[3] = {4'd0, 5'd1, 4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2};
            {PIECE_T, 2'b10}: piece_data[2] = {4'd0, 5'd1, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd1};
            {PIECE_T, 2'b01}: piece_data[1] = {4'd1, 5'd0, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd1};
            {PIECE_T, 2'b00}: piece_data[0] = {4'd0, 5'd1, 4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd1};
            
            // Z piece (6)
            {PIECE_Z, 2'b11}: piece_data[3] = {4'd0, 5'd1, 4'd0, 5'd2, 4'd1, 5'd0, 4'd1, 5'd1};
            {PIECE_Z, 2'b10}: piece_data[2] = {4'd0, 5'd1, 4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd2};
            {PIECE_Z, 2'b01}: piece_data[1] = {4'd1, 5'd1, 4'd1, 5'd2, 4'd2, 5'd0, 4'd2, 5'd1};
            {PIECE_Z, 2'b00}: piece_data[0] = {4'd0, 5'd0, 4'd1, 5'd0, 4'd1, 5'd1, 4'd2, 5'd1};
        
        endcase
    end

    //Check if we are drawing the active piece
    logic in_active_piece;
    logic [3:0] active_piece_color;
    always_comb begin
        in_active_piece = (((current_x + piece_data[current_rotation][8:5] == grid_cellX) && (current_y + piece_data[current_rotation][4:0] == grid_cellY))
                        || ((current_x + piece_data[current_rotation][17:14] == grid_cellX) && (current_y + piece_data[current_rotation][13:9] == grid_cellY))
                        || ((current_x + piece_data[current_rotation][26:23] == grid_cellX) && (current_y + piece_data[current_rotation][22:18] == grid_cellY))
                        || ((current_x + piece_data[current_rotation][35:32] == grid_cellX) && (current_y + piece_data[current_rotation][31:27] == grid_cellY)));

        active_piece_color = current_color;
    end
    task automatic new_piece();
        // Simple pseudo-random number (replace with better RNG if needed)
        rand_val <= lfsr_reg % 7;
        
        next_piece <= piece_type_t'(rand_val);
        
        // Set color based on piece type
        case (piece_type_t'(rand_val))
            PIECE_I: next_color <= CYAN;
            PIECE_J: next_color <= BLUE;
            PIECE_L: next_color <= ORANGE;
            PIECE_O: next_color <= YELLOW;
            PIECE_S: next_color <= GREEN;
            PIECE_T: next_color <= PURPLE;
            PIECE_Z: next_color <= RED;
        endcase
    endtask

    task automatic reset_drop_timer();
        drop_timer <= INITIAL_DROP_TIME; // - level * LEVEL_DROP_DECREMENT;
    endtask
    
    task automatic reset_soft_timer();
        drop_timer <= SOFT_DROP_TIME;
    endtask
    
    task automatic reset_x_delay();
        delay_timer <= X_DELAY;
    endtask

    task automatic reset_rot_delay();
        rot_timer <= R_DELAY;
    endtask

    task automatic reset_wiggle_delay();
        wiggle_timer <= WIGGLE_DELAY;
    endtask

    logic debug;
    assign debug = can_move(0, 0);

    function logic can_move(input int dx, dy);
        int x;
        logic [4:0] x_offset;
        logic [5:0] y_offset;

        for(x=0; x<4; x++) begin
            x_offset = piece_data[current_rotation][(x*9 + 5) +:4];
            y_offset = piece_data[current_rotation][(x*9) +: 5];

            if ((current_x + x_offset + dx) < 2 || 
                (current_x + x_offset + dx) >= GRID_COLS ||
                (current_y + y_offset + dy) >= GRID_ROWS) begin
                return 0;
            end

            if ((current_y + y_offset + dy) >= 0 && 
                (current_x + x_offset + dx) >= 2 &&
                (current_x + x_offset + dx) < 12 &&
                vram[current_y + y_offset + dy][current_x + x_offset + dx][4]==1) begin
                return 0;
            end
        end
        return 1;
    endfunction

    function logic can_rotate(input int direction);?
    
        int x;
        logic [4:0] x_rot_off;
        logic [5:0] y_rot_off;

        for (x=0; x<4; x++) begin
            x_rot_off = piece_data[current_rotation + direction][(x*9 + 5) +: 4];
            y_rot_off = piece_data[current_rotation + direction][(x*9) +: 5];

            if ((current_x + x_rot_off) < 2 ||
                (current_x + x_rot_off) >= GRID_COLS ||
                (current_y + y_rot_off) >= GRID_ROWS) begin
                return 0;
            end

            if ((current_y + y_rot_off) >= 0 &&
                (current_x + x_rot_off) >= 2 &&
                (current_x + x_rot_off) < 12 &&
                vram[current_y+y_rot_off][current_x + x_rot_off][4]==1) begin
                return 0;
            end
        end
        return 1;
    endfunction

     always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            game_state <= INIT;
            
            // Clear VRAM
            for (int y = 0; y < GRID_ROWS; y++) begin
                for (int x = 2; x < GRID_COLS; x++) begin
                    vram[y][x] <= {1'b0, BLACK};
                end
            end
            
            // Reset game stats
            score <= 0;
            level <= 0;
            lines_cleared <= 0;
            drop_timer <= 0;
            delay_timer <= 0;
            wiggle_timer <=0;
            count <= 0;
            lfsr_reg <= 16'hACE1;
            current_x <= 0;
            current_y <= 0;
            new_piece();
        end else begin
            // Default next state
            game_state <= next_state;
            unique case (next_state)
                INIT: begin
                    count <= count + 3'b1;
                    lfsr_reg <= {lfsr_reg[14:0], lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10]};
                    new_piece();
                end
                SPAWN_PIECE: begin
                    new_piece();
                    current_y <= 0;
                    current_x <= 5;
                    current_rotation <= 0;
                    reset_drop_timer();
                    reset_x_delay();
                end
                FALLING: begin
                    new_piece();
                    current_piece <= next_piece;
                    current_color <= next_color;
                    if (can_move(0, 1)) begin
                        if (drop_event) begin
                            current_y <= current_y + 1;
                        end
                    end
                end
                WIGGLE: begin
                    reset_wiggle_delay();
                end
                LOCK_PIECE: begin
                    for(int x=0; x<4; x++) begin
                        block_x_offset[x] = piece_data[current_rotation][(x*9 + 5) +:4];
                        block_y_offset[x] = piece_data[current_rotation][(x*9) +: 5];
                        vram[current_y + block_y_offset[x]][current_x + block_x_offset[x]] <= {1'b1, current_color};
                    end
                end
            endcase
            if (game_state == FALLING || game_state == WIGGLE) begin
                if (drop_timer > 0) begin
                    drop_timer <= drop_timer - 1;
                end
                else if (keycode == 8'h16 && can_move(0, 1) && drop_event) begin
                    reset_soft_timer();
                end 
                else if (can_move(0, 1) && drop_event) begin
                    reset_drop_timer();
                end

                if (wiggle_timer > 0) begin
                    wiggle_timer <= wiggle_timer - 1;
                end

                if (keycode == 8'h04 && can_move(-1, 0) && delay_event) begin
                    current_x <= current_x - 1;
                    reset_x_delay();
                end
                else if (keycode == 8'h07 && can_move(1, 0) && delay_event) begin
                    current_x <= current_x + 1;
                    reset_x_delay();
                end
                else if (delay_timer > 0) begin
                    delay_timer <= delay_timer - 1;
                end

                if (keycode == 8'h0D && can_rotate(-1) && rot_event) begin
                    current_rotation <= current_rotation - 2'b01;
                    reset_rot_delay();
                end
                else if (keycode == 8'h0F && can_rotate(1) && rot_event) begin
                    current_rotation <= current_rotation + 2'b01;
                    reset_rot_delay();
                end
                else if (keycode == 8'h0E && can_rotate(2) && rot_event) begin
                    current_rotation <= current_rotation + 2'b10;
                    reset_rot_delay();
                end
                else if (rot_timer > 0) begin
                    rot_timer <= rot_timer - 1;
                end
            end
        end
     end




     always_comb begin 
        next_state = game_state;
        drop_event = (drop_timer == 0);
        delay_event = (delay_timer == 0);
        rot_event = (rot_timer == 0);
        wiggle_event = (wiggle_timer == 0);

        unique case (game_state) 
            INIT:
                next_state = SPAWN_PIECE;
            SPAWN_PIECE: begin
                if (!can_move(0, 0)) begin
                     next_state = GAME_OVER;
                end else begin
                    next_state = FALLING;
                end
            end
            FALLING:
                if (drop_event && !can_move(0, 1)) begin
                    next_state = WIGGLE;
                end
            WIGGLE:
                if (wiggle_event) begin
                    next_state = LOCK_PIECE;
                end
            LOCK_PIECE:
                next_state = INIT;
            GAME_OVER:
                if (reset) begin
                    next_state = INIT;
                end
        endcase
     end

    //Rendering logic
    always_comb begin
       red = BLACK;
       green = BLACK;
       blue = BLACK;

        if (vde) begin
            if (gridX <= GRID_WIDTH && gridY <= GRID_HEIGHT) begin
                if (cellX == 0 || cellY == 0) begin
                    {red, green, blue} = {4'hF, 4'hF, 4'hF};
                end
                else if (in_active_piece && (game_state == FALLING)) begin
                    unique case (active_piece_color)
                        CYAN:   {red, green, blue} = {4'h0, 4'hF, 4'hF};
                        BLUE:   {red, green, blue} = {4'h0, 4'h0, 4'h9};
                        ORANGE: {red, green, blue} = {4'hF, 4'h6, 4'h0};
                        YELLOW: {red, green, blue} = {4'hF, 4'hF, 4'h0};
                        GREEN:  {red, green, blue} = {4'h0, 4'hC, 4'h0};
                        PURPLE: {red, green, blue} = {4'h8, 4'h0, 4'hF};
                        RED:    {red, green, blue} = {4'hF, 4'h0, 4'h0};
                        BLACK:  {red, green, blue} = {4'h0, 4'h0, 4'h0}; // Handle Black explicitly
                        WHITE:  {red, green, blue} = {4'hF, 4'hF, 4'hF};
                        default: {red, green, blue} = {4'hF, 4'hF, 4'hF};
                    endcase
                end
                else if (vram[grid_cellY][grid_cellX][4] == 1) begin
                    unique case (vram[grid_cellY][grid_cellX][3:0])
                        CYAN:   {red, green, blue} = {4'h0, 4'hF, 4'hF};
                        BLUE:   {red, green, blue} = {4'h0, 4'h0, 4'h9};
                        ORANGE: {red, green, blue} = {4'hF, 4'h6, 4'h0};
                        YELLOW: {red, green, blue} = {4'hF, 4'hF, 4'h0};
                        GREEN:  {red, green, blue} = {4'h0, 4'hC, 4'h0};
                        PURPLE: {red, green, blue} = {4'h8, 4'h0, 4'hF};
                        RED:    {red, green, blue} = {4'hF, 4'h0, 4'h0};
                        BLACK:  {red, green, blue} = {4'h0, 4'h0, 4'h0}; // Handle Black explicitly
                        WHITE:  {red, green, blue} = {4'hF, 4'hF, 4'hF};
                        default: {red, green, blue} = {4'hF, 4'hF, 4'hF};
                    endcase
                end
            end
        end
    end

endmodule







