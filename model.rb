require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
require 'sinatra/flash'
enable :sessions




helpers do
    def Connect_to_db(path)
        db = SQLite3::Database.new("#{path}")
        db.results_as_hash = true
        return db
    end

    def Select_turtle_id
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT Description_Id from Describing_features").last
    end

    def Select_all_Tags_Descriptions
        db = Connect_to_db("db/db.db")
        tag = db.execute("SELECT * FROM Rel_Description INNER JOIN Describing_tags ON Rel_Description.Tag_Id = Describing_tags.Tag_Id")
        return tag
    end

    def Select_all_features_user
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Describing_features INNER JOIN Users ON Describing_features.User_Id=Users.User_Id")
        return result
    end

    def Select_user_id_from_feature_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT User_Id FROM Describing_features WHERE Description_Id = ?", id).last
        return result
    end

    def Select_all_features_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * from Describing_features WHERE Description_Id=?", id).last
        return result
    end

    def Select_tag_in_use(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT Tag_Id FROM Rel_Description WHERE Description_Id=?", id).to_a.flat_map(&:values)
        return result
    end

    def Select_user_password_where_name(username)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT User_Id, Password from Users WHERE Name=?", username).first
        return result
    end

    def Select_user_where_name(username)
        db = Connect_to_db("db/db.db")
        result = db.execute("Select User_Id FROM Users WHERE Name=?", username).last
        return result["User_Id"]
    end

    def Select_all_post_users
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Post INNER JOIN Users ON Post.User_Id = Users.User_Id")
        return result
    end

    def Select_all_post_where_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM POST WHERE Post_ID = ?", id).last
        return result
    end

    def Select_all_tags_where_id(id)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT * FROM Describing_tags WHERE Tag_Id = ?", id).last
        return result
    end

    def Select_all_Tags
        db = Connect_to_db("db/db.db")
        tags = db.execute("Select * FROM Describing_tags")
        return tags
    end

    def Select_current_user(user_id)
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT * FROM Users WHERE User_Id=?", user_id)
    end






    def Insert_turtle_tags(turtle_tags, turtle_id)
        db = Connect_to_db("db/db.db")
        turtle_tags.each do |turtle_tag|
            db.execute("INSERT INTO Rel_Description (Tag_Id, Description_Id) VALUES (?,?)", turtle_tag.last, turtle_id)
        end
    end

    def Insert_post(content, user_id)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Post (Content, User_id) VALUES (?, ?)", content, user_id)  
    end

    def Insert_tags(content)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Describing_tags (Tag) VALUES (?)", content)
    end

    def Insert_new_Turtle(turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Describing_features (Turt_Name, Size, Species, Weight, Special_notes, User_Id) VALUES (?, ?, ?, ?, ?, ?)", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
    end






    def Delete_x_tag_id(tabel, tag_id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM #{table} WHERE Tag_Id = ?", tag_id)
    end

    def Delete_x_description_id(tabel, description_id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM #{tabel} WHERE Description_Id = ?", description_id)
    end

    def Delete_post_where_id(id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM Post WHERE Post_Id = ?", id)
    end





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

    def Update_post(content, id)
        db = Connect_to_db("db/db.db")
        db.execute("UPDATE Post SET 
            Content = ? 
            WHERE Post_id = ?", content, id)
    end

    def Update_tags(content, id)
        db = Connect_to_db("db/db.db")
        db.execute("UPDATE Describing_tags SET Tag = ? WHERE Tag_Id = ?", content, tag_id)
    end




    def Check_admin(current_user)
        db = Connect_to_db("db/db.db")
        a = db.execute("SELECT Admin FROM Users WHERE User_Id = ?", current_user).last
        if a == nil
            return false
        else
            return a["Admin"] == 1
        end
    end

    def Check_password(password_digest, password)
        return BCrypt::Password.new(password_digest) == password
    end

    def Check_user(username)
        db = Connect_to_db("db/db.db")
        result = db.execute("SELECT Name FROM Users WHERE Name = ?", username)
        return result != nil
    end



    def Register_user(username, password)
        db = Connect_to_db("db/db.db")
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO Users ('Name', 'Password') VALUES (?, ?)", username, password_digest) 
    end
end
