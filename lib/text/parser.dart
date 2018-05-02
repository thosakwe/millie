part of millie.text;

class Parser {
  final List<Token> tokens;
  Token _current;
  int _index = -1;

  Parser(this.tokens);

  bool get done => _index >= tokens.length - 1;

  bool next(TokenType type) {
    if (done) return false;
    var peek = tokens[_index + 1];
    if (peek.type != type) return false;
    _current = tokens[++_index];
    return true;
  }
}
