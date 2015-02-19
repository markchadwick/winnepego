package winnepego;

import haxe.io.Bytes;

import winnepego.Parser;

/**
    Commonly used utility parsers. All values are static, so a class can use
    these parses at the top level by including the following in their code.

      using Parsers;
**/
class Parsers {

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

  static public var float = Parser.apply(
    signedDigits > '.' > digits,
    function(sign: String, _: String, digits: String) {
      return Std.parseFloat(sign +'.'+ digits);
    }
  );

}
