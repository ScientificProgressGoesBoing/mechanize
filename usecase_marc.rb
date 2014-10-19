#Requires Ruby 1.9.3 or higher
       
require 'rubygems'
require 'mechanize'
require 'logger'


#preparation
class HelpfulRobot

  attr_reader :agent

  def initialize
    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.ssl_version, agent.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE
      agent.log = Logger.new('mechanize.log')
      agent.keep_alive = false
    }
  end
  
end 


class Scraper

  attr_accessor :base_url, :ext, :dir_name, :robot

  def initialize(base_url, ext = '.html', dir_name = 'new')   
    @base_url = base_url
    @ext = ext
    @dir_name = dir_name
    @robot = HelpfulRobot.new.agent
  end
  
  def clean_title_for_filename( page )
    #clean page title from characters that cannot be part of filenames
    if not page.title == nil
      titletext  =  page.title.gsub(/\s{2,}/," ").strip
      titletext  =  titletext.gsub(/\t/," ").strip
      titletext  =  titletext.gsub(/\//," - ").strip
      titletext  =  titletext.gsub(/:/," - ").strip
      titletext  =  titletext.gsub(/\r/," ").strip
      titletext  =  titletext.gsub(/\n/," ").strip
    else 
      titletext = ''
    end 
    titletext
  end

  def go(start_value = 0, end_value = 900)        
    #parameters
    n = start_value
    marc = []
    separator = '--------------------------------------'
    #loop
    loop do
      begin   
        #right align incremented url snippet
        limit = 3 - n.to_s.length
        i = 0
        right_align = ''        
        while i < limit do	
          right_align += '0'
          i+=1
        end   
        #condition
      break if n == end_value 
        #go
        url = self.base_url + right_align + n.to_s() + self.ext
        puts url
        page = self.robot.get( url ) 
        #check
        if page.body.include?( 'No indicators or subfield codes.' ) || page.body.include?(  'no indicators or subfield codes' ) 
          filename = File.basename(url, '.htm')
          #page_title = clean_title_for_filename( page )
          page.save_as self.dir_name + '/' + filename
          puts 'yay!'
        end
        #collect existing MARC21 tags
        marc << n
        #increment
        n += 1
        sleep(0.1)            
        #error handling
        rescue Mechanize::ResponseCodeError 
          puts 'Seite antwortet nicht >>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
          n += 1  #anscheinend, wenn ein Error ausgelöst wird, wird das Inkrement in dem Durchlauf nicht ausgeführt, egal, wo es steht
          next    #continue
        #rescue Mechanize::ArgumentError
          #puts 'ArgumentError >>>>>>>>>>>'
        rescue Net::HTTPError => e
          if e.message == '404 Not Found'
            #handle 404 error
            puts 'Page not found >>>>>>>>>>>>>>>>>>>>>>>>>'
            n += 1
            next
          else
            raise e
          end  
        end
        #for readability
        puts separator
        
    end #end loop
    #puts existing MARC21 tags
    puts marc
  end
  
end


#main
#parameters
base_url = 'http://www.loc.gov/marc/bibliographic/bd'
ext = '.html'
Scraper.new( base_url ).go



    
    