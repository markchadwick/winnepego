![](http://i.imgur.com/SKw1apG.png)

Winnepego lets your write really fast parsers that work with many different
runtimes. It's able to parse so quickly by making you, the chum, twiddle their
thumbs for dozens of milliseconds at compile time while it transforms your
rules into a parser implementation. Macros. What are you going to do?

Because all the code generation is done at compile time, it means that your
parser will be type safe, even if your target runtime does not support such a
novel idea.

It's written in [Haxe](http://haxe.org). You can target any language Haxe can
target.

## An example
First, we're going to try to match the sign of an integer. We'll say the sign
can either be present at `-` or not present at all. First, we'll write a parser
to match the `-` string alone.

```haxe
  static var minus = Parser.apply('-', function(s: String) {
    return s;
  });

  function testMinus() {
    var input = Bytes.ofString('-');

    switch(minus(input, 0)) {
      case Pass(_, _, value): assertEquals('-', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testNotMinus() {
    var input = Bytes.ofString('+');

    switch(minus(input, 0)) {
      case Pass(_, _, _): throw "should not have passed!";
      case Fail(_, _, error):
        assertEquals("Expected '-' got '+'", error);
    };
  }
```

Cool, so we know we can match a minus character pretty quickly. But the rule is
that if there's a `'-'` char, the rule should give us `'-'`, otherwise, the rule
should give us an empty string, `''`. Right now, it fails to parse, so we need
to fix that by invoking the optional `~` operator. This rule will hand our
function `null` if the value has not been matched, and the matched value if it
has. We need to transform the null value into an empty string.

```haxe
  static var sign = Parser.apply(~minus, function(s: String) {
    return if(s == null) '' else s;
  });

  function testSignMinus() {
    var input = Bytes.ofString('-');

    switch(sign(input, 0)) {
      case Pass(_, _, value): assertEquals('-', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testSignOther() {
    var input = Bytes.ofString('+');

    switch(sign(input, 0)) {
      case Pass(_, _, value): assertEquals('', value);
      case other: throw "unexpected "+ other;
    };
  }

  function testSignEmpty() {
    var input = Bytes.ofString('');

    switch(sign(input, 0)) {
      case Pass(_, _, value): assertEquals('', value);
      case other: throw "unexpected "+ other;
    };
  }
```

Okay. That's pretty robust.

Next we'd want to define a string of digits. Check this jam out. Taking baby
steps each way, we're first going to describe what it looks like when there's a
bunch of contiguous numbers all run up next to each other. Callin' 'em `digits`
here.

In regex terms, this would be `[0-9]+`. Note that in the test case here, there's
trailing input. We just ignore that for now, be we not in the matching test case
that `pos` has been advanced to `5`. You can use this or not. I'm not your mom.

```haxe
  static var digits = Parser.apply(
    ('0'-'9')++,
    function(digits: Array<String>) {
      return digits.join('');
    }
  );

  function testDigits() {
    var input = Bytes.ofString('12345, right?');

    switch(digits(input, 0)) {
      case Pass(_, pos, value):
        assertEquals(5, pos);
        assertEquals('12345', value);
      case other: throw "unexpected "+ other;
    };
  }
```

Christ, anyway. Let's wrap this up. I want to parse integers not write crap all
day. Here we're going to introduce a compound rule. This will say that we need
one rule to pass, and if it does, start executing the next rule. The part to be
mindful here is that it will cause a second argument to grow on your "what it
means" function. Take a seat and watch as we now parse signed integer.

```haxe
  static var int = Parser.apply(
    sign > digits,
    function(sign: String, digits: String) {
      return Std.parseInt(sign + digits);
    }
  );

  function testNegativeInteger() {
    var input = Bytes.ofString('-666');

    switch(int(input, 0)) {
      case Pass(_, _, value): assertEquals(-666, value);
      case other: throw "unexpected "+ other;
    };
  }

  function testPositiveInteger() {
    var input = Bytes.ofString('666');

    switch(int(input, 0)) {
      case Pass(_, _, value): assertEquals(666, value);
      case other: throw "unexpected "+ other;
    };
  }
```

## Rules
Ah, the rules. Here's the thing you need to know. In order to make a parser, you
need to describe how to extract that value from from text, and you need to
describe what that values means. For the first part, we're going to use the
rules listed below which can be smooshed together however you like, and for the
second part (what the string values mean, remember?) we're going to describe
them with functions. Here we go. Piece of cake.


### Primitive Rules

#### Literal `'party'`
Matches the exact string `party`.

```haxe
var party = Parser.apply('party', function(s: String) { return s; });
```

#### Parenthetical `('woah. deep.')`
This just lends the compiler a helping hand to know what you mean in potentially
ambiguous situations.

```haxe
var secretParty = Parser.apply(('party'), function(s: String) { return s; });
```

#### Range `'0'-'9'`
Inclusively matches all character values which are `>=` the value provided on
the left and `<=` value provided on the right. There is no exclusive variation
on this rule.

```haxe
var number = Parser.apply('0'-'9', Std.parseInt);
```

#### Or `'this' | 'that'`
Aw, you got this one. You totally already get it. I really don't even have to
type this. Naw, I'm just screwing around. We're cool.

```haxe
var thisOrThat = Parser.apply('foo' | 'bar', function(matched: String) {
  if(matched == 'foo') return 'this';
  else return 'that';
});
```

### Operational Rules
These rules can take any of the primitive rules above to make new rules.

#### Optional `~'your baby'`
Makes a new rule which may not match anything. If nothing matches, the resultant
will be `null`.

Also, that's a parsing rule joke about [A Stevie Wonder
Song](https://www.youtube.com/watch?v=0ItPnIG6abg). Just making sure you caught
that.

#### Repeated `++'over and '`
Matches zero or more instances of `over and ` and returns an array of those
values. This is just like saying `'over and '*` when writing a regex. Why the
divergence? See [Rule Syntax](#rule-syntax).

#### Repeated `'over and '++`
Matches one or more instances of `over and ` and returns an array of those
values. This is just like saying `'over and '+` when writing a regex. Why the
divergence? See [Rule Syntax](#rule-syntax).

### Compound Rules
These are your real units of composition. Before now, each rule could be reduced
to a single value, but that's no longer the case.

## Rule Syntax
Why in the word would this pile of garbage require `++'6'` instead of `'6'*`?
The Haxe lexer needs to parse it. Or maybe it doesn't, and there's a thing I
don't know. I wrote out the rules in this README here so you didn't have to
think about it too hard. But if that's still too difficult, we're probably not
going to get along anyway. You know? Are we just wasting each other's time?
You're right, though.
