# Usage: 
#  alml = Alml::Engine.new template_text
#  script_order = alml.scripts
#  # Optional preprocessing using script_order elements
#  alml.render { |dynamic_script_name| "I return the rendered content of #{dynamic_script_name}<br/>\n" }  
module Alml
  class Engine

    def initialize(body_text)
      lines_text = body_text.split(/\r\n|\r|\n/)

      @lines = []
      prev_l = nil
      lines_text.each_with_index do |line_text, index|
        l = Line.new line_text, index, prev_l
        next if l.empty?

        @lines << l
        prev_l = l
      end
    end

    # Returns an array of the scripts that will be called during render.
    # Can be called for preprocessing purposes.
    def scripts
      @lines.reject { |l| !l.script? }.collect { |l| l.parameter }
    end

    # Block is called, sending in scripts (name of script or a script keyword, like :all)
    def render(&block)
      buffer = ''

      prev_l = nil
      @lines.each do |line|
        buffer << line.render(prev_l, &block)
        prev_l = line
      end
      buffer << Line.render_remaining_closures(prev_l)
      
      buffer
    end


    class Line 
      # How many spaces equals a single tab.  The simpler the syntax, the faster the compiler.
      SPACES_PER_TAB  = 2

      # Designates a <tt><div></tt> element with the given class.
      DIV_CLASS       = ?.

      # Designates a <tt><div></tt> element with the given id.
      DIV_ID          = ?#

      # Designates an XHTML/XML comment.
      COMMENT         = ?!

      # Designates script, the result of which is output.
      SCRIPT          = ?@

      attr_reader :full, :command, :line_number, :open_output


      def self.render_remaining_closures(previous_line)
        buffer = ''
        previous_line.tabs.times { buffer << close_div }
        buffer
      end

      def initialize(line_text, line_number, previous_line)
        @full = line_text
        @line_number = line_number
        @command = line_text.strip
        
        return if empty? # Quit while we're ahead
        
        if !valid_compared_to_previous?(previous_line)
          raise SyntaxError.new("Line #{line_number}: The line was indented #{tab_distance_from(previous_line)} levels deeper than the previous line.")
        end
        
        # Up-front all the burden, except for dynamic content
        prerender_static_content
      end

      def empty?
        @command.nil? || @command.empty?
      end

      def script?
        command[0] == SCRIPT
      end

      # Optinal block incase it's dynamic
      # The fact that there is only 1 self-closing tag makes it VERY easy to work with.  
      # Any differences in tab distance can be attributed to a close div tag, and no other kinds of tags.
      def render(previous_line, &block)
        return '' if empty? # Quit while we're ahead

        buffer = ''
        tab_distance = tab_distance_from(previous_line)

        if tab_distance < 0
          (tab_distance * -1).times { buffer << render_close_div }
        end

        if script?
          buffer << render_script(command, &block)
        else
          buffer << @open_output
        end
        buffer
      end
      
      def tabs
        return @tabs unless @tabs.nil?
        @tabs = empty? ? 0 : @full[/^ */].length / SPACES_PER_TAB
      end

      def parameter
        command[1..-1]
      end

      protected

      def valid_compared_to_previous?(previous_line)
        return false if tab_distance_from(previous_line) > 1
        true
      end
      
      
      private

      def tab_distance_from(another_line)
        tabs - (another_line.nil? ? 0 : another_line.tabs)
      end

      def prerender_static_content
        case command[0]
        when DIV_CLASS, DIV_ID; render_div(command)
        when COMMENT; render_comment(command)
        when SCRIPT; # Dynamic commands here (do nothing). 
        else; raise SyntaxError.new("Line #{line_number}: Unknown ALML command `#{command[0]}'.")
        end
      end

      def render_div(markup)
        render_open_div(markup)
        render_close_div
      end

      def render_open_div(markup)
        id = ''
        only_classes = markup.gsub(/\#[^\.]*/) { |match| id = match[1..-1]; '' }
        class_names = only_classes.split('.').reject { |cn| cn.empty? }.join(' ')
        @open_output = "<div" + (id.empty? ? '' : " id=\"#{id}\"") + (class_names.empty? ? '' : " class=\"#{class_names}\"") + ">"
      end

      def render_close_div
        @close_output = self.class.close_div
      end
      
      def self.close_div
        "</div>"
      end

      def render_comment(markup)
        @open_output = "<!-- " + markup[1..-1] + " -->"
      end

      def render_script(markup, &block)
        block.call(markup[1..-1])
      end
    end

  end
end