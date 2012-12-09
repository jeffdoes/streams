require 'sinatra'
require 'kramdown'
require 'json'
require 'haml'

set :streams, {}

def put_stream id, data
  settings.streams[id] = {:data => data, :version => Time.now.to_i}
  settings.streams[id][:version]
end

def get_stream id
  settings.streams[id]
end

#ENV['RACK_ENV'] = "production"

# simplify, simplify
#

get '/streams/:id.*' do
  content_type 'image/jpeg' # change content type for image type?
  stream = get_stream params[:id]
  stream.data
end

put '/streams/:id.*' do
  content_type :json
  version = put_stream params[:id], request.body.read

  # version (time travel)
  {:version => version}.to_json
end

get '/watch/:id' do
  haml :watch
  end
  
post '/stream_has_been_updated' do
  content_type :json
  answer = 'no'

  id = request.referrer.split('/')[-1]
  version = params[:version].to_i

  stream = get_stream id

  if stream && version < stream[:version]
    answer = 'yes'
  end

  {:answer => answer}.to_json
end

get '/' do
  @rand_src = nil
  @streams = settings.streams
  if settings.streams.empty?
    @rand_src = "/no.jpeg"
  else
    @rand_src = "/streams/#{settings.shuffle[0]}"
  end
  haml :index, :format => :html5
end

get '/streams.json' do
  streams.to_json
end

get '/client/' do
  # instructions for client
  markdown :client
end

get '/client' do
  redirect '/client/'
end

get '/watch' do
  redirect '/watch/'
end

get '/watch/' do
  redirect '/'
end

# think about end points
get '/endless' do
  redirect '/endless/'
end

get '/endless/' do
  haml :endless
end

