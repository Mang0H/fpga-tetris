module tetromino_rom (
    input logic [2:0] shape_idx,  // Index of tetromino shape (0-6)
    input logic [1:0] rotation,   // Rotation state (0-3)
    output logic [3:0][3:0] shape // 4x4 block representation
);

    // Tetromino definitions (I, O, T, S, Z, J, L)
    // Each tetromino is defined in all 4 rotations
    typedef logic [3:0][3:0] tetromino_rot_t [4];
    
    // Array of all tetromino rotations
    tetromino_rot_t tetrominoes [7] = '{
        // I shape (0)
        '{
            '{4'b0000, 4'b1111, 4'b0000, 4'b0000}, // Rotation 0
            '{4'b0010, 4'b0010, 4'b0010, 4'b0010}, // Rotation 1
            '{4'b0000, 4'b0000, 4'b1111, 4'b0000}, // Rotation 2
            '{4'b0100, 4'b0100, 4'b0100, 4'b0100}  // Rotation 3
        },
        // O shape (1) - same for all rotations
        '{
            '{4'b0000, 4'b0110, 4'b0110, 4'b0000},
            '{4'b0000, 4'b0110, 4'b0110, 4'b0000},
            '{4'b0000, 4'b0110, 4'b0110, 4'b0000},
            '{4'b0000, 4'b0110, 4'b0110, 4'b0000}
        },
        // T shape (2)
        '{
            '{4'b0000, 4'b1110, 4'b0100, 4'b0000},
            '{4'b0100, 4'b1100, 4'b0100, 4'b0000},
            '{4'b0100, 4'b1110, 4'b0000, 4'b0000},
            '{4'b0100, 4'b0110, 4'b0100, 4'b0000}
        },
        // S shape (3)
        '{
            '{4'b0000, 4'b0110, 4'b1100, 4'b0000},
            '{4'b0100, 4'b0110, 4'b0010, 4'b0000},
            '{4'b0000, 4'b0110, 4'b1100, 4'b0000},
            '{4'b0100, 4'b0110, 4'b0010, 4'b0000}
        },
        // Z shape (4)
        '{
            '{4'b0000, 4'b1100, 4'b0110, 4'b0000},
            '{4'b0010, 4'b0110, 4'b0100, 4'b0000},
            '{4'b0000, 4'b1100, 4'b0110, 4'b0000},
            '{4'b0010, 4'b0110, 4'b0100, 4'b0000}
        },
        // J shape (5)
        '{
            '{4'b0000, 4'b1000, 4'b1110, 4'b0000},
            '{4'b0110, 4'b0100, 4'b0100, 4'b0000},
            '{4'b0000, 4'b1110, 4'b0010, 4'b0000},
            '{4'b0100, 4'b0100, 4'b1100, 4'b0000}
        },
        // L shape (6)
        '{
            '{4'b0000, 4'b0010, 4'b1110, 4'b0000},
            '{4'b0100, 4'b0100, 4'b0110, 4'b0000},
            '{4'b0000, 4'b1110, 4'b1000, 4'b0000},
            '{4'b1100, 4'b0100, 4'b0100, 4'b0000}
        }
    };
    
    // Output the selected shape and rotation
    assign shape = tetrominoes[shape_idx][rotation];

endmodule