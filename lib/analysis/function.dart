part of millie.analysis;

class Function_ {
  final List<Statement> body = [];
  final ast.Function_ declaration;
  final List<Parameter> parameters;
  final Type returnType;
  bool isExtern = false;

  Function_(this.declaration, this.parameters, this.returnType);
}

class Parameter {
  final String name;
  final Type type;
  final FileSpan span;

  Parameter(this.name, this.type, this.span);
}
