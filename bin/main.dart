import 'dart:io';
import 'package:args/args.dart';
import 'package:millie/millie.dart' as millie;

main(List<String> args) async {
  try {
    var file = new File(args[0]);
    var contents = await file.readAsString();
    var tokens = millie.scan(contents, sourceUrl: file.uri);
    var parser = new millie.Parser(tokens);
    var compilationUnit = parser.parseCompilationUnit();
  } catch (e) {
    stderr.writeln(e);
  }
}
