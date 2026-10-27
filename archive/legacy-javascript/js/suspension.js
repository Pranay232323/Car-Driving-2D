/**
 * ==========================================================
 * Suspension Class
 * ----------------------------------------------------------
 * Connects a Body and a Wheel.
 * Responsible for measuring suspension travel and later
 * applying spring and damping forces.
 * ==========================================================
 */

class Suspension {
    /**
 * Measure the current suspension length.
 */
measure() {

    // Body anchor position in world space
    const anchorX = this.body.x + this.anchor.x;
    const anchorY = this.body.y + this.anchor.y;

    // Distance from anchor to wheel
    const dx = this.wheel.x - anchorX;
    const dy = this.wheel.y - anchorY;

    // Current spring length
    this.currentLength = Math.sqrt(dx * dx + dy * dy);

    // Initialize rest length once
    if (this.restLength === 0) {
        this.restLength = this.currentLength;
    }

    // Spring compression
    this.compression = this.restLength - this.currentLength;

}
/**
 * Calculate and apply spring force.
 */
applySpringForce() {

    // Body anchor position
    const anchorX = this.body.x + this.anchor.x;
    const anchorY = this.body.y + this.anchor.y;

    // Spring vector
    const dx = this.wheel.x - anchorX;
    const dy = this.wheel.y - anchorY;

    const length = Math.sqrt(dx * dx + dy * dy);

    if (length === 0) return;

    // Normalized direction
    const nx = dx / length;
    const ny = dy / length;

    // Current compression
    const displacement = this.restLength - length;

    // Relative velocity of body along spring
    const relativeVelocity =
        this.body.vx * nx +
        this.body.vy * ny;

    // Hooke's Law + damping
    const force =
        displacement * this.stiffness -
        relativeVelocity * this.damping;

    // Apply to body
    this.body.fx -= nx * force;
    this.body.fy -= ny * force;

}

    constructor(body, wheel, anchor) {

        // Connected physics objects
        this.body = body;
        this.wheel = wheel;

        // Attachment point relative to the body
        this.anchor = anchor;

        // Suspension settings
        this.restLength = 0;
        this.currentLength = 0;
        this.compression = 0;

        // These values will be tuned later
       this.stiffness = 0.15;
this.damping = 0.08;

    }

}