#!rvm ruby-2.4 do ruby
require "rubygems"

require 'ostruct'
require 'optparse'
# require 'optparse/time'
require "tumblr_client"
require "colorize"
require 'yaml'
require "faraday"
require 'open-uri'
require "nokogiri"
require "nokogiri/html"
require "pp"



module Dialog
  def slurp_from_dialog a_caption
    raw = IO.popen(%(osascript -e ' display dialog "#{a_caption}" default answer ""')).read

    return "" if raw.empty?
    return "" unless raw =~ /OK/
    return raw.gsub(/button returned:OK, text returned:/, "")

  end
end

module TumblrPostOptsParser
  def self.parse!
    opts = OpenStruct.new

    a_parser = parser(opts)

    begin
      # a_parser.parse!

      a_parser.parse!(ARGV)

      raise OptionParser::MissingArgument, "BLOG_NAME" if opts.blog_name.nil?
      raise OptionParser::MissingArgument, "POST_TYPE" if opts.type.nil?

      Post.parse_argv! ARGV, opts

      Post.check_options! opts

      return opts
    rescue RuntimeError => e
      STDERR.puts "Error: #{e}"
      STDERR.puts a_parser.help

      exit 1
    end
  end

  private

  def self.parser (options)
    options.verbose = false
    # options.type = :text

    return OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [options] [BODY|PHOTO_PATH|QUOTE|URL]"

      opts.separator ""
      opts.separator "options are:"

      opts.on("-v", "--[no-]verbose", "run verbosely") do |v|
        options.verbose = v
      end

      opts.on("-t", "--post-type POST_TYPE", [:text, :photo, :quote, :link], "Type of post (text, photo)") do |t|
        options.type = t.to_sym
      end

      opts.on("-b", "--blog-name BLOG_NAME", "Name of the blog") do |b_name|
        options.blog_name = b_name
      end
    end
  end
end

BLOG = "h0k0"

class TumblrConfig
  attr_reader :options

  def initialize (options)
    @options = options
  end

  def blog_name
    return BLOG
  end

  def blog_url
    return "#{BLOG}.tumblr.com"
  end

  def auth
    @auth = read_tumblr_config if @auth.nil?
    return @auth
  end

  private

  def read_tumblr_config
    f = IO.popen("gpg -d ~/.tumblr.yml.gpg")
    return YAML.load(f.read)
  end

end


module Post
  #
  #
  # TYPE UTILS
  #
  #
  module Types
    #
    # predicates
    #
    def self.text? options
      return type? options, :text
    end

    def self.photo? options
      return type? options, :photo
    end

    def self.quote? options
      return type? options, :quote
    end

    def self.link? options
      return type? options, :link
    end

    def self.type? options, e_type
      return get_options(options).type == e_type
    end

    private

    #
    # wrap config and options in one getter
    #
    def self.get_options o
      return o.options if o.instance_of? TumblrConfig
      return o
    end

  end

  #
  #
  # ABSTRACT POST
  #
  #
  class AbstractPost

    def initialize (options)
      @opts = options
    end

    def post client
      raise "unimplemented"
    end

    def parse_argv! argv
      raise "unimplemented"
    end

    def check_options!
      raise "unimplemented"
    end

    protected

    def options
      return @opts.options if @opts.instance_of? TumblrConfig
      return @opts
    end

    def config
      raise "there is no config" unless @opts.instance_of? TumblrConfig
      return @opts
    end
  end

  #
  #
  # TEXT POST
  #
  #
  class TextPost < AbstractPost
    def parse_argv! argv
      raise OptionParser::MissingArgument, "BODY" if argv.empty?
      options.body = argv[0]

      return options
    end

    def check_options!
      raise OptionParser::MissingArgument, "BODY" if options.body.nil?
    end

    def post client
      client.text config.blog_url, body: options.body
    end
  end

  #
  #
  # PHOTO POST
  #
  #
  class PhotoPost < AbstractPost
    include Dialog

    def parse_argv! argv
      raise OptionParser::MissingArgument, "PHOTO_PATH" if argv.empty?
      options.photo_path = argv[0]
      return options
    end

    def check_options!
      raise OptionParser::MissingArgument, "PHOTO_PATH" if options.photo_path.nil?
    end

    def post client
      client.photo config.blog_url, data: [options.photo_path], caption: slurp_from_dialog("Photo caption/source:")
    end
  end

  #
  #
  # QUOTE POST
  #
  #
  class QuotePost < AbstractPost
    include Dialog

    def parse_argv! argv
      raise OptionParser::MissingArgument, "QUOTE" if argv.empty?
      options.quote = argv[0]
      return options
    end

    def check_options!
      raise OptionParser::MissingArgument, "QUOTE" if options.quote.nil?
    end


    def post client
      client.quote config.blog_url, quote: options.quote, source: slurp_from_dialog("Quote source:")
    end
  end

  #
  #
  # LINK POST
  #
  #
  class LinkPost < AbstractPost
    def parse_argv! argv
      raise OptionParser::MissingArgument, "URL" if argv.empty?
      options.url = argv[0]
      return options
    end

    def check_options!
      raise OptionParser::MissingArgument, "URL" if options.url.empty?
    end

    def post client
      client.link config.blog_url, url: options.url, title: get_title
    end

    private

    def get_title
      d = Nokogiri::HTML(Faraday.get(options.url).body)
      return d.at_css('title').text
    end
  end


  #
  #
  # POST FACTORY METHOD
  #
  #
  def self.get options
    return TextPost.new(options) if Types.text? options
    return PhotoPost.new(options) if Types.photo? options
    return QuotePost.new(options) if Types.quote? options
    return LinkPost.new(options) if Types.link? options

    raise "unknown post type: #{options.type}"
  end

  #
  # parse argv depending on post type
  #
  def self.parse_argv! argv, opts
    return get(opts).parse_argv!(argv)
  end

  #
  # check type dependent options consistency
  #
  def self.check_options! opts
    return get(opts).check_options!
  end
end

# TUMBLR_CONFIG = read_tumblr_config

opts = TumblrPostOptsParser.parse!

options = TumblrConfig.new opts

Tumblr.configure do |c|
  c.consumer_key = options.auth["tumblr_auth"]["consumer_key"]
  c.consumer_secret = options.auth["tumblr_auth"]["consumer_secret"]
  c.oauth_token = options.auth["tumblr_auth"][options.blog_name]["oauth_token"]
  c.oauth_token_secret = options.auth["tumblr_auth"][options.blog_name]["oauth_secret"]
end

client = Tumblr::Client.new

Post.get(options).post(client)


# client.text blog_url, title: "test", body: "test again"
# pp client.posts("h0k0.tumblr.com")
