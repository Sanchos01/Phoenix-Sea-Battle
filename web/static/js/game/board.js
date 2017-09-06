export let grid = [];
export let letters = ['a','b','c','d','e','f','g','h','i','j'];

export function create_board(app, offsetL, offsetT) {
  var board_container = new PIXI.Container();
  app.stage.addChild(board_container)
  for (let i = 0; i < 100; i++) {
    let rect = new PIXI.Graphics();
    rect.lineStyle(0, 0xFFFFFF, 1);
    rect.beginFill(0x0022b4, 0.25);
    let x = 18 + (i % 10) * 20;
    let y = 20 + Math.floor(i / 10) * 20;
    rect.drawRect(x, y, 18, 18);
    rect.interactive = true;
    rect.column = `${letters[i % 10]}`;
    rect.line = Math.floor(i / 10);
    // rect.name = `${letters[i % 10]}:${9 - Math.floor(i / 10)}`;
    grid.push(new PIXI.Point(x + 9, y + 44));
    rect.endFill();
    board_container.addChild(rect);
  };
  letters.forEach(function(item, i, arr) {
    let text = new PIXI.Text(item, {fontSize: 18});
    text.anchor.set(0.5, 0.1);
    text.position = new PIXI.Point(27 + i * 20, 0);
    board_container.addChild(text);
  });
  for (let i = 0; i < 10; i++) {
    let text = new PIXI.Text(`${i}`, {fontSize: 18});
    text.anchor.set(0.5, 0.1);
    text.position = new PIXI.Point(9, 20 + i * 20);
    board_container.addChild(text);
  };
  board_container.position = new PIXI.Point(0, offsetT);
}