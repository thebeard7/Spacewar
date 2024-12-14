module vga_driver_memory (
  //////////// ADC //////////
//output           ADC_CONVST,
//output           ADC_DIN,
//input           ADC_DOUT,
//output           ADC_SCLK,

//////////// Audio //////////
//input           AUD_ADCDAT,
//inout           AUD_ADCLRCK,
//inout           AUD_BCLK,
//output           AUD_DACDAT,
//inout           AUD_DACLRCK,
//output           AUD_XCK,

//////////// CLOCK //////////
//input           CLOCK2_50,
//input           CLOCK3_50,
//input           CLOCK4_50,
input           CLOCK_50,

//////////// SDRAM //////////
//output    [12:0] DRAM_ADDR,
//output     [1:0] DRAM_BA,
//output           DRAM_CAS_N,
//output           DRAM_CKE,
//output           DRAM_CLK,
//output           DRAM_CS_N,
//inout    [15:0] DRAM_DQ,
//output           DRAM_LDQM,
//output           DRAM_RAS_N,
//output           DRAM_UDQM,
//output           DRAM_WE_N,

//////////// I2C for Audio and Video-In //////////
//output           FPGA_I2C_SCLK,
//inout           FPGA_I2C_SDAT,

//////////// SEG7 //////////
output     [6:0] HEX0,
output     [6:0] HEX1,
output     [6:0] HEX2,
output     [6:0] HEX3,
//output     [6:0] HEX4,
//output     [6:0] HEX5,

//////////// IR //////////
//input           IRDA_RXD,
//output           IRDA_TXD,

//////////// KEY //////////
input     [3:0] KEY,

//////////// LED //////////
output     [9:0] LEDR,

//////////// PS2 //////////
//inout           PS2_CLK,
//inout           PS2_CLK2,
//inout           PS2_DAT,
//inout           PS2_DAT2,

//////////// SW //////////
input     [9:0] SW,

//////////// Video-In //////////
//input           TD_CLK27,
//input     [7:0] TD_DATA,
//input           TD_HS,
//output           TD_RESET_N,
//input           TD_VS,

//////////// VGA //////////
output           VGA_BLANK_N,
output reg     [7:0] VGA_B,
output           VGA_CLK,
output reg     [7:0] VGA_G,
output           VGA_HS,
output reg     [7:0] VGA_R,
output           VGA_SYNC_N,
output           VGA_VS,

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
//inout    [35:0] GPIO_0,

//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
//inout    [35:0] GPIO_1,

//////////// Additional ports for game interface //////////
output   [9:0]  x_pixel,
output   [9:0]  y_pixel,
output wire      active_pixels,
output          frame_done,
input    [23:0] rgb_in

);

  // Turn off all displays.
assign HEX0 = 7'h00;
assign HEX1 = 7'h00;
assign HEX2 = 7'h00;
assign HEX3 = 7'h00;

//reg active_pixels; // is on when we're in the active draw space

wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = KEY[0];

assign LEDR[0] = active_pixels;
assign LEDR[9:1] = 9'h000;  // Turn off unused LEDs

vga_driver the_vga(
.clk(clk),
.rst(rst),

.vga_clk(VGA_CLK),

.hsync(VGA_HS),
.vsync(VGA_VS),

.active_pixels(active_pixels),

.xPixel(x),
.yPixel(y),

.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N)
);

assign x_pixel = x;
assign y_pixel = y;
assign frame_done = ~active_pixels;  // Frame is done when not in active pixels

// Game instance
wire [23:0] game_rgb_out;

game game_inst (
    .clk(clk),
    .rst(rst),
    .SW(SW),              // Pass all switches directly to game
    .x_pixel(x),
    .y_pixel(y),
    .active_pixels(active_pixels),
    .rgb_out(game_rgb_out)
);

always @(*)
begin
    if (active_pixels) begin
        {VGA_R, VGA_G, VGA_B} = game_rgb_out;  // Use the game's color output
    end else begin
        {VGA_R, VGA_G, VGA_B} = 24'h000000;  // Black during blanking
    end
end

endmodule