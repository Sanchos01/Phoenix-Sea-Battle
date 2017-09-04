import GameSocket from "./game_socket"
import * as PIXI from "pixi.js"

var Game = {
  init(socket, element, gameId){
    if(!element) { return }
    socket.connect()
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e) )
    let lobby = socket.channel("room:lobby", {game: `${gameId}`})
    let game_channel = socket.channel(`game:${ gameId }`)
    GameSocket.onReady(game_channel, lobby, gameId);

    let size = [element.offsetWidth-30, element.offsetHeight-30];
    var app = new PIXI.Application(size[0],size[1],{backgroundColor : 0xa7b3ff});
    element.appendChild(app.view);
    console.log(app);

    GameSocket.game_push(game_channel, "get_state", null);
    game_channel.on("get_state", resp => {
      switch(resp.state) {
        case "initial": this.initial_run(app)
        case "play": this.main_run(app)
        case "ended": this.ended_run(app)
      }
    })
  },

  initial_run(app) {
    // board container
    var board_container = new PIXI.Container();
    app.stage.addChild(board_container)
    var offsetL = (app._options.width/2 - 200)/2;
    console.log(`offsetLeft ${offsetL}`);
    let letters = ['a','b','c','d','e','f','g','h','i','j'];
    letters.forEach(function(item, i, arr) {
      let text = new PIXI.Text(item, {fontSize: 18});
      text.anchor.set(0.5, 0.1);
      text.position = new PIXI.Point(offsetL * 1.5 + i * 20, 0);
      board_container.addChild(text)
    });
    for (let i = 0; i < 10; i++) {
      let text = new PIXI.Text(`${i}`, {fontSize: 18});
      text.anchor.set(0.5, 0.1);
      text.position = new PIXI.Point(offsetL/2, 200 - i * 20);
      board_container.addChild(text)
    };
    for (let i = 0; i < 100; i++) {
      let graphics = new PIXI.Graphics();
      graphics.lineStyle(0, 0xFFFFFF, 1);
      graphics.beginFill(0x0022b4, 0.25);
      graphics.drawRect(offsetL + (i % 10) * 20, 20 + Math.floor(i / 10) * 20, 18, 18);
      graphics.interactive = true;
      // graphics.buttonMode = true;
      graphics.name = `${letters[i % 10]}:${9 - Math.floor(i / 10)}`
      graphics.click = function(e) { console.log("click") }
      graphics.mouseover = function(e) {
        console.log(graphics.name)
      }
      graphics.endFill();
      board_container.addChild(graphics);
    };
    board_container.position = new PIXI.Point(0, 35);

    // ships container
    var ships_container = new PIXI.Container();
    app.stage.addChild(ships_container)
    let ships = [4,3,3,2,2,2,1,1,1,1];
    ships.forEach(function(item, i, arr) {
      let graphics = new PIXI.Graphics();
      graphics.lineStyle(0, 0xFFFFFF, 1);
      graphics.beginFill(0x000000, 0.7);
      graphics.pivot.set(9, 9);
      for (let j = item; j > 0; j--) {
        graphics.drawRect(0, (j - 1) * 20, 18, 18);
      };
      graphics.position.set(270 + (i % 5) * 30, 60 + Math.floor(i / 5) * 90);
      graphics.endFill();
      graphics.name = `${item}:${i}`
      ships_container.addChild(graphics);
      graphics.interactive = true;
      graphics.buttonMode = true;
      graphics.click = function(e) {
        console.log("click")
        if(parseInt(graphics.name) == 1) { return }
        if(graphics.rotation == 0) {
          graphics.rotation += Math.PI/2
        } else {
          graphics.rotation -= Math.PI/2
        }
      }
      graphics
          .on('pointerdown', onDragStart)
          .on('pointerup', onDragEnd)
          .on('pointerupoutside', onDragEnd)
          .on('pointermove', onDragMove);
      // graphics.mouseover = function(e) {
      //   console.log(graphics.name)
      // }
    })

    var style = new PIXI.TextStyle({
      fontFamily: 'Arial',
      fontSize: 20,
      fontWeight: 'bold',
      fill: ['#ffffff', '#00ff99'],
      stroke: '#4a1850',
      strokeThickness: 4
  });
    var fieldText = new PIXI.Text('Your field', style);
    fieldText.position = new PIXI.Point(20, 5);
    app.stage.addChild(fieldText);

    var shipsText = new PIXI.Text('Place ships on the Field', style);
    shipsText.position = new PIXI.Point(app._options.width/2, 5);
    app.stage.addChild(shipsText);
  },

  main_run(app) {

  },

  ended_run(app) {

  },
  
}

function onDragStart(event) {
  this.data = event.data;
  this.alpha = 0.5;
  this.dragging = true;
}

function onDragEnd() {
  this.alpha = 1;
  this.dragging = false;
  this.data = null;
}

function onDragMove() {
  if (this.dragging) {
      var newPosition = this.data.getLocalPosition(this.parent);
      this.x = newPosition.x;
      this.y = newPosition.y;
  }
}
export default Game