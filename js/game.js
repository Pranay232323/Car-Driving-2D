function updateGame() {

    currentVehicle.update();

    updateCamera(currentVehicle.body.x);

    extendTerrain();

    cleanupTerrain();

}

function drawGame(){

    renderer.render();

}

gameLoop();