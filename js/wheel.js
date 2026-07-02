/**
 * ==========================================================
 * Wheel Class
 * ----------------------------------------------------------
 * Represents a single physical wheel.
 * This class owns its own state and rendering.
 * Physics behaviour will be added in later steps.
 * ==========================================================
 */

class Wheel {

    /**
     * Create a wheel.
     *
     * @param {number} x Initial X position
     * @param {number} y Initial Y position
     * @param {number} radius Wheel radius
     */
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
     * Draw this wheel.
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