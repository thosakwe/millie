part of millie.ast;

abstract class Type extends AstNode {
  final FileSpan span;

  Type(this.span);
}

class NamedSpan extends Type {
  final Identifier name;

  NamedSpan(this.name) : super(name.span);
}

class PointerType extends Type {
  final Type type;

  PointerType(this.type, FileSpan span) : super(span);
}
