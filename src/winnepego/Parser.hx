package winnepego;

import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;

enum LexResult<T> {
  Pass(buf: Bytes, pos: Int, value: T);
  Fail(buf: Bytes, pos: Int, error: String);
}


class Parser {

  static var p = new haxe.macro.Printer('  ');

  macro public static function apply(e: Expr, fn: Expr) {
    return getParser(e, fn);
  }

  public static function printFailure<A>(res: LexResult<A>): String {
    return switch(res) {
      case Pass(_, _, v): throw "Not a failure: "+ v;
      case Fail(buf, pos, error):
        var idxedErr = '['+ pos +']: ' + error;
        var lines   = [idxedErr, buf.toString()];
        var spacers = [for(i in 0...pos-1) ' '];
        lines.push(spacers.join('') + '^');
        return lines.join('\n');
    }
  }

  macro public static function debug(e: Expr, fn: Expr) {
    var parser  = getParser(e, fn);
    var ruleStr = p.printExpr(e);

    Sys.println("\n---------------------------------------------------");
    Sys.println("Parser:");
    Sys.println(p.printExpr(parser));

    var debugged = macro function(buf: Bytes, pos: Int) {
      Sys.println("\n---------------------------------------------------");
      Sys.println("rule:   "+ $v{ruleStr});
      Sys.println("input:  "+ buf);
      Sys.println("pos:    "+ pos);

      switch(${parser}(buf, pos)) {

        case Pass(buf, pos, value):
          Sys.print("passed with value: '"+ value +"'");
          Pass(buf, pos, value);

        case Fail(buf, pos, error):
          Sys.print("failed: "+ error);
          Fail(buf, pos, error);
      }
    }

    return debugged;
  }

  #if macro

  static function getParser(e: Expr, fn: Expr): Expr {
    var exprs = lexExprs(e);

    var parser = macro function(buf: Bytes, pos: Int) {
      var _bufLen = buf.length;
      return ${compoundExpr(exprs.iterator(), fn, 0)};
    }

    return parser;
  }

  static function compoundExpr(es: Iterator<Expr>, fn: Expr, n: Int): Expr {
    var expr       = es.next();
    var resultName = '_res' + n;

    var passConition = if(es.hasNext()) {
      macro {
        var $resultName = value;
        ${compoundExpr(es, fn, n + 1)};
      }
    } else {

      // Create a call like fn(_res0, _res1, _res2);
      var callExpr = {
        pos:  Context.currentPos(),
        expr: ECall(fn, [
          for (i in 0...n+1)
            {expr: EConst(CIdent('_res' + i)), pos: Context.currentPos()}
        ]),
      }

      macro {
        var $resultName = value;
        return Pass(buf, pos, ${callExpr});
      }
    }

    return macro switch(${expr}) {
      case Fail(buf, pos, error):
        return Fail(buf, pos, error);
      case Pass(buf, pos, value):
        ${passConition}
    }
  }

  static function lexExprs(e: Expr): List<Expr> {
    var lexers = new List<Expr>();

    switch(e.expr) {
      // Match a continuation: ruleA > ruleB
      case EBinop(OpGt, l, r):
        var exprs  = Lambda.concat(lexExprs(l), lexExprs(r));
        lexers = Lambda.concat(lexers, exprs);

      // In the default case, the expression stands by itself.
      case _: lexers.push(lexExpr(e));
    }

    return lexers;
  }

  // NOTE: For now, recursive operations can only deal with simple expressions
  // -- no 'one' > 'two' rules. I'll noodle on it. The types get totally fucking
  // confounding.
  static function lexExpr(e: Expr): Expr {
    return switch(e.expr) {
      // literal value: 'hello'
      case EConst(CString(s)): lit(s);

      // Paren'd value: ('hello')
      case EParenthesis(inner): lexExpr(inner);

      // literal range value: '0'-'9'
      case EBinop(OpSub,
        {expr: EConst(CString(l))},
        {expr: EConst(CString(r))})
        if(l.length == 1 && r.length == 1):

        range(l, r);

      // Or value: 'this' | 'that'
      case EBinop(OpOr, l, r):
        lexOr(lexExpr(l), lexExpr(r));

      // Optional value: ~'hello'
      case EUnop(OpNegBits, false, opt): optional(lexExpr(opt));

      // repeated value > 0: ++'hello'
      case EUnop(OpIncrement, false, rule): repeat(0, lexExpr(rule));

      // repeated value > 1: 'hello'++
      case EUnop(OpIncrement, true, rule): repeat(1, lexExpr(rule));

      // Matches a variable, assumed to be another parser
      case EConst(CIdent(_)) | EField(_): parser(e);

      case other: throw "Parser.lexExpr don't understand "+ other;
    }
  }

  static function lit(s: String): Expr {
    return macro {
      if(pos + $v{s.length} > _bufLen) {
        Fail(buf, pos, "Unexpected EOF");
      } else {
        switch(buf.getString(pos, $v{s.length})) {
          case pass if(pass == $v{s}):
            Pass(buf, pos + $v{s.length}, pass);
          case err:
            var error = "Expected '"+ $v{s} +"' got '"+ err +"'";
            Fail(buf, pos + $v{s.length}, error);
        }
      }
    }
  }

  static function range(l: String, r: String): Expr {
    return macro {
      if(pos + 1 > _bufLen) {
        Fail(buf, pos, "Unexpected EOF");
      } else {
        switch(buf.getString(pos, 1)) {
          case c if (c >= $v{l} && c <= $v{r}): Pass(buf, pos+1, c);
          case f:
            var error = "Expected "+ $v{l} +"-"+ $v{r} +" got '"+ f +"'";
            Fail(buf, pos + 1, error);
        }
      }
    }
  }

  static function lexOr(l: Expr, r: Expr): Expr {
    return macro switch(${l}) {
      case Pass(buf, pos, value): Pass(buf, pos, value);
      case Fail(buf0, pos0, _): ${r};
    }
  }


  static function optional(e: Expr): Expr {
    return macro {
      switch(${e}) {
        case Fail(buf, p0, msg): Pass(buf, pos, null);
        case pass: pass;
      }
    }
  }

  static function repeat(min: Int, e: Expr): Expr {

    return macro {
      var initPos  = pos;
      var results  = [];

      var lastFailPos = pos;
      var lastFail    = null;

      while(lastFail == null) {
        switch(${e}) {
          case Pass(buf0, pos0, value):
            pos = pos0;
            results.push(value);
          case Fail(_, pos, msg):
            lastFailPos = pos;
            lastFail = msg;
        }
      }

      if(results.length > $v{min}) {
        Pass(buf, pos, results);
      } else {
        Fail(buf, lastFailPos, lastFail);
      }
    }
  }

  static function parser(e: Expr): Expr {
    return macro ${e}(buf, pos);
  }


  #end
}
