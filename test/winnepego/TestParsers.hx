package winnepego;

import haxe.unit.TestCase;
import haxe.io.Bytes;

import winnepego.Parser;


class TestParsers extends TestCase {

  function testBasicWhitespace() {
    var result = Parsers.whitespace(Bytes.ofString(' \t\n'), 0);
    assertPass(' \t\n', result);
  }

  function testSignNegative() {
    var result = Parsers.sign(Bytes.ofString('-'), 0);
    assertPass('-', result);
  }

  function testNoSign() {
    var result = Parsers.sign(Bytes.ofString('huh?'), 0);
    assertPass('', result);
  }

  function testDigits() {
    var result = Parsers.digits(Bytes.ofString('666'), 0);
    assertPass('666', result);
  }

  function testDigit() {
    var result = Parsers.digits(Bytes.ofString('0'), 0);
    assertPass('0', result);
  }

  function testSignedDigits() {
    var result = Parsers.signedDigits(Bytes.ofString('-666'), 0);
    assertPass('-666', result);
  }

  function testUnsignedInteger() {
    var result = Parsers.int(Bytes.ofString('123'), 0);
    assertPass(123, result);
  }

  function testNegativeInteger() {
    var result = Parsers.int(Bytes.ofString('-123'), 0);
    assertPass(-123, result);
  }

  function testUnsignedFloat() {
    var result = Parsers.float(Bytes.ofString('3.14159'), 0);
    assertPass(3.14159, result);
  }

  function testNoDecimalFloat() {
    var result = Parsers.float(Bytes.ofString('3.'), 0);
    assertPass(3.0, result);
  }

  function testIntegralFloat() {
    var result = Parsers.float(Bytes.ofString('3'), 0);
    assertPass(3.0, result);
  }

  function testOneRepeated() {
    var parser = Parsers.repSep(
      Parser.apply('name', Parsers.noop),
      Parser.apply(', ', Parsers.noop));

    var result = parser(Bytes.ofString('name'), 0);
    switch(result) {
      case Pass(_, names):
        assertEquals(1, names.length);
        assertEquals('name', names[0]);
      case Fail(_, msg):
        throw msg;
    }
  }

  function testThreeRepeated() {
    var parser = Parsers.repSep(
      Parser.apply('name', Parsers.noop),
      Parser.apply(', ', Parsers.noop));

    var input  = Bytes.ofString('name, name, name, fame');
    var result = parser(input, 0);
    switch(result) {
      case Pass(_, names):
        assertEquals(3, names.length);
        assertEquals('name', names[0]);
        assertEquals('name', names[1]);
        assertEquals('name', names[2]);
      case Fail(_, msg):
        throw msg;
    }
  }

  function testZeroRepeated() {
    var parser = Parsers.repSep(
      Parser.apply('name', Parsers.noop),
      Parser.apply(', ', Parsers.noop));

    var result = parser(Bytes.ofString(''), 0);
    switch(result) {
      case Pass(_, names):
        assertEquals(0, names.length);
      case Fail(_, msg):
        throw msg;
    }
  }

  function assertPass<A>(v: A, res: ParseResult<A>) {
    switch(res) {
      case Pass(_, value): assertEquals(value, v);
      case Fail(_, error):
        throw error;
    }
  }
}
