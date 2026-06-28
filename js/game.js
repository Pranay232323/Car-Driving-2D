function updateGame() {

    currentVehicle.update();

    updateCamera();

    extendTerrain();

    cleanupTerrain();

}

function drawGame() {

    renderer.render();

}