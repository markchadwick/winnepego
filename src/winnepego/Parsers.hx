package winnepego;

import haxe.io.Bytes;

import winnepego.Parser;

/**
    Commonly used utility parsers. All values are static, so a class can use
    these parses at the top level by including the following in their code.

      using Parsers;
**/
class Parsers {
  private static var noop = function(s) { return s; }

  static public function repSep<A, B>(
        p0: Bytes -> Int -> ParseResult<A>,
        p1: Bytes -> Int -> ParseResult<B>):
      Bytes -> Int -> ParseResult<Array<A>> {

    return function(buf: Bytes, pos: Int) {
      var results = new Array<A>();
      var pos0    = pos;

      while(true) {

        // Match prefix. If it matches, advance, otherwise return.
        switch(p0(buf, pos0)) {
          case Pass(pos1, result):
            pos0 = pos1;
            results.push(result);
          case Fail(pos1, error):
            return Pass(pos0, results);
        }

        // Match the seperator. Keep going if it matches, return results when it
        // fails
        switch(p1(buf, pos0)) {
          case Pass(pos1, _):
            pos0 = pos1;
          case Fail(pos1, error):
            return Pass(pos0, results);
        }
      }

      return Pass(pos0, results);
    }
  }

  static public var wsVal = Parser.apply((' ' | '\t' | '\r' | '\n'), noop);

  static public var whitespace = Parser.apply(
    wsVal++,
    function(chars: Array<String>) { return chars.join(''); }
  );

  static public var sign = Parser.apply(~'-', function(sign: String) {
    return if(sign == null) '' else sign;
  });

  static public var digits = Parser.apply(
    ('0'-'9')++,
    function(vs: Array<String>) { return vs.join(''); }
  );

  static public var signedDigits = Parser.apply(
    sign > digits,
    function(sign: String, digits: String) {
      return sign + digits;
    }
  );

  static public var int = Parser.apply(signedDigits, Std.parseInt);

  private static var floatTail = Parser.apply(
    '.' > digits,
    function(dot: String, digits: String) {
      return '.' + digits;
    }
  );

  static public var float = Parser.apply(
    signedDigits > ~floatTail,
    function(digits: String, decimal: String) {
      if(decimal == null) decimal = '.0';
      return Std.parseFloat(digits + decimal);
    }
  );

}
