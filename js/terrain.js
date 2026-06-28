// =========================
// Terrain Engine
// =========================

const terrain = [];

const TERRAIN_SEGMENT = 120;
const TERRAIN_BASE_HEIGHT = 420;
const MAX_POINTS = 60;

// Generate the initial terrain
generateTerrain();

// =========================
// Generate Initial Terrain
// =========================

function generateTerrain() {

    terrain.length = 0;

    let x = 0;
    let y = TERRAIN_BASE_HEIGHT;

    for (let i = 0; i < MAX_POINTS; i++) {

        // Random height change
        y += (Math.random() - 0.5) * 40;

        // Keep terrain within limits
        y = Math.max(320, Math.min(520, y));

        terrain.push({
            x: x,
            y: y
        });

        x += TERRAIN_SEGMENT;
    }
}

// =========================
// Extend Terrain
// =========================

function extendTerrain() {

    while (
        terrain[terrain.length - 1].x <
        car.x + canvas.width * 2
    ) {

        const last = terrain[terrain.length - 1];

        let newY = last.y + (Math.random() - 0.5) * 40;

        newY = Math.max(320, Math.min(520, newY));

        terrain.push({
            x: last.x + TERRAIN_SEGMENT,
            y: newY
        });
    }
}

// =========================
// Remove Old Terrain
// =========================

function cleanupTerrain() {

    while (
        terrain.length > MAX_POINTS &&
        terrain[1].x < car.x - canvas.width
    ) {

        terrain.shift();

    }
}

// =========================
// Draw Terrain
// =========================

function drawTerrain() {

    if (terrain.length === 0) return;

    ctx.beginPath();

    ctx.moveTo(
        terrain[0].x - camera.x,
        canvas.height
    );

    for (const point of terrain) {

        ctx.lineTo(
            point.x - camera.x,
            point.y
        );

    }

    ctx.lineTo(
        terrain[terrain.length - 1].x - camera.x,
        canvas.height
    );

    ctx.closePath();

    // Dirt
    ctx.fillStyle = "#8D6E63";
    ctx.fill();

    // Grass
    ctx.beginPath();

    ctx.moveTo(
        terrain[0].x - camera.x,
        terrain[0].y
    );

    for (const point of terrain) {

        ctx.lineTo(
            point.x - camera.x,
            point.y
        );

    }

    ctx.strokeStyle = "#4CAF50";
    ctx.lineWidth = 8;
    ctx.stroke();
}

// =========================
// Ground Height
// =========================

function getGroundHeight(x) {

    for (let i = 0; i < terrain.length - 1; i++) {

        const p1 = terrain[i];
        const p2 = terrain[i + 1];

        if (x >= p1.x && x <= p2.x) {

            const t = (x - p1.x) / (p2.x - p1.x);

            return p1.y + (p2.y - p1.y) * t;
        }
    }

    return TERRAIN_BASE_HEIGHT;
}