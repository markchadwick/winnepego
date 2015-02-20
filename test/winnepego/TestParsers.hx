package winnepego;

import haxe.unit.TestCase;
import haxe.io.Bytes;

import winnepego.Parser;


class TestParsers extends TestCase {

  function testBasicWhitespace() {
    var result = Parsers.whitespace(Bytes.ofString(' \t\n'), 0);
    assertPass(' \t\n', result);
  }

  function testNoWhitespace() {
    var result = Parsers.whitespace(Bytes.ofString(''), 0);
    assertPass('', result);
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

  function assertPass<A>(v: A, res: LexResult<A>) {
    switch(res) {
      case Pass(_, _, value): assertEquals(value, v);
      case Fail(buf, pos, error):
        throw Parser.printFailure(Fail(buf, pos, error));
    }
  }
}
