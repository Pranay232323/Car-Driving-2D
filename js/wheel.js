/**
 * ==========================================================
 * Wheel Class
 * ----------------------------------------------------------
 * Represents a single physical wheel.
 * Handles its own state and basic physics.
 * ==========================================================
 */

class Wheel {

    constructor(x, y, radius) {

        // Position
        this.x = x;
        this.y = y;

        // Velocity
        this.vx = 0;
        this.vy = 0;

        // Size
        this.radius = radius;

        // Visual rotation
        this.rotation = 0;
    }

    /**
     * Update wheel physics.
     *
     * @param {PhysicsWorld} physics
     */
   update(physics) {

    // Apply gravity
    this.vy += physics.gravity;

    // Move
    this.x += this.vx;
    this.y += this.vy;

    // -------------------------
    // Ground Collision
    // -------------------------

    const groundY = getGroundHeight(this.x) - this.radius;

    if (this.y > groundY) {

        // Place wheel on terrain
        this.y = groundY;

        // Stop falling
        this.vy = 0;

    }

}

    /**
     * Draw wheel.
     */
    draw() {

        ctx.save();

        ctx.translate(
            this.x - camera.x,
            this.y
        );

        ctx.rotate(this.rotation);

        // Tire
        ctx.fillStyle = "#222";

        ctx.beginPath();
        ctx.arc(0, 0, this.radius, 0, Math.PI * 2);
        ctx.fill();

        // Spokes
        ctx.strokeStyle = "white";
        ctx.lineWidth = 3;

        ctx.beginPath();

        ctx.moveTo(-this.radius / 2, 0);
        ctx.lineTo(this.radius / 2, 0);

        ctx.moveTo(0, -this.radius / 2);
        ctx.lineTo(0, this.radius / 2);

        ctx.stroke();

        ctx.restore();

    }

}