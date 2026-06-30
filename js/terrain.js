const terrain = [];

const SEGMENT = 120;
const BASE_HEIGHT = 420;

generateTerrain();

function generateTerrain() {

    let x = 0;
    let y = BASE_HEIGHT;

    for (let i = 0; i < 40; i++) {

        y += (Math.random() - 0.5) * 35;

        if (y < 320) y = 320;
        if (y > 500) y = 500;

        terrain.push({
            x,
            y
        });

        x += SEGMENT;

    }

}
// =========================
// Extend Terrain
// =========================

function extendTerrain() {

    console.log(
        "Last X:",
        terrain[terrain.length - 1].x,
        "Car X:",
        currentVehicle.body.x
    );

    while (
        terrain[terrain.length - 1].x <
        currentVehicle.body.x + canvas.width * 2
    ) {

        const last = terrain[terrain.length - 1];

       let y = last.y + (Math.random() - 0.5) * 90;

       if (y < 250) y = 250;
if (y > 550) y = 550;

        terrain.push({
            x: last.x + SEGMENT,
            y: y
        });

        console.log("New terrain added!");
    }
}
// =========================
// Remove Old Terrain
// =========================

function cleanupTerrain() {

    while (

        terrain.length > 60 &&

        terrain[1].x < currentVehicle.body.x - canvas.width

    ) {

        terrain.shift();

    }

}

function drawTerrain() {

    ctx.beginPath();

    ctx.moveTo(
        terrain[0].x - camera.x,
        canvas.height
    );

    terrain.forEach(point => {

        ctx.lineTo(
            point.x - camera.x,
            point.y
        );

    });

    ctx.lineTo(
        terrain[terrain.length - 1].x - camera.x,
        canvas.height
    );

    ctx.closePath();

    ctx.fillStyle = "#8D6E63";

    ctx.fill();

    ctx.beginPath();

    terrain.forEach((point, index) => {

        if (index === 0) {

            ctx.moveTo(
                point.x - camera.x,
                point.y
            );

        } else {

            ctx.lineTo(
                point.x - camera.x,
                point.y
            );

        }

    });

    ctx.strokeStyle = "#4CAF50";
    ctx.lineWidth = 8;
    ctx.stroke();

}

function getGroundHeight(x) {

    for (let i = 0; i < terrain.length - 1; i++) {

        const a = terrain[i];
        const b = terrain[i + 1];

        if (x >= a.x && x <= b.x) {

            const t = (x - a.x) / (b.x - a.x);

            return a.y + (b.y - a.y) * t;

        }

    }

    return BASE_HEIGHT;

}