part of millie.ast;

abstract class Statement extends AstNode {}

class Block extends Statement {
  final FileSpan span;
  final List<Statement> statements;

  Block(this.statements, this.span);
}

class VariableDeclaration extends Statement {
  final Identifier name;
  final Expression expression;

  VariableDeclaration(this.name, this.expression);

  @override
  FileSpan get span => name.span.expand(expression.span);
}

class ExpressionStatement extends Statement {
  final Expression expression;
  final bool isReturn;
  final FileSpan span;

  ExpressionStatement(this.expression, this.isReturn, this.span);
}

class IfStatement extends Statement {
  final Expression condition;
  final Statement body;
  final Statement else_;
  final FileSpan span;
}