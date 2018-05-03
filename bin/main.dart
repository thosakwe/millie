import 'dart:io';
import 'package:args/args.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:millie/analysis/analysis.dart';
import 'package:millie/compiler/compiler.dart';
import 'package:millie/text/text.dart';

main(List<String> args) async {
  try {
    var file = new File(args[0]);
    var contents = await file.readAsString();
    var tokens = scan(contents, sourceUrl: file.uri);
    var parser = new Parser(tokens);
    var compilationUnit = parser.parseCompilationUnit();
    var program = analyzer.analyze(compilationUnit);
    var assembly = compiler.compileProgram(program);
    var buf = new CodeBuffer();
    assembly.generate(buf);
    print(buf);
  } catch (e) {
    stderr.writeln(e);
  }
}
