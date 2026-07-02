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
     * Apply global forces.
     */
    applyForces(physics) {

        this.vy += physics.gravity;

    }

    /**
     * Integrate velocity.
     */
    integrate() {

        this.x += this.vx;
        this.y += this.vy;

        this.angle += this.angularVelocity;

    }

    /**
     * Update body physics.
     */
    update(physics) {

        this.applyForces(physics);

        this.integrate();

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