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
    attr_reader :keywords, :symbols, :line_comment_marker, :comment_markers, :tokens, :str

    def initialize(keywords, symbols, line_comment_marker, comment_marker)
      @keywords = ((keywords.nil?) ? [] : keywords.uniq.compact)
      @symbols = ((symbols.nil?) ? [] : symbols.uniq.compact)
      @line_comment_marker = ((line_comment_marker.nil?) ? '' : line_comment_marker)
      @comment_markers = ((comment_marker.nil?) ? ['', ''] : comment_marker)
    end

    def analyze(str)
      @str = str
      tokenize
    end

    def pop_token
      token = @tokens.shift
      if token.nil? then
        return END_TOKEN
      end
      case token[0]
      when /^[\d]+[\.]?[\d]*\z/
        [:NUMBER, Token.new(token[0], token[1], token[2])]
      when /^\"(.*)\"\z/m
        [:STRING, Token.new(token[0], token[1], token[2])]
      else
        id = is_reserved?(token[0]) ? token[0] : :IDENT
        [id, Token.new(token[0], token[1], token[2])]
      end
    end

    private

    class StringIterator
      attr_reader :index

      def initialize(str)
        @str = str
        @index = 0
        @marked_pos = -1
      end

      def mark_set
        @marked_pos = @index
      end

      def is(target_string)
        return false if target_string.length.zero?
        end_pos = (@index + target_string.length - 1)
        @str[@index..end_pos] == target_string
      end

      def is_in(target_list)
        target_list.find { |target| is(target) } != nil
      end

      def move_next
        @index += 1
      end

      def move_to_the_end_of_the_line
        @index += (@str[@index..-1] =~ /$/) - 1
      end

      def move_to(target)
        esceped_target = Regexp.escape(target)
        @index += (@str[@index..-1] =~ /#{esceped_target}/m) + target.length - 1
      end

      def [](range)
        @str[range]
      end

      def <(pos)
        @index < pos
      end

      def char
        @str[@index]
      end

      def is_white_space
        /[\s]/.match(char)
      end

      def info(pos)
        [0, 0] if pos == 0
        line_no, char_no = 1, 0
        @str[0..pos].each_char do |char|
          if /\n/.match(char)
            line_no += 1
            char_no = 0
          else
            char_no += 1
          end
        end
        [line_no, char_no]
      end

      def marked?
        @marked_pos != -1
      end

      def shift
        result = @str[@marked_pos..(@index - 1)]
        line_no_and_char_no = info(@marked_pos) 
        @marked_pos = -1
        return result, *line_no_and_char_no
      end
    end

    def tokenize()
      @tokens = []
      iterator = StringIterator.new(@str)

      while iterator < @str.length do
        if iterator.is_white_space then
          @tokens.push iterator.shift if iterator.marked?
        elsif iterator.is(@line_comment_marker) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.move_to_the_end_of_the_line
        elsif iterator.is(@comment_markers[0]) then
          @tokens.push iterator.shift if iterator.marked?
          iterator.move_to(@comment_markers[1])
        elsif iterator.is('"') then
          @tokens.push iterator.shift if iterator.marked?
          iterator.mark_set
          iterator.move_next
          iterator.move_to('"')
          iterator.move_next
          @tokens.push iterator.shift
          next
        elsif iterator.is_in(@symbols) then
          @tokens.push iterator.shift if iterator.marked?
          symbol = @symbols.find { |symbol| iterator.is(symbol) }
          @tokens.push [iterator[iterator.index..(iterator.index + symbol.length - 1)], *iterator.info(iterator.index)]
          (symbol.length - 1).times { iterator.move_next }
        elsif !iterator.marked? then
          iterator.mark_set
        end
        iterator.move_next
      end

      @tokens.push iterator.shift if iterator.marked?
    end

    def is_reserved?(token)
      @keywords.include?(token) || @symbols.include?(token)
    end
  end
end
