# -*- encoding: utf-8 -*-
require "src_lexer/version"

module SrcLexer
  class Token
    attr_reader :str, :line_no, :char_no

    def initialize(str, line_no, char_no)
      @str = str
      @line_no = line_no
      @char_no = char_no
    end

    def ==(other_object)
      @str == other_object.str && @line_no == other_object.line_no && @char_no == other_object.char_no
    end
  end

  class Lexer
    END_TOKEN = [false, nil]
    NUMBER_REGEX = /^[\d]+[\.]?[\d]*\z/
    STRING_REGEX = /^\"(.*)\"\z/m
    attr_reader :keywords, :symbols, :string_literal_marker, :line_comment_marker, :comment_markers, :tokens, :str

    def initialize(keywords, symbols, string_literal_marker, line_comment_marker, comment_markers)
      @keywords = (keywords ? keywords.uniq.compact : [])
      @symbols = (symbols ? symbols.uniq.compact : [])
      @string_literal_marker = string_literal_marker
      @line_comment_marker = line_comment_marker
      @comment_markers = comment_markers
    end

    def analyze(str)
      @str = str
      tokenize
    end

    def pop_token
      token = @tokens.shift
      return END_TOKEN if token.nil?
      case token[0]
      when NUMBER_REGEX
        [:NUMBER, Token.new(token[0], token[1], token[2])]
      when STRING_REGEX
        [:STRING, Token.new(token[0], token[1], token[2])]
      else
        [is_reserved?(token[0]) ? token[0] : :IDENT, Token.new(token[0], token[1], token[2])]
      end
    end

    private

    class PosInfo
      attr_accessor :index, :line_no, :char_no
      
      def initialize
        @index = 0
        @line_no = 1
        @char_no = 1
      end
    end

    class StringIterator
      def initialize(str)
        @str = str
        @current_pos = PosInfo.new
        @marked_pos = PosInfo.new
        mark_clear()
      end

      def mark_clear
        @marked_pos.index = -1
        @marked_pos.line_no = 0
        @marked_pos.char_no = 0
      end

      def mark_set
        @marked_pos = @current_pos.clone
      end

      def is(target_string)
        return false if target_string.length.zero?
        end_pos = (@current_pos.index + target_string.length - 1)
        @str[@current_pos.index..end_pos] == target_string
      end

      def is_in(target_list)
        target_list.find { |target| is(target) } != nil
      end

      def move_next
        if /\n/.match @str[@current_pos.index]
          @current_pos.line_no += 1
          @current_pos.char_no = 1
        else
          @current_pos.char_no += 1
        end
        @current_pos.index += 1
      end

      def move_to_the_end_of_the_line
        char_count_to_the_end_of_the_line = (@str[@current_pos.index..-1] =~ /$/) - 1
        @current_pos.index += char_count_to_the_end_of_the_line
        @current_pos.char_no += char_count_to_the_end_of_the_line
      end

      def move_to(target)
        char_count_to_target = (@str[@current_pos.index..-1] =~ /#{Regexp.escape(target)}/m) + target.length - 1
        chopped_string = @str[@current_pos.index..@current_pos.index + char_count_to_target]
        @current_pos.index += char_count_to_target
        match = /.*\n(.*)$/m.match(chopped_string)
        p match[1].length if match
        if match
          @current_pos.char_no = match[1].length
        else
          @current_pos.char_no += char_count_to_target
        end
        @current_pos.line_no += chopped_string.each_char.select{|char| /\n/.match char}.length
      end

      def <(index)
        @current_pos.index < index
      end

      def is_white_space
        /\s/.match(@str[@current_pos.index])
      end

      def marked?
        @marked_pos.index != -1
      end

      def shift
        result = [@str[@marked_pos.index..(@current_pos.index - 1)], @marked_pos.line_no, @marked_pos.char_no]
        mark_clear()
        return result
      end
    end

    def tokenize()
      @tokens = []
      iterator = StringIterator.new(@str)

      while iterator < @str.length do
        if iterator.is_white_space then
          @tokens.push iterator.shift if iterator.marked?
          iterator.move_next
        elsif @line_comment_marker && iterator.is(@line_comment_marker) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.move_to_the_end_of_the_line
          iterator.move_next
        elsif @comment_markers && iterator.is(@comment_markers[0]) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.move_to(@comment_markers[1])
          iterator.move_next
        elsif @string_literal_marker && iterator.is(@string_literal_marker[0]) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.mark_set
          iterator.move_next
          iterator.move_to(@string_literal_marker[1])
          iterator.move_next
          @tokens.push iterator.shift
        elsif iterator.is_in(@symbols) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.mark_set
          @symbols.find { |symbol| iterator.is(symbol) }.length.times { iterator.move_next }
          @tokens.push iterator.shift
        elsif !iterator.marked? then
          iterator.mark_set
        else
          iterator.move_next
        end
      end
      @tokens.push iterator.shift if iterator.marked?
      
      return self
    end

    def is_reserved?(token)
      @keywords.include?(token) || @symbols.include?(token)
    end
  end

  class CSharpLexer < Lexer
    def initialize
      super(
        [ # C# keywords
          'abstract',   'as',       'base',       'bool',      'break',
          'byte',       'case',     'catch',      'char',      'checked',
          'class',      'const',    'continue',   'decimal',   'default',
          'delegate',   'do',       'double',     'else',      'enum',
          'event',      'explicit', 'extern',     'false',     'finally',
          'fixed',      'float',    'for',        'foreach',   'goto',
          'if',         'implicit', 'in',         'int',       'interface',
          'internal',   'is',       'lock',       'long',      'namespace',
          'new',        'null',     'object',     'operator',  'out',
          'override',   'params',   'private',    'protected', 'public',
          'readonly',   'ref',      'return',     'sbyte',     'sealed',
          'short',      'sizeof',   'stackalloc', 'static',    'string',
          'struct',     'switch',   'this',       'throw',     'true',
          'try',        'typeof',   'uint',       'ulong',     'unchecked',
          'unsafe',     'ushort',   'using',      'virtual',   'void',
          'volatile',   'while',
          # C# context keywords
          'add',        'alias',    'ascending',  'async',     'await',
          'descending', 'dynamic',  'from',       'get',       'global',
          'group',      'into',     'join',       'let',       'orderby',
          'partial',    'remove',   'select',     'set',       'value',
          'var',        'where',    'yield'
        ],
        [
          '<<=', '>>=', '<<',  '>>',  '<=',
          '>=',  '==',  '!=',  '&&',  '||',
          '??',  '+=',  '-=',  '*=',  '/=',
          '%=',  '&=',  '|=',  '^=',  '=>',
          '*',   '/',   '%',   '+',   '-',
          '<',   '>',   '&',   '^',   '|',
          '?',   ':',   '=',   '{',   '}',
          '(',   ')',   '[',   ']',   ';',
          ','
        ],
        ['"', '"'], # comment markers
        '//', # line comment marker
        ['/*', '*/']) # multi line comment markers
    end
  end
end
