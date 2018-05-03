part of millie.analysis;

class Type {
  static const Map<String, Type> predefinedTypes = const {
    'void': const Type(0, 'db'),
    'i8': const Type(1, 'db'),
    'i16': const Type(2, 'db'),
    'i32': const Type(4, 'db'),
  };
  final int size;
  final String asmType;

  const Type(this.size, this.asmType);
}

class PointerType extends Type {
  final Type type;

  PointerType(this.type) : super(4, 'dw');
}
