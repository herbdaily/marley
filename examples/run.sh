#!/bin/sh

# directory of the marley base directory
MARLEY_DIR=..

# directory of the marley libs
MARLEY_LIB=$MARLEY_DIR/lib

# ruby interpreter to use (1.8, 1.9)
RUBY=ruby
#RUBY=/opt/local/bin/ruby1.9

RUBYLIB=$MARLEY_LIB $RUBY ./simple_forum.rb run

