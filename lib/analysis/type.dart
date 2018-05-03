part of millie.analysis;

class Type {
  final int size;
  final String asmType;

  Type(this.size, this.asmType);
}

class PointerType extends Type {
  final Type type;

  PointerType(this.type) : super(4, 'dw');
}
