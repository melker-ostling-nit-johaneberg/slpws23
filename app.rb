require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require 'sinatra/flash'
require_relative './model.rb'
enable :sessions

include Model


before do
    @user = Select_current_user(session[:user_id])
    if session[:user_id] == nil && ((request.path_info == '/turtle/new') || (request.path_info == '/post/new'))
        flash[:error] = "Måste vara inloggad för att skapa ett inlägg"
        redirect('/turtle/')
    end
end


# Redirects to landing page '/turtle/'
#
get('/') do
    redirect('/turtle/')
end

# Displays landing page with all turtles
#
# @see Model#Select_all_features_user
# @see Model#Select_all_Tags_Descriptions()
get('/turtle/') do
    result = Select_all_features_user()
    @Tag = Select_all_Tags_Descriptions()
    slim(:"turtle/index", locals:{turtels:result})
end

# Displays a form to creat a new turtle
#
# @see Model#Select_all_Tags()
get('/turtle/new') do
    tags = Select_all_Tags()
    slim(:"turtle/new", locals:{tags:tags})
end

# Creates a new turtle and checks some of the input, then it redirects to '/turtle/'
#
# @param [String] turtle_name, The turtles name
# @param [Integer] turtle_size, The size of the turtle
# @param [String] turtle_species, The species of the turtle
# @param [Integer] turtle_weight, The weight of the turtle
# @param [String] turtle_notes, Any specal feature of the turtle
# @param [Hash] turtle_tags, Wich tags are atrributed to the turtle
#
# @see Model#Insert_new_Turtle
# @see Model#Select_turtle_id
# @see Model#Insert_turtle_tags
post('/turtle') do
    if params[:turtle_name].length == 0
        flash[:error] = "Skölpaddan har väll ett namn i alla fall"
        redirect('/turtle/new') 
    end
    if params[:turtle_size] == "" || params[:turtle_weight] == ""
        flash[:error] = "Är du säker på att sköldpaddan finns? Skriv in en vikt och/eller längd."
        redirect('/turtle/new') 
    end
    Insert_new_Turtle(params[:turtle_name], params[:turtle_size].to_i, params[:turtle_species], params[:turtle_weight].to_i, params[:turtle_notes], session[:user_id])
    turtle_id = Select_turtle_id()
    Insert_turtle_tags(params[:turtle_tags].to_a, turtle_id["Description_Id"])
    redirect('/turtle/')
end

# Displays a form to edit your own turtle
#
# @param [Integer] description_id, Which turtle that is edited
#
# @see Model#Select_all_features_id
# @see Model#Check_admin
# @see Model#Select_all_Tags
# @see Model#Select_tag_in_use
get('/turtle/:description_id/edit') do
    id = params[:description_id].to_i
    result = Select_all_features_id(id)
    if result["User_Id"] != session[:user_id] && !Check_admin(session[:user_id])
        flash[:error] = "Du är inte inloggad med rätt konto för att ändra detta inlägg"
        redirect('/turtle/') 
    end
    tag = Select_all_Tags()
    tag_in_use = Select_tag_in_use(id)
    slim(:"turtle/edit", locals:{user_content:result, tags:tag, tag_in_use:tag_in_use})
end

# Updates an existing turtle and redirects to '/turtle/'
#
# @param [Integer] description_id, Which turtle that is edited
# @param [String] turtle_name, The turtles name
# @param [Integer] turtle_size, The size of the turtle
# @param [String] turtle_species, The species of the turtle
# @param [Integer] turtle_weight, The weight of the turtle
# @param [String] turtle_notes, Any specal feature of the turtle
# @param [Hash] turtle_tags, Which tags are atrributed to the turtle
#
# @see Model#Delete_x_description_id
# @see Model#Update_features
# @see Model#Insert_turtle_tags
post('/turtle/:description_id/update') do
    id = params[:description_id].to_i
    turtle_name = params[:turtle_name]
    turtle_size = params[:turtle_size].to_i
    turtle_species = params[:turtle_species]
    turtle_weight = params[:turtle_weight].to_i
    turtle_notes = params[:turtle_notes]
    turtle_tags = params[:turtle_tags].to_a
    Delete_x_description_id("Rel_Description", id)
    Update_features(turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, id)
    Insert_turtle_tags(turtle_tags, id)
    redirect('/turtle/')
end

# Deletes an existing turtle and checks if it is the correct user ant then redirects to '/turtle/'
#
# @param [Integer] description_id, Which turtle that is deleted
#
# @see Model#Select_all_features_id
# @see Model#Check_admin
# @see Model#Delete_x_description_id
post('/turtle/:description_id/delete') do
    id = params[:description_id].to_i
    result = Select_all_features_id(id)
    if result["User_Id"] != session[:user_id] && !Check_admin(session[:user_id])
        flash[:error] = "Du är inte inloggad med rätt konto för att ändra detta inlägg"
        redirect('/turtle/') 
    end
    Delete_x_description_id("Describing_features", id)
    Delete_x_description_id("Rel_Description", id)
    redirect("/turtle/")
end

# Displays a register form
#
get('/register') do
    slim(:register)
end

# Attempts register and updates the session
#
# @param [String] username, The username
# @param [String] password, The password
#
# @see Model#Check_user
# @see Model#Register_user
# @see Model#Select_user_password_where_name
post('/register') do
    username = params[:username]
    password = params[:password]
    if Check_user(username)
        flash[:error] = "Användarnamn annvänds redan, va lite unik"
        redirect('/register') 
    end
    Register_user(username, password)
    session[:user_id] = Select_user_password_where_name(username)["User_Id"]
    redirect('/turtle/')
