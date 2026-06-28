const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

function resize(){

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

}

window.addEventListener("resize",resize);

resize();

function gameLoop(){

    updateGame();

    drawGame();

    requestAnimationFrame(gameLoop);

}

gameLoop();