include BrowseHelper

class BrowseController < ApplicationController
  def index
    @artists = get_music_index
    @groups = @artists.collect { |x| x.name[/^./] }.uniq.sort
  end    
        
  def play
    stream_path = '/tmp/stream'
    
    playlist = params[:id].gsub('|', '.').split(',')
    out_playlist = playlist.collect { |x|  "#{stream_path}#{File::SEPARATOR}#{x}\r\n" }
        
    FileUtils::mkdir_p(stream_path)
    FileUtils.rm_r Dir.glob("#{stream_path}/*")

    File.open("#{stream_path}#{File::SEPARATOR}playlist", "wb") { |file|
      file.write out_playlist } 
      
    daap = Net::DAAP::Client.new('localhost')

    daap.connect do |dsn|    
      #Write out first song
      db = daap.databases[0].id
      
      song = playlist.first
      song_url = "databases/#{db}/items/#{song}"
      filename = "#{stream_path}#{File::SEPARATOR}#{song}"

      File.open(filename, "wb") { |file|
        daap.get_song(song_url) { |x|
          #FileUtils::mkdir_p(path)
          file.write x
        } 
      }    
    
      pid = `ps a -o pid,comm | grep mplayer`.scan(/\d+/).to_s
      `kill -9 #{pid}` if !pid.empty?
      
      # Start playing playlist 
      #Open3::popen3 "mplayer -playlist #{stream_path}#{File::SEPARATOR}playlist &"
      system("mplayer -playlist #{stream_path}#{File::SEPARATOR}playlist &")
            
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
    
    render :text => playlist.inspect
  end
end
