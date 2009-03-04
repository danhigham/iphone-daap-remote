include BrowseHelper

class BrowseController < ApplicationController
  def index
            
    daap = Net::DAAP::Client.new('192.168.1.5')

    daap.connect do |dsn|        
      daap.databases.each do |db|
        @artists = db.artists
      end

      @groups = @artists.collect { |x| x.name[/^./] }.uniq.sort

    end    
    
  end
  
  def artist
    artist_name = params[:id]
    
    
  end
end
