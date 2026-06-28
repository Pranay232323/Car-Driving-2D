// =========================
// Renderer
// =========================

class Renderer {

    constructor(ctx) {
        this.ctx = ctx;
    }

    clear() {

        this.ctx.clearRect(
            0,
            0,
            canvas.width,
            canvas.height
        );

    }

    drawSky() {

        this.ctx.fillStyle = "#87CEEB";

        this.ctx.fillRect(
            0,
            0,
            canvas.width,
            canvas.height
        );

    }

    render() {

        this.clear();

        this.drawSky();

        // Draw world
        drawTerrain();

        currentVehicle.draw();

        // Draw UI
        drawUI();

    }

}

const renderer = new Renderer(ctx);