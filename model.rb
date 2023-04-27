require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require 'sinatra/flash'
enable :sessions




module Model
    # Connects to sqlite database
    #
    # @return [] containing the database
    def Connect_to_db(path)
        db = SQLite3::Database.new("#{path}")
        db.results_as_hash = true
        return db
    end

    # Selects all ID:s to the turtles
    #
    # @return [Hash]
    #   * :Description_Id [Integer] The ID of a Describing_feature/turtle
    def Select_turtle_id
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT Description_Id from Describing_features").last
    end

    # Selects all from Rel_descriptions and describing_tags where tag_id is the same
    #
    # @return [Hash]
    #   * :Tag_Id [Integer] The ID of a tag
    #   * :Rel_Id [Integer] The ID of a relationship
    #   * :Description_Id [Integer] The ID of a Describing_feature/turtle
    #   * :Tag [String] The tag 
    def Select_all_Tags_Descriptions
        db = Connect_to_db("db/db.db")
        tag = db.execute("SELECT * FROM Rel_Description INNER JOIN Describing_tags ON Rel_Description.Tag_Id = Describing_tags.Tag_Id")
        return tag
    end

    # Selects all from Describing_features and Users where User_Id is the same
    #
    # @return [Hash]
    #   * :Description_Id [Integer] The ID of a Description/turtle
    #   * :Turt_name [String] The turtles name
    #   * :Size [Integer] The size of the turtle
    #   * :Species [String] The spices of the turtle
    #   * :Weight [Integer] The weight of the turtle
    #   * :Special_notes [String] any special message attaced to the turtle
    #   * :User_Id [Integer] The ID of a user
    #   * :Name [String] The name of the user
    #   * :Password [String] The password of the user
    #   * :Admin [Integer] Either 1 or 0 for if the user if an admin (1 = admin) (0 = not admin)
    def Select_all_features_user
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Describing_features INNER JOIN Users ON Describing_features.User_Id=Users.User_Id")
        return result
    end

    # Selects all from Describing_features for a Description_Id
    #
    # @param [Integer] id The id of the choosen description  
    #
    # @return [Hash]
    #   * :Description_Id [Integer] The ID of a Describing_feature/turtle
    #   * :Turt_name [String] The turtles name
    #   * :Size [Integer] The size of the turtle
    #   * :Species [String] The spices of the turtle
    #   * :Weight [Integer] The weight of the turtle
    #   * :Special_notes [String] any special message attaced to the turtle
    #   * :User_Id [Integer] The ID of a user
    def Select_all_features_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * from Describing_features WHERE Description_Id=?", id).last
        return result
    end

    # Selects the Tag_Id from Rel_descriptions for a Description_Id
    #
    # @param [Integer] id The id of the choosen description  
    #
    # @return [Hash]
    #   * :Tag_Id [Integer] The ID of a tag
    def Select_tag_in_use(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT Tag_Id FROM Rel_Description WHERE Description_Id=?", id).to_a.flat_map(&:values)
        return result
    end

    # Selects User_Id and Password from User for Name
    #
    # @param [String] username The name of the choosen user
    #
    # @return [Hash]
    #   * :User_Id [Integer] The ID of a user
    #   * :Password [String] The password of the user
    def Select_user_password_where_name(username)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT User_Id, Password from Users WHERE Name=?", username).first
        return result
    end

    # Selects all from Post and Users
    #
    # @return [Hash]
    #   * :Post_Id [Integer] The ID of a post
    #   * :User_Id [Integer] The ID of a user
    #   * :Content [String] The content of a post
    #   * :Name [String] The name of the user
    #   * :Password [String] The password of the user
    #   * :Admin [Integer] Either 1 or 0 for if the user if an admin (1 = admin) (0 = not admin)
    def Select_all_post_users
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Post INNER JOIN Users ON Post.User_Id = Users.User_Id")
        return result
    end

    # Selects all from Post for a Post_Id
    #
    # @param [Integer] id The id of the choosen post  
    #
    # @return [Hash]
    #   * :Post_Id [Integer] The ID of a post
    #   * :User_Id [Integer] The ID of a user
    #   * :Content [String] The content of a post
    def Select_all_post_where_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM POST WHERE Post_Id = ?", id).last
        return result
    end

    # Selects all from Describing_tags for a Tag_Id
    #
    # @param [Integer] id The id of the choosen Describing_tag
    #
    # @return [Hash]
    #   * :Tag_Id [Integer] The ID of a tag
    #   * :Tag [String] The tag 
    def Select_all_tags_where_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Describing_tags WHERE Tag_Id = ?", id).last
        return result
    end

    # Selects all from Describing_tags
    #
    # @return [Hash]
    #   * :Tag_Id [Integer] The ID of a tag
    #   * :Tag [String] The tag 
    def Select_all_Tags
        db = Connect_to_db("db/db.db")
        tags = db.execute("Select * FROM Describing_tags")
        return tags
    end

    # Selects all from Users for a User_id
    #
    # @param [Integer] user_id The id of the choosen user
    #
    # @return [Hash]
    #   * :User_Id [Integer] The ID of a user
    #   * :Name [String] The name of the user
    #   * :Password [String] The password of the user
    #   * :Admin [Integer] Either 1 or 0 for if the user if an admin (1 = admin) (0 = not admin)
    def Select_current_user(user_id)
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT * FROM Users WHERE User_Id=?", user_id)
    end




    # Attempts to insert a new row for every selected tag in the Rel_Description table
    #
    # @param [Hash] turtle_tags The choosen tags of a turtle
    # @param [Integer] turtle_id The id of the choosen Describing_feature/turtle
    def Insert_turtle_tags(turtle_tags, turtle_id)
        db = Connect_to_db("db/db.db")
        turtle_tags.each do |turtle_tag|
            db.execute("INSERT INTO Rel_Description (Tag_Id, Description_Id) VALUES (?,?)", turtle_tag.last, turtle_id)
        end
    end

    # Attempts to insert a new row in the Post table
    #
    # @param [String] content The content of the post
    # @param [Integer] user_id The user_id of the creator
    def Insert_post(content, user_id)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Post (Content, User_id) VALUES (?, ?)", content, user_id)  
    end

    # Attempts to insert a new row in the Describing_tags table
    #
    # @param [String] content The new tag
    def Insert_tags(content)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Describing_tags (Tag) VALUES (?)", content)
    end

    # Attempts to insert a new row in the Describing_tags table
    #
    # @param [String] turtle_name The turtles name
    # @param [Integer] turtle_size The size of the turtle
    # @param [String] turtle_species The species of the turtle
    # @param [Integer] turtle_weight The weight of the turtle
    # @param [String] turtle_notes Any specal feature of the turtle
    # @param [Hash] turtle_tags Wich tags are atrributed to the turtle
    # @param [Integer] user_id The user_id of the creator
    def Insert_new_Turtle(turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Describing_features (Turt_Name, Size, Species, Weight, Special_notes, User_Id) VALUES (?, ?, ?, ?, ?, ?)", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
    end





    # Attempts to delete a row from a table for a tag_Id 
    #
    # @param [String] tabel The name of which table to delete from
    # @param [Integer] tag_id The tag_id of the tag that is deleted
    def Delete_x_tag_id(tabel, tag_id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM #{table} WHERE Tag_Id = ?", tag_id)
    end

    # Attempts to delete a row from a table for a description_Id
    #
    # @param [String] tabel The name of which table to delete from
    # @param [Integer] description_id The description_id of the description that is deleted
    def Delete_x_description_id(tabel, description_id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM #{tabel} WHERE Description_Id = ?", description_id)
    end

    # Attempts to delete a row from the post table for a Post_Id
    #
    # @param [Integer] id The id of the choosen post to delete 
    def Delete_post_where_id(id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM Post WHERE Post_Id = ?", id)
    end




    # Attempts to update a row in the Describing_features table
    #
    # @param [String] turtle_name The turtles name
    # @param [Integer] turtle_size The size of the turtle
    # @param [String] turtle_species The species of the turtle
    # @param [Integer] turtle_weight The weight of the turtle
    # @param [String] turtle_notes Any specal feature of the turtle
    # @param [Integer] user_id The user_id of the creator
    def Update_features(turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, id)
        db = Connect_to_db("db/db.db")
        db.execute("UPDATE Describing_features SET 
            Turt_Name = ?, 
            Size = ?, 
            Species = ?, 
            Weight = ?, 
            Special_notes = ? 
            WHERE Description_Id = ?", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, id)
    end

    # Attempts to update a row in the Post table
    #
    # @param [String] content The content of the post
    # @param [Integer] id The user_id of the creator
    def Update_post(content, id)
        db = Connect_to_db("db/db.db")
        db.execute("UPDATE Post SET 
            Content = ? 
            WHERE Post_id = ?", content, id)
    end

    # Attempts to update a row in the Tag table
    #
    # @param [String] content The updated tag
    # @param [Integer] id The user_id of the creator
    def Update_tags(content, id)
        db = Connect_to_db("db/db.db")
        db.execute("UPDATE Describing_tags SET Tag = ? WHERE Tag_Id = ?", content, tag_id)
    end



    # Checks if the current user is an admin
    #
    # @param [Integer] current_user The user_id of user that is currently logged in
    #
    # @return [Boolean] whether the current user is an admin and false if no one is logged in
    def Check_admin(current_user)
        db = Connect_to_db("db/db.db")
        a = db.execute("SELECT Admin FROM Users WHERE User_Id = ?", current_user).last
        if a == nil
            return false
        else
            return a["Admin"] == 1
        end
    end

    # Checks if the enterd passwor is correct
    #
    # @param [String] password_digest, The correct password
    # @param [String] password, The enterd password
    #
    # @return [Boolean] whether the passwords are the same
    def Check_password(password_digest, password)
        return BCrypt::Password.new(password_digest) == password
    end

    # Checks if there is a user by the same username already
    #
    # @param [String] username, The username
    #
    # @return [Boolean] true if there are no user by that username else false
    def Check_user(username)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT Name FROM Users WHERE Name = ?", username)
        return !result.empty?
    end


    # Attempts to create a new user
    #
    # @param [String] username The name of the new user
    # @param [String] password The password of the new user
    def Register_user(username, password)
        db = Connect_to_db("db/db.db")
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO Users ('Name', 'Password') VALUES (?, ?)", username, password_digest) 
    end
end
