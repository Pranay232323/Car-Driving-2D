// =========================
// Current Vehicle
// =========================

const currentVehicle = {

    // Body
    body: {

        x: 250,
        y: 250,

        width: 120,
        height: 40,

        angle: 0

    },

    // Engine
    speed: 0,
    acceleration: 0.25,
    maxSpeed: 8,
    friction: 0.98,

    // Physics
    velocityY: 0,
    gravity: 0.6,

    // Wheels
    frontWheel: {

        offsetX: 95,
        offsetY: 45,

        radius: 20,
        rotation: 0

    },

    rearWheel: {

        offsetX: 25,
        offsetY: 45,

        radius: 20,
        rotation: 0

    }

};

currentVehicle.update = function () {

    if (keys["ArrowRight"] || keys["d"]) {

        this.speed += this.acceleration;

    }

    if (keys["ArrowLeft"] || keys["a"]) {

        this.speed -= this.acceleration;

    }

    this.speed *= this.friction;

    if (this.speed > this.maxSpeed)
        this.speed = this.maxSpeed;

    if (this.speed < -this.maxSpeed)
        this.speed = -this.maxSpeed;

    this.body.x += this.speed;

    const ground = getGroundHeight(
        this.body.x + this.body.width / 2
    );

    this.body.y = ground - 65;
    // Rear wheel ground
    const rearGround = getGroundHeight(
        this.body.x + this.rearWheel.offsetX
    );

    // Front wheel ground
    const frontGround = getGroundHeight(
        this.body.x + this.frontWheel.offsetX
    );

    // Calculate body angle
    this.body.angle = Math.atan2(
        frontGround - rearGround,
        this.frontWheel.offsetX - this.rearWheel.offsetX
    );
    console.log(this.body.angle);

    this.frontWheel.rotation += this.speed * 0.08;
    this.rearWheel.rotation += this.speed * 0.08;

};

currentVehicle.draw = function () {

    const x = this.body.x - camera.x;

    ctx.fillStyle = this.color;

    ctx.fillRect(
        x,
        this.body.y,
        this.body.width,
        this.body.height
    );

    ctx.fillStyle = "#a00020";

    ctx.fillRect(
        x + 20,
        this.body.y - 20,
        45,
        20
    );

    drawWheel(
        x + this.rearWheel.offsetX,
        this.body.y + this.rearWheel.offsetY,
        this.rearWheel.rotation
    );

    drawWheel(
        x + this.frontWheel.offsetX,
        this.body.y + this.frontWheel.offsetY,
        this.frontWheel.rotation
    );

};

function drawWheel(x, y, rotation) {

    ctx.save();

    ctx.translate(x, y);

    ctx.rotate(rotation);

    ctx.fillStyle = "#222";

    ctx.beginPath();

    ctx.arc(0, 0, 20, 0, Math.PI * 2);

    ctx.fill();

    ctx.strokeStyle = "white";

    ctx.lineWidth = 3;

    ctx.beginPath();

    ctx.moveTo(-10, 0);
    ctx.lineTo(10, 0);

    ctx.moveTo(0, -10);
    ctx.lineTo(0, 10);

    ctx.stroke();

    ctx.restore();

}