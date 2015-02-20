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
