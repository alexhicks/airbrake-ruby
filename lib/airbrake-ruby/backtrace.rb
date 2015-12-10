module Airbrake
  ##
  # Represents a cross-Ruby backtrace from exceptions (including JRuby Java
  # exceptions). Provides information about stack frames (such as line number,
  # file and method) in convenient for Airbrake format.
  #
  # @example
  #   begin
  #     raise 'Oops!'
  #   rescue
  #     Backtrace.parse($!)
  #   end
  module Backtrace
    ##
    # @return [Regexp] the pattern that matches standard Ruby stack frames,
    #   such as ./spec/notice_spec.rb:43:in `block (3 levels) in <top (required)>'
    STACKFRAME_REGEXP = %r{\A
      (?<file>.+)       # Matches './spec/notice_spec.rb'
      :
      (?<line>\d+)      # Matches '43'
      :in\s
      `(?<function>.+)' # Matches "`block (3 levels) in <top (required)>'"
    \z}x

    ##
    # @return [Regexp] the template that matches JRuby Java stack frames, such
    #  as org.jruby.ast.NewlineNode.interpret(NewlineNode.java:105)
    JAVA_STACKFRAME_REGEXP = /\A
      (?<function>.+)  # Matches 'org.jruby.ast.NewlineNode.interpret
      \(
        (?<file>[^:]+) # Matches 'NewlineNode.java'
        :?
        (?<line>\d+)?  # Matches '105'
      \)
    \z/x

    ##
    # Parses an exception's backtrace.
    #
    # @param [Exception] exception The exception, which contains a backtrace to
    #   parse
    # @return [Array<Hash{Symbol=>String,Integer}>] the parsed backtrace
    def self.parse(exception)
      regexp = if java_exception?(exception)
                 JAVA_STACKFRAME_REGEXP
               else
                 STACKFRAME_REGEXP
               end

      (exception.backtrace || []).map do |stackframe|
        stack_frame(regexp.match(stackframe))
      end
    end

    ##
    # Checks whether the given exception was generated by JRuby's VM.
    #
    # @param [Exception] exception
    # @return [Boolean]
    def self.java_exception?(exception)
      defined?(Java::JavaLang::Throwable) &&
        exception.is_a?(Java::JavaLang::Throwable)
    end

    class << self
      private

      def stack_frame(match)
        { file: match[:file],
          line: (Integer(match[:line]) if match[:line]),
          function: match[:function] }
      end
    end
  end
end
