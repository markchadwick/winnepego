package winnepego;

import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.unit.TestCase;

import winnepego.Parser;
import winnepego.Parsers;

typedef Coord = {x: Float, y: Float};

enum Geometry {
}

/**
 * The immediate goal of this library is to parse WKT. So, why not just write
 * the bulk of it here.
 */
class TestWKT extends TestCase {

  /* ------------------------------------------------------------------------
   * Coordinates: 152.56, -23.9
   */

  var coord = Parser.apply(
    Parsers.float > Parsers.whitespace > Parsers.float,
    function(x: Float, _, y: Float) {
      return {x: x, y: y};
    }
  );

  var coordsItem = Parser.apply(
    coord > ~Parsers.whitespace > ',' > ~Parsers.whitespace,
    function(coord: Coord, _, _, _) {
      return coord;
    }
  );

  var coords = Parser.debug(
    ++coordsItem > coord,
    function(head: Array<Coord>, tail: Coord) {
      head.push(tail);
      return head;
    }
  );

  function testPristineCoord() {
    var coord = mustParse(coord, '12.3 45.6');
    assertEquals(12.3, coord.x);
    assertEquals(45.6, coord.y);
  }

  function testCoordsItem() {
    var coord = mustParse(coord, '1	2,');
    assertEquals(1.0, coord.x);
    assertEquals(2.0, coord.y);
  }

  function testCoords() {
    var coords = mustParse(this.coords, '1	2, 4.5 -6');
    assertEquals(2, coords.length);
  }

  /* ------------------------------------------------------------------------
   * Helpers
   */

  function assertParsesTo<A>(exp: A,
                             parser: Bytes -> Int -> LexResult<A>,
                             s: String,
                             ?c: PosInfos) {

    switch(parse(parser, s)) {
      case Pass(_, _, value):
        assertEquals(exp, value);

      case Fail(_, _, error):
        currentTest.success  = false;
        currentTest.error    = error;
        currentTest.posInfos = c;
        throw currentTest;
    }
  }

  function parse<A>(parser: Bytes -> Int -> LexResult<A>, s: String): LexResult<A> {
    return parser(Bytes.ofString(s), 0);
  }

  function mustParse<A>(parser: Bytes -> Int -> LexResult<A>, s: String): A {
    switch(parse(parser, s)) {
      case Pass(_, _, value): return value;
      case fail: throw Parser.printFailure(fail);
    }
  }
}
