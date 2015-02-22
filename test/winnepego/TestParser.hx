package winnepego;

import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.unit.TestCase;

import winnepego.Parser;


class TestParser extends TestCase {

  function noop<A>(v: A) { return v; };

  function testShortLiteralPass() {
    var parser = Parser.apply('3', noop);
    var result = parser(Bytes.ofString('345'), 0);

    switch(result) {
      case Pass(pos, res):
        assertEquals(1, pos);
        assertEquals('3', res);

      case _: fail("unexpected failure");
    }
  }

  function testShortLiteralFail() {
    var parser = Parser.apply('3', noop);
    var result = parser(Bytes.ofString('123'), 0);

    switch(result) {
      case Fail(pos, error):
        assertEquals(1, pos);
        assertEquals("Expected '3' got '1'", error);
      case Pass(_, value):
        fail("should have failed, got "+ value);
    }
  }

  function testShortLiteralOverrun() {
    var parser = Parser.apply('party', noop);
    var result = parser(Bytes.ofString('part'), 0);

    switch(result) {
      case Pass(_, res): fail("unexpected res: "+ res);
      case Fail(pos, msg):
        assertEquals(0, pos);
        assertEquals('Unexpected EOF', msg);
    }
  }

  function testLiteralTransform() {
    var parser = Parser.apply('3', function(s: String) {
      return s + s;
    });
    var result = parser(Bytes.ofString('321'), 0);

    switch(result) {
      case Pass(pos, res):
        // The cursor should only have advanced one position
        assertEquals(1, pos);
        assertEquals('33', res);

      case _: fail("unexpected failure");
    }
  }

  function testParse666() {
    var parser = Parser.apply('666', Std.parseInt);
    var result = parser(Bytes.ofString('666'), 0);

    switch(result) {
      case Pass(_, res): assertEquals(666, res);
      case _: fail("unexpected failure");
    }
  }

  function testConsumeOtherParser() {
    var p0 = Parser.apply('hello', noop);
    var p1 = Parser.apply(p0, noop);

    var result = p1(Bytes.ofString('hello'), 0);

    switch(result) {
      case Pass(_, res): assertEquals('hello', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testConsumeField() {
    var p1 = Parser.apply(Parsers.int, function(i: Int) {
      return i + 198;
    });

    var result = p1(Bytes.ofString('123'), 0);

    switch(result) {
      case Pass(_, res): assertEquals(321, res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testThenPass() {
    var parser = Parser.apply('a' > 'b', function(a: String, b: String) {
      return 'a:'+ a +', b:'+ b;
    });
    var result = parser(Bytes.ofString('abc'), 0);

    switch(result) {
      case Pass(_, res): assertEquals('a:a, b:b', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testThenFailFirst() {
    var parser = Parser.apply('a' > 'b', function(a: String, b: String) {
      return 'a:'+ a +', b:'+ b;
    });
    var result = parser(Bytes.ofString('bbc'), 0);

    switch(result) {
      case Pass(_, res): fail("should not have passed, got: "+ res);
      case Fail(_, msg): assertEquals("Expected 'a' got 'b'", msg);
    }
  }

  function testThenFailSecond() {
    var parser = Parser.apply('a' > 'b', function(a: String, b: String) {
      return 'a:'+ a +', b:'+ b;
    });
    var result = parser(Bytes.ofString('aac'), 0);

    switch(result) {
      case Pass(_, res): fail("should not have passed, got: "+ res);
      case Fail(_, msg): assertEquals("Expected 'b' got 'a'", msg);
    }
  }

  function testAny() {
    var parser = Parser.apply(++'6', function(c: Array<String>) {
      return c.join(',');
    });

    var result = parser(Bytes.ofString('6665'), 0);

    switch(result) {
      case Pass(_, res): assertEquals('6,6,6', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testAtLeastOne() {
    var parser = Parser.apply('6'++, function(c: Array<String>) {
      return c.join(',');
    });

    var result = parser(Bytes.ofString('6665'), 0);

    switch(result) {
      case Pass(_, res): assertEquals('6,6,6', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testAtLeastOneFails() {
    var parser = Parser.apply('6'++, function(c: Array<String>) {
      return c.join(',');
    });

    var result = parser(Bytes.ofString('5'), 0);

    switch(result) {
      case Pass(_, res): throw "should not have passed";
      case Fail(_, msg):
        assertEquals("Expected '6' got '5'", msg);
    }
  }

  function testRangePass() {
    var parser = Parser.apply('0'-'9', Std.parseInt);
    var result = parser(Bytes.ofString('5'), 0);

    switch(result) {
      case Pass(_, res): assertEquals(5, res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testRangeFail() {
    var parser = Parser.apply('0'-'9', Std.parseInt);
    var result = parser(Bytes.ofString('kittens!'), 0);

    switch(result) {
      case Pass(_, res): fail("Expected failure, got " + res);
      case Fail(_, msg): assertEquals("Expected 0-9 got 'k'", msg);
    }
  }

  function testRepeatedRange() {
    var parser = Parser.apply(('0'-'9')++, function(vs: Array<String>) {
      return Std.parseInt(vs.join(''));
    });
    var result = parser(Bytes.ofString('123xzz'), 0);

    switch(result) {
      case Pass(_, res): assertEquals(123, res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testRepeateOverflow() {
    var parser = Parser.apply(('0'-'9')++, function(vs: Array<String>) {
      return Std.parseInt(vs.join(''));
    });

    // The loop by default will continue to try to read past the last character
    var result = parser(Bytes.ofString('123'), 0);
    switch(result) {
      case Pass(_, res): assertEquals(123, res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testOptionalPass() {
    var parser = Parser.apply(~'pants', noop);
    var result = parser(Bytes.ofString('pants on!'), 0);

    switch(result) {
      case Pass(pos, res):
        assertEquals(5, pos);
        assertEquals('pants', res);

      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testOptionalFail() {
    var parser = Parser.apply(~'pants', noop);
    var result = parser(Bytes.ofString('no pants!'), 0);

    switch(result) {
      case Pass(pos, res):
        assertEquals(0, pos);
        assertEquals(null, res);

      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testCombinedParsers() {
    var p = Parser.apply(
      'more than ' > Parsers.int,
      function(s: String, v: Int) {
        return v + 1;
      }
    );

    switch(p(Bytes.ofString('more than 12'), 0)) {
      case Pass(_, res): assertEquals(13, res);
      case other: throw "unexpected: "+ other;
    }
  }

  function testOr() {
    var p = Parser.apply('a' | 'b', noop);

    switch(p(Bytes.ofString('a'), 0)) {
      case Pass(_, res): assertEquals('a', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }

    switch(p(Bytes.ofString('b'), 0)) {
      case Pass(_, res): assertEquals('b', res);
      case Fail(_, msg): fail("unexpected failure: "+ msg);
    }
  }

  function testOrFail() {
    var p = Parser.apply('a' | 'b', noop);

    switch(p(Bytes.ofString('c'), 0)) {
      case Pass(_, res): throw "passed with "+ res;
      case Fail(_, msg):
        assertEquals("Expected 'b' got 'c'", msg);
    }
  }

  private function fail(msg: String, ?c: PosInfos) {
    currentTest.success  = false;
    currentTest.error    = msg;
    currentTest.posInfos = c;
    throw currentTest;
  }
}
