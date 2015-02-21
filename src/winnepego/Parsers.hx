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
        p0: Bytes -> Int -> LexResult<A>,
        p1: Bytes -> Int -> LexResult<B>):
      Bytes -> Int -> LexResult<Array<A>> {

    return function(buf: Bytes, pos: Int) {
      var results = new Array<A>();
      var buf0    = buf;
      var pos0    = pos;

      while(true) {

        // Match prefix. If it matches, advance, otherwise return.
        switch(p0(buf0, pos0)) {
          case Pass(buf1, pos1, result):
            buf0 = buf1;
            pos0 = pos1;
            results.push(result);
          case Fail(buf1, pos1, error):
            return Fail(buf1, pos1, error);
        }

        // Match the seperator. Keep going if it matches, return results when it
        // fails
        switch(p1(buf0, pos0)) {
          case Pass(buf1, pos1, _):
            buf0 = buf1;
            pos0 = pos1;
          case Fail(buf1, pos1, error):
            return Pass(buf1, pos0, results);
        }
      }

      return Pass(buf0, pos0, results);
    }
  }

  static public var wsVal = Parser.apply((' ' | '\t' | '\r' | '\n'), noop);

  static public var whitespace = Parser.apply(
    ++wsVal,
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
