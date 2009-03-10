# These settings change the behavior of Rails 2 apps and will be defaults
# for Rails 3. You can remove this initializer when Rails 3 is released.

if defined?(ActiveRecord)
  # Include Active Record class name as root for JSON serialized output.
  ActiveRecord::Base.include_root_in_json = true

  # Store the full class name (including module namespace) in STI type column.
  ActiveRecord::Base.store_full_sti_class = true
end

# Use ISO 8601 format for JSON serialized times and dates.
ActiveSupport.use_standard_json_time_format = true

# Don't escape HTML entities in JSON, leave that for the #json_escape helper.
# if you're including raw json in an HTML page.
ActiveSupport.escape_html_entities_in_json = false

$daap_server = 'localhost'

opts = ''
$mplayer_io = IO.popen "mplayer -noconsolecontrols -idle -slave #{opts} 2>&1", 'r+'

$mplayer_out = Hash.new

Thread.new() {
  loop do
    $mplayer_io.each { |line|
      if !line.scan(/\:/).empty?
        k = line.split(/^([^:]+)\:/)[1].strip
        v = line.split(/^([^:]+)\:/)[2].strip
        $mplayer_out[k] = v
       
        RAILS_DEFAULT_LOGGER.info("Mplayer: #{k} :- #{v}") 
      end            
    }
    sleep 0.1
  end
}
