// =============================
// Canvas
// =============================

const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

// =============================
// Resize
// =============================

function resizeCanvas(){

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

}

window.addEventListener("resize", resizeCanvas);

resizeCanvas();

// =============================
// Game Loop
// =============================

function gameLoop(){

    updateGame();

    drawGame();

    requestAnimationFrame(gameLoop);

}