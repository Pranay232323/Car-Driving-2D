// =========================
// Vehicle Class
// =========================

class Vehicle {

    constructor(config) {

        // Configuration
        this.name = config.name;
        this.mass = config.mass;
        this.enginePower = config.enginePower;
        this.maxSpeed = config.maxSpeed;
        this.wheelRadius = config.wheelRadius;
        this.bodyWidth = config.bodyWidth;
        this.bodyHeight = config.bodyHeight;
        this.color = config.color;

        // Position
        this.x = 250;
        this.y = 300;

        // Motion
        this.speed = 0;
        this.velocityY = 0;
        this.gravity = 0.6;

        // Animation
        this.wheelRotation = 0;
    }

    update() {

        // Accelerate
        if (keys["ArrowRight"] || keys["d"]) {
            this.speed += this.enginePower;
        }

        // Reverse
        if (keys["ArrowLeft"] || keys["a"]) {
            this.speed -= this.enginePower;
        }

        // Clamp Speed
        if (this.speed > this.maxSpeed)
            this.speed = this.maxSpeed;

        if (this.speed < -this.maxSpeed)
            this.speed = -this.maxSpeed;

        // Friction
        this.speed *= 0.98;

        // Horizontal movement
        this.x += this.speed;

        // Gravity
        this.velocityY += this.gravity;
        this.y += this.velocityY;

        // Ground Collision
        const ground = getGroundHeight(this.x + this.bodyWidth / 2);

        if (this.y > ground - 62) {

            this.y = ground - 62;
            this.velocityY = 0;

        }

        // Rotate wheels
        this.wheelRotation += this.speed * 0.05;
    }

    drawWheel(x, y) {

        ctx.save();

        ctx.translate(x, y);
        ctx.rotate(this.wheelRotation);

        ctx.fillStyle = "#222";

        ctx.beginPath();
        ctx.arc(0, 0, this.wheelRadius, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeStyle = "white";
        ctx.lineWidth = 3;

        ctx.beginPath();

        ctx.moveTo(-12, 0);
        ctx.lineTo(12, 0);

        ctx.moveTo(0, -12);
        ctx.lineTo(0, 12);

        ctx.stroke();

        ctx.restore();

    }

    draw() {

        const x = this.x - camera.x;

        // Body
        ctx.fillStyle = this.color;
        ctx.fillRect(
            x,
            this.y,
            this.bodyWidth,
            this.bodyHeight
        );

        // Cabin
        ctx.fillStyle = "#b00020";

        ctx.fillRect(
            x + 20,
            this.y - 20,
            45,
            20
        );

        // Wheels
        this.drawWheel(
            x + 25,
            this.y + 45
        );

        this.drawWheel(
            x + 95,
            this.y + 45
        );
    }

}

// =========================
// Current Vehicle
// =========================

const currentVehicle = new Vehicle(
    VEHICLES.jeep
);