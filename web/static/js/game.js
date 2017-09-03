import GameSocket from "./game_socket"
import * as PIXI from "pixi.js"

var Game = {
  init(socket, element, gameId){
    if(!element) { return }
    var size = [element.offsetWidth-30, element.offsetHeight-30];
    var app = new PIXI.Application(size[0],size[1],{backgroundColor : 0xffffff});
    element.appendChild(app.view);
    console.log(app);
    GameSocket.init(socket, element, gameId);
    // this.run(renderer)
  },

  run() {
    
  },
}
export default Game