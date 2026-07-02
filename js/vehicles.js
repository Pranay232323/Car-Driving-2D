/**
 * ==========================================================
 * Vehicle Database
 * ----------------------------------------------------------
 * Stores configuration for every vehicle in the game.
 * No vehicle-specific values should be hardcoded elsewhere.
 * ==========================================================
 */

const VEHICLES = {

    jeep: {

        // -------------------------
        // Body
        // -------------------------

        body: {

            width: 120,
            height: 40,
            color: "#d62828"

        },

        // -------------------------
        // Wheels
        // -------------------------

        wheels: {

            radius: 20,

            rearOffsetX: 25,
            frontOffsetX: 95,

            offsetY: 45

        },

        // -------------------------
        // Engine
        // -------------------------

        engine: {

            acceleration: 0.25,
            maxSpeed: 8,
            friction: 0.98

        }

    }

};