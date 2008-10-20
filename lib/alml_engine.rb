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

    # Helps to order the scripts, sending in a block to evaluate equality
    # Returns an array, indexed by script_index, with all the objects in them 
    # that should be mapped, according to the layout (including :auto script keyword)
    def script_map(objects_to_map_array, &block)
      objs = objects_to_map_array.dup
      ss = scripts
      script_map_array = Array.new(ss.length + 1)
      auto_fill_index = -1
      last_auto_index = -1 # Filled with anything remaining
      
      ss.each_with_index do |script_param, script_index|
        if script_param == ':auto'
          script_map_array[script_index] = Array.new
          last_auto_index = auto_fill_index = script_index
        elsif auto_fill_index != -1
          while auto_fill_index != -1 && obj = objs.shift
            if block.call(obj, script_param) # Next item matches
              script_map_array[script_index] = [obj]
              auto_fill_index = -1
            else
              script_map_array[auto_fill_index] << obj
            end
          end
        else
          # Essentially, delete_first_if (&block)
          found_at = nil
          objs.each_with_index { |obj, i| found_at = i if block.call(obj, script_param) }
          script_map_array[script_index] = objs.delete_at(found_at) if found_at
        end
      end
      
      # Remaining, fill in auto; otherwise, just put it all the way at the end
      if last_auto_index != -1
        script_map_array[last_auto_index].concat(objs)
      else
        script_map_array << objs
      end
      
      script_map_array
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
      script_index = [0] # So we can pass by reference
      @lines.each do |line|
        buffer << line.render(prev_l, script_index, &block)
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
      def render(previous_line, script_index, &block)
        return '' if empty? # Quit while we're ahead
        buffer = ''

        tab_distance = tab_distance_from(previous_line)
        if tab_distance < 0
          (tab_distance * -1).times { buffer << render_close_div }
        elsif tab_distance == 0 && !previous_line.nil? && previous_line.requires_closing?
          buffer << render_close_div # same level divs
        end

        if script?
          buffer << render_script(command, script_index[0], &block)
          script_index[0] += 1
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
      
      def requires_closing?
        command[0] == DIV_CLASS || command[0] == DIV_ID
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

      def render_script(markup, script_index, &block)
        block.call(markup[1..-1], script_index)
      end
    end

  end
end