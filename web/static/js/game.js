import GameChannel from "./game_channel"
import * as PIXI from "pixi.js"
import * as init from "./game/initial"
import * as main from "./game/main"

var Game = {
  init(socket, element, gameId){
    if(!element) { return }
    socket.connect()
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e) )
    let lobby = socket.channel("room:lobby", {game: `${gameId}`})
    let game_channel = socket.channel(`game:${ gameId }`)
    GameChannel.onReady(game_channel, lobby, gameId);

    let size = [element.offsetWidth-30, element.offsetHeight-30];
    var app = new PIXI.Application(size[0],size[1],{backgroundColor : 0xa7b3ff});
    element.addEventListener('contextmenu', event => event.preventDefault());
    element.appendChild(app.view);

    GameChannel.game_push(game_channel, "get_state", null);
    game_channel.on("get_state", resp => {
      switch(resp.state) {
        case "initial": init.run(app, game_channel)
        case "play": main.run(app)
        case "ended": main.run(app)
      }
    })
  },
}
export default Game