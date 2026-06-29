// =========================
// Renderer
// =========================

class Renderer {

    render() {

        // Sky
        ctx.fillStyle = "#87CEEB";

        ctx.fillRect(
            0,
            0,
            canvas.width,
            canvas.height
        );

        // Terrain
        drawTerrain();

        // Vehicle
        currentVehicle.draw();

        // UI
        drawUI();

    }

}

// Create renderer object
const renderer = new Renderer();