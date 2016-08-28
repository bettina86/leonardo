package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class Runner extends FlxGroup {

  public var speed: Float = 1;
  public var done(get, never): Bool;

  private var puzzle: Puzzle;
  private var program: Program;
  private var embroidery: Embroidery;
  private var needle: Needle;
  private var punchCards: Array<PunchCard>;
  private var wheels: Array<Wheel>;
  private var help: HelpText;

  private var state: State = INSTRUCTION_START;
  private var totalTimeInState: Float = 0;
  private var timeSpentInState: Float = 0;
  private var currentCard: Int = 0;
  private var currentInstruction: Int = 0;
  private var stepDirection: Int = 1;
  private var colHighlight: FlxSprite;
  private var text: String = "";

  public function new(puzzle: Puzzle, program: Program, embroidery: Embroidery, needle: Needle, punchCards: Array<PunchCard>, wheels: Array<Wheel>, help: HelpText) {
    super();
    this.puzzle = puzzle;
    this.program = program;
    this.embroidery = embroidery;
    this.needle = needle;
    this.punchCards = punchCards;
    this.wheels = wheels;
    this.help = help;

    colHighlight = punchCards[0].makeColHighlight();
    add(colHighlight);
    setColHighlightPos(0, 0);
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
        switchState(WHEEL_CHANGE_START);
      case WHEEL_CHANGE_START:
        if (instruction.increment || instruction.decrement) {
          var newValue = wheels[instruction.wheel].value + instruction.wheelDelta;
          switchState(WHEEL_CHANGE(newValue), 1.0,
              instruction.increment ? "Incrementing..." : "Decrementing...");
        } else {
          switchState(WHEEL_CHANGE_END);
        }
      case WHEEL_CHANGE(newValue):
        var wheel = wheels[instruction.wheel];
        wheel.moveToValue(FlxMath.lerp(wheel.value, newValue, stateFraction));
        if (stateDone) {
          wheel.value = newValue;
          switchState(WHEEL_CHANGE_END);
        }
      case WHEEL_CHANGE_END:
        switchState(CONDITIONAL_START);
      case CONDITIONAL_START:
        if (instruction.ifZero) {
          switchState(CONDITIONAL(wheels[instruction.wheel].value == 0), 0.5,
              "Checking " + (instruction.bottomWheel ? "bottom" : "top") + " wheel...");
        } else if (instruction.ifNonzero) {
          switchState(CONDITIONAL(wheels[instruction.wheel].value != 0), 0.5,
              "Checking " + (instruction.bottomWheel ? "bottom" : "top") + " wheel...");
        } else {
          switchState(CONDITIONAL_END);
        }
      case CONDITIONAL(value):
        var wheel = wheels[instruction.wheel];
        if (!stateDone) {
          wheel.alpha = 0.2 + 0.8 * (Math.floor(stateFraction * 5) % 2);
        } else {
          wheel.alpha = 1;
          if (value) {
            switchState(CONDITIONAL_END);
          } else {
            // XXX duplicated below
            var nextInstruction = currentInstruction + stepDirection;
            if (nextInstruction < 0 || nextInstruction >= program.cardSize) {
              switchState(DONE, "Done");
            } else {
              switchState(NEXT_INSTRUCTION(currentCard, nextInstruction, stepDirection), 0.5);
            }
          }
        }
      case CONDITIONAL_END:
        switchState(STITCH_START);
      case STITCH_START:
        if (instruction.stitch &&
            needle.col >= 0 && needle.col < embroidery.cols &&
            needle.row >= 0 && needle.row < embroidery.rows) {
          var stitch = embroidery.makeStitch(needle.col, needle.row, program.getThreadColor(currentCard));
          add(stitch);
          switchState(STITCH(stitch), 1.0, "Stitching...");
        } else {
          switchState(STITCH_END);
        }
      case STITCH(sprite):
        var S = 0.5;
        var dx = Math.sin(3 * stateFraction * 2 * Math.PI);
        var dy = -Math.sin(stateFraction * 2 * Math.PI);
        needle.setEmbroideryPos(needle.col + S * dx, needle.row + S * dy);
        sprite.alpha = stateFraction;
        if (stateDone) {
          remove(sprite);
          embroidery.stampStitch(needle.col, needle.row, program.getThreadColor(currentCard));
          switchState(STITCH_END);
        }
      case STITCH_END:
        switchState(MOVE_NEEDLE_START);
      case MOVE_NEEDLE_START:
        if (instruction.move) {
          var nextCol = needle.col + instruction.colDelta;
          if (nextCol < 0) nextCol = 0;
          if (nextCol >= embroidery.cols) nextCol = embroidery.cols - 1;
          var nextRow = needle.row + instruction.rowDelta;
          if (nextRow < 0) nextRow = 0;
          if (nextRow >= embroidery.rows) nextRow = embroidery.rows - 1;
          if (nextCol != needle.col || nextRow != needle.row) {
            switchState(MOVE_NEEDLE(nextCol, nextRow), 1.0, "Moving...");
          } else {
            switchState(MOVE_NEEDLE_END);
          }
        } else {
          switchState(MOVE_NEEDLE_END);
        }
      case MOVE_NEEDLE(toCol, toRow):
        needle.setEmbroideryPos(
            FlxMath.lerp(needle.col, toCol, stateFraction),
            FlxMath.lerp(needle.row, toRow, stateFraction));
        if (stateDone) {
          needle.col = toCol;
          needle.row = toRow;
          switchState(MOVE_NEEDLE_END);
        }
      case MOVE_NEEDLE_END:
        switchState(NEXT_INSTRUCTION_START);
      case NEXT_INSTRUCTION_START:
        var nextStepDirection = stepDirection;
        if (instruction.jump && (instruction.left || instruction.right)) {
          nextStepDirection = instruction.colDelta;
        }
        if (instruction.jump && instruction.up) {
          var nextCard = (currentCard + program.numCards - 1) % program.numCards;
          switchState(NEXT_INSTRUCTION(nextCard, currentInstruction, nextStepDirection), 0.5);
        } else if (instruction.jump && instruction.down) {
          var nextCard = (currentCard + 1) % program.numCards;
          switchState(NEXT_INSTRUCTION(nextCard, currentInstruction, nextStepDirection), 0.5);
        } else {
          // XXX duplicated above
          var nextInstruction = currentInstruction + nextStepDirection;
          if (nextInstruction < 0 || nextInstruction >= program.cardSize) {
            switchState(DONE, "Done");
          } else {
            switchState(NEXT_INSTRUCTION(currentCard, nextInstruction, nextStepDirection), 0.5);
          }
        }
      case NEXT_INSTRUCTION(nextCard, nextInstruction, nextStepDirection):
        setColHighlightPos(
            FlxMath.lerp(currentCard, nextCard, stateFraction),
            FlxMath.lerp(currentInstruction, nextInstruction, stateFraction));
        needle.setColor(
            FlxColor.interpolate(program.getThreadColor(currentCard), program.getThreadColor(nextCard), stateFraction));
        if (stateDone) {
          currentCard = nextCard;
          currentInstruction = nextInstruction;
          stepDirection = nextStepDirection;
          switchState(NEXT_INSTRUCTION_END);
        }
      case NEXT_INSTRUCTION_END:
        if (isSolved()) {
          switchState(DONE, "Complete!");
        } else {
          switchState(INSTRUCTION_START);
        }
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

  public function isSolved(): Bool {
    return embroidery.matches(puzzle);
  }
}

enum State {
  INSTRUCTION_START;
  WHEEL_CHANGE_START;
  WHEEL_CHANGE(newValue: Int);
  WHEEL_CHANGE_END;
  CONDITIONAL_START;
  CONDITIONAL(value: Bool);
  CONDITIONAL_END;
  STITCH_START;
  STITCH(sprite: FlxSprite);
  STITCH_END;
  MOVE_NEEDLE_START;
  MOVE_NEEDLE(toCol: Int, toRow: Int);
  MOVE_NEEDLE_END;
  NEXT_INSTRUCTION_START;
  NEXT_INSTRUCTION(nextCard: Int, nextInstruction: Int, nextStepDirection: Int);
  NEXT_INSTRUCTION_END;
  DONE;
}
