/**
 * ==========================================================
 * Vehicle Class
 * ----------------------------------------------------------
 * First implementation of the new Physics V2 vehicle.
 * This version only creates and draws the vehicle.
 * No movement or physics yet.
 * ==========================================================
 */

class Vehicle {

    constructor(config) {

        // -------------------------
        // Vehicle Body
        // -------------------------

       this.body = new Body(
    250,
    250,
    config.body
);

        // -------------------------
        // Engine Values
        // -------------------------

        this.speed = 0;

        this.acceleration = config.engine.acceleration;
        this.maxSpeed = config.engine.maxSpeed;
        this.friction = config.engine.friction;
        // -------------------------
        // Wheels
        // -------------------------

        this.rearWheel = new Wheel(
            this.body.x + config.wheels.rearOffsetX,
            this.body.y + config.wheels.offsetY,
            config.wheels.radius
        );

        this.frontWheel = new Wheel(
            this.body.x + config.wheels.frontOffsetX,
            this.body.y + config.wheels.offsetY,
            config.wheels.radius
        );
        // Wheel attachment points relative to the body
this.rearAnchor = {
    x: config.wheels.rearOffsetX,
    y: config.wheels.offsetY
};

this.frontAnchor = {
    x: config.wheels.frontOffsetX,
    y: config.wheels.offsetY
};

    }
    

    /**
     * Update vehicle.
     * Physics will be added later.
     */
    update(physics) {

        // Update both wheels using the physics world
        this.rearWheel.update(physics);
        this.frontWheel.update(physics);
        //update body
        this.body.update(physics);
        // Calculate the constraint error 
        this.calculateConstraints();

    }
    /**
 * Calculate the constraint error between
 * the body anchor points and the wheels.
 */
calculateConstraints() {

    // Desired rear wheel position
    const rearTargetX = this.body.x + this.rearAnchor.x;
    const rearTargetY = this.body.y + this.rearAnchor.y;

    // Desired front wheel position
    const frontTargetX = this.body.x + this.frontAnchor.x;
    const frontTargetY = this.body.y + this.frontAnchor.y;

    // Constraint error
    this.rearConstraint = {
        x: this.rearWheel.x - rearTargetX,
        y: this.rearWheel.y - rearTargetY
    };

    this.frontConstraint = {
        x: this.frontWheel.x - frontTargetX,
        y: this.frontWheel.y - frontTargetY
    };

}

    /**
     * Draw vehicle.
     */
    draw() {

        // -------------------------
        // Draw Body
        // -------------------------

        const x = this.body.x - camera.x;

        const centerX = x + this.body.width / 2;
        const centerY = this.body.y + this.body.height / 2;

        ctx.save();

        ctx.translate(centerX, centerY);
        ctx.rotate(this.body.angle);

        // Body
        ctx.fillStyle = this.body.color;

        ctx.fillRect(
            -this.body.width / 2,
            -this.body.height / 2,
            this.body.width,
            this.body.height
        );

        // Cabin
        ctx.fillStyle = "#ff6708";

        ctx.fillRect(
            -this.body.width / 2 + 20,
            -this.body.height / 2 - 20,
            45,
            20
        );

        ctx.restore();

        // -------------------------
        // Draw Rear Wheel
        // -------------------------

        this.rearWheel.draw();
        this.frontWheel.draw();

    }

}

const currentVehicle = new Vehicle(VEHICLES.jeep);