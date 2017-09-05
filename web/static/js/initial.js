export function run(app) {
  var grid = [];
  // board container
  var board_container = new PIXI.Container();
  app.stage.addChild(board_container)
  var offsetL = (app._options.width/2 - 200)/2;
  let letters = ['a','b','c','d','e','f','g','h','i','j'];
  for (let i = 0; i < 100; i++) {
    let graphics = new PIXI.Graphics();
    graphics.lineStyle(0, 0xFFFFFF, 1);
    graphics.beginFill(0x0022b4, 0.25);
    let x = offsetL + (i % 10) * 20;
    let y = 20 + Math.floor(i / 10) * 20;
    graphics.drawRect(x, y, 18, 18);
    graphics.interactive = true;
    graphics.name = `${letters[i % 10]}:${9 - Math.floor(i / 10)}`
    grid.push(new PIXI.Point(x + 9, y + 44));
    graphics.endFill();
    board_container.addChild(graphics);
  };
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
    graphics.rightclick = function(e) {
      if(parseInt(graphics.name) == 1) { return }
      if(graphics.rotation == 0) {
        graphics.rotation = Math.PI/2
      } else {
        graphics.rotation = 0
      }
    }
    graphics
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
    if(arr.length == parseInt(this.name)) {
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

  function hitTest(graphics) {
    let grid_arr = grid.filter((value) => {return graphics.containsPoint(value)});
    if(grid_arr.length == 0) {return grid_arr}
    let arr = ships_container.children.reduce((prev, curr, index, array) => {
      if(prev.length == 0) {return prev}
      if(graphics.name == curr.name) {return prev}
      let value = grid_arr.filter((value) => {return curr.containsPoint(value)});
      if(value.length == 0) { return prev }
      return []
    }, grid_arr)
    return arr
  }
}