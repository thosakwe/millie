library millie.compiler;

import 'package:code_buffer/code_buffer.dart';
import 'package:linear_memory/linear_memory.dart';
import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'package:tuple/tuple.dart';
import '../analysis/analysis.dart' as ml;
import '../ast/ast.dart' as ast;
part 'asm.dart';
part 'register.dart';

const Compiler compiler = const Compiler._();

class Compiler {
  const Compiler._();

  Assembly compileProgram(ml.Program program) {
    var assembly = new Assembly();
    var dataSection = new Section('data'), textSection = new Section('text');
    assembly.body.addAll([dataSection, textSection]);
    var state = new CompilerState(
      program,
      assembly,
      dataSection,
      textSection,
      {},
      program.rootScope,
      null,
      null,
      new SymbolTable(),
      new Registers.x86(),
      {},
    );

    for (var function in program.functions) {
      state = compileFunction(function, state);
    }

    return assembly;
  }

  CompilerState compileFunction(ml.Function_ function, CompilerState state) {
    if (state.labels.containsKey(function)) return state;
    var comment = new Comment(function.declaration.span.start.toolString);

    if (function.isExtern) {
      state.dataSection.body.addAll([
        comment,
        new Instruction('extern', [function.name]),
      ]);
      return state;
    }

    var label = new Label(function.name);
    state = state.copyWith(
      function: function,
      scope: function.scope,
      label: label,
    );
    state.textSection.body.addAll([
      comment,
      state.labels[function] = label,
    ]);

    if (function.declaration is ast.ImplementedFunction) {
      state = compileStatement(
          (function.declaration as ast.ImplementedFunction).body, state);
    }

    return state;
  }

  CompilerState compileStatement(ast.Statement ctx, CompilerState state) {
    state.label.body.add(new Comment(ctx.span.start.toolString));

    if (ctx is ast.Block) {
      for (var child in ctx.statements) state = compileStatement(child, state);
      return state;
    }

    if (ctx is ast.ExpressionStatement) {
      var tuple = compileExpression(ctx.expression, state);
      state = tuple.item2;
      var value = tuple.item1;

      if (ctx.isReturn) {
        if (value.register != state.registers.accumulator)
          state.label.body.add(new Instruction('mov', [
            state.registers.accumulator.name32,
            value.compile(state),
          ]));
        state.label.body.add(new Instruction('ret', []));
      }

      return state;
    }

    throw new UnsupportedError(ctx.runtimeType.toString());
    return state;
  }

  Tuple2<RegisterValue, CompilerState> compileExpression(
      ast.Expression ctx, CompilerState state) {
    if (ctx.isConstant) {
      var name = state.scope.uniqueName('constant');
      String initializer;
      ml.Type type;

      if (ctx is ast.String_) {
        type = ml.Type.predefinedTypes['i8'];
        initializer =
            "'" + ctx.constantValue.toString().replaceAll("'", "\\'") + "'";
      } else {
        // TODO: Check if type is already defined
        // TODO: Get actual type
        type = ml.Type.predefinedTypes['i32'];
        initializer = ctx.constantValue.toString();
      }

      var value = state.constants.putIfAbsent(ctx.constantValue, () {
        var constant = new Data(name, type.asmType, [initializer]);
        state.dataSection.body.add(constant);
        return constant;
      });
      return new Tuple2(new DataPointer(value, type, ctx.span), state);
    }

    if (ctx is ast.Identifier) {
      var symbol = state.dominanceFrontier.allVariables
          .firstWhere((v) => v.name == ctx.name, orElse: () => null);

      if (symbol != null) {
        return new Tuple2(
            new DataPointer(
                new Data(symbol.name, symbol.value.type.asmType, []),
                symbol.value.type,
                ctx.span),
            state);
      }

      var function = state.program.functions
          .firstWhere((f) => f.name == ctx.name, orElse: () => null);

      if (function == null)
        throw "The name '${ctx.name}' does not exist in this context.\n${ctx.span.highlight(color: true)}";

      return new Tuple2(
          new DataPointer(
              new Data(ctx.name, ml.Type.predefinedTypes['i32'].asmType, []),
              ml.Type.predefinedTypes['i32'],
              ctx.span),
          state);
    }

    if (ctx is ast.Call) {
      for (int i = ctx.arguments.length - 1; i >= 0; i--) {
        var tuple = compileExpression(ctx.arguments[i], state);
        state = tuple.item2;
        var value = tuple.item1;
        state.label.body.add(new Instruction('push', [value.compile(state)]));
      }

      var tuple = compileExpression(ctx.target, state);
      state = tuple.item2;
      var target = tuple.item1;
      state.label.body.add(new Instruction('call', [target.compile(state)]));

      // Return `eax` as-is
      var returnValue =
          new RegisterValue(ml.Type.predefinedTypes['i32'], ctx.span)
            ..register = state.registers.accumulator;
      return new Tuple2(returnValue, state);
    }

    throw new UnsupportedError(ctx.runtimeType.toString());
  }
}

class CompilerState {
  final ml.Program program;
  final Assembly assembly;
  final Section dataSection, textSection;
  final Map<ml.Function_, Label> labels;
  final SymbolTable<ml.Value> scope;
  final SymbolTable<RegisterValue> dominanceFrontier;
  final Label label;
  final ml.Function_ function;
  final Registers registers;
  final Map<dynamic, Data> constants;

  CompilerState(
      this.program,
      this.assembly,
      this.dataSection,
      this.textSection,
      this.labels,
      this.scope,
      this.label,
      this.function,
      this.dominanceFrontier,
      this.registers,
      this.constants);

  CompilerState copyWith(
      {SymbolTable<ml.Value> scope,
      Label label,
      ml.Function_ function,
      SymbolTable<RegisterValue> dominanceFrontier}) {
    return new CompilerState(
      program,
      assembly,
      dataSection,
      textSection,
      this.labels,
      scope ?? this.scope,
      label ?? this.label,
      function ?? this.function,
      dominanceFrontier ?? this.dominanceFrontier,
      registers,
      constants,
    );
  }
}
