part of millie.text;

class Parser {
  final List<Token> tokens;
  Token _current;
  int _index = -1;

  Parser(this.tokens);

  bool get done => _index >= tokens.length - 1;

  void throw_(String msg, FileSpan span) {
    throw '$msg\n${span.highlight()}';
  }

  bool next(TokenType type) {
    if (done) return false;
    var peek = tokens[_index + 1];
    if (peek.type != type) return false;
    _current = tokens[++_index];
    return true;
  }

  Token peek() => done ? null : tokens[_index + 1];

  Statement parseStatement() {
    return parseExpressionStatement() ?? parseReturnStatement();
  }

  ExpressionStatement parseExpressionStatement() {
    var expr = parseExpression();
    return expr == null
        ? null
        : new ExpressionStatement(expr, false, expr.span);
  }

  ExpressionStatement parseReturnStatement() {
    if (!next(TokenType.return_)) return null;
    var return_ = _current;
    var expr = parseExpression();
    if (expr == null) throw_('Missing expression.', return_.span);
    return new ExpressionStatement(expr, true, return_.span.expand(expr.span));
  }

  Expression parseExpression() {
    var exprs = new Queue<Expression>(), operators = new Queue<Token>();
    var expr = parsePrefixExpression();
    if (expr == null) return null;
    bool lastWasExpression = true;
    exprs.addFirst(expr);

    while (!done) {
      if (lastWasExpression) {
        if (next(TokenType.lParen)) {
          // TODO: Call
        }

        var op = peek();
        if (!binaryOperators.contains(op.type)) break;
        next(op.type);
        operators.addFirst(op);
        lastWasExpression = false;

        while (operators.length > 1 &&
            binaryOperators.indexOf(operators.first.type) <
                binaryOperators.indexOf(op.type)) {
          var left = exprs.removeFirst(),
              right = exprs.removeFirst(),
              op = operators.removeFirst();
          var out = new Binary(left, right, op, left.span.expand(right.span));
          exprs.addFirst(out);
        }

        operators.addFirst(op);
      } else {
        var expr = parsePrefixExpression();
        if (expr == null)
          throw_('Missing expression', operators.removeFirst().span);
        exprs.addFirst(expr);
        lastWasExpression = true;
      }
    }

    Expression out = exprs.removeFirst();

    while (operators.isNotEmpty) {
      var left = exprs.removeFirst();
      out = new Binary(
          left, out, operators.removeFirst(), left.span.expand(out.span));
    }
  }

  Expression parsePrefixExpression() {
    if (next(TokenType.bitwiseAnd)) {
      var bitwiseAnd = _current;
      var expr = parseExpression();
      if (expr == null) throw_('Missing expression.', bitwiseAnd.span);
      return new Pointer(expr, bitwiseAnd.span.expand(expr.span));
    } else if (next(TokenType.hex)) {
      return new Hex(_current);
    } else if (next(TokenType.id)) {
      return new Identifier(_current);
    } else if (next(TokenType.number)) {
      return new Number(_current);
    } else if (next(TokenType.string)) {
      return new String_(_current);
    } else if (next(TokenType.lParen)) {
      var lParen = _current;
      var expr = parseExpression();
      if (expr = null) throw_('Missing expression.', lParen.span);
      if (!next(TokenType.rParen)) throw_("Missing ')'.", expr.span);
      return new Parentheses(
          expr, lParen.span.expand(expr.span).expand(_current.span));
    } else {
      return null;
    }
  }
}
