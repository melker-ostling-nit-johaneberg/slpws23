require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'
enable :sesions

# current user
# @user = db.execute("SELECT * FROM Users WHERE User_Id=?", session[:user_id])

get('/') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Describing_features INNER JOIN Users ON Describing_features.User_Id=Users.User_Id")
    @Tag = db.execute("SELECT * FROM Rel_Description INNER JOIN Describing_tags ON Rel_Description.Tag_Id = Describing_tags.Tag_Id")
    print @Tag
    slim(:"start", locals:{turtels:result})
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
    user_id = db.execute("Select User_Id FROM Users WHERE Name=?")
    session[:user_id] = user_id
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
    result = db.execute("SELECT User_Id, Password from Users WHERE Name=?", username).first
    if result == nil
        return "FEL ANVÄNDARNAMN"
    end
    user_id = result["User_Id"].to_i
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
    db.execute("INSERT INTO Describing_features (Name, Size, Species, Weight, Special_notes, User_Id) VALUES (?, ?, ?, ?, ?, ?)", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, session[:user_id].to_i).first
    redirect('/')
end

get('/posts') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM Post INNER JOIN Users ON Post.User_Id = Users.User_Id")
    slim(:post, locals:{content:result})
end

get('/new_post') do
    slim(:new_post)
end

post('/new_post') do
    content = params[:Content]
    db = SQLite3::Database.new("db/db.db")
    if session[:user_id] == nil
        return "Logga in"
    else   
        db.execute("INSERT INTO Post (Content, User_id) VALUES (?, ?)", content, session[:user_id].to_i)
    end
    redirect('/posts')
end