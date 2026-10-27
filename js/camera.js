// =========================
// Camera
// =========================

const camera = {

    x: 0,
    y: 0,

    smoothness: 0.08

};

function updateCamera(targetX = 0) {

    const target = targetX - canvas.width / 3;

    camera.x += (target - camera.x) * camera.smoothness;

    if (camera.x < 0) {

        camera.x = 0;

    }

}