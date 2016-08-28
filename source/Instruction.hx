package;

using StringTools;

class Instruction {

  public var bottomWheel(get, never): Bool;
  public var increment(get, never): Bool;
  public var decrement(get, never): Bool;
  public var ifZero(get, never): Bool;
  public var ifNonzero(get, never): Bool;
  public var stitch(get, never): Bool;
  public var move(get, never): Bool;
  public var jump(get, never): Bool;
  public var up(get, never): Bool;
  public var down(get, never): Bool;
  public var left(get, never): Bool;
  public var right(get, never): Bool;

  public var wheel(get, never): Int;
  public var wheelDelta(get, never): Int;
  public var colDelta(get, never): Int;
  public var rowDelta(get, never): Int;

  public var holes(default, null): Array<Bool> = [for (i in 0...11) false];

  public function new() {
  }

  private function get_bottomWheel(): Bool { return holes[0]; }
  private function get_increment(): Bool { return holes[1] && !holes[2]; }
  private function get_decrement(): Bool { return holes[2] && !holes[1]; }
  private function get_ifZero(): Bool { return holes[3] && !holes[4]; }
  private function get_ifNonzero(): Bool { return holes[4] && !holes[3]; }
  private function get_stitch(): Bool { return holes[5]; }
  private function get_move(): Bool { return !holes[6] && (up || down || left || right); }
  private function get_jump(): Bool { return holes[6] && (up || down || left || right); }
  private function get_up(): Bool { return holes[7] && !holes[8]; }
  private function get_down(): Bool { return holes[8] && !holes[7]; }
  private function get_left(): Bool { return holes[9] && !holes[10]; }
  private function get_right(): Bool { return holes[10] && !holes[9]; }

  private function get_wheel(): Int { return bottomWheel ? 1 : 0; }
  private function get_wheelDelta(): Int { return increment ? 1 : decrement ?  -1 : 0; }
  private function get_colDelta(): Int { return left ? -1 : right ? 1 : 0; }
  private function get_rowDelta(): Int { return up ? -1 : down ? 1 : 0; }

  public static function isRowEnabled(row: Int, puzzle: Puzzle) {
    switch (row) {
      case 0:
        return puzzle.numWheels > 1;
      case 1:
        return puzzle.hasFeature(INCREMENT);
      case 2:
        return puzzle.hasFeature(DECREMENT);
      case 3:
        return puzzle.hasFeature(TEST_ZERO);
      case 4:
        return puzzle.hasFeature(TEST_NONZERO);
      case 5:
        return true;
      case 6:
        return puzzle.hasFeature(JUMP);
      default:
        return true;
    }
  }

  public static function helpForRow(row: Int): String {
    switch (row) {
      case 0: return "Select the bottom wheel instead of the top one";
      case 1: return "Increment the value of the selected wheel (after " + (Wheel.COUNT - 1) + ", wraps back to 0)";
      case 2: return "Decrement the value of the selected wheel (after 0, wraps back to " + (Wheel.COUNT - 1) + ")";
      case 3: return "Only execute the rest of this instruction if the wheel is 0";
      case 4: return "Only execute the rest of this instruction if the wheel is not 0";
      case 5: return "Paint at the current location in the colour selected for this punch card";
      case 6: return "Jump up/down to another punch card and/or switch read direction to left/right";
      case 7: return "Move the brush up if possible, or jump to the previous punch card (wraps around)";
      case 8: return "Move the brush down if possible, or jump to the next punch card (wraps around)";
      case 9: return "Move the brush left if possible, or start reading instructions to the left";
      case 10: return "Move the brush right if possible, or start reading instructions to the right";
      default: return "";
    }
  }

  public function toString() {
    var text = "";
    var mentionedWheel = false;
    if (increment || decrement) {
      if (increment) {
        text += "increment";
      } else if (decrement) {
        text += "decrement";
      }
      text += " the";
      if (bottomWheel) {
        text += " bottom wheel";
      } else {
        text += " top wheel";
      }
      mentionedWheel = true;
    }
    var conditional = ifZero || ifNonzero;
    if (conditional) {
      if (text != "") {
        text += "; if";
      } else {
        text += "if";
      }
      if (mentionedWheel) {
        text += " it";
      } else if (bottomWheel) {
        text += " the bottom wheel";
      } else {
        text += " the top wheel";
      }
      if (ifZero) {
        text += " is zero";
      } else if (ifNonzero) {
        text += " is not zero";
      }
      text += ": ";
    }

    var textAfterConditional = [];
    if (stitch) {
      textAfterConditional.push("paint this square");
    }
    if (move) {
      var moveText = "move the brush";
      if (left) {
        moveText += " left";
      } else if (right) {
        moveText += " right";
      }
      if ((up || down) && (left || right)) {
        moveText += " and";
      }
      if (up) {
        moveText += " up";
      } else if (down) {
        moveText += " down";
      }
      textAfterConditional.push(moveText);
    }
    if (jump) {
      if (up || down) {
        var jumpText = "jump";
        if (up) {
          jumpText += " one card up";
        } else if (down) {
          jumpText += " one card down";
        }
        textAfterConditional.push(jumpText);
      }
      if (left) {
        textAfterConditional.push("continue to the left");
      } else if (right) {
        textAfterConditional.push("continue to the right");
      }
    }

    for (i in 0...textAfterConditional.length) {
      var first = i == 0;
      var last = i == textAfterConditional.length - 1;
      if (!first) {
        if (last) {
          text += conditional ? " and " : ", then ";
        } else {
          text += ", ";
        }
      }
      text += textAfterConditional[i];
    }

    text = text.trim();
    if (text == "") {
      text = "do nothing";
    }

    text = text.charAt(0).toUpperCase() + text.substring(1);
    return text;
  }
}
