include BrowseHelper

class BrowseController < ApplicationController
  layout 'application', :except => [:play, :currentinfo, :nowplaying]

  def index
    @artists = get_music_index
    @groups = @artists.collect { |x| (x.name || "-")[/^./] }.uniq.sort
  end    
        
  def play
    stream_path = '/tmp/stream'
    
    playlist = params[:id].gsub('|', '.').split(',')
    out_playlist = playlist.collect { |x|  "#{stream_path}#{File::SEPARATOR}#{x}\r\n" }
    
    FileUtils::mkdir_p(stream_path)
    FileUtils.rm_r Dir.glob("#{stream_path}/*")

    File.open("#{stream_path}#{File::SEPARATOR}playlist", "wb") { |file|
      file.write out_playlist } 
      
    daap = Net::DAAP::Client.new($daap_server)

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
    
      #pid = `ps a -o pid,comm | grep mplayer`.scan(/\d+/).to_s
      #`kill -9 #{pid}` if !pid.empty?
      
      # Start playing playlist 
      
      cmd = "loadlist #{stream_path}#{File::SEPARATOR}playlist"
     # $mplayer_out = Hash.new if $mplayer_out.nil?
      
     # Thread.new() {
     #    RAILS_DEFAULT_LOGGER.info("playing... #{cmd}")
      
         $mplayer_io.puts cmd
                
     #    $mplayer_io.each {|line|
     #       if !line.scan(/\:/).empty?
     #         k = line.split(/^([^:]+)\:/)[1].strip
     #         v = line.split(/^([^:]+)\:/)[2].strip
     #         $mplayer_out[k] = v
     #        
     #         RAILS_DEFAULT_LOGGER.info("Mplayer: #{k} :- #{v}") 
     #       end            
     #    }
     # }

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

    @artist = $mplayer_out['Artist']     
    @track_name = $mplayer_out['Title']
  end
  
  def currentinfo
    @artist = $mplayer_out['Artist']     
    @track_name = $mplayer_out['Title']
  end
  
  def nowplaying
    @artist = $mplayer_out['Artist']     
    @track_name = $mplayer_out['Title']  
  end
  
end
