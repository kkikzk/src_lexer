# SrcLexer

SrcLexer is a simple source file lexer.

## Installation

Add this line to your application's Gemfile:

    gem 'src_lexer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install src_lexer

## Usage

    lexer = SrcLexer::Lexer.new(
      ['struct', 'enum', 'true', 'false'], # kyewords
      ['{', '}', '(', ')', ',', '==', '=', ';'], # symbols
      ['"', '"'], # string literal markers
      '//', # line comment marker
      ['/*', '*/'] # multi line comment markers
    )
    
    lexer.analyze(<<-'EOS')
      // comment
      enum ID {
        First = 1,
        Second = 1.5
      }
      /* comment
         againe */
      struct Data {
        string name = "This is a name.";
        ID id;
      }
      bool b = (true==false);
    EOS
    
    lexer.pop_token # => ['enum', SrcLexer::Token.new('enum', 2, 3)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('ID', 2, 8)]
    lexer.pop_token # => ['{', SrcLexer::Token.new('{', 2, 11)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('First', 3, 5)]
    lexer.pop_token # => ['=', SrcLexer::Token.new('=', 3, 11)]
    lexer.pop_token # => [:NUMBER, SrcLexer::Token.new('1', 3, 13)]
    lexer.pop_token # => [',', SrcLexer::Token.new(',', 3, 14)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('Second', 4, 5)]
    lexer.pop_token # => ['=', SrcLexer::Token.new('=', 4, 12)]
    lexer.pop_token # => [:NUMBER, SrcLexer::Token.new('1.5', 4, 14)]
    lexer.pop_token # => ['}', SrcLexer::Token.new('}', 5, 3)]
    lexer.pop_token # => ['struct', SrcLexer::Token.new('struct', 8, 3)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('Data', 8, 10)]
    lexer.pop_token # => ['{', SrcLexer::Token.new('{', 8, 15)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('string', 9, 5)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('name', 9, 12)]
    lexer.pop_token # => ['=', SrcLexer::Token.new('=', 9, 17)]
    lexer.pop_token # => [:STRING, SrcLexer::Token.new('"This is a name."', 9, 19)]
    lexer.pop_token # => [';', SrcLexer::Token.new(';', 9, 36)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('ID', 10, 5)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('id', 10, 8)]
    lexer.pop_token # => [';', SrcLexer::Token.new(';', 10, 10)]
    lexer.pop_token # => ['}', SrcLexer::Token.new('}', 11, 3)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('bool', 12, 3)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('b', 12, 8)]
    lexer.pop_token # => [:IDENT, SrcLexer::Token.new('=', 12, 10)]
    lexer.pop_token # => ['(', SrcLexer::Token.new('(', 12, 12)]
    lexer.pop_token # => ['true', SrcLexer::Token.new('true', 12, 13)]
    lexer.pop_token # => ['==', SrcLexer::Token.new('==', 12, 17)]
    lexer.pop_token # => ['false', SrcLexer::Token.new('==', 12, 19)]
    lexer.pop_token # => [')', SrcLexer::Token.new('==', 12, 24)]
    lexer.pop_token # => [';', SrcLexer::Token.new('==', 12, 25)]
    lexer.pop_token # => SrcLexer::Lexer::END_TOKEN

## Contributing

1. Fork it ( http://github.com/<my-github-username>/src_lexer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
