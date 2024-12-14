module top_level (
    //////////// CLOCK //////////
    input           CLOCK_50,

    //////////// KEY //////////
    input    [3:0]  KEY,

    //////////// SW //////////
    input    [9:0]  SW,

    //////////// VGA //////////
    output          VGA_CLK,
    output          VGA_HS,
    output          VGA_VS,
    output          VGA_BLANK_N,
    output          VGA_SYNC_N,
    output   [7:0]  VGA_R,
    output   [7:0]  VGA_G,
    output   [7:0]  VGA_B,
   
    //////////// LED //////////
    output   [9:0]  LEDR,

    //////////// HEX //////////
    output   [6:0]  HEX0,
    output   [6:0]  HEX1,
    output   [6:0]  HEX2,
    output   [6:0]  HEX3
);

// Turn off hex displays
assign HEX0 = 7'h7F;
assign HEX1 = 7'h7F;
assign HEX2 = 7'h7F;
assign HEX3 = 7'h7F;

// Internal signals
wire [9:0] x_pixel;
wire [9:0] y_pixel;
wire active_pixels;
wire frame_done;
wire [23:0] rgb_out;

// Debug output
assign LEDR = SW_db;

// Debounce switches
wire [9:0] SW_db;
debounce_switches debouncer (
    .clk(CLOCK_50),
    .rst(KEY[0]),
    .SW(SW),
    .SW_db(SW_db)
);

// Game instance
game game_inst (
    .clk(clk),
    .rst(rst),
    .SW(SW),              // Pass all switches directly to game
    .x_pixel(x),
    .y_pixel(y),
    .active_pixels(active_pixels),
    .rgb_out(game_rgb_out)
);

// VGA driver with memory
vga_driver_memory vga_mem (
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW_db),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_CLK(VGA_CLK),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .active_pixels(active_pixels),
    .frame_done(frame_done),
    .rgb_in(rgb_out)
);

endmodule