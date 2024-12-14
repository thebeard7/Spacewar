module game (
    input wire clk,                    // Clock input
    input wire rst,                    // Reset input
    input wire [9:0] SW,              // Switch inputs for both players
    input wire [9:0] x_pixel,         // Current VGA x coordinate
    input wire [9:0] y_pixel,         // Current VGA y coordinate
    input wire active_pixels,         // VGA active area signal
    output reg [23:0] rgb_out         // 24-bit RGB output (8 bits each for R,G,B)
);

// Update parameters for VGA resolution
parameter SCREEN_WIDTH = 640;
parameter SCREEN_HEIGHT = 480;
parameter SHIP_SIZE = 20;      // Size in pixels

// Ship positions now use 10-bit values for full VGA resolution
reg [9:0] ship1_x, ship1_y;
reg [9:0] ship2_x, ship2_y;
reg [7:0] ship1_angle, ship2_angle;

// Game state registers remain the same
reg game_over;
reg [1:0] winner;

// Wire definitions for player controls
wire [4:0] player1_controls;
wire [4:0] player2_controls;

// Assign switch controls to players
assign player1_controls = SW[4:0];   // SW[0] to SW[4] for player 1
assign player2_controls = SW[9:5];   // SW[5] to SW[9] for player 2


// Color definitions
parameter [23:0] SHIP1_COLOR = 24'hFF0000;  // Red
parameter [23:0] SHIP2_COLOR = 24'h0000FF;  // Blue
parameter [23:0] BULLET_COLOR = 24'hFFFF00; // Yellow
parameter [23:0] BG_COLOR = 24'h000000;     // Black

// Add these declarations after the existing parameters
reg [9:0] ship1_dx, ship1_dy;         // Velocity vectors
reg [9:0] ship2_dx, ship2_dy;
reg [9:0] bullet1_x, bullet1_y;       // Bullet positions
reg [9:0] bullet2_x, bullet2_y;
reg [9:0] bullet1_dx, bullet1_dy;     // Bullet velocity
reg [9:0] bullet2_dx, bullet2_dy;
reg bullet1_active, bullet2_active;    // Bullet state

// RGB output logic
always @(*) begin
    if (!active_pixels) begin
        rgb_out = 24'h000000;
    end else begin
        // Default background
        rgb_out = BG_COLOR;
       
        // Draw ship 1 (make it a filled rectangle)
        if ((x_pixel >= ship1_x && x_pixel < ship1_x + SHIP_SIZE) &&
            (y_pixel >= ship1_y && y_pixel < ship1_y + SHIP_SIZE)) begin
            // Add a border effect
            if (x_pixel == ship1_x || x_pixel == (ship1_x + SHIP_SIZE - 1) ||
                y_pixel == ship1_y || y_pixel == (ship1_y + SHIP_SIZE - 1))
                rgb_out = 24'hFFFFFF;  // White border
            else
                rgb_out = SHIP1_COLOR;
        end
       
        // Draw ship 2 (make it a filled rectangle)
        if ((x_pixel >= ship2_x && x_pixel < ship2_x + SHIP_SIZE) &&
            (y_pixel >= ship2_y && y_pixel < ship2_y + SHIP_SIZE)) begin
            // Add a border effect
            if (x_pixel == ship2_x || x_pixel == (ship2_x + SHIP_SIZE - 1) ||
                y_pixel == ship2_y || y_pixel == (ship2_y + SHIP_SIZE - 1))
                rgb_out = 24'hFFFFFF;  // White border
            else
                rgb_out = SHIP2_COLOR;
        end
       
        // Make bullets larger and brighter
        if (bullet1_active &&
            (x_pixel >= bullet1_x && x_pixel < bullet1_x + 4) &&
            (y_pixel >= bullet1_y && y_pixel < bullet1_y + 4)) begin
            rgb_out = BULLET_COLOR;
        end
        if (bullet2_active &&
            (x_pixel >= bullet2_x && x_pixel < bullet2_x + 4) &&
            (y_pixel >= bullet2_y && y_pixel < bullet2_y + 4)) begin
            rgb_out = BULLET_COLOR;
        end
    end
end

// Game state machine
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Initialize ship positions
        ship1_x <= 10'd50;
        ship1_y <= 10'd240;
        ship2_x <= 10'd590;
        ship2_y <= 10'd240;
       
        // Initialize velocities
        ship1_dx <= 10'd0;
        ship1_dy <= 10'd0;
        ship2_dx <= 10'd0;
        ship2_dy <= 10'd0;
       
        // Initialize angles
        ship1_angle <= 8'd0;
        ship2_angle <= 8'd180;
       
        // Initialize bullet states
        bullet1_active <= 1'b0;
        bullet2_active <= 1'b0;
       
        game_over <= 1'b0;
        winner <= 2'd0;
    end
    else begin
        if (!game_over) begin
            // Player 1 controls
            if (player1_controls[0]) ship1_y <= (ship1_y > 5) ? ship1_y - 5 : 0; // W - SW[0]
            if (player1_controls[1]) ship1_y <= (ship1_y < SCREEN_HEIGHT-SHIP_SIZE-5) ? ship1_y + 5 : SCREEN_HEIGHT-SHIP_SIZE; // S - SW[1]
            if (player1_controls[2]) ship1_x <= (ship1_x > 5) ? ship1_x - 5 : 0; // A - SW[2]
            if (player1_controls[3]) ship1_x <= (ship1_x < SCREEN_WIDTH-SHIP_SIZE-5) ? ship1_x + 5 : SCREEN_WIDTH-SHIP_SIZE; // D - SW[3]
           
            // Player 2 controls
            if (player2_controls[0]) ship2_y <= (ship2_y > 5) ? ship2_y - 5 : 0; // Up - SW[5]
            if (player2_controls[1]) ship2_y <= (ship2_y < SCREEN_HEIGHT-SHIP_SIZE-5) ? ship2_y + 5 : SCREEN_HEIGHT-SHIP_SIZE; // Down - SW[6]
            if (player2_controls[2]) ship2_x <= (ship2_x > 5) ? ship2_x - 5 : 0; // Left - SW[7]
            if (player2_controls[3]) ship2_x <= (ship2_x < SCREEN_WIDTH-SHIP_SIZE-5) ? ship2_x + 5 : SCREEN_WIDTH-SHIP_SIZE; // Right - SW[8]
           
            // Bullet 1 firing
            if (player1_controls[4] && !bullet1_active) begin // Fire - SW[4]
                bullet1_active <= 1'b1;
                bullet1_x <= ship1_x + SHIP_SIZE;
                bullet1_y <= ship1_y + (SHIP_SIZE/2);
                bullet1_dx <= 10'd8;  // Bullet speed
                bullet1_dy <= 10'd0;
            end
           
            // Bullet 2 firing
            if (player2_controls[4] && !bullet2_active) begin // Fire - SW[9]


                bullet2_active <= 1'b1;
                bullet2_x <= ship2_x;
                bullet2_y <= ship2_y + (SHIP_SIZE/2);
                bullet2_dx <= -10'd8;  // Bullet moves left
                bullet2_dy <= 10'd0;
            end
           
            // Update bullet positions
            if (bullet1_active) begin
                bullet1_x <= bullet1_x + bullet1_dx;
                if (bullet1_x >= SCREEN_WIDTH) bullet1_active <= 1'b0;
            end
           
            if (bullet2_active) begin
                bullet2_x <= bullet2_x + bullet2_dx;
                if (bullet2_x == 0) bullet2_active <= 1'b0;
            end
           
            // Collision detection
            if (bullet1_active &&
                bullet1_x >= ship2_x && bullet1_x <= ship2_x + SHIP_SIZE &&
                bullet1_y >= ship2_y && bullet1_y <= ship2_y + SHIP_SIZE) begin
                game_over <= 1'b1;
                winner <= 2'd1;
            end
           
            if (bullet2_active &&
                bullet2_x >= ship1_x && bullet2_x <= ship1_x + SHIP_SIZE &&
                bullet2_y >= ship1_y && bullet2_y <= ship1_y + SHIP_SIZE) begin
                game_over <= 1'b1;
                winner <= 2'd2;
            end
        end
    end
end

endmodule