// =========================
// UI
// =========================

let fps = 0;
let lastTime = performance.now();

function updateFPS() {

    const now = performance.now();

    fps = Math.round(1000 / (now - lastTime));

    lastTime = now;

}

function drawUI() {

    updateFPS();

    // Text Style
    ctx.fillStyle = "white";
    ctx.font = "22px Arial";

    // Distance
    ctx.fillText(
        "Distance: " + Math.floor(currentVehicle.x / 10) + " m",
        20,
        35
    );

    // Speed
    ctx.fillText(
        "Speed: " + Math.abs(Math.floor(currentVehicle.speed * 10)) + " km/h",
        20,
        70
    );

    // FPS
    ctx.fillText(
        "FPS: " + fps,
        canvas.width - 120,
        35
    );

}