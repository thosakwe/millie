part of millie.ast;

class CompilationUnit extends AstNode {
  final List<Function_> functions;
  final FileSpan span;

  CompilationUnit(this.functions, this.span);
}

class Block extends AstNode {
  final FileSpan span;

  Block(this.span);
}

abstract class Function_ extends AstNode {
  FunctionSignature get signature;
}

class ImplementedFunction extends Function_ {
  final FunctionSignature signature;
  final Block body;

  ImplementedFunction(this.signature, this.body);

  FileSpan get span => signature.span.expand(body.span);
}

class ExternFunction extends Function_ {
  final FunctionSignature signature;
  final FileSpan span;

  ExternFunction(this.signature, this.span);
}

class FunctionSignature extends AstNode {
  final Identifier name;
  final List<Parameter> parameters;
  final Type returnType;
  final FileSpan span;

  FunctionSignature(this.name, this.parameters, this.returnType, this.span);
}

class Parameter extends AstNode {
  final Identifier name;
  final Type type;

  Parameter(this.name, this.type);

  FileSpan get span => name.span.expand(type.span);
}
