#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <stdbool.h>
#include <termios.h>
#include <fcntl.h>

#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 24
#define GRAVITY 0.05
#define SHIP_RADIUS 1.0

/**
 * @brief constructor for ship
 * - holds the x and y position of the ship
 * - dx and dy are the ships velocity 
 * - angle determines the way the ship is facing
 */
typedef struct {
    float x, y;
    float dx, dy;
    float angle;
} Ship;

/**
 * @brief constructor for bullet
 * - holds the x and y position of the bullet
 * - dx and dy are the bullets velocity 
 * - active determines whether if the bullet exists and is moving
 */
typedef struct {
    float x, y;
    float dx, dy;
    bool active;
} Bullet;

char screen[SCREEN_HEIGHT][SCREEN_WIDTH];

/*
clears the terminal screen
*/
void clear_screen() {
    system("clear");
}

/*
resets the screen array
*/
void init_screen() {
    for (int i = 0; i < SCREEN_HEIGHT; i++) {
        for (int j = 0; j < SCREEN_WIDTH; j++) {
            screen[i][j] = ' ';
        }
    }
}

/*
clears the terminal screen and draws the current screen
*/
void draw_screen() {
    clear_screen();
    for (int i = 0; i < SCREEN_HEIGHT; i++) {
        for (int j = 0; j < SCREEN_WIDTH; j++) {
            putchar(screen[i][j]);
        }
        putchar('\n');
    }
}

/*
places a ship
*/
void draw_ship(Ship *ship, char symbol) {
    int x = (int)ship->x;
    int y = (int)ship->y;
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        screen[y][x] = symbol;
    }
}

/*
draws a bullet and checks if it is active
*/
void draw_bullet(Bullet *bullet) {
    if (bullet->active) {
        int x = (int)bullet->x;
        int y = (int)bullet->y;
        if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
            screen[y][x] = '*';
        } else {
            bullet->active = false;
        }
    }
}

/*
applies gravity to a ship by calculating the force pulling it toward the center
*/ 
void apply_gravity(Ship *ship) {
    float star_x = SCREEN_WIDTH / 2;
    float star_y = SCREEN_HEIGHT / 2;

    float dist_x = star_x - ship->x;
    float dist_y = star_y - ship->y;
    float distance = sqrt(dist_x * dist_x + dist_y * dist_y);

    if (distance > 0) {
        ship->dx += GRAVITY * dist_x / distance;
        ship->dy += GRAVITY * dist_y / distance;
    }
}

/*
updates a ship's position based on its velocity, implements screen wrapping, 
so ships leaving one edge reappear on the opposite edge.
*/
void move_ship(Ship *ship) {
    ship->x += ship->dx;
    ship->y += ship->dy;

    if (ship->x < 0) ship->x += SCREEN_WIDTH;
    if (ship->x >= SCREEN_WIDTH) ship->x -= SCREEN_WIDTH;
    if (ship->y < 0) ship->y += SCREEN_HEIGHT;
    if (ship->y >= SCREEN_HEIGHT) ship->y -= SCREEN_HEIGHT;
}

/*
updates a bullets position
*/
void move_bullet(Bullet *bullet) {
    if (bullet->active) {
        bullet->x += bullet->dx;
        bullet->y += bullet->dy;
    }
}

/*
fires a bullet from a ship's current position
*/
void shoot_bullet(Ship *ship, Bullet *bullet) {
    if (!bullet->active) {
        bullet->x = ship->x;
        bullet->y = ship->y;
        bullet->dx = cos(ship->angle) * 1.5;
        bullet->dy = sin(ship->angle) * 1.5;
        bullet->active = true;
    }
}

/*
detects if a bullet hits a ship
*/
bool check_collision(Ship *ship, Bullet *bullet) {
    if (bullet->active) {
        float dist_x = ship->x - bullet->x;
        float dist_y = ship->y - bullet->y;
        float distance = sqrt(dist_x * dist_x + dist_y * dist_y);
        return distance <= SHIP_RADIUS;
    }
    return false;
}

/*
checks if a key is pressed without pausing the game
*/
int kbhit() {
    struct termios oldt, newt;
    int ch;
    int oldf;

    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);

    ch = getchar();

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);

    if (ch != EOF) {
        ungetc(ch, stdin);
        return 1;
    }

    return 0;
}

/*
sets up initial positions for ships and bullets, starts the game loop,
handles input for both players, updates ship and bullet positions based on physics,
checks for collisions between bullets and ships, 
ends the game if a collision occurs, draws all objects on the screen, 
uses usleep to control the game speed
*/
int main() {
    Ship ship1 = {10, 12, 0, 0, 0};
    Ship ship2 = {70, 12, 0, 0, M_PI};
    Bullet bullet1 = {0, 0, 0, 0, false};
    Bullet bullet2 = {0, 0, 0, 0, false};
    char input;
    bool running = true;

    while (running) {
        init_screen();

        if (kbhit()) {
            input = getchar();
            if (input == 'q') running = false;
            if (input == 'w') ship1.dy -= 0.1;
            if (input == 's') ship1.dy += 0.1;
            if (input == 'a') ship1.angle -= 0.1;
            if (input == 'd') ship1.angle += 0.1;
            if (input == ' ') shoot_bullet(&ship1, &bullet1);

            if (input == 'i') ship2.dy -= 0.1;
            if (input == 'k') ship2.dy += 0.1;
            if (input == 'j') ship2.angle -= 0.1;
            if (input == 'l') ship2.angle += 0.1;
            if (input == 'm') shoot_bullet(&ship2, &bullet2);
        }

        apply_gravity(&ship1);
        apply_gravity(&ship2);

        move_ship(&ship1);
        move_ship(&ship2);

        move_bullet(&bullet1);
        move_bullet(&bullet2);

        if (check_collision(&ship1, &bullet2)) {
            printf("Ship 2 wins! Ship 1 was hit.\n");
            break;
        }
        if (check_collision(&ship2, &bullet1)) {
            printf("Ship 1 wins! Ship 2 was hit.\n");
            break;
        }

        draw_ship(&ship1, '>');
        draw_ship(&ship2, '<');
        draw_bullet(&bullet1);
        draw_bullet(&bullet2);

        screen[SCREEN_HEIGHT / 2][SCREEN_WIDTH / 2] = '*';

        draw_screen();
        usleep(50000);
    }

    return 0;
}