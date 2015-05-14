require "pony"

if ENV["SENDGRID_USERNAME"]
  Pony.options = {
    via: :smtp,
    via_options: {
      address: 'smtp.sendgrid.net',
      port: '587',
      domain: 'heroku.com',
      user_name: ENV['SENDGRID_USERNAME'],
      password: ENV['SENDGRID_PASSWORD'],
      authentication: :plain,
      enable_starttls_auto: true
    }
  }
end

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
