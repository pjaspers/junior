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
  Integer :user_id
end

$db.create_table? :users do
  primary_key :id
  String :email
  String :name
  Bool :paid
  String :token
  Time :created_at
  Time :updated_at
end

class Vote < Sequel::Model
  plugin :timestamps
  plugin :validation_helpers
  many_to_one :user

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

class User < Sequel::Model
  plugin :timestamps
  plugin :validation_helpers
  one_to_one :vote

  def validate
    super
    validates_presence [:name, :email]
    validates_schema_types
  end
end

class Junior < Sinatra::Application
  helpers do
    # Returns a user or just shows the 404.
    def fetch_user!(token)
      if user = User[token: (token || "").downcase]
        user
      else
        halt erb(:"404")
      end
    end

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
      if errors?(@vote, attribute)
        (Array(css_class) + ["errors"]).join(" ")
      else
        css_class
      end
    end

    def fetch_date(data)
      time_string = "2015/%s/%s %s:%s" % [data[:month], data[:day], data[:hour], data[:minute]]
      Time.strptime(time_string, "%Y/%m/%d %H:%M")
    end
  end

  get "/" do
    @votes = Vote.all
    erb :index
  end

  get "/:token" do
    @user = fetch_user!(params["token"])
    erb :instructions
  end

  get "/vote/:token" do
    @user = fetch_user!(params["token"])
    @vote = Vote.new
    erb :vote
  end

  post "/vote/:token" do
    @user = fetch_user!(params["token"])
    @vote = Vote.new(user: @user)
    @vote.weight = params[:weight]
    @vote.length = params[:length]
    if params[:sex]
      @vote.male = (params[:sex] == "male")
    end
    if params[:born_at]
      @vote.born_at = fetch_date(params[:born_at])
    end

    if @vote.valid?
      @vote.save
      redirect "/"
    else
      erb :vote
    end
  end

  not_found do
    status 404
    erb :"404"
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