end

# Displays a login form
#
get('/login')do
    slim(:login)
end

login_attempts = {}
# Attempts login and updates the session and redirects to '/turtle/'
#
# @param [String] username, The username
# @param [String] password, The password
#
# @see Model#Select_user_password_where_name
post('/login') do
    username = params[:username]
    password = params[:password]
    result = Select_user_password_where_name(username)
    

    if login_attempts[request.ip] != nil && (Time.now.to_i - login_attempts[request.ip]) < 60
        flash[:error] = "Du har försökt för många gånger"
        redirect('/login') 
    else
        if result != nil
            if Check_password(result["Password"], password)
                session[:user_id] = result["User_Id"].to_i
                redirect('/turtle/')
            end
        end
        login_attempts[request.ip] = Time.now.to_i
        if result == nil
            flash[:error] = "Fel Användarnamn"
        else
            flash[:error] = "Fel Lösenord"
        end
        redirect('/login') 
    end
end

# Displays landing page with all posts
#
# @see Model#Select_all_post_users
get('/posts/') do
    result = Select_all_post_users()
    slim(:"post/index", locals:{content:result})
end

# Displays a form to creat a new post
#
get('/post/new') do
    slim(:"post/new")
end

# Creates a new post and checks it's length, then it redirects to '/posts/'
#
# @param [String] content, The content of the post
#
# @see Model#Insert_post
post('/post') do
    content = params[:Content]
    if content.length == 0
        flash[:error] = "Du måste skriva nåt"
        redirect('/post/new') 
    end
    Insert_post(content, session[:user_id])
    redirect('/posts/')
end

# Displays a form to edit an existing post
#
# @param [Integer] post_id, Which post that is edited
#
# @see Model#Select_all_post_where_id
# @see Model#Check_admin
get('/posts/:post_id/edit') do
    id = params[:post_id].to_i
    result = Select_all_post_where_id(id)
    if result["User_Id"] != session[:user_id] && !Check_admin(session[:user_id])
        flash[:error] = "Du är inte inloggad med rätt konto för att ändra detta inlägg"
        redirect('/turtle/') 
    end
    slim(:"post/edit", locals:{post:result})
end

# Updates an existing post and redirects to '/posts/'
#
# @param [Integer] post_id, Which post that is edited
# @param [String] content, The content of the post
#
# @see Model#Update_post
post('/posts/:post_id/update') do
    id = params[:post_id].to_i
    content = params[:Content]
    Update_post(content, id)
    redirect("/posts/")
end

# Deletes an existing post and redirects to '/posts/'
#
# @param [Integer] post_id, Which post that is edited
#
# @see Model#Select_all_post_where_id
# @see Model#Check_admin
# @see Model#Delete_post_where_id
post('/posts/:post_id/delete') do
    id = params[:post_id].to_i
    result = Select_all_post_where_id(id)
    if result["User_Id"] != session[:user_id] && !Check_admin(session[:user_id])
        flash[:error] = "Du är inte inloggad med rätt konto för att ändra detta inlägg"
        redirect('/turtle/') 
    end
    Delete_post_where_id(id)
    redirect("/posts/")
end

# Displays all tags and checks if the user is an admin
#
# @see Model#Select_all_Tags
# @see Model#Check_admin
get('/admin/tags/') do
    if Check_admin(session[:user_id]) == false
        flash[:error] = "Du har inte tillgång till denna funktionaliteten"
        redirect('/turtle/') 
    end
    result = Select_all_Tags()
    slim(:"admin/tag/index", locals:{content:result})
end

# Displays a form to creat a new tag and checks if the user is an admin
#
get('/admin/tags/new') do
    if Check_admin(session[:user_id]) == false
        flash[:error] = "Du har inte tillgång till denna funktionaliteten"
        redirect('/turtle/') 
    end
    slim(:"admin/tag/new")
end

# Creates a new tag and redirects to '/admin/tags'
#
# @param [String] New_tag, The new tag
#
# @see Model#Insert_tags
post('/admin/tags') do
    Insert_tags(params[:New_tag])
    redirect('/admin/tags/')
end

# Displays a form to edit an existing tag and checks if the user is an admin
#
# @param [Integer] tag_id, Which tag that is edited
#
# @see Model#Check_admin
# @see Model#Select_all_tags_where_id
get('/admin/tags/:tag_id/edit') do
    id = params[:tag_id].to_i
    if Check_admin(session[:user_id]) == false
        flash[:error] = "Du har inte tillgång till denna funktionaliteten"
        redirect('/turtle/') 
    end
    result = Select_all_tags_where_id(id)
    slim(:"admin/tag/edit", locals:{edit_tag:result})
end

# Updates an existing tag and redirects to '/admin/tags/'
#
# @param [String] new_tag, The updated tag
# @param [Integer] tag_id, Which tag that is edited
#
# @see Model#Update_tags
post('/admin/tags/:tag_id/update') do
    Update_tags(params[:new_tag], params[:tag_id].to_i)
    redirect('/admin/tags/')
end

# Deletes an existing tag and checks if the user is an admin, then it redirects to '/admin/tags/'
#
# @param [Integer] tag_id, Which tag that is edited
#
# @see Model#Delete_x_tag_id
post('/admin/tags/:tag_id/delete') do
    tag_id = params[:tag_id].to_i
    if Check_admin(session[:user_id]) == false
        flash[:error] = "Du har inte tillgång till denna funktionaliteten"
        redirect('/turtle/') 
    end
    Delete_x_tag_id("Describing_tags", tag_id)
    Delete_x_tag_id("Rel_Description", tag_id)
    redirect("/admin/tags/")
end