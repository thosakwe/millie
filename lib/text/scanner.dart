part of millie.text;

final Map<Pattern, TokenType> _patterns = {};
final RegExp _whitespace = new RegExp(r'[ \n\r\t]+');

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
      throw 'Unexpected text or EOF.\n${scanner.emptySpan.highlight()}';

    matches.sort((a, b) => b.span.length.compareTo(a.span.length));
    tokens.add(matches[0]);
    scanner.scan(matches[0].span.text);
  }

  return tokens;
}
