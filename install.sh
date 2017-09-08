#!/bin/sh

function confirm() {
    local response
    local msg="${1:-Are you sure?} [y/N] "; shift
    read -r $* -p "$msg" response || echo
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

echo "installing rvm" && confirm && `\curl -sSL https://get.rvm.io | bash -s stable`

echo "installing ruby 2.4" && confirm && rvm install ruby-2.4

echo "installing required gems" && confirm && rvm ruby-2.4 do gem install tumblr_client colorize faraday nokogiri

echo "installing oauth and oauth2 pip modules" && confirm && pip install oauth oauth2

echo "creating ~/bin directory" && confirm && mkdir -p ~/bin

echo "creating ~/log directory" && confirm && mkdir -p ~/log

echo "removing old binaries" &&
    confirm &&
    rm -f ~/bin/hazel-tumblr-post-link \
       ~/bin/hazel-tumblr-post-photo \
       ~/bin/hazel-tumblr-post-quote \
       ~/bin/tumblr-post.rb

echo "installing binaries" &&
    confirm &&
    ln -s `pwd`/hazel-tumblr-post-link ~/bin/hazel-tumblr-post-link &&
    ln -s `pwd`/hazel-tumblr-post-photo ~/bin/hazel-tumblr-post-photo &&
    ln -s `pwd`/hazel-tumblr-post-quote ~/bin/hazel-tumblr-post-quote &&
    ln -s `pwd`/tumblr-post.rb ~/bin/tumblr-post.rb
