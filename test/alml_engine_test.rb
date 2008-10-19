require 'test/unit'
require 'lib/alml_engine'

class AlmlEngineTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_simple_render
    str = <<END_OF_STRING
! Start Header
#header
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
    
    correct_result = "<!--  Start Header --><div id=\"header\"><div class=\"ring\"><div class=\"outer\"><div class=\"inside\"><div class=\"lining\">I return the rendered content of header-and-logo<br/>\n</div></div></div></div></div><!--  Start Nav --><div id=\"navigation\"><div class=\"container\"><div class=\"inside\">I return the rendered content of navigation<br/>\n</div></div></div><!--  Start Content --><div id=\"content\"><div class=\"inside\"><div id=\"liquid\"><div class=\"lining\">I return the rendered content of :auto<br/>\n</div></div></div></div><!--  Start Footer --><div id=\"footer\"><div class=\"outside\"><div class=\"inside\">I return the rendered content of footer-navigation<br/>\nI return the rendered content of footer-logo<br/>\n</div></div></div>"
    
    alml = Alml::Engine.new str
    rendered_result = alml.render { |dynamic_script_name| "I return the rendered content of #{dynamic_script_name}<br/>\n" } 
    
    assert_equal rendered_result, correct_result
  end
end
