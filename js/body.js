/**
 * ==========================================================
 * Body Class
 * ----------------------------------------------------------
 * Represents the vehicle body as an independent physics object.
 * It manages its own position, velocity, rotation, and rendering.
 * ==========================================================
 */

class Body {

    constructor(x, y, config) {

        // -------------------------
        // Position
        // -------------------------

        this.x = x;
        this.y = y;

        // -------------------------
        // Linear Velocity
        // -------------------------

        this.vx = 0;
        this.vy = 0;
        // Force accumulator
        this.fx = 0;
        this.fy = 0;

        // -------------------------
        // Rotation
        // -------------------------

        this.angle = 0;
        this.angularVelocity = 0;

        // -------------------------
        // Dimensions
        // -------------------------

        this.width = config.width;
        this.height = config.height;

        // -------------------------
        // Appearance
        // -------------------------

        this.color = config.color;

    }
    /**
 * Reset accumulated forces.
 */
    clearForces() {

        this.fx = 0;
        this.fy = 0;

    }

    /**
     * Apply global forces.
     */
    applyForces(physics) {

        // Gravity contributes to the accumulated force
        this.fy += physics.gravity;

    }

    /**
     * Integrate velocity.
     */
    integrate() {
        // Convert accumulated force into velocity
        this.vx += this.fx;
        this.vy += this.fy;

        this.x += this.vx;
        this.y += this.vy;

        this.angle += this.angularVelocity;

    }

    /**
     * Update body physics.
     */
    update(physics) {

    this.clearForces();

    this.applyForces(physics);

    // Don't integrate here.
    // Vehicle decides when integration happens.

}

    /**
     * Draw body.
     */
    draw() {

        const x = this.x - camera.x;

        const centerX = x + this.width / 2;
        const centerY = this.y + this.height / 2;

        ctx.save();

        ctx.translate(centerX, centerY);

        ctx.rotate(this.angle);

        // Body
        ctx.fillStyle = this.color;

        ctx.fillRect(
            -this.width / 2,
            -this.height / 2,
            this.width,
            this.height
        );

        // Cabin
        ctx.fillStyle = "#ff6708";

        ctx.fillRect(
            -this.width / 2 + 20,
            -this.height / 2 - 20,
            45,
            20
        );

        ctx.restore();

    }

}