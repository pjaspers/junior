# test_helper.rb
ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "minitest/pride"
require "rack/test"
require "pry"

ENV['DATABASE_URL'] = 'sqlite://test_junior.db'
require File.expand_path "../../junior.rb", __FILE__

include Rack::Test::Methods

def app
  Junior
end

def setup_user
  User.create(name: "Bob", email: "bob@franz.com", token: "franz")
end


# Or you could override the base implementation like this
class Minitest::Test
  alias_method :_original_run, :run

  def run(*args, &block)
    result = nil
    Sequel::Model.db.transaction(:rollback => :always, :auto_savepoint=>true) do
      result = _original_run(*args, &block)
    end
    result
  end
end

class AppTest < Minitest::Test

  def test_renders_front_page
    get "/"
    assert_includes last_response.body, "Naam"
  end

  def test_shows_404_on_invalid_token
    get "/robin"
    assert_includes last_response.body, "batman"
  end

  def test_shows_instructions_for_user_based_on_token
    setup_user
    get "/franz"
    assert_includes last_response.body, "Bob"
  end

  def test_voting_with_wrong_token_is_wrong
    post "/vote/franz", length: "abc"
    assert_includes last_response.body, "batman"
  end

  def test_user_can_only_vote_once
    user = setup_user
    post "/vote/franz", length: "52", weight: "3.6", sex: "male", born_at: {month: 11, day: 1, hour: 3, minute: 3}
    post "/vote/franz", length: "46", weight: "3.6", sex: "male", born_at: {month: 11, day: 1, hour: 3, minute: 3}

    assert_includes last_response.body, "Sorry"
    assert_equal user.vote.length, 52
  end

  def test_user_can_enter_comma_numbers
    user = setup_user
    post "/vote/franz", length: "52,34", weight: "3,6", sex: "male", born_at: {month: 11, day: 1, hour: 3, minute: 3}
    assert_equal user.vote.length, 52.34
    assert_equal user.vote.weight, 3.6
  end

  def test_shows_errors_on_invalid_inputs
    setup_user
    post "/vote/franz", length: "abc"
    assert_includes last_response.body, "errors"
  end

  def test_shows_results_after_voting
    setup_user
    post "/vote/franz", length: "52", weight: "3.6", sex: "male", born_at: {month: 11, day: 1, hour: 3, minute: 3}
    get "/"
    assert_includes last_response.body, "Bob"
    assert_includes last_response.body, "52"
    assert_includes last_response.body, "Jongen"
  end
end
