include BrowseHelper

class BrowseController < ApplicationController
  
  layout 'application', :except => :play
  
  def index
    @artists = get_music_index
    @groups = @artists.collect { |x| x.name[/^./] }.uniq.sort
  end    
        
  def play
    stream_path = '/tmp/stream'
    
    playlist = params[:id].gsub('|', '.').split(',')
    out_playlist = playlist.collect { |x|  "#{stream_path}#{File::SEPARATOR}#{x}" }
    
    FileUtils::mkdir_p(stream_path)
    FileUtils.rm_r Dir.glob("#{stream_path}/*")
      
    daap = Net::DAAP::Client.new('localhost')

    daap.connect do |dsn|    
      #Write out first song
      db = daap.databases[0].id
      
      song = playlist.first
      song_url = "databases/#{db}/items/#{song}"
      filename = "#{stream_path}#{File::SEPARATOR}#{song}"

      File.open(filename, "wb") { |file|
        daap.get_song(song_url) { |x|
          file.write x
        } 
      }    
    
      @@player.stop
      @@player.playlist = out_playlist
      #@@player.play
    
      if (playlist.length > 1)
        (1..playlist.length-1).each { |z|
          song = playlist[z]
          song_url = "databases/#{db}/items/#{song}"
          filename = "#{stream_path}#{File::SEPARATOR}#{song}"

          File.open(filename, "wb") { |file|
        
            daap.get_song(song_url) { |x|
              #FileUtils::mkdir_p(path)
              file.write x
            } 
          }
        }
      end 
    end
    
  end
end
