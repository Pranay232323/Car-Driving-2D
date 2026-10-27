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
        // Wheel attachment points
        this.rearAnchor = {
            x: config.wheels.rearOffsetX,
            y: config.wheels.offsetY
        };

        this.frontAnchor = {
            x: config.wheels.frontOffsetX,
            y: config.wheels.offsetY
        };

        // Suspension state
        this.rearSuspension = new Suspension(
            this.body,
            this.rearWheel,
            this.rearAnchor
        );

        this.frontSuspension = new Suspension(
            this.body,
            this.frontWheel,
            this.frontAnchor
        );

    }


    /**
     * Update vehicle.
     * Physics will be added later.
     */
    update(physics) {
        // Engine
        if (keys["ArrowRight"] || keys["d"]) {

            this.rearWheel.velocityX += this.acceleration;

        }

        if (keys["ArrowLeft"] || keys["a"]) {

            this.rearWheel.velocityX -= this.acceleration;

        }

        // Friction
        this.rearWheel.velocityX *= this.friction;

        // Speed limit
        this.rearWheel.velocityX = Math.max(
            -this.maxSpeed,
            Math.min(this.maxSpeed, this.rearWheel.velocityX)
        );

        // 1. Wheels
        this.rearWheel.update(physics);
        this.frontWheel.update(physics);

        // 2. Measure suspension
        // this.rearSuspension.measure();
        // this.frontSuspension.measure();

        // 3. Body collects forces
        this.body.update(physics);

        // 4. Suspension applies forces
        // this.rearSuspension.applySpringForce();
        //  this.frontSuspension.applySpringForce();

        // 5. Body moves
        this.body.integrate();
        this.updateChassis();

    }
    updateChassis() {

        // Midpoint between wheels
        const midX = (this.rearWheel.x + this.frontWheel.x) / 2;
        const midY = (this.rearWheel.y + this.frontWheel.y) / 2;

        // Position body
        this.body.x = midX - this.body.width / 2;

        this.body.y = midY - this.rearAnchor.y;

        // Rotate body
        this.body.angle = Math.atan2(

            this.frontWheel.y - this.rearWheel.y,

            this.frontWheel.x - this.rearWheel.x

        );



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