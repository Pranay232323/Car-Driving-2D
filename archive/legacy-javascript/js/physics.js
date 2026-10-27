/**
 * ==========================================================
 * Physics World
 * ----------------------------------------------------------
 * Manages all physics simulation.
 * Vehicles and other physics objects will be updated here.
 * ==========================================================
 */

class PhysicsWorld {

    constructor() {

        /**
         * Global gravity.
         * Every physics object will use this.
         */
        this.gravity = 0.6;

    }

    /**
     * Update the physics simulation.
     *
     * @param {Vehicle} vehicle
     */
    update(vehicle) {

        vehicle.update(this);

    }

}

/**
 * Global physics world.
 */
const physicsWorld = new PhysicsWorld();