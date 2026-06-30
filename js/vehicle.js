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
    onGround: false,

    // Wheels
  frontWheel: {

    x: 0,
    y: 0,

    velocityX: 0,
    velocityY: 0,

    radius: 20,

    rotation: 0,

    offsetX: 95,
    offsetY: 45

},

  rearWheel: {

    x: 0,
    y: 0,

    velocityX: 0,
    velocityY: 0,

    radius: 20,

    rotation: 0,

    offsetX: 25,
    offsetY: 45

},

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
    // Update rear wheel position
   // Rear wheel always follows body horizontally
this.rearWheel.x = this.body.x + this.rearWheel.offsetX;

// Apply gravity to rear wheel
this.rearWheel.velocityY += this.gravity;

// Move rear wheel vertically
this.rearWheel.y += this.rearWheel.velocityY;
// Rear wheel ground collision
const rearWheelGround = getGroundHeight(this.rearWheel.x);

const rearWheelGroundY =
    rearWheelGround - this.rearWheel.radius;

if (this.rearWheel.y > rearWheelGroundY) {

    this.rearWheel.y = rearWheelGroundY;

    this.rearWheel.velocityY = 0;

}
    // Update front wheel position
this.frontWheel.x = this.body.x + this.frontWheel.offsetX;
this.frontWheel.y = this.body.y + this.frontWheel.offsetY;

    // Apply Gravity
    this.velocityY += this.gravity;

    // Move Vertically
  this.body.y =
    this.rearWheel.y - this.rearWheel.offsetY;

    // Rear Wheel Ground
    const rearGround = getGroundHeight(
        this.body.x + this.rearWheel.offsetX
    );

    // Front Wheel Ground
    const frontGround = getGroundHeight(
        this.body.x + this.frontWheel.offsetX
    );

    // Average Ground
    const ground = (rearGround + frontGround) / 2;

    // Apply Gravity
    this.velocityY += this.gravity;

    // Move Vehicle
    this.body.y += this.velocityY;

    // Ground Collision
    if (this.body.y >= ground - 65) {

        this.body.y = ground - 65;

        this.velocityY = 0;

        this.onGround = true;

    } else {

        this.onGround = false;

    }

    // Body Rotation
    this.body.angle = Math.atan2(
        frontGround - rearGround,
        this.frontWheel.offsetX - this.rearWheel.offsetX
    );

    this.frontWheel.rotation += this.speed * 0.08;
    this.rearWheel.rotation += this.speed * 0.08;

};


currentVehicle.draw = function () {

    const x = this.body.x - camera.x;

    const centerX = x + this.body.width / 2;
    const centerY = this.body.y + this.body.height / 2;

    ctx.save();

    // Move origin to body center
    ctx.translate(centerX, centerY);

    // Rotate body
    ctx.rotate(this.body.angle);

    // Draw Body
    ctx.fillStyle = this.color;

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

    // Rear Wheel
    drawWheel(
        this.rearWheel.x - camera.x,
        this.rearWheel.y,
        this.rearWheel.rotation
    );

    // Front Wheel
   drawWheel(
    this.frontWheel.x - camera.x,
    this.frontWheel.y,
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