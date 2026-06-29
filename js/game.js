function updateGame() {

    currentVehicle.update();

    updateCamera(currentVehicle.x);

    extendTerrain();

    cleanupTerrain();

}

function drawGame(){

    renderer.render();

}

gameLoop();