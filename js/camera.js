// =========================
// Camera
// =========================

const camera = {
    x: 0,
    y: 0
};

function updateCamera() {

    camera.x = currentVehicle.x - canvas.width / 3;

    if (camera.x < 0) {
        camera.x = 0;
    }

}