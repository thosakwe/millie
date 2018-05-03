part of millie.analysis;

class Program {
  final SymbolTable<Value> rootScope;
  final List<Function_> functions;
  final Map<String, Type> types;

  Program(this.rootScope, this.functions, this.types);
}
