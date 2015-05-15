require "bundler"
Bundler.setup
require "sinatra/base"
require "sequel"
require "time"
require "./boot"

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

  def mail_with_template(template_name)
    template = Tilt::ERBTemplate.new("views/#{template_name}")
    template.render(self, name: name, link_name: "baby.jaspe.rs/#{token}", link_href: "http://baby.jaspe.rs/#{token}")
  end

  def send_mail
    raise "No email" unless email
    raise "No token set" unless token
    Pony.mail(
      to: email,
      subject: "Plaats een gokje",
      from: "'Piet Jaspers' <piet@pjaspers.com>",
      body: mail_with_template("mail.txt.erb"),
      html_body: mail_with_template("mail.html.erb")
    )
  end

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
    if @user.vote
      redirect "/#{params["token"]}"
    else
      @vote = Vote.new
      erb :vote
    end
  end

  post "/vote/:token" do
    @user = fetch_user!(params["token"])
    if @user.vote
      halt "Sorry, je hebt al gestemd."
    end
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
