part of millie.ast;

abstract class Type extends AstNode {
  final FileSpan span;

  Type(this.span);
}

class NamedType extends Type {
  final Identifier name;

  NamedType(this.name) : super(name.span);
}

class PointerType extends Type {
  final Type type;

  PointerType(this.type, FileSpan span) : super(span);
}
