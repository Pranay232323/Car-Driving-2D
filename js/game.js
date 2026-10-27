/**
 * ==========================================================
 * Game Update
 * ==========================================================
 */

function updateGame() {

    // Update physics simulation
    physicsWorld.update(currentVehicle);

    // Update camera
    updateCamera(currentVehicle.body.x);

    // Terrain management
    extendTerrain();
    cleanupTerrain();

}

/**
 * ==========================================================
 * Game Render
 * ==========================================================
 */

function drawGame() {

    renderer.render();

}

// Start the game loop
gameLoop();