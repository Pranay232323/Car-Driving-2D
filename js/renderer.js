class Renderer{

    render(){

        ctx.fillStyle="#87CEEB";

        ctx.fillRect(
            0,
            0,
            canvas.width,
            canvas.height
        );

        drawTerrain();

        currentVehicle.draw();

    }

}

const renderer=new Renderer();