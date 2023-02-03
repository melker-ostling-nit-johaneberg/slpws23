require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'
enable :sesions

get('/') do
    db = SQLite3::Database.new("db/db.db")
    result = db.execute("SELECT * FROM Post")
    slim(:"start", locals:{result:result})
end

get('/new') do
    slim(:start)
end
get('/register') do
    slim(:register)
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/db.db")
    db.execute("INSERT INTO User ('Name', 'Password') VALUES (?, ?)", username, password_digest)
    redirect('/')
end

get('/login')do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT User_Id, Password from User WHERE Name=?", username).first
    if result == nil
        return "FEL ANVÄNDARNAMN"
    end
    user_id = result["UserId"].to_i
    password_digest = result["Password"]
    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        redirect('/')
    else
        p "hejasklandlkan"
        "FEL LÖSEN!!!!"
    end
end