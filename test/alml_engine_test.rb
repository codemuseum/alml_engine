require 'test/unit'
require 'lib/alml_engine'

class AlmlEngineTest < Test::Unit::TestCase
  
  TEST_STR = <<END_OF_STRING

! Start Header
#header.foo.bar
  .ring
    .outer
      .inside
        .lining
          @header-and-logo

! Start Nav
#navigation
  .container
    .inside	
      @navigation

! Start Content
#content
  .inside
    #liquid
      .lining
        @:auto

! Start Footer
#footer
  .outside
    .inside
       @footer-navigation
       @footer-logo

END_OF_STRING


  # Replace this with your real tests.
  def test_simple_render
    
    correct_result = "<!--  Start Header --><div id=\"header\" class=\"foo bar\"><div class=\"ring\"><div class=\"outer\"><div class=\"inside\"><div class=\"lining\">I return the rendered content of header-and-logo at 0<br/>\n</div></div></div></div></div><!--  Start Nav --><div id=\"navigation\"><div class=\"container\"><div class=\"inside\">I return the rendered content of navigation at 1<br/>\n</div></div></div><!--  Start Content --><div id=\"content\"><div class=\"inside\"><div id=\"liquid\"><div class=\"lining\">I return the rendered content of :auto at 2<br/>\n</div></div></div></div><!--  Start Footer --><div id=\"footer\"><div class=\"outside\"><div class=\"inside\">I return the rendered content of footer-navigation at 3<br/>\nI return the rendered content of footer-logo at 4<br/>\n</div></div></div>"
    
    alml = Alml::Engine.new TEST_STR
    rendered_result = alml.render { |dynamic_script_name, script_index| "I return the rendered content of #{dynamic_script_name} at #{script_index}<br/>\n" } 
    
    assert_equal correct_result, rendered_result
  end
  
  def test_scripts
    correct_result = ['header-and-logo', 'navigation', ':auto', 'footer-navigation', 'footer-logo']
    
    alml = Alml::Engine.new TEST_STR
    assert_equal correct_result, alml.scripts

  end
  
  def test_scripts_map
    correct_result = "<!--  Start Header --><div id=\"header\" class=\"foo bar\"><div class=\"ring\"><div class=\"outer\"><div class=\"inside\"><div class=\"lining\">I return the rendered content of header-and-logo<br/>\n</div></div></div></div></div><!--  Start Nav --><div id=\"navigation\"><div class=\"container\"><div class=\"inside\">I return the rendered content of navigation<br/>\n</div></div></div><!--  Start Content --><div id=\"content\"><div class=\"inside\"><div id=\"liquid\"><div class=\"lining\">I return the rendered content of filled0<br/>\nI return the rendered content of filled1<br/>\nI return the rendered content of filled2<br/>\nI return the rendered content of filled3<br/>\nI return the rendered content of notfilled<br/>\n</div></div></div></div><!--  Start Footer --><div id=\"footer\"><div class=\"outside\"><div class=\"inside\">I return the rendered content of footer-navigation<br/>\nI return the rendered content of footer-logo<br/>\n</div></div></div>"
    
    unordered_app_array = ['filled0', 'header-and-logo', 'navigation', 'filled1', 'filled2', 'filled3', 'footer-navigation', 'footer-logo', 'notfilled']
  
    alml = Alml::Engine.new TEST_STR
    script_order_map = alml.script_map(unordered_app_array) { |app, script_name| app == script_name }

    rendered_result = alml.render do |script_name, script_index|
      script_order_map[script_index].collect { |app| "I return the rendered content of #{app}<br/>\n" }.join('')
    end  

    assert_equal correct_result, rendered_result
  end
  
end
