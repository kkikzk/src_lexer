# -*- encoding: utf-8 -*-
require_relative './spec_helper'

describe SrcLexer do
  it 'should have a version number' do
    SrcLexer::VERSION.should_not be_nil
  end
end

describe SrcLexer::Lexer, 'with empty string' do  
  it 'should return Lexer::END_TOKEN' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, nil, nil)
    sut.analyze('')
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
end

describe SrcLexer::Lexer, 'with keyword definitions' do
  it 'should recognize keywords' do
    sut = SrcLexer::Lexer.new(['struct', 'enum'], nil, nil, nil, nil)
    sut.analyze('struct structenum enum')
    sut.pop_token.should == ['struct', SrcLexer::Token.new('struct', 1, 1)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('structenum', 1, 8)]
    sut.pop_token.should == ['enum', SrcLexer::Token.new('enum', 1, 19)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
  it 'should reduce keyword duplication' do
    sut = SrcLexer::Lexer.new(['struct', 'struct'], nil, nil, nil, nil)
    sut.keywords.should == ['struct']
  end
  it 'should ignore nil keyword' do
    sut = SrcLexer::Lexer.new(['struct', nil, 'enum'], nil, nil, nil, nil)
    sut.keywords.should == ['struct', 'enum']
  end
end

describe SrcLexer::Lexer, 'with symbol definitions' do
  it 'should recognize symbols' do
    sut = SrcLexer::Lexer.new(nil, ['..', ','], nil, nil, nil)
    sut.analyze('.. A ,')
    sut.pop_token.should == ['..', SrcLexer::Token.new('..', 1, 1)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('A', 1, 4)]
    sut.pop_token.should == [',', SrcLexer::Token.new(',', 1, 6)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
  it 'should recognize symbols(,) if continues like "A,B"' do
    sut = SrcLexer::Lexer.new(['A', 'B'], [','], nil, nil, nil)
    sut.analyze('A,B')
    sut.pop_token.should == ['A', SrcLexer::Token.new('A', 1, 1)]
    sut.pop_token.should == [',', SrcLexer::Token.new(',', 1, 2)]
    sut.pop_token.should == ['B', SrcLexer::Token.new('B', 1, 3)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
  it 'should reduce symbol duplication' do
    sut = SrcLexer::Lexer.new(nil, [',', ','], nil, nil, nil)
    sut.symbols.should == [',']
  end
  it 'should ignore nil keyword' do
    sut = SrcLexer::Lexer.new(nil, ['{', nil, '}'], nil, nil, nil)
    sut.symbols.should == ['{', '}']
  end
end

describe SrcLexer::Lexer, 'with line comment marker' do
  it 'should recognize line comment' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, '//', nil)
    sut.analyze(<<-'EOS')
      A//comment
      B
    EOS
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('A', 1, 7)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('B', 2, 7)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
  it 'should recognize multi line comment' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, '//', ['/*', '*/'])
    sut.analyze(<<-'EOS')
      A/*comment
      B//still in comment*/C
    EOS
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('A', 1, 7)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('C', 2, 28)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
end

describe SrcLexer::Lexer do
  it 'should analyze number string' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, nil, nil)
    sut.analyze('9 1.5')
    sut.pop_token.should == [:NUMBER, SrcLexer::Token.new("9", 1, 1,)]
    sut.pop_token.should == [:NUMBER, SrcLexer::Token.new("1.5", 1, 3)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
  it 'should analyze string literal' do
    sut = SrcLexer::Lexer.new(nil, nil, ['"', '"'], '//', ['/*', '*/'])
    sut.analyze('A"//"B"/**/"C')
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('A', 1, 1)]
    sut.pop_token.should == [:STRING, SrcLexer::Token.new('"//"', 1, 2)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('B', 1, 6)]
    sut.pop_token.should == [:STRING, SrcLexer::Token.new('"/**/"', 1, 7)]
    sut.pop_token.should == [:IDENT, SrcLexer::Token.new('C', 1, 13)]
    sut.pop_token.should == SrcLexer::Lexer::END_TOKEN
  end
end
