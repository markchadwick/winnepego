package winnepego;

import haxe.io.Bytes;
import haxe.unit.TestCase;

import winnepego.Parser;
import winnepego.Parsers;

enum Geometry {
  Point(x: Int, y: Int);
}

/**
 * The immediate goal of this library is to parse WKT. So, why not just write
 * the bulk of it here.
 */
class TestWKT extends TestCase {


  var point = Parser.apply(
    'POINT(' > Parsers.int > ' ' > Parsers.int > ')',
    function(pre: String, x: Int, sp: String, y: Int, post: String) {
      return Point(x, y);
    }
  );

  function testPristinePoint() {
    var pointWkt = Bytes.ofString("POINT(30 10)");

    switch(point(pointWkt, 0)) {
      case Pass(_, _, Point(x, y)):
        assertEquals(30, x);
        assertEquals(10, y);

      case fail:
        throw "unexpected "+ fail;
    }

  }

}
