package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class PunchCard extends FlxSpriteGroup {

  private static inline var highlightColor = 0x80ffffff;

  public var inputEnabled: Bool = true;

  private var program: Program;
  private var number: Int;
  private var help: HelpText;

  public var paddingX(default, null): Float = 94;
  public var paddingY(default, null): Float = 0;
  private var rows: Int;
  private var cols: Int;

  public var holeWidth(default, null): Int;
  public var holeHeight(default, null): Int;

  private var colHighlight: FlxSprite;
  private var rowHighlight: FlxSprite;

  private var holes: Array<FlxSprite>;

  public function new(program: Program, number: Int, help: HelpText) {
    super();
    this.program = program;
    this.number = number;
    this.help = help;
    this.rows = program.cards[number][0].holes.length;
    this.cols = program.cardSize;

    var holeSprite = new FlxSprite(AssetPaths.hole__png);
    holeWidth = Math.ceil(holeSprite.width);
    holeHeight = Math.ceil(holeSprite.height);

    add(new FlxSprite(AssetPaths.punch_card__png));
    add(new FlxSprite(paddingX + program.cardSize * holeWidth, 0, AssetPaths.punch_card_right__png));

    colHighlight = makeColHighlight();
    colHighlight.y = paddingY;
    add(colHighlight);
    rowHighlight = new ColorSprite(30 + cols * holeWidth, holeHeight, highlightColor);
    rowHighlight.x = paddingX - 30;
    add(rowHighlight);

    holes = [for (i in 0...(rows*cols)) null];
  }

  public function makeColHighlight(): FlxSprite {
    return new ColorSprite(holeWidth, rows * holeHeight, highlightColor);
  }

  override public function update(elapsed: Float) {
    if (!inputEnabled) {
      colHighlight.visible = false;
      rowHighlight.visible = false;
      return;
    }
    var x = FlxG.mouse.x;
    var y = FlxG.mouse.y;
    var col = Math.floor((x - this.x - paddingX) / holeWidth);
    var row = Math.floor((y - this.y - paddingY) / holeHeight);
    if (col >= 0 && col < cols && row >= 0 && row < rows) {
      colHighlight.visible = true;
      rowHighlight.visible = true;
      colHighlight.x = this.x + paddingX + col * holeWidth;
      rowHighlight.y = this.y + paddingY + row * holeHeight;
      if (FlxG.mouse.justPressed) {
        toggleHole(col, row);
      }
      help.set(program.cards[number][col].toString());
    } else {
      colHighlight.visible = false;
      rowHighlight.visible = false;
    }
  }

  private function toggleHole(col: Int, row: Int) {
    var index = row * cols + col;
    if (holes[index] != null) {
      remove(holes[index]);
      holes[index] = null;
      program.cards[number][col].holes[row] = false;
    } else {
      var hole = new FlxSprite(paddingX + col * holeWidth, paddingY + row * holeHeight, AssetPaths.hole__png);
      holes[index] = hole;
      add(hole);
      program.cards[number][col].holes[row] = true;
    }
  }
}
