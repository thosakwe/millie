part of millie.compiler;

abstract class Code {
  const Code();
  void generate(CodeBuffer buf);
}

class Assembly extends Code {
  final List<Code> body = [];

  @override
  void generate(CodeBuffer buf) {
    body.forEach((b) {
      b.generate(buf);
      buf.writeln(' ');
    });
  }
}

class Section extends Code {
  final List<Code> body = [];
  final String name;

  Section(this.name);

  @override
  void generate(CodeBuffer buf) {
    buf
      ..writeln('section .$name')
      ..indent();
    body.forEach((b) => b.generate(buf));
    buf.outdent();
  }
}

class Data extends Code {
  final String name, type;
  final List<String> initializers;

  Data(this.name, this.type, this.initializers);

  @override
  void generate(CodeBuffer buf) {
    buf.writeln('$name $type ${initializers.join(',')}');
  }
}

class Label extends Code {
  final List<Code> body = [];
  final String name;

  Label(this.name);

  @override
  void generate(CodeBuffer buf) {
    buf
      ..writeln('$name:')
      ..indent();
    body.forEach((b) => b.generate(buf));
    buf.outdent();
  }
}

class Comment extends Code {
  final String text;

  Comment(this.text);

  @override
  void generate(CodeBuffer buf) {
    buf.writeln('; $text');
  }
}

class Raw extends Code {
  final String code;

  const Raw(this.code);

  @override
  void generate(CodeBuffer buf) {
    buf.writeln(code);
  }
}

class Instruction extends Code {
  final String opcode;
  final List<String> operands;

  Instruction(this.opcode, this.operands);

  @override
  void generate(CodeBuffer buf) {
    buf.writeln('$opcode ${operands.join(',')}');
  }
}
