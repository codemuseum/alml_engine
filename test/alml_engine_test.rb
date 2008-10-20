require 'test/unit'
require 'lib/alml_engine'

class AlmlEngineTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_simple_render
    str = <<END_OF_STRING
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
    
    correct_result = "<!--  Start Header --><div id=\"header\" class=\"foo bar\"><div class=\"ring\"><div class=\"outer\"><div class=\"inside\"><div class=\"lining\">I return the rendered content of header-and-logo at 0<br/>\n</div></div></div></div></div><!--  Start Nav --><div id=\"navigation\"><div class=\"container\"><div class=\"inside\">I return the rendered content of navigation at 1<br/>\n</div></div></div><!--  Start Content --><div id=\"content\"><div class=\"inside\"><div id=\"liquid\"><div class=\"lining\">I return the rendered content of :auto at 2<br/>\n</div></div></div></div><!--  Start Footer --><div id=\"footer\"><div class=\"outside\"><div class=\"inside\">I return the rendered content of footer-navigation at 3<br/>\nI return the rendered content of footer-logo at 4<br/>\n</div></div></div>"
    
    alml = Alml::Engine.new str
    rendered_result = alml.render { |dynamic_script_name, script_index| "I return the rendered content of #{dynamic_script_name} at #{script_index}<br/>\n" } 
    
    assert_equal rendered_result, correct_result
  end
  
  def test_scripts
    str = <<END_OF_STRING
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
    
    correct_result = ['header-and-logo', 'navigation', ':auto', 'footer-navigation', 'footer-logo']
    
    
    alml = Alml::Engine.new str
    assert_equal alml.scripts, correct_result

  end
end
