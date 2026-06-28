// =========================
// Current Vehicle
// =========================

const currentVehicle = {

    x: 250,
    y: 300,

    width: 120,
    height: 40,

    wheelRadius: 20,

    speed: 0,
    velocityY: 0,

    gravity: 0.6,

    wheelRotation: 0,

    acceleration: 0.25,
    maxSpeed: 8,
    friction: 0.98

};

// =========================
// Update Vehicle
// =========================

currentVehicle.update = function () {

    // Accelerate
    if (keys["ArrowRight"] || keys["d"]) {

        this.speed += this.acceleration;

    }

    // Brake / Reverse
    if (keys["ArrowLeft"] || keys["a"]) {

        this.speed -= this.acceleration;

    }

    // Clamp speed
    if (this.speed > this.maxSpeed)
        this.speed = this.maxSpeed;

    if (this.speed < -this.maxSpeed)
        this.speed = -this.maxSpeed;

    // Friction
    this.speed *= this.friction;

    // Horizontal movement
    this.x += this.speed;

    // Gravity
    this.velocityY += this.gravity;
    this.y += this.velocityY;

    // Ground collision
    const ground = getGroundHeight(
        this.x + this.width / 2
    );

    if (this.y > ground - 62) {

        this.y = ground - 62;

        this.velocityY = 0;

    }

    // Rotate wheels
    this.wheelRotation += this.speed * 0.08;

};

// =========================
// Draw Wheel
// =========================

function drawWheel(x, y, rotation) {

    ctx.save();

    ctx.translate(x, y);

    ctx.rotate(rotation);

    // Tire
    ctx.fillStyle = "#222";

    ctx.beginPath();

    ctx.arc(
        0,
        0,
        currentVehicle.wheelRadius,
        0,
        Math.PI * 2
    );

    ctx.fill();

    // Rim

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

// =========================
// Draw Vehicle
// =========================

currentVehicle.draw = function () {

    const screenX = this.x - camera.x;

    // Body
    ctx.fillStyle = "#d62828";

    ctx.fillRect(
        screenX,
        this.y,
        this.width,
        this.height
    );

    // Cabin
    ctx.fillStyle = "#a00020";

    ctx.fillRect(
        screenX + 20,
        this.y - 20,
        45,
        20
    );

    // Wheels

    drawWheel(
        screenX + 25,
        this.y + 45,
        this.wheelRotation
    );

    drawWheel(
        screenX + 95,
        this.y + 45,
        this.wheelRotation
    );

};