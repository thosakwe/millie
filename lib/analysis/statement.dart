part of millie.analysis;

class Statement {
  final SymbolTable<Value> scope;
  final ast.Statement declaration;

  Statement(this.scope, this.declaration);
}