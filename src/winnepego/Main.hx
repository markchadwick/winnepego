package winnepego;

import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;

import winnepego.Compiler;


class Main {

  macro static function arity(e: Expr, fn: Expr) {
    var id = 0;

    var fn = macro function() {
      $i{"var _res" + ++id} = 0;
      return fn($i{"_res" + id});
    }

    var expr = fn;

    var p = new haxe.macro.Printer('  ');
    trace("parser: "+ p.printExpr(expr));

    return fn;
  }

  public static function main() {
    var f = arity(2, function(a: Int, b: Int) {
      return a + b;
    });
    trace("hiya");
  }

}
