require 'rest_client'

host = 'localhost:4567'

puts "Please enter the name of your stream:"
stream = gets.chomp
stream_sanitized = stream.gsub(/[^A-Za-z]/, '')
stream = stream_sanitized

puts "You can watch this stream at http://#{host}/watch/#{stream}"

response = RestClient.put "http://#{host}/update/#{stream}",
                            :file => File.new("capture.jpg", 'rb')

puts response.code
