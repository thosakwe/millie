part of millie.analysis;

const Analyzer analyzer = const Analyzer._();

class Analyzer {
  const Analyzer._();

  Program analyze(ast.CompilationUnit ctx) {
    var rootScope = new SymbolTable<Value>();
    var state = new AnalyzerState(rootScope, {}, {}, null);

    for (var function in ctx.functions)
      state = analyzeFunction(function, state);

    return new Program(rootScope, state.functions.values.toList(), state.types);
  }

  AnalyzerState analyzeFunction(ast.Function_ function, AnalyzerState state) {
    if (state.functions.containsKey(function)) return state;

    var parameters = function.signature.parameters
        .map((p) =>
            new Parameter(p.name.name, analyzeType(p.type, state), p.span))
        .toList();

    var fn = new Function_(
      function.signature.name.name,
      function,
      parameters,
      analyzeType(function.signature.returnType, state),
      state.scope.createChild(),
    );

    if (function is ast.ExternFunction) {
      state.functions[function] = fn;
    } else if (function is ast.ImplementedFunction) {
      var extern = state.functions.values.firstWhere(
          (f) => f.name == fn.name && f.declaration is ast.ExternFunction,
          orElse: () => null);
      if (extern != null) {
        extern
          ..isExtern = false
          ..body.addAll(fn.body);
        fn = extern;
      } else {
        state.functions[function] = fn;
      }
    }

    return state.copyWith(
      function: fn,
      scope: fn.scope,
    );
  }

  Type analyzeType(ast.Type type, AnalyzerState state) {
    if (type is ast.PointerType) {
      return new PointerType(analyzeType(type.type, state));
    } else if (type is ast.NamedType) {
      var resolved = state.types[type.name.name];
      if (resolved == null)
        throw "Undefined name '${type.name.name}'.\n${type.span.highlight(color: true)}";
      return resolved;
    }

    throw new UnsupportedError(type.runtimeType.toString());
  }
}

class AnalyzerState {
  final SymbolTable<Value> scope;
  final Map<ast.Function_, Function_> functions;
  final Map<String, Type> types;
  final Function_ function;

  AnalyzerState(this.scope, this.functions, this.types, this.function);

  AnalyzerState copyWith({SymbolTable<Value> scope, Function_ function}) {
    return new AnalyzerState(
      scope ?? this.scope,
      functions,
      types,
      function ?? this.function,
    );
  }
}
