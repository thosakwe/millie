part of millie.text;

class Parser {
  final List<Token> tokens;
  Token _current;
  int _index = -1;

  Parser(this.tokens);

  bool get done => _index >= tokens.length - 1;

  void throw_(String msg, FileSpan span) {
    throw 'Syntax error: $msg\n${span.highlight(color: true)}';
  }

  bool next(TokenType type) {
    if (done) return false;
    var peek = tokens[_index + 1];
    if (peek.type != type) return false;
    _current = tokens[++_index];
    return true;
  }

  Token peek() => done ? null : tokens[_index + 1];

  CompilationUnit parseCompilationUnit() {
    var functions = <Function_>[];
    var function = parseFunction();
    FileSpan span;

    while (function != null) {
      span ??= function.span;
      span = span.expand(function.span);
      functions.add(function);
      function = parseFunction();
    }

    if (!done) {
      throw_('Malformed document. Unexpected or erroneous text starts here.',
          tokens[_index].span);
    }

    return new CompilationUnit(functions, span);
  }

  Function_ parseFunction() =>
      parseExternFunction() ?? parseImplementedFunction();

  ExternFunction parseExternFunction() {
    if (!next(TokenType.externFn)) return null;
    var externFn = _current;
    var signature = parseFunctionSignature();
    if (signature == null) throw_('Missing function signature.', externFn.span);
    return new ExternFunction(signature, externFn.span.expand(signature.span));
  }

  ImplementedFunction parseImplementedFunction() {
    if (!next(TokenType.fn)) return null;
    var fn = _current;
    var signature = parseFunctionSignature();
    if (signature == null) throw_('Missing function signature.', fn.span);
    var body = parseStatement();
    if (body == null) throw_('Missing statement.', signature.span);
    return new ImplementedFunction(
        signature, body, fn.span.expand(signature.span).expand(body.span));
  }

  FunctionSignature parseFunctionSignature() {
    if (!next(TokenType.id)) return null;
    var name = new Identifier(_current);
    if (!next(TokenType.lParen)) throw_("Missing '('.", name.span);
    var lParen = _current,
        lastSpan = lParen.span,
        parameters = <Parameter>[],
        parameter = parseParameter();
    var span = name.span.expand(lParen.span);

    while (parameter != null) {
      span = span.expand(lastSpan = parameter.span);
      parameters.add(parameter);
      if (!next(TokenType.comma)) break;
      span = span.expand(lastSpan = _current.span);
      parameter = parseParameter();
    }

    if (!next(TokenType.rParen)) throw_("Missing ')'.", lastSpan);
    span = span.expand(lastSpan = _current.span);
    if (!next(TokenType.colon)) throw_("Missing ':'.", lastSpan);
    span = span.expand(lastSpan = _current.span);
    var returnType = parseType();
    if (returnType == null) throw_('Missing return type.', lastSpan);
    return new FunctionSignature(
        name, parameters, returnType, span.expand(returnType.span));
  }

  Parameter parseParameter() {
    if (!next(TokenType.id)) return null;
    var name = new Identifier(_current);
    if (!next(TokenType.colon)) throw_("Missing ':'.", name.span);
    var colon = _current;
    var type = parseType();
    if (type == null) throw_('Missing type.', colon.span);
    return new Parameter(name, type);
  }

  ast.Type parseType() {
    if (!next(TokenType.id)) return null;
    ast.Type type = new NamedType(new Identifier(_current));

    while (next(TokenType.times))
      type = new PointerType(type, type.span.expand(_current.span));

    return type;
  }

  Statement parseStatement() {
    return parseExpressionStatement() ??
        parseReturnStatement() ??
        parseBlock() ??
        parseIfStatement() ??
        parseVariableDeclaration();
  }

  VariableDeclaration parseVariableDeclaration() {
    if (!next(TokenType.let)) return null;
    var let = _current;
    if (!next(TokenType.id)) throw_('Missing identifier.', let.span);
    var name = new Identifier(_current);
    if (!next(TokenType.equals)) throw_("Missing '='.", name.span);
    var equals = _current;
    var expression = parseExpression();
    if (expression == null) throw_('Missing expression.', equals.span);
    return new VariableDeclaration(name, expression);
  }

  IfStatement parseIfStatement() {
    if (!next(TokenType.if_)) return null;
    var if_ = _current;
    var condition = parseExpression();
    if (condition == null) throw_('Missing expression', if_.span);
    var body = parseStatement();
    if (body == null) throw_('Missing statement', condition.span);
    var span = if_.span.expand(condition.span).expand(body.span);
    Statement else_;

    if (next(TokenType.else_)) {
      var elseToken = _current;
      else_ = parseStatement();
      if (else_ == null) throw_('Missing statement', elseToken.span);
    }

    return new IfStatement(condition, body, else_, span);
  }

  Block parseBlock() {
    if (!next(TokenType.lCurly)) return null;
    var lCurly = _current, span = lCurly.span;
    var statements = <Statement>[], statement = parseStatement();

    while (!done) {
      if (statement == null) break;
      span = span.expand(statement.span);
      statements.add(statement);
      statement = parseStatement();
    }

    if (!next(TokenType.rCurly)) throw_("Missing '}'", span);
    return new Block(statements, span.expand(_current.span));
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
          var target = exprs.removeFirst();
          var span = _current.span, lastSpan = span;
          var arguments = <Expression>[], argument = parseExpression();

          while (argument != null) {
            span = span.expand(lastSpan = argument.span);
            arguments.add(argument);
            if (!next(TokenType.comma)) break;
            argument = parseExpression();
          }

          if (!next(TokenType.rParen)) throw_("Missing ')'.", lastSpan);
          exprs.addFirst(
              new Call(target, arguments, span.expand(_current.span)));
        } else {
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
        }
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

    return out;
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
