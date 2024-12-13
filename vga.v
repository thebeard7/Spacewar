module vga (
    input wire clk_50,        // 50 MHz system clock
    input wire rst,
    input wire [1919:0] game_display,  // Game display data from main module
    output wire hsync,        // Horizontal sync
    output wire vsync,        // Vertical sync
    output wire [7:0] VGA_R,  // Red color channel (8-bit)
    output wire [7:0] VGA_G,  // Green color channel (8-bit)
    output wire [7:0] VGA_B,  // Blue color channel (8-bit)
    output wire VGA_BLANK_N,  // Blank signal (active low)
    output wire VGA_SYNC_N,   // Sync signal (active low)
    output wire VGA_CLK,      // Pixel clock output
    output reg [7:0] debug_led // Debug LEDs to show status
);
    // Generate pixel clock (25MHz for VGA)
    reg pixel_clk;
    reg [1:0] clk_divider;
    
    always @(posedge clk_50 or posedge rst) begin
        if (rst)
            clk_divider <= 2'b00;
        else
            clk_divider <= clk_divider + 1;
    end
    
    always @(posedge clk_50)
        pixel_clk <= clk_divider[1];

    // VGA timing parameters for 640x480 @ 60Hz
    parameter H_DISPLAY = 640;
    parameter H_FRONT = 16;
    parameter H_SYNC = 96;
    parameter H_BACK = 48;
    parameter H_TOTAL = 800;
    
    parameter V_DISPLAY = 480;
    parameter V_FRONT = 10;
    parameter V_SYNC = 2;
    parameter V_BACK = 33;
    parameter V_TOTAL = 525;
    
    // Scaling parameters
    parameter SCALE_X = 8;   // 640/80 = 8
    parameter SCALE_Y = 20;  // 480/24 = 20
    
    // Pixel counters and position
    reg [9:0] h_count;
    reg [9:0] v_count;
    reg [6:0] game_x;
    reg [4:0] game_y;
    
    // Color registers
    reg [7:0] red, green, blue;
    
    // Display active signal
    wire display_on;
    assign display_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // Horizontal and Vertical counters
    always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL-1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL-1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1;
            end else
                h_count <= h_count + 1;
        end
    end
    
    // Sync signal generation
    assign hsync = ~(h_count >= (H_DISPLAY + H_FRONT) && 
                     h_count < (H_DISPLAY + H_FRONT + H_SYNC));
    assign vsync = ~(v_count >= (V_DISPLAY + V_FRONT) && 
                     v_count < (V_DISPLAY + V_FRONT + V_SYNC));
    
    // Pixel color generation
    always @(posedge pixel_clk) begin
        debug_led <= 8'b10101010;
        if (display_on) begin
            // Convert current pixel position to game grid coordinates
            game_x <= h_count / SCALE_X;
            game_y <= v_count / SCALE_Y;
            
            // Check if current pixel is active in game display
            if (game_display[game_y * 80 + game_x]) begin
                // White color for game objects
                red <= 8'hFF;
                green <= 8'hFF;
                blue <= 8'hFF;
                debug_led <= 8'b11110000;
            end else begin
                // Black background
                red <= 8'h00;
                green <= 8'h00;
                blue <= 8'h00;
                debug_led <= 8'b00001111;
            end
        end else begin
            // Outside display area - black
            red <= 8'h00;
            green <= 8'h00;
            blue <= 8'h00;
            debug_led <= 8'b01010101;
        end
    end
    
    // Assign outputs
    assign VGA_R = red;
    assign VGA_G = green;
    assign VGA_B = blue;
    assign VGA_CLK = pixel_clk;
    assign VGA_BLANK_N = display_on;
    assign VGA_SYNC_N = 1'b0;  // Composite sync (not used in this mode)

endmodule