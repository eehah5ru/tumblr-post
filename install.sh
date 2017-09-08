#!/bin/sh

echo "installing rvm" && `\curl -sSL https://get.rvm.io | bash -s stable`

echo "installing ruby 2.4" && rvm install ruby-2.4

echo "installing required gems" && rvm ruby-2.4 do gem install tumblr_client colorize faraday nokogiri

echo "installing oauth and oauth2 pip modules" && pip install oauth oauth2

echo "creating ~/bin directory" && mkdir -p ~/bin

echo "creating ~/log directory" && mkdir -p ~/log

echo "installing binaries" &&
    ln -s hazel-tumblr-post-link ~/bin/hazel-tumblr-post-link &&
    ln -s hazel-tumblr-post-photo ~/bin/hazel-tumblr-post-photo &&
    ln -s hazel-tumblr-post-quote ~/bin/hazel-tumblr-post-quote &&
    ln -s tumblr-post.rb
