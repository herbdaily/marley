module Marley
  #
  # Here we define the Jamaica client class for Marley.  This client
  # is a simple HTML page that is intended to be run in a browser.
  # It will have its actual UI metadata in the global variable '_jamaica_json'
  # and onDocumentReady, this will be turned into the client UI.
  #
  CLIENT_DIR=File.dirname(__FILE__)
  LIBS = [ 'jquery-1.6.2.js', 'jquery.form.js', 'jamaica.js' ]
  STYLES = [ 'jamaica.css' ]
  class Client
    def initialize(opts={})
      @opts={:name => 'Application',:css => '', :js => ''}.merge(opts)
    end
    def css(add_css=nil)
      @opts[:css]+=add_css if add_css
      @opts[:css]
    end
    def js(add_js=nil)
      @opts[:js]+=add_js if add_js
      @opts[:js]
    end
    def to_s(json='')
      <<-EOHTML
      <head>
        <title>#{@opts[:app_name]}</title>
        <script type='text/javascript'>var _jamaica_json=#{json};</script>
        <script type='text/javascript'>#{ LIBS.map{ |x| File.new("#{CLIENT_DIR}/" + x).read }.push(@opts[:js]).join("\n") }</script>
        <style>#{ STYLES.map{ |x| File.new("#{CLIENT_DIR}/" + x).read }.push(@opts[:css]).join("\n") }
      </head>
      <body></body>
      EOHTML
    end
  end
end
