require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require 'sinatra/flash'
require_relative './model.rb'
enable :sessions

# current user
# @user = db.execute("SELECT * FROM Users WHERE User_Id=?", session[:user_id])
# @user = Select_current_user(session[:user_id])

before do
    @user = Select_current_user(session[:user_id])
    if session[:user_id] == nil && ((request.path_info == '/turtle/new') || (request.path_info == '/post/new'))
        flash[:error] = "Måste vara inloggad för att skapa ett inlägg"
        redirect('/turtle/')
    end
end

before('/turtle/:description_id/edit') do
    db = Connect_to_db("db/db.db")
    id = db.execute("SELECT User_Id FROM Describing_features WHERE Description_Id = ?", params[:description_id].to_i).last
    if id["User_Id"] != session[:user_id]
        flash[:error] = "Du är inte inloggad med rätt konto för att ändra detta inlägg"
        redirect('/turtle/') 
    end
end

get('/') do
    redirect('/turtle/')
end

get('/turtle/') do
    db = Connect_to_db("db/db.db")
    result = db.execute("SELECT * FROM Describing_features INNER JOIN Users ON Describing_features.User_Id=Users.User_Id")
    @Tag = db.execute("SELECT * FROM Rel_Description INNER JOIN Describing_tags ON Rel_Description.Tag_Id = Describing_tags.Tag_Id")
    @Current_User = session[:user_id]
    slim(:"turtle/index", locals:{turtels:result})
end

get('/turtle/new') do
    tags = Select_all_Tags()
    slim(:"turtle/new", locals:{tags:tags})
end

post('/turtle/new') do
    Insert_new_Turtle(params[:turtle_name], params[:turtle_size].to_i, params[:turtle_species], params[:turtle_weight].to_i, params[:turtle_notes], session[:user_id])
    turtle_id = Select_turtle_id()
    Insert_turtle_tags(params[:turtle_tags].to_a, turtle_id["Description_Id"])
    redirect('/turtle/')
end

get('/turtle/:description_id/edit') do
    id = params[:description_id].to_i
    db = Connect_to_db("db/db.db")
    result = db.execute("SELECT * from Describing_features WHERE Description_Id=?", id)
    tag = Select_all_Tags()
    tag_in_use = db.execute("SELECT Tag_Id FROM Rel_Description WHERE Description_Id=?", id).to_a.flat_map(&:values)
    slim(:"Turtle/edit", locals:{user_content:result, tags:tag, tag_in_use:tag_in_use})
end

post('/turtle/:description_id/update') do
    id = params[:description_id].to_i
    turtle_name = params[:turtle_name]
    turtle_size = params[:turtle_size].to_i
    turtle_species = params[:turtle_species]
    turtle_weight = params[:turtle_weight].to_i
    turtle_notes = params[:turtle_notes]
    turtle_tags = params[:turtle_tags].to_a
    db = Connect_to_db("db/db.db")
    Delete_x("Rel_Description", id)
    db.execute("UPDATE Describing_features SET Turt_Name = ?, Size = ?, Species = ?, Weight = ?, Special_notes = ? WHERE Description_Id = ?", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, id)
    Insert_turtle_tags(turtle_tags, id)
    redirect('/turtle/')
end

post('/turtle/:description_id/remove') do
    id = params[:description_id].to_i
    Delete_x("Describing_features", id)
    Delete_x("Rel_Description", id)
    redirect("/")
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
    user_id = db.execute("Select User_Id FROM Users WHERE Name=?", username).last.last
    session[:user_id] = user_id
    redirect('/turtle/')
end

get('/login')do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = Connect_to_db("db/db.db")
    result = db.execute("SELECT User_Id, Password from Users WHERE Name=?", username).first
    if result == nil
        return "FEL ANVÄNDARNAMN"
    end
    user_id = result["User_Id"].to_i
    password_digest = result["Password"]
    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        redirect('/turtle/')
    else
        "FEL LÖSEN!!!!"
    end
end

get('/posts/') do
    db = Connect_to_db("db/db.db")
    result = db.execute("SELECT * FROM Post INNER JOIN Users ON Post.User_Id = Users.User_Id")
    slim(:"post/index", locals:{content:result})
end

get('/post/new') do
    slim(:"post/new")
end

post('/post/new') do
    content = params[:Content]
    db = SQLite3::Database.new("db/db.db")
    if session[:user_id] == nil
        return "Logga in"
    else   
        db.execute("INSERT INTO Post (Content, User_id) VALUES (?, ?)", content, session[:user_id])  
    end
    redirect('/posts/')
end