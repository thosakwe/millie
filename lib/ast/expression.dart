part of millie.ast;

abstract class Expression extends AstNode {
  final FileSpan span;

  Expression(this.span);

  Expression get innermost => this;

  bool get isConstant => false;

  dynamic get constantValue => throw new UnsupportedError('Not a constant');
}

class Pointer extends Expression {
  final Expression expression;

  Pointer(this.expression, FileSpan span) : super(span);
}

class Binary extends Expression {
  static const List<TokenType> constantOperators = const [
    TokenType.times,
    TokenType.div,
    TokenType.mod,
    TokenType.plus
  ];

  final Expression left, right;
  final Token op;

  Binary(this.left, this.right, this.op, FileSpan span) : super(span);

  @override
  bool get isConstant =>
      left.isConstant &&
      right.isConstant &&
      constantOperators.contains(op.type);

  @override
  get constantValue {
    switch (op.type) {
      case TokenType.times:
        return left.constantValue * right.constantValue;
      case TokenType.div:
        return left.constantValue / right.constantValue;
      case TokenType.mod:
        return left.constantValue % right.constantValue;
      case TokenType.plus:
        return left.constantValue + right.constantValue;
      case TokenType.minus:
        return left.constantValue - right.constantValue;
      default:
        throw "Not a constant operator.\n${op.span.highlight()}";
    }
  }
}

class Parentheses extends Expression {
  final Expression innermost;

  Parentheses(this.innermost, FileSpan span) : super(span);

  @override
  bool get isConstant => innermost.isConstant;

  @override
  get constantValue => innermost.constantValue;
}

class Identifier extends Expression {
  final Token token;

  Identifier(this.token) : super(token.span);

  String get name => token.span.text;
}

class Number extends Expression {
  final Token token;

  Number(this.token) : super(token.span);

  @override
  bool get isConstant => true;

  @override
  get constantValue => num.parse(token.span.text);
}

class String_ extends Expression {
  final Token token;

  String_(this.token) : super(token.span);

  @override
  bool get isConstant => true;

  @override
  get constantValue => token.span.text.substring(1, token.span.length - 1);
}

class Hex extends Expression {
  final Token token;

  Hex(this.token) : super(token.span);

  @override
  bool get isConstant => true;

  @override
  get constantValue => int.parse(token.match[1], radix: 16);
}
