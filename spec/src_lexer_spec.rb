# -*- encoding: utf-8 -*-
require_relative './spec_helper'

describe SrcLexer do
  it 'should have a version number' do
    expect(SrcLexer::VERSION).not_to eq(be_nil)
  end
end

describe SrcLexer::Lexer, 'with empty string' do  
  it 'should return Lexer::END_TOKEN' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, nil, nil)
    sut.analyze('')
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
end

describe SrcLexer::Lexer, 'with keyword definitions' do
  it 'should recognize keywords' do
    sut = SrcLexer::Lexer.new(['struct', 'enum'], nil, nil, nil, nil)
    sut.analyze('struct structenum enum')
    expect(sut.pop_token).to eq(['struct', SrcLexer::Token.new('struct', 1, 1)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('structenum', 1, 8)])
    expect(sut.pop_token).to eq(['enum', SrcLexer::Token.new('enum', 1, 19)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should reduce keyword duplication' do
    sut = SrcLexer::Lexer.new(['struct', 'struct'], nil, nil, nil, nil)
    expect(sut.keywords).to eq(['struct'])
  end
  it 'should ignore nil keyword' do
    sut = SrcLexer::Lexer.new(['struct', nil, 'enum'], nil, nil, nil, nil)
    expect(sut.keywords).to eq(['struct', 'enum'])
  end
end

describe SrcLexer::Lexer, 'with symbol definitions' do
  it 'should recognize symbols' do
    sut = SrcLexer::Lexer.new(nil, ['..', ','], nil, nil, nil)
    sut.analyze('.. A ,')
    expect(sut.pop_token).to eq(['..', SrcLexer::Token.new('..', 1, 1)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('A', 1, 4)])
    expect(sut.pop_token).to eq([',', SrcLexer::Token.new(',', 1, 6)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should recognize symbols(,) if continues like "A,B"' do
    sut = SrcLexer::Lexer.new(['A', 'B'], [','], nil, nil, nil)
    sut.analyze('A,B')
    expect(sut.pop_token).to eq(['A', SrcLexer::Token.new('A', 1, 1)])
    expect(sut.pop_token).to eq([',', SrcLexer::Token.new(',', 1, 2)])
    expect(sut.pop_token).to eq(['B', SrcLexer::Token.new('B', 1, 3)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should recognize symbol(==) if symbol(=) defined' do
    sut = SrcLexer::Lexer.new(nil, ['==', '='], nil, nil, nil)
    sut.analyze('A = B == C')
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('A', 1, 1)])
    expect(sut.pop_token).to eq(['=', SrcLexer::Token.new('=', 1, 3)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('B', 1, 5)])
    expect(sut.pop_token).to eq(['==', SrcLexer::Token.new('==', 1, 7)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('C', 1, 10)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should reduce symbol duplication' do
    sut = SrcLexer::Lexer.new(nil, [',', ','], nil, nil, nil)
    expect(sut.symbols).to eq([','])
  end
  it 'should ignore nil keyword' do
    sut = SrcLexer::Lexer.new(nil, ['{', nil, '}'], nil, nil, nil)
    expect(sut.symbols).to eq(['{', '}'])
  end
end

describe SrcLexer::Lexer, 'with line comment marker' do
  it 'should recognize line comment' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, '//', nil)
    sut.analyze(<<-'EOS')
      A//comment
      B
    EOS
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('A', 1, 7)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('B', 2, 7)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should recognize multi line comment' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, '//', ['/*', '*/'])
    sut.analyze(<<-'EOS')
      A/*comment
      B//still in comment*/C
    EOS
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('A', 1, 7)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('C', 2, 28)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
end

describe SrcLexer::Lexer do
  it 'should analyze number string' do
    sut = SrcLexer::Lexer.new(nil, nil, nil, nil, nil)
    sut.analyze('9 1.5')
    expect(sut.pop_token).to eq([:NUMBER, SrcLexer::Token.new("9", 1, 1,)])
    expect(sut.pop_token).to eq([:NUMBER, SrcLexer::Token.new("1.5", 1, 3)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
  it 'should analyze string literal' do
    sut = SrcLexer::Lexer.new(nil, nil, ['"', '"'], '//', ['/*', '*/'])
    sut.analyze('A"//"B"/**/"C')
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('A', 1, 1)])
    expect(sut.pop_token).to eq([:STRING, SrcLexer::Token.new('"//"', 1, 2)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('B', 1, 6)])
    expect(sut.pop_token).to eq([:STRING, SrcLexer::Token.new('"/**/"', 1, 7)])
    expect(sut.pop_token).to eq([:IDENT, SrcLexer::Token.new('C', 1, 13)])
    expect(sut.pop_token).to eq(SrcLexer::Lexer::END_TOKEN)
  end
end
