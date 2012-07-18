class PersistentCache

def initialize
	@fetchers = Hash.new
end

def init_with_fetcher(name, fetcher)
	@fetchers[name]=fetcher
end

def [](name)
	should_fetch=true
	filename = name.to_s+".cache.yaml"
	if File.exists? filename then
		last_fetched = File.mtime filename
		difference = Time.now - last_fetched
		difference = difference.to_i
		should_fetch = difference > @@fetch_delay
	end
	if should_fetch then
		#puts "fetching "+name.to_s
		data = @fetchers[name].call
		File.open(filename,'w') do|file|
			file.puts data.to_yaml
		end
	else
		#puts "loading "+name.to_s+" from file"
		data = YAML::load(File.read(filename))
	end
	data
end


private

@@fetch_delay = 120

end
