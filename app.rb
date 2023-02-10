require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'
enable :sesions

get('/') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Describing_features")
    slim(:"start", locals:{turtels:result})
end

get('/new') do
    db = SQLite3::Database.new("db/db.db")
    result = db.execute("SELECT * FROM Post")
    slim(:start, locals:{turtels:result})
end
get('/register') do
    slim(:register)
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/db.db")
    db.execute("INSERT INTO Users ('Name', 'Password') VALUES (?, ?)", username, password_digest)
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

get('/new_turtle') do
    slim(:new_turtle)
end

post('/new_turtle') do
    turtle_name = params[:turtle_name]
    turtle_size = params[:turtle_size].to_i
    turtle_species = params[:turtle_species]
    turtle_weight = params[:turtle_weight].to_i
    turtle_notes = params[:turtle_notes]
    db = SQLite3::Database.new("db/db.db")
    db.execute("INSERT INTO Describing_features (Name, Size, Species, Weight, Special_notes) VALUES (?, ?, ?, ?, ?)", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes).first
    redirect('/')
end

get('/posts') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Post")
    slim(:post, locals:{content:result})
end

get('/new_post') do
    slim(:new_post)
end

post('/new_post') do
    content = params[:Content]
    db = SQLite3::Database.new("db/db.db")
    db.execute("INSERT INTO Post (Content) VALUES (?)", content)
    redirect('/posts')
end