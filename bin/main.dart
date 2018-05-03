import 'dart:io';
import 'package:args/args.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:millie/analysis/analysis.dart';
import 'package:millie/compiler/compiler.dart';
import 'package:millie/text/text.dart';
import 'package:path/path.dart' as p;

main(List<String> args) async {
  var argParser = new ArgParser()
    ..addFlag('delete-asm',
        help: 'Delete the generated .asm file after compilation.',
        defaultsTo: true)
    ..addFlag('help',
        abbr: 'h',
        help: 'Print this help information.',
        negatable: false,
        defaultsTo: false)
    ..addFlag('execute',
        abbr: 'x',
        help: 'Execute the generated assembly after compilation.',
        negatable: false,
        defaultsTo: false)
    ..addOption(
      'format',
      abbr: 'f',
      help: 'The binary format to generate. Passed to NASM.',
      defaultsTo: 'elf',
    )
    ..addOption('out',
        abbr: 'o',
        help: 'The output filename to generate. Defaults to <filename>.out.');

  try {
    var argResults = argParser.parse(args);

    if (argResults['help']) {
      print('usage: millie [options...] <filename>');
      print(argParser.usage);
      return;
    }

    if (argResults.rest.isEmpty)
      throw 'fatal error: no input file. Run `millie --help`.';
    var file = new File(argResults.rest[0]);
    var contents = await file.readAsString();
    var tokens = scan(contents, sourceUrl: file.uri);
    var parser = new Parser(tokens);
    var compilationUnit = parser.parseCompilationUnit();
    var program = analyzer.analyze(compilationUnit);
    var assembly = compiler.compileProgram(program);
    var buf = new CodeBuffer();
    assembly.generate(buf);

    var asmFile = new File(p.setExtension(file.path, '.asm'));
    await asmFile.writeAsString(buf.toString());

    var outFile = argResults.wasParsed('out')
        ? argResults['out']
        : p.setExtension(file.path, '.out');
    var nasm = await Process.start('nasm', [
      '-o',
      outFile,
      '-f${argResults['format']}',
      asmFile.path,
    ]);
    stdout.addStream(nasm.stdout);
    stderr.addStream(nasm.stderr);

    var code = await nasm.exitCode;

    if (code != 0) {
      stderr.writeln('`nasm` finished with exit code $code');
      exitCode = 1;
    }

    if (argResults['delete-asm']) await asmFile.delete();
    if (!Platform.isWindows) await Process.run('chmod', ['+x', outFile]);

    if (argResults['execute']) {
      var exec = await Process.start(p.absolute(outFile), []);
      stdout.addStream(exec.stdout);
      stderr.addStream(exec.stderr);
      exitCode = await exec.exitCode;
    }
  } catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}
