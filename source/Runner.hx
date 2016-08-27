package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class Runner extends FlxGroup {

  public var speed: Float = 1;
  public var done(get, never): Bool;

  private var program: Program;
  private var embroidery: Embroidery;
  private var needle: Needle;
  private var punchCards: Array<PunchCard>;
  private var help: HelpText;

  private var state: State = INSTRUCTION_START;
  private var totalTimeInState: Float = 0;
  private var timeSpentInState: Float = 0;
  private var currentCard: Int = 0;
  private var currentInstruction: Int = 0;
  private var colHighlight: FlxSprite;
  private var text: String = "";

  public function new(program: Program, embroidery: Embroidery, needle: Needle, punchCards: Array<PunchCard>, help: HelpText) {
    super();
    this.program = program;
    this.embroidery = embroidery;
    this.needle = needle;
    this.punchCards = punchCards;
    this.help = help;

    colHighlight = punchCards[0].makeColHighlight();
    add(colHighlight);

    reset();
  }

  public function reset() {
    setColHighlightPos(0, 0);

    needle.col = 0;
    needle.row = 0;
    needle.setEmbroideryPos(needle.col, needle.row);

    embroidery.removeAllStitches();
  }

  private function setColHighlightPos(card: Float, instruction: Float) {
    var top = punchCards[Math.floor(card)];
    var bottom = punchCards[Math.ceil(card)];
    var f = card - Math.floor(card);
    colHighlight.x = FlxMath.lerp(top.x + top.paddingX + instruction * top.holeWidth, bottom.x + bottom.paddingX + instruction * bottom.holeWidth, f);
    colHighlight.y = FlxMath.lerp(top.y + top.paddingY, bottom.y + bottom.paddingY, f);
  }

  private function get_done(): Bool {
    return state == DONE;
  }
  
  override public function update(elapsed: Float) {
    elapsed *= speed;
    while (!done && elapsed > 0) {
      elapsed = tick(elapsed);
    }
    help.set(text);
  }

  private function tick(remainingInFrame: Float): Float {
    timeSpentInState += remainingInFrame;
    var stateDone;
    if (timeSpentInState >= totalTimeInState) {
      remainingInFrame = timeSpentInState - totalTimeInState;
      timeSpentInState = totalTimeInState;
      stateDone = true;
    } else {
      remainingInFrame = 0;
      stateDone = false;
    }
    var stateFraction = totalTimeInState == 0 ? 1.0 : timeSpentInState / totalTimeInState;

    var instruction = program.cards[currentCard][currentInstruction];
    switch (state) {
      case INSTRUCTION_START:
        switchState(MOVE_NEEDLE_START);
      case MOVE_NEEDLE_START:
        if (instruction.up || instruction.down || instruction.left || instruction.right) {
          var fromX = needle.col;
          var fromY = needle.row;
          needle.col += instruction.colDelta;
          needle.row += instruction.rowDelta;
          switchState(MOVE_NEEDLE(fromX, fromY, needle.col, needle.row), 1.0, "Moving...");
        } else {
          switchState(MOVE_NEEDLE_END);
        }
      case MOVE_NEEDLE(fromX, fromY, toX, toY):
        needle.setEmbroideryPos(
            FlxMath.lerp(fromX, toX, stateFraction),
            FlxMath.lerp(fromY, toY, stateFraction));
        if (stateDone) {
          switchState(MOVE_NEEDLE_END);
        }
      case MOVE_NEEDLE_END:
        switchState(STITCH_START);
      case STITCH_START:
        if (instruction.stitch) {
          if (needle.col < 0 || needle.col >= embroidery.cols || needle.row < 0 || needle.row >= embroidery.rows) {
            switchState(DONE, "Error: cannot stitch here");
          } else if (embroidery.stitchAt(needle.col, needle.row) == null) {
            var stitch = embroidery.addStitch(needle.col, needle.row, FlxColor.RED);
            switchState(STITCH(stitch), 1.0, "Stitching...");
          } else {
            switchState(DONE, "Error: already stitched here");
          }
        } else {
          switchState(STITCH_END);
        }
      case STITCH(sprite):
        var S = 0.4;
        if (stateFraction < 0.125) {
          var f = stateFraction * 8;
          needle.setEmbroideryPos(
              FlxMath.lerp(needle.col, needle.col - S, f),
              FlxMath.lerp(needle.row, needle.row - S, f));
        } else if (stateFraction < 0.375) {
          var f = (stateFraction - 0.125) * 4;
          needle.setEmbroideryPos(
              FlxMath.lerp(needle.col - S, needle.col + S, f),
              FlxMath.lerp(needle.row - S, needle.row + S, f));
        } else if (stateFraction < 0.625) {
          var f = (stateFraction - 0.375) * 4;
          needle.setEmbroideryPos(
              needle.col + S,
              FlxMath.lerp(needle.row + S, needle.row - S, f));
        } else if (stateFraction < 0.875) {
          var f = (stateFraction - 0.625) * 4;
          needle.setEmbroideryPos(
              FlxMath.lerp(needle.col + S, needle.col - S, f), 
              FlxMath.lerp(needle.row - S, needle.row + S, f));
        } else {
          var f = (stateFraction - 0.875) * 8;
          needle.setEmbroideryPos(
              FlxMath.lerp(needle.col - S, needle.col, f),
              FlxMath.lerp(needle.row + S, needle.row, f));
        }
        sprite.alpha = stateFraction;
        if (stateDone) {
          switchState(STITCH_END);
        }
      case STITCH_END:
        switchState(NEXT_INSTRUCTION_START);
      case NEXT_INSTRUCTION_START:
        var prevCard = currentCard;
        var prevInstruction = currentInstruction;
        currentInstruction++;
        if (currentInstruction >= program.cardSize) {
          switchState(DONE, "Done");
        } else {
          switchState(NEXT_INSTRUCTION(prevCard, prevInstruction), 0.5);
        }
      case NEXT_INSTRUCTION(prevCard, prevInstruction):
        setColHighlightPos(
            FlxMath.lerp(prevCard, currentCard, stateFraction),
            FlxMath.lerp(prevInstruction, currentInstruction, stateFraction));
        if (stateDone) {
          switchState(NEXT_INSTRUCTION_END);
        }
      case NEXT_INSTRUCTION_END:
        switchState(INSTRUCTION_START);
      case DONE:
    }

    return remainingInFrame;
  }

  private function switchState(nextState: State, duration: Float = 0.0, text: String = "") {
    this.state = nextState;
    this.totalTimeInState = duration;
    this.timeSpentInState = 0;
    this.text = text;
  }

  private function stateFraction(): Float {
    return totalTimeInState == 0 ? 1 : timeSpentInState / totalTimeInState;
  }
}

enum State {
  INSTRUCTION_START;
  MOVE_NEEDLE_START;
  MOVE_NEEDLE(fromX: Float, fromY: Float, toX: Float, toY: Float);
  MOVE_NEEDLE_END;
  STITCH_START;
  STITCH(sprite: FlxSprite);
  STITCH_END;
  NEXT_INSTRUCTION_START;
  NEXT_INSTRUCTION(prevCard: Int, prevInstruction: Int);
  NEXT_INSTRUCTION_END;
  DONE;
}
