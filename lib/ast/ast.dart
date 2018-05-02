library millie.ast;

import 'package:source_span/source_span.dart';
part 'expression.dart';
part 'statement.dart';
part 'top_level.dart';
part 'type.dart';

abstract class AstNode {
  FileSpan get span;
}

class Token {
  final TokenType type;
  final FileSpan span;
  final Match match;

  Token(this.type, this.span, this.match);
}

const List<TokenType> binaryOperators = const [
  TokenType.times,
  TokenType.div,
  TokenType.mod,
  TokenType.plus,
  TokenType.minus
];

enum TokenType {
  // Symbols
  colon,
  comma,
  lCurly,
  rCurly,
  lParen,
  rParen,

  // Operators
  bitwiseAnd,
  equals,
  times,
  div,
  mod,
  plus,
  minus,

  // Keywords
  else_,
  externFn,
  if_,
  fn,
  return_,

  // Data
  string,
  number,
  hex,
  id
}
