import GameChannel from "./../game_channel"
import * as board from "./board"

export function run(app, game_channel) {
  var bar = document.getElementById("state-bar");
  bar.innerText = 'Preparing';
  board.create_board(app, 0, 35);

  game_channel.on("board_ok", resp => {
    bar.innerText = 'All OK, wait another player';
  });

  game_channel.on("bad_position", resp => {
    bar.innerText = 'Something wrong with your board';
  });

  // ships container
  var ships_container = new PIXI.Container();
  app.stage.addChild(ships_container);
  let ships = [4,3,3,2,2,2,1,1,1,1];
  ships.forEach(function(item, i, arr) {
    let ship = new PIXI.Graphics();
    ship.lineStyle(0, 0xFFFFFF, 1);
    ship.beginFill(0x000000, 0.7);
    ship.pivot.set(9, 9);
    for (let j = item; j > 0; j--) {
      ship.drawRect(0, (j - 1) * 20, 18, 18);
    };
    ship.position.set(270 + (i % 5) * 30, 60 + Math.floor(i / 5) * 90);
    ship.endFill();
    ship.length = item;
    ship.num = i;
    ships_container.addChild(ship);
    ship.interactive = true;
    ship.buttonMode = true;
    ship.rightclick = function(e) {
      if(ship.length == 1) { return }
      if(ship.rotation == 0) {
        ship.rotation = Math.PI/2;
      } else {
        ship.rotation = 0;
      }
    }
    ship
        .on('mousedown', onDragStart)
        .on('mouseup', onDragEnd)
        .on('mouseupoutside', onDragEnd)
        .on('mousemove', onDragMove);
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

  var ready = new PIXI.Graphics();
  ready.lineStyle(1, 0x000000, 1);
  ready.beginFill(0x992242, 0.5);
  ready.drawRect(0, 0, 50, 20);
  ready.endFill();
  ready.interactive = true;
  ready.position.set(300, 200);
  ready.click = function(e) {
    let res_arr = checking();
    // console.log(res_arr);
    if(res_arr.reduce((prev, curr, index, arr) => {
      if(prev == false) {return prev}
      if(curr.length == 0) {return false} else {return prev}
    }, true) == false) {
      bar.innerText = 'Bad ships position'
    } else {
      bar.innerText = 'Wait answer from server'
      GameChannel.game_push(game_channel, "ready", res_arr);
    }
  };
  app.stage.addChild(ready);

  function onDragStart(event) {
    this.data = event.data;
    this.alpha = 0.5;
    this.dragging = true;
    this.data.startX = this.x;
    this.data.startY = this.y;
  }

  function onDragEnd() {
    if(this.dragging) {
      this.alpha = 1;
      this.dragging = false;
      let arr = hitTest(this);
      if(arr.length == parseInt(this.length)) {
        if(this.rotation == 0) {
          this.x = arr[0].x
          this.y = arr[0].y
        } else {
          this.x = arr[arr.length - 1].x
          this.y = arr[arr.length - 1].y
        }
      } else {
        this.x = this.data.startX;
        this.y = this.data.startY;
        this.data = null;
      }
    }
  }

  function onDragMove(event) {
    if (this.dragging) {
        var newPosition = this.data.getLocalPosition(this.parent);
        this.x = newPosition.x;
        this.y = newPosition.y;
        let point = new PIXI.Point(27.5, 64)
    }
  }

  function hitTest(ship) {
    let grid_arr = board.grid.filter((value) => {return ship.containsPoint(value)});
    if(grid_arr.length == 0) {return grid_arr};
    return ships_container.children.reduce((prev, curr, index, array) => {
      if(prev.length == 0) {return prev};
      if(ship.num == curr.num) {return prev};
      let value = grid_arr.filter((value) => {return curr.containsPoint(value)});
      if(value.length == 0) { return prev };
      return [];
    }, grid_arr)
  }

  function checking() {
    return (ships_container.children.map((ship) => {
      return board.grid.filter((point) => {return ship.containsPoint(point)})
                       .map((point) => {
                         let column = board.letters[Math.floor((point.x - 27)/20)];
                         let line = Math.floor((point.y - 64)/20);
                         return `${column}:${line}`
                       })
    }))
  }
}