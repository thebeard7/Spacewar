module top_level (
    input wire CLOCK_50,          // 50MHz system clock (PIN_AF14)
    input wire [3:0] KEY,         // Keys for player controls (KEY[0] is PIN_AA14, etc)
    input wire [9:0] SW,          // Switches for additional controls
    
    // VGA signals
    output wire VGA_CLK,          // PIN_A11
    output wire VGA_BLANK_N,      // PIN_F10
    output wire VGA_SYNC_N,       // PIN_C10
    output wire VGA_HS,           // PIN_B11
    output wire VGA_VS,           // PIN_D11
    output wire [7:0] VGA_R,      // PIN_A13 through PIN_F13
    output wire [7:0] VGA_G,      // PIN_J9 through PIN_E11
    output wire [7:0] VGA_B,      // PIN_B13 through PIN_J14
    
    // Debug LEDs
    output wire [9:0] LEDR        // PIN_V16 through PIN_Y21
);

    // Internal wires
    wire [1919:0] game_display;
    wire [7:0] debug_led;
    
    // Map player controls from KEY and SW
    wire [7:0] player1_controls;
    wire [7:0] player2_controls;
    
    // Map controls - active low KEY needs to be inverted
    assign player1_controls = {
        ~KEY[0],           // Primary action
        ~KEY[1],           // Secondary action
        SW[3:0]            // Movement controls
    };
    
    assign player2_controls = {
        ~KEY[2],           // Primary action
        ~KEY[3],           // Secondary action
        SW[7:4]            // Movement controls
    };
    
    // Map debug LEDs to the board's LEDs
    assign LEDR[7:0] = debug_led;
    assign LEDR[9:8] = 2'b00;     // Extra LEDs off

    // Instantiate the game module
    game space (
        .clk(CLOCK_50),
        .rst(~KEY[0]),            // Use KEY[0] as reset (active low)
        .player1_controls(player1_controls),
        .player2_controls(player2_controls),
        .display(game_display)
    );

    // Instantiate the VGA controller
    vga vga_module (
        .clk_50(CLOCK_50),
        .rst(~KEY[0]),
        .game_display(game_display),
        .VGA_CLK(VGA_CLK),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .debug_led(debug_led)
    );

endmodule