part of millie.analysis;

const Analyzer analyzer = const Analyzer._();

class Analyzer {
  const Analyzer._();

  Program analyze(ast.CompilationUnit ctx) {
    var rootScope = new SymbolTable<Value>();
    var state = new AnalyzerState(rootScope, {}, {});
    return new Program(rootScope, state.functions.values.toList(), state.types);
  }
}

class AnalyzerState {
  final SymbolTable<Value> scope;
  final Map<ast.Function_, Function_> functions;
  final Map<String, Type> types;

  AnalyzerState(this.scope, this.functions, this.types);

  AnalyzerState copyWith(
      {SymbolTable<Value> scope,
      Map<ast.Function_, Function_> functions,
      Map<String, Type> types}) {
    return new AnalyzerState(scope, functions, types);
  }
}
