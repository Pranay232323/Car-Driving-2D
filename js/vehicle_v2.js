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

        this.body = {

            x: 250,
            y: 250,

            width: config.width,
            height: config.height,

            angle: 0,

            color: config.color

        };

        // -------------------------
        // Engine Values
        // -------------------------

        this.speed = 0;

        this.acceleration = config.acceleration;
        this.maxSpeed = config.maxSpeed;
        this.friction = config.friction;

        // -------------------------
        // Wheels
        // -------------------------

        this.rearWheel = new Wheel(
            this.body.x + 25,
            this.body.y + 45,
            config.wheelRadius
        );

        this.frontWheel = new Wheel(
            this.body.x + 95,
            this.body.y + 45,
            config.wheelRadius
        );

    }

    /**
     * Update vehicle.
     * Physics will be added later.
     */
    update() {

        // Nothing yet

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