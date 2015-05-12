require "bundler"
Bundler.setup
require "sinatra/base"
require "sequel"
require "time"

$db = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://junior.db')

$db.create_table? :votes do
  primary_key :id
  Float :length
  Float :weight
  Bool :male
  Time :born_at
  Time :created_at
  Time :updated_at
  Reference :user_id
end

$db.create_table? :users do
  primary_key :id
  String :email
  String :token
  Time :created_at
  Time :updated_at
end

class Vote < Sequel::Model
  plugin :timestamps
  plugin :validation_helpers

  def male?
    !!male
  end

  def female?
    return false if male.nil?
    !male?
  end

  def validate
    super
    validates_presence [:male, :length, :weight, :born_at]
    validates_schema_types
  end
end

class Junior < Sinatra::Application
  helpers do
    def selected?(date, method, value)
      return unless date

      if date.public_send(method) == value
        "selected"
      end
    end

    def errors?(object, attribute)
      if object && object.respond_to?(:errors)
        !!object.errors.fetch(attribute, false)
      else
        false
      end
    end

    def add_error_class(object, attribute, css_class)
      if errors?(@vote, :weight)
        (Array(css_class) + ["errors"]).join(" ")
      else
        css_class
      end
    end
  end

  get "/" do
    @votes = Vote.all
    erb :index
  end

  get "/vote" do
    @vote = Vote.new
    erb :vote
  end

  post "/vote" do
    @vote = Vote.new
    @vote.weight = params[:weight]
    @vote.length = params[:length]
    if params[:sex]
      @vote.male = (params[:sex] == "male")
    end
    @vote.born_at = fetch_date(params[:born_at])
    if @vote.valid?
      @vote.save
      redirect "/"
    else
      erb :vote
    end
  end

  def fetch_date(data)
    time_string = "2015/%s/%s %s:%s" % [data[:month], data[:day], data[:hour], data[:minute]]
    Time.strptime(time_string, "%Y/%m/%d %H:%M")
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
