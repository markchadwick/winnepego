package winnepego;

import haxe.io.Bytes;
import haxe.unit.TestCase;

import winnepego.Parser;


typedef TPoint = {x: Float, y: Float};


// Spec from Section 7 of http://www.opengeospatial.org/standards/sfa
class TestWKT2 extends TestCase {

  // --------------------------------------------------------------------------
  // Primative Elements

  static var x = Parsers.float;
  static var y = Parsers.float;

  static var quotedName = Parser.apply(
    '"' > name > '"',
    function(_, s: String, _) { return s; });

  static var name = letters;

  static var letters = Parser.apply(++letter, function(cs: Array<String>) {
    return cs.join('');
  });

  static var letter = Parser.apply(
    simpleLatinLetter,
    Parsers.noop);

  static var simpleLatinLetter = Parser.apply(
    'a'-'z' | 'A'-'Z', Parsers.noop);

  static var emptySet = Parser.apply('EMPTY', Parsers.noop);

  static var leftParen  = Parser.apply('(', Parsers.noop);
  static var rightParen = Parser.apply(')', Parsers.noop);

  // --------------------------------------------------------------------------
  // Point

  static var point = Parser.apply(
    x > Parsers.wsVal++ > y,
    function(x: Float, _, y: Float) {
      return {x: x, y: y};
    }
  );

  static var pointText = Parser.apply(
    leftParen > point > rightParen,
    function(_, tPoint: TPoint, _) {
      return tPoint;
    }
  );

  static var pointTaggedText = Parser.apply(
    'POINT' > pointText,
    function(_, tPoint: TPoint) {
      return tPoint;
    }
  );
}
