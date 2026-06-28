function updateGame(){

    currentVehicle.update();

    updateCamera(currentVehicle.x);

}

function drawGame(){

    renderer.render();

}

gameLoop();