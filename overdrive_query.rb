#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'mechanize'

$: << File.dirname(__FILE__)

require "pp"

class Result
  attr_accessor :title, :subtitle, :link_path, :author,
                :as_epub, :as_pdf, :as_audio, :as_kindle
  
  def to_s
    s = <<-DUMP
======
#{title}: #{subtitle}
  author: #{author}
    link: #{link_path}
DUMP
    s += "  format: epub\n" if self.as_epub
    s += "  format: pdf\n" if self.as_pdf
    s += "  format: audio\n" if self.as_audio
    s += "  format: kindle\n" if self.as_kindle
    s
  end
end

class SendMessage
  def initialize
    @options = {}

    optparse = OptionParser.new do|opts|
      # Set a banner, displayed at the top
      # of the help screen.
      opts.banner = "Usage: #{__FILE__} [options]"

      # Define the options, and what they do
      @options[:verbose] = false
      opts.on( '-v', '--verbose', 'Output more information' ) do
        @options[:verbose] = true
      end

      @options[:debug] = false
      opts.on( '--debug', 'Output even more information' ) do
        @options[:debug] = true
      end

      @options[:query] = nil
      opts.on( '-q', '--query text', 'The text query' ) do |t|
        @options[:query] = t
      end

      @options[:isbn] = nil
      opts.on( '-i', '--isbn number', 'Lookup by ISBN' ) do |isbn|
        @options[:isbn] = isbn
      end

      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end
    
    optparse.parse!
    
    if @options[:debug]
      puts "Options:"
      pp @options
    end
  end
  
  def do_text_query(page)
    query = @options[:query]
    puts "Searching for '#{query}'"

    search_result = page.form_with(:name => 'freeform') do |search|
      search['FullTextCriteria'] = query
    end.submit
    
    return parse_results(search_result)
  end

  def do_isbn_query(page)
    isbn = @options[:isbn]
    puts "Searching for 'isbn=#{isbn}'"

    page = page.link_with(:text => 'Advanced search...').click
    
    search_result = page.form_with(:action => 'BANGSearch.dll') do |search|
      search['ISBN'] = isbn
    end.submit
    
    return parse_results(search_result)
  end
  
  def parse_results(search_result)
    results = {}
    
    search_result.search('td').each_with_index do |td, ti|
      title_links = td.search('b/a')
      if title_links && title_links.size==1
        result = Result.new
        
        anchor = title_links.first
        result.title = anchor.inner_html
        result.link_path = anchor["href"]
        
        small_elements = td.search('div/small')
        small_elements.each do |small_element|
          #puts "********************************"
          #pp small_element
          subtitle_element = small_element.search('b')
          unless subtitle_element.empty?
            result.subtitle = ": #{subtitle_element.inner_html}"
          end

          is_author_element = small_element.search('noscript')
          unless is_author_element.empty?
            result.author = small_element.children.last.text.strip
          end
        end
        
        # The 4th TR down will contain the associated formats
        if td.path =~ %r(/html/body/table\[3\]/tr/td\[3\]/table\[3\]/tr\[(\d+)\]/td\[3\]/table/tr/td\[1\])
          title_tr_index = $1
          formats_tr_index = $1.to_i + 4
          formats_tr = search_result.parser.xpath("/html/body/table[3]/tr/td[3]/table[3]/tr[#{formats_tr_index}]")
          
          result.as_audio = !formats_tr.search('img[@alt="OverDrive WMA Audiobooks"]').empty?
          result.as_epub = !formats_tr.search('img[@alt="Adobe EPUB eBook"]').empty?
          result.as_pdf = !formats_tr.search('img[@alt="Adobe PDF eBook"]').empty?
          result.as_kindle = !formats_tr.search('img[@alt="Kindle Book"]').empty?

          results[result.link_path] = result
        end
      end
    end
    results  end 
  
  def run
    unless @options[:query] || @options[:isbn]
      puts "Not enough options specified. Need -q or -i. Try -h"
      exit
    end
    
    url = 'http://oakland.lib.overdrive.com/'
    
    agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
    
    agent.get(url) do |page|
      results = if @options[:isbn]
        do_isbn_query(page)
      else
        do_text_query(page)
      end
      
      results.keys.each do |key|
        puts results[key]
      end
    end
    
    
  end
end

if __FILE__ == $0
  ARGV << '-h' if ARGV.length == 0
    
  script = SendMessage.new
  script.run
end
