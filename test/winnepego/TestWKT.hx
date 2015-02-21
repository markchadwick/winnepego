package winnepego;

import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.unit.TestCase;

import winnepego.Parser;
import winnepego.Parsers;

typedef Coord = {x: Float, y: Float};

enum Geometry {
  Point(c: Coord);
  LineString(cs: Array<Coord>);
}

/**
 * The immediate goal of this library is to parse WKT. So, why not just write
 * the bulk of it here.
 */
class TestWKT extends TestCase {

  /* ------------------------------------------------------------------------
   * Coordinates: 152.56 -23.9
   */

  static var coord = Parser.apply(
    Parsers.float > Parsers.whitespace > Parsers.float,
    function(x: Float, _, y: Float) {
      return {x: x, y: y};
    }
  );

  static var sep = Parser.apply(',' > Parsers.whitespace, function(_, _) {
    return ',';
  });

  static var coords = Parsers.repSep(coord, sep);

  static var lParen = Parser.apply(
    ~Parsers.whitespace > '(' > ~Parsers.whitespace,
    function(_, p: String, _) { return p; });

  static var rParen = Parser.apply(
    ~Parsers.whitespace > ')' > ~Parsers.whitespace,
    function(_, p: String, _) { return p; });

  // POINT ( x y )
  static var point = Parser.apply(
    'POINT' > lParen > coord > rParen,
    function(_, _, c: Coord, _) { return Point(c); });

  // LINESTRING(x y, x y)
  static var linestring = Parser.apply(
    'LINESTRING' > lParen > coords > rParen,
    function(_, _, cs: Array<Coord>, _) {
      return LineString(cs);
    }
  );

  static var geom = Parser.apply(
    point | linestring,
    function(e: Geometry) { return e; });

  function parseIt(s: String) {
  }

  function testPristineCoord() {
    var coord = mustParse(coord, '12.3 45.6');
    assertEquals(12.3, coord.x);
    assertEquals(45.6, coord.y);
  }

  function testCoords() {
    var coords = mustParse(coords, '1 2, 4.5 -6');
    assertEquals(2, coords.length);
  }

  function testPoint() {
    switch(mustParse(point, 'POINT (30 10)')) {
      case Point(c):
        assertEquals(30.0, c.x);
        assertEquals(10.0, c.y);
      case _: // fails
    }
  }

  function testLinestring() {
    switch(mustParse(linestring, 'LINESTRING (30 10, 10 30, 40 40)')) {
      case LineString(cs):
        assertEquals(3, cs.length);

        assertEquals(30.0, cs[0].x);
        assertEquals(10.0, cs[0].y);

        assertEquals(10.0, cs[1].x);
        assertEquals(30.0, cs[1].y);

        assertEquals(40.0, cs[2].x);
        assertEquals(40.0, cs[2].y);

      case geom: throw "Incorrect geometry! "+ geom;
    }
  }

  function testGeomPoint() {
    switch(mustParse(geom, 'POINT (30 10)')) {
      case Point(c):
        assertEquals(30.0, c.x);
        assertEquals(10.0, c.y);
      case geom: throw "Incorrect geometry! "+ geom;
    }
  }

  function testGeomLinestring() {
    switch(mustParse(geom, 'LINESTRING (30 10, 10 30, 40 40)')) {
      case LineString(cs):
        assertEquals(3, cs.length);
      case geom: throw "Incorrect geometry! "+ geom;
    }
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
