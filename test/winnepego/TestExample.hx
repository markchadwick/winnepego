package winnepego;

import haxe.unit.TestCase;
import haxe.io.Bytes;

import winnepego.Parser;


class TestExample extends TestCase {

  // ---------------------------------------------------------------------------
  // Minus Rule
  // ---------------------------------------------------------------------------

  static var minus = Parser.apply('-', function(s) { return s; });

  function testMinus() {
    var input = Bytes.ofString('-');

    switch(minus(input, 0)) {
      case Pass(_, value): assertEquals('-', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testNotMinus() {
    var input = Bytes.ofString('+');

    switch(minus(input, 0)) {
      case Pass(_, _): throw "should not have passed!";
      case Fail(_, error):
        assertEquals("Expected '-' got '+'", error);
    };
  }

  // ---------------------------------------------------------------------------
  // Sign Rule
  // ---------------------------------------------------------------------------

  static var sign = Parser.apply(
    ~minus,
    function(s) { return if(s == null) '' else s; });

  function testSignMinus() {
    var input = Bytes.ofString('-');

    switch(sign(input, 0)) {
      case Pass(_, value): assertEquals('-', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testSignOther() {
    var input = Bytes.ofString('+');

    switch(sign(input, 0)) {
      case Pass(_, value): assertEquals('', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testSignEmpty() {
    var input = Bytes.ofString('');

    switch(sign(input, 0)) {
      case Pass(_, value): assertEquals('', value);
      case other: throw "unexpected "+ other;
    };
  }

  // ---------------------------------------------------------------------------
  // Digits Rule
  // ---------------------------------------------------------------------------

  static var digits = Parser.apply(
    ('0'-'9')++,
    function(digits) { return digits.join(''); });

  function testDigits() {
    var input = Bytes.ofString('12345, right?');

    switch(digits(input, 0)) {
      case Pass(pos, value):
        assertEquals(5, pos);
        assertEquals('12345', value);
      case other: throw "unexpected "+ other;
    };
  }

  // ---------------------------------------------------------------------------
  // Integer Rule
  // ---------------------------------------------------------------------------

  static var int = Parser.apply(
    sign > digits,
    function(sign: String, digits: String) {
      return Std.parseInt(sign + digits);
    }
  );

  function testNegativeInteger() {
    var input = Bytes.ofString('-666');

    switch(int(input, 0)) {
      case Pass(_, value): assertEquals(-666, value);
      case other: throw "unexpected "+ other;
    };
  }

  function testPositiveInteger() {
    var input = Bytes.ofString('666');

    switch(int(input, 0)) {
      case Pass(_, value): assertEquals(666, value);
      case other: throw "unexpected "+ other;
    };
  }

}
