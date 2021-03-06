require_relative '../streams'
require 'test/unit'
require 'rack/test'

class StreamsTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    # start with no streams
    settings.streams.delete_if { true }
  end

  def test_random_stream_gives_us_a_green_screen_with_no_streams
    get '/random'

    json_response = JSON.parse last_response.body
    assert_equal '/img/no.jpg', json_response['src']
  end

  def test_random_stream_gives_up_only_stream_with_one_stream
    put '/streams/beano.jpg', 'british pounds'
    get '/random'

    json_response = JSON.parse last_response.body
    assert_equal '/streams/beano.jpg', json_response['src']
  end

  def test_updating_a_stream
    start_time = Time.now.to_i

    # put, because the same data creates the same _resource_
    # (even if that resource may have different attributes,
    # like when it was last updated)
    put '/streams/radiohead.jpg', 'in rainbows'
    # assert_equal last_request.body.read, 'in rainbows'

    # take a number
    json_response = JSON.parse last_response.body
    version = json_response['version']

    assert version >= start_time, "#{version} should be later than #{start_time}"
  end

  # pollute
  def test_should_update_if_no_streams_exist
    post '/stream_has_been_updated', {}, 'HTTP_REFERER' =>
      'http://localhost:4567/watch/coming_to_america'

    json_response = JSON.parse last_response.body
    assert_equal 'no', json_response['answer']
  end

  def test_different_image_types_write_to_same_stream
    put '/streams/stones_throw.jpg', 'organ sounds'
    put '/streams/stones_throw.tiff', 'synthesizer'

    stream = get_stream 'stones_throw'

    assert_equal stream[:data], 'synthesizer'
  end

  def test_my_version_is_earlier_than_latest_version
    put '/streams/shabazz.jpg', 'black up'

    post '/stream_has_been_updated', {:version => 0},
      'HTTP_REFERER' => 'http://localhost:4567/watch/shabazz'

    json_response = JSON.parse last_response.body
    assert_equal 'yes', json_response['answer']
  end

  def test_my_version_is_same_as_latest_version
    put '/streams/busta.png', 'new york sh*t'
    stream = get_stream 'busta'
    latest_version = stream[:version]

    post '/stream_has_been_updated', {:version => latest_version},
      'HTTP_REFERER' => 'http://localhost:4567/watch/busta'

    json_response = JSON.parse last_response.body
    assert_equal 'no', json_response['answer']
  end

  def test_get_latest_version_of_stream_that_does_not_exist
    assert_equal 0, get_latest_version('foo')
  end

  def test_stream_does_not_exist_what_is_the_latest_version
    post '/stream_has_been_updated', {},
      'HTTP_REFERER' => 'http://localhost:4567/watch/lake'
    json_response = JSON.parse last_response.body

    assert_equal 0, json_response['version']
  end

  def test_stream_has_been_updated_what_is_the_latest_version
    put '/streams/dock.jpg'
    stream = get_stream 'dock'
    version = stream[:version]

    post '/stream_has_been_updated', {},
      'HTTP_REFERER' => 'http://localhost:4567/watch/dock'
    json_response = JSON.parse last_response.body

    assert_equal version, json_response['version']
  end

  def test_my_version_is_earlier_what_is_the_new_url
    put '/streams/woody_allen.jpg'
    stream = get_stream 'woody_allen'
    latest_version = stream[:version]

    post '/stream_has_been_updated', {:version => 0},
      'HTTP_REFERER' => 'http://localhost:4567/watch/woody_allen'

    json_response = JSON.parse last_response.body
    assert_equal "/streams/woody_allen.jpg?#{latest_version}", json_response['src']
  end

  def test_put_stream_data
    put_stream 'big cat', 'soft and furry'
    stream = get_stream 'big cat'
    assert_equal 'soft and furry', stream[:data]
  end

  def test_put_stream_updates_version
    start_time = Time.now.to_i
    put_stream 'little cat', 'sweet'
    stream = get_stream 'little cat'
    assert start_time <= stream[:version], "#{start_time} should be <= than #{stream[:version]}"
  end

  def test_random_stream_with_one_stream
    put '/streams/rhubarb.jpg'

    assert_equal 'rhubarb', random_stream
  end
end
