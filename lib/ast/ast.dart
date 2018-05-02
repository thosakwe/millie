library millie.ast;

import 'package:source_span/source_span.dart';

abstract class AstNode {
  FileSpan get span;
}

class Token {
  final TokenType type;
  final FileSpan span;
  final Match match;

  Token(this.type, this.span, this.match);
}

enum TokenType {
  // Symbols
  colon,
  lCurly,
  rCurly,
  lParen,
  rParen,
  semi,

  // Operators
  bitwiseAnd,
  equals,
  times,
  div,
  mod,
  plus,
  minus,

  // Keywords
  externFn,
  fn,
}