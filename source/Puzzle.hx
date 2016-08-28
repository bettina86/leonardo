package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class Puzzle {

  public var numCards(default, null): Int;
  public var cardSize(default, null): Int;
  public var patternAsset(default, null): Null<String>;
  public var cols(default, null): Int;
  public var rows(default, null): Int;
  public var pattern(default, null): Null<Array<Array<FlxColor>>>;
  public var colors(default, null): Array<FlxColor>;

  public function new(numCards: Int, cardSize: Int, patternAsset: Null<String>) {
    this.numCards = numCards;
    this.cardSize = cardSize;
    this.patternAsset = patternAsset;
    if (patternAsset != null) {
      var bitmap = FlxG.bitmap.add(patternAsset).bitmap;
      cols = bitmap.width;
      rows = bitmap.height;
      pattern = [for (y in 0...bitmap.height) [for (x in 0...bitmap.width) bitmap.getPixel32(x, y)]];
      colors = extractColors(bitmap);
    } else {
      cols = 13;
      rows = 13;
      pattern = null;
      colors = [0xffffffff, 0xff111111, 0xffFF4136, 0xffFFDC00, 0xff0074D9];
    }
  }

  public function colorAt(col: Int, row: Int) {
    return pattern[row][col];
  }

  private function extractColors(bitmap: BitmapData): Array<FlxColor> {
    var colors = [];
    for (y in 0...bitmap.height) {
      for (x in 0...bitmap.width) {
        var color = bitmap.getPixel32(x, y);
        if (colors.indexOf(color) == -1) {
          colors.push(color);
        }
      }
    }
    return colors;
  }

  public function createPatternSprite(): FlxSprite {
    var pattern = new FlxSprite();
    var S = 24;
    pattern.makeGraphic(S * cols + 1, S * rows + 1, FlxColor.TRANSPARENT, true);
    var squareOutline = new FlxSprite(AssetPaths.pattern_square_outline__png);
    for (row in 0...rows) {
      for (col in 0...cols) {
        pattern.stamp(squareOutline, S * col, S * row);
      }
    }
    var square = new FlxSprite(AssetPaths.pattern_square__png);
    for (row in 0...rows) {
      for (col in 0...cols) {
        square.color = colorAt(col, row);
        pattern.stamp(square, S * col, S * row);
      }
    }
    return pattern;
  }
}
