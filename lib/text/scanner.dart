part of millie.text;

final RegExp _whitespace = new RegExp(r'[ \n\r\t]+');

final Map<Pattern, TokenType> _patterns = {
  // Symbols
  ':': TokenType.colon,
  ',': TokenType.comma,
  '{': TokenType.lCurly,
  '}': TokenType.rCurly,
  '(': TokenType.lParen,
  ')': TokenType.rParen,

  // Operators
  '&': TokenType.bitwiseAnd,
  '=': TokenType.equals,
  '*': TokenType.times,
  '/': TokenType.div,
  '%': TokenType.mod,
  '+': TokenType.plus,
  '-': TokenType.minus,

  // Keywords
  'else': TokenType.else_,
  'extern-fn': TokenType.externFn,
  'if': TokenType.if_,
  'fn': TokenType.fn,
  'let': TokenType.let,
  'return': TokenType.return_,

  // Data
  new RegExp(r'"(([^"])|(\\"))*"'): TokenType.string,
  new RegExp(r'-?[0-9]+(\.[0-9]+)?'): TokenType.number,
  new RegExp(r'0[Xx]([A-Fa-f908]+)'): TokenType.hex,
  new RegExp(r'[A-Za-z_][A-Za-z0-9_]*'): TokenType.id
};

List<Token> scan(String text, {sourceUrl}) {
  var scanner = new SpanScanner(text, sourceUrl: sourceUrl);
  var tokens = <Token>[];

  while (!scanner.isDone) {
    var matches = <Token>[];
    scanner.scan(_whitespace);

    _patterns.forEach((pattern, type) {
      if (scanner.matches(pattern))
        matches.add(new Token(type, scanner.lastSpan, scanner.lastMatch));
    });

    if (matches.isEmpty)
      throw 'Syntax error: Unexpected text or EOF.\n${scanner.emptySpan.highlight(color: true)}';

    matches.sort((a, b) => b.span.length.compareTo(a.span.length));
    tokens.add(matches[0]);
    scanner.scan(matches[0].span.text);
  }

  return tokens;
}
