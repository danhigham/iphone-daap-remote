require 'rubygems'
require 'net/daap'
require 'fileutils'
require 'ruby-debug'

module BrowseHelper
  def get_music_index
      daap = Net::DAAP::Client.new('192.168.1.5')

      daap.connect do |dsn|        
        daap.databases.each do |db|
          return db.artists
        end
      end   
  end
  
  def download_song
    
  end
end


module Net
  module DAAP
  # This class contains a database found on an iTunes server.
    class Database
      attr_reader :persistentid, :name, :containercount, :id, :itemcount
      attr_blockreader :songs, :artists, :albums

      @@SONG_ATTRIBUTES = %w{ dmap.itemid 
                              dmap.itemname 
                              dmap.persistentid
                              daap.songalbum
                              daap.songartist 
                              daap.songformat
                              daap.songsize 
                              daap.songtracknumber 
                              daap.songdataurl }

      def initialize(args)
        @persistentid   = args['dmap.persistentid']
        @name           = args['dmap.itemname']
        @containercount = args['dmap.containercount']
        @id             = args['dmap.itemid']
        @itemcount      = args['dmap.itemcount']
        @daap           = args[:daap]
        @songs          = []
        @artists        = []
        @albums         = []
        load_songs
      end

# Returns the playlists associated with this database
      def playlists
        url = "databases/#{@id}/containers?meta=dmap.itemid,dmap.itemname,dmap.persistentid,com.apple.itunes.smart-playlist"
        res = @daap.do_get(url)

        listings = @daap.dmap.find(res, "daap.databaseplaylists/dmap.listing")

        playlists = []
        @daap.unpack_listing(listings) do |value|
          playlist = Playlist.new( value.merge( 
                                    :daap     => @daap,
                                    :db       => self ))
          if block_given?
            yield playlist
          else
            playlists << playlist
          end
        end
        playlists
      end

      private
      def load_songs
        path = "databases/#{@id}/items?type=music&meta="
        path += @@SONG_ATTRIBUTES.join(',')

        listings = @daap.dmap.find(@daap.do_get(path),
                             "daap.databasesongs/dmap.listing")
        artist_hash = {}
        album_hash  = {}
        @daap.unpack_listing(listings) do |value|
        
          artist  = artist_hash[value['daap.songartist']] ||= Artist.new(value)
          album   = album_hash[value['daap.songalbum']]   ||= Album.new(
                              :name   => value['daap.songalbum'],
                              :artist => artist )

          song = Song.new(  value.merge(
                            :daap      => @daap,
                            :db        => self,
                            :artist    => artist,
                            :album     => album))

          album.songs   << song
          artist.songs  << song
          @songs        << song
        end

        # Add each album to its artist
        album_hash.each_value do |value|
          value.artist.albums << value
          @albums << value
        end

        artist_hash.each_value { |v| @artists << v }
      end
    end
# This class contains song information returned from the DAAP server.
    class Song
      include Comparable
      attr_reader :size, :album, :name, :artist, :format, :persistentid, :id, :tracknum, :dataurl
      attr_accessor :path, :file

      alias :to_s :name

      def initialize(args)
        @size           = args['daap.songsize']
        @album          = args[:album]
        @name           = args['dmap.itemname']
        #@artist         = args['daap.songartist']
        @artist         = args[:artist]
        @format         = args['daap.songformat']
        @persistentid   = args['dmap.persistentid']
        @id             = args['dmap.itemid']
        @tracknum       = args['daap.songtracknumber']
        @dataurl        = args['daap.songdataurl']
        @daap           = args[:daap]
        @db             = args[:db]
        @path = [@artist.name, @album.name].collect { |name|
          name.gsub(File::SEPARATOR, '_') unless name.nil?
        }.join(File::SEPARATOR)
        
        @file = @file.nil? ? "" : "#{@name.gsub(File::SEPARATOR, '_')}.#{@format}"
      end

# Fetches the song data from the DAAP server and returns it.
      def get(&block)
        filename = "#{@id}.#{@format}"
        @daap.get_song("databases/#{@db.id}/items/#{filename}", &block)
      end

      def save(basedir = nil)
        path = "#{basedir}#{File::SEPARATOR}#{@path}"
        FileUtils::mkdir_p(path)
        filename = "#{path}#{File::SEPARATOR}#{@file}"
        File.open(filename, "wb") { |file|
          get do |str|
            file.write str
          end
        }
        @daap.log.debug("Saved #{filename}") if @daap.log
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end
end
