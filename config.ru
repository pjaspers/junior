require "bundler/setup"
require "shack"
use Rack::Static, :urls => ["/public"]
sha = ENV["SHA"] || "24bf2e40aa9695cc6036752687265b5cb187f875"
Shack::Middleware.configure do |shack|
  shack.sha = sha
  shack.content = "<a href='https://github.com/pjaspers/junior/commit/{{sha}}'>{{short_sha}}</a>"
end
use Shack::Middleware
require "./junior"
run Junior
