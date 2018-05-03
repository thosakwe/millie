part of millie.compiler;

abstract class Registers {
  factory Registers.x86() = _X86Registers;

  Register get accumulator;
}

class _X86Registers implements Registers {
  final Register accumulator = new Register('eax', 'ax', 'ah', 'al');
}

class Register {
  final LinearMemory<RegisterValue> memory = new LinearMemory(32);
  final String name32, name16, nameHigh8, nameLow8;

  Register(this.name32, this.name16, this.nameHigh8, this.nameLow8);
}

class RegisterValue {
  final ml.Type type;
  final FileSpan span;
  Register register;
  MemoryBlock<RegisterValue> registerOffset, spillOffset;

  RegisterValue(this.type, this.span);

  String compile(CompilerState state) {
    if (register != null) {} else if (spillOffset != null) {
      // TODO: Is this a pointer?
      // TODO: get constant
      return '[0x${spillOffset.offset.toRadixString(16)}]';
    }

    throw 'This value has not been assigned to a register or memory.\n${span.highlight(color: true)}';
  }
}

class DataPointer extends RegisterValue {
  final Data value;
  final ml.Type type;

  DataPointer(this.value, this.type, FileSpan span) : super(type, span);

  @override
  String compile(CompilerState state) {
    return value.name;
  }
}
