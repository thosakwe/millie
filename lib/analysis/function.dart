part of millie.analysis;

class Function_ {
  final String name;
  final ast.Function_ declaration;
  final List<Parameter> parameters;
  final Type returnType;
  SymbolTable<Value> scope;
  Statement body;
  bool isExtern = false;

  Function_(this.name, this.declaration, this.parameters, this.returnType,
      this.scope);
}

class Parameter {
  final String name;
  final Type type;
  final FileSpan span;

  Parameter(this.name, this.type, this.span);
}
