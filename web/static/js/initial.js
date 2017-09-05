export function run(app) {
  var grid = [];
  // board container
  var board_container = new PIXI.Container();
  app.stage.addChild(board_container)
  var offsetL = (app._options.width/2 - 200)/2;
  var letters = ['a','b','c','d','e','f','g','h','i','j'];
  for (let i = 0; i < 100; i++) {
    let rect = new PIXI.Graphics();
    rect.lineStyle(0, 0xFFFFFF, 1);
    rect.beginFill(0x0022b4, 0.25);
    let x = offsetL + (i % 10) * 20;
    let y = 20 + Math.floor(i / 10) * 20;
    rect.drawRect(x, y, 18, 18);
    rect.interactive = true;
    rect.column = `${letters[i % 10]}`;
    rect.line = 9 - Math.floor(i / 10);
    // rect.name = `${letters[i % 10]}:${9 - Math.floor(i / 10)}`;
    grid.push(new PIXI.Point(x + 9, y + 44));
    rect.endFill();
    board_container.addChild(rect);
  };
  letters.forEach(function(item, i, arr) {
    let text = new PIXI.Text(item, {fontSize: 18});
    text.anchor.set(0.5, 0.1);
    text.position = new PIXI.Point(offsetL * 1.5 + i * 20, 0);
    board_container.addChild(text);
  });
  for (let i = 0; i < 10; i++) {
    let text = new PIXI.Text(`${i}`, {fontSize: 18});
    text.anchor.set(0.5, 0.1);
    text.position = new PIXI.Point(offsetL/2, 200 - i * 20);
    board_container.addChild(text);
  };
  board_container.position = new PIXI.Point(0, 35);

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
  ready.click = function(e) { checking() };
  app.stage.addChild(ready);

  function onDragStart(event) {
    this.data = event.data;
    this.alpha = 0.5;
    this.dragging = true;
    this.data.startX = this.x;
    this.data.startY = this.y;
  }

  function onDragEnd() {
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

  function onDragMove(event) {
    if (this.dragging) {
        var newPosition = this.data.getLocalPosition(this.parent);
        this.x = newPosition.x;
        this.y = newPosition.y;
        let point = new PIXI.Point(27.5, 64)
    }
  }

  function hitTest(ship) {
    let grid_arr = grid.filter((value) => {return ship.containsPoint(value)});
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
    let ships = ships_container.children;
    console.log(ships.map((ship) => {
      return grid.filter((value) => {return ship.containsPoint(value)})
                 .map((value) => {
                   let column = letters[Math.floor((value.x - offsetL - 9)/20)];
                   let line = 9 - Math.floor((value.y - 64)/20);
                   return `${column}:${line}`
                 })
    }))
    console.log(offsetL);
  }
}