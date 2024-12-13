module game (
    input wire clk,                    // Clock input
    input wire rst,                    // Reset input
    input wire [7:0] player1_controls, // w,s,a,d,space
    input wire [7:0] player2_controls, // i,k,j,l,m
    output reg [1919:0] display       // 80x24 display output (each pixel is 1 bit)
);

// Parameters for game constants
parameter SCREEN_WIDTH = 80;
parameter SCREEN_HEIGHT = 24;
parameter GRAVITY_FACTOR = 8'h0C;      // Fixed-point representation of gravity
parameter SHIP_RADIUS = 8'h01;

// Ship structure using fixed-point arithmetic
reg [7:0] ship1_x, ship1_y;           // Position (fixed-point)
reg [7:0] ship1_dx, ship1_dy;         // Velocity (fixed-point)
reg [7:0] ship1_angle;                // Angle (fixed-point)

reg [7:0] ship2_x, ship2_y;
reg [7:0] ship2_dx, ship2_dy;
reg [7:0] ship2_angle;

// Bullet structure
reg [7:0] bullet1_x, bullet1_y;
reg [7:0] bullet1_dx, bullet1_dy;
reg bullet1_active;

reg [7:0] bullet2_x, bullet2_y;
reg [7:0] bullet2_dx, bullet2_dy;
reg bullet2_active;

// Game state
reg game_over;
reg [1:0] winner; // 0: no winner, 1: player1 wins, 2: player2 wins

// Clock divider for game timing
reg [19:0] clock_divider;
wire frame_update;
assign frame_update = (clock_divider == 0);

// Game state machine
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset game state
        ship1_x <= 8'd10;
        ship1_y <= 8'd12;
        ship1_dx <= 8'd0;
        ship1_dy <= 8'd0;
        ship1_angle <= 8'd0;
        
        ship2_x <= 8'd70;
        ship2_y <= 8'd12;
        ship2_dx <= 8'd0;
        ship2_dy <= 8'd0;
        ship2_angle <= 8'd180;
        
        bullet1_active <= 1'b0;
        bullet2_active <= 1'b0;
        
        game_over <= 1'b0;
        winner <= 2'd0;
        
        clock_divider <= 20'd0;
    end
    else begin
        // Update clock divider
        clock_divider <= clock_divider + 1;
        
        if (frame_update && !game_over) begin
            // Process player controls
            if (player1_controls[0]) ship1_dy <= ship1_dy - 8'h01; // W
            if (player1_controls[1]) ship1_dy <= ship1_dy + 8'h01; // S
            if (player1_controls[2]) ship1_angle <= ship1_angle - 8'h01; // A
            if (player1_controls[3]) ship1_angle <= ship1_angle + 8'h01; // D
            if (player1_controls[4] && !bullet1_active) begin // Space
                bullet1_active <= 1'b1;
                bullet1_x <= ship1_x;
                bullet1_y <= ship1_y;
                // Simplified bullet velocity calculation
                bullet1_dx <= 8'h02;
                bullet1_dy <= 8'h00;
            end
            
            // Similar controls for player 2
            // ... (implement player 2 controls similarly)
            
            // Update positions
            ship1_x <= ship1_x + ship1_dx;
            ship1_y <= ship1_y + ship1_dy;
            ship2_x <= ship2_x + ship2_dx;
            ship2_y <= ship2_y + ship2_dy;
            
            // Update bullets
            if (bullet1_active) begin
                bullet1_x <= bullet1_x + bullet1_dx;
                bullet1_y <= bullet1_y + bullet1_dy;
                // Deactivate if out of bounds
                if (bullet1_x >= SCREEN_WIDTH || bullet1_y >= SCREEN_HEIGHT)
                    bullet1_active <= 1'b0;
            end
            
            // Check collisions
            if (check_collision(ship1_x, ship1_y, bullet2_x, bullet2_y) && bullet2_active) begin
                game_over <= 1'b1;
                winner <= 2'd2;
            end
            if (check_collision(ship2_x, ship2_y, bullet1_x, bullet1_y) && bullet1_active) begin
                game_over <= 1'b1;
                winner <= 2'd1;
            end
        end
    end
end

// Collision detection function
function check_collision;
    input [7:0] ship_x, ship_y, bullet_x, bullet_y;
    begin
        // Simplified collision detection
        check_collision = (ship_x == bullet_x && ship_y == bullet_y);
    end
endfunction

// Display update logic
always @* begin
    display = 1920'b0; // Clear display
    
    // Draw ships
    display[ship1_y * SCREEN_WIDTH + ship1_x] = 1'b1;
    display[ship2_y * SCREEN_WIDTH + ship2_x] = 1'b1;
    
    // Draw bullets
    if (bullet1_active)
        display[bullet1_y * SCREEN_WIDTH + bullet1_x] = 1'b1;
    if (bullet2_active)
        display[bullet2_y * SCREEN_WIDTH + bullet2_x] = 1'b1;
    
    // Draw center star
    display[(SCREEN_HEIGHT/2) * SCREEN_WIDTH + (SCREEN_WIDTH/2)] = 1'b1;
end

endmodule