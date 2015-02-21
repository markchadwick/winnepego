package winnepego;

import haxe.unit.TestRunner;

import winnepego.Parser;


class Test {

  static function main() {
    var runner = new TestRunner();

    runner.add(new TestExample());
    runner.add(new TestParser());
    runner.add(new TestParsers());
    runner.add(new TestWKT());
    runner.add(new TestWKT2());

    runner.run();
  }
}
