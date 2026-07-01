// =========================
// Vehicle V2
// =========================

class Vehicle {

    constructor(x, y) {

        // Engine
        this.engineForce = 0.25;
        this.maxSpeed = 8;
        this.friction = 0.98;
        this.speed = 0;

        // Body
        this.body = {

            x: x,
            y: y,

            width: 120,
            height: 40,

            angle: 0,

            color: "#d62828"

        };

        // Rear Wheel
        this.rearWheel = {

            x: x + 25,
            y: y + 45,

            radius: 20,

            velocityX: 0,
            velocityY: 0,

            rotation: 0

        };

        // Front Wheel
        this.frontWheel = {

            x: x + 95,
            y: y + 45,

            radius: 20,

            velocityX: 0,
            velocityY: 0,

            rotation: 0

        };

        // Physics
        this.gravity = 0.6;

    }

    update() {

        // We will build this in Part B

    }

    draw() {

        // We will build this in Part C

    }

}

// Current Vehicle
const currentVehicle = new Vehicle(250, 250);