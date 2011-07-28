module Marley
  CLIENT_DIR=File.dirname(__FILE__)
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
        <script type='text/javascript'>var json=#{json};</script>
        <script type='text/javascript'>#{File.new("#{CLIENT_DIR}/jquery-1.4.3.min.js").read}</script>
        <script type='text/javascript'>#{File.new("#{CLIENT_DIR}/jquery.form.js").read}</script>
        <script type='text/javascript'>#{File.new("#{CLIENT_DIR}/jamaica.js").read}</script>
        <script type='text/javascript'>#{@opts[:js]}</script>
        <style>#{File.new("#{CLIENT_DIR}/jamaica.css").read}</style>
        <style>#{@opts[:css]}</style>
      </head>
      <body></body>
      EOHTML

    end
  end
end
