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
    s = "#{title}#{subtitle} ==================\n"+
    "  #{author}\n" +
    "  #{link_path}\n"
    s += "  epub\n" if self.as_epub
    s += "  pdf\n" if self.as_pdf
    s += "  audio\n" if self.as_audio
    s += "  kindle\n" if self.as_kindle
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
  
  def run
    unless @options[:query]
      puts "Not enough options specified. Need -f, -t and -m. Try -h"
      exit
    end
    
    query = @options[:query]
    
    puts "Searching for '#{query}'"
    
    url = 'http://oakland.lib.overdrive.com/'
    
    agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
    
    agent.get(url) do |page|
      search_result = page.form_with(:name => 'freeform') do |search|
        search['FullTextCriteria'] = query
      end.submit
      # page.search('h2[@class="subtitle"]').first.inner_html.strip
      # times = page.search('//div[@class="content"]/div[@class="datetime"]').first.inner_html.strip
      # location = page.search('//div[@class="content"]/div[@class="location"]').first.inner_html.strip
      
      puts '--------------'
      results = {}
      
      search_result.search('td').each_with_index do |td, ti|
        #puts "TD #{ti} &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        title_links = td.search('b/a')
        if title_links && title_links.size==1
          result = Result.new
          
          anchor = title_links.first
          result.title = anchor.inner_html
          result.link_path = anchor["href"]
          
          #puts "TD LINK #{ti} &^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^&^"
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
          
          result.as_audio = !td.search('//img[@alt="OverDrive WMA Audiobooks"]').empty?
          result.as_epub = !td.search('//img[@alt="Adobe EPUB eBook"]').empty?
          result.as_pdf = !td.search('//img[@alt="Adobe PDF eBook"]').empty?
          result.as_kindle = !td.search('//img[@alt="Kindle Book"]').empty?
          
          results[result.link_path] = result
        end
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
