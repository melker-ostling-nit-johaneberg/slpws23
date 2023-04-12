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

    def Insert_turtle_tags(turtle_tags, turtle_id)
        db = Connect_to_db("db/db.db")
        turtle_tags.each do |turtle_tag|
            db.execute("INSERT INTO Rel_Description (Tag_Id, Description_Id) VALUES (?,?)", turtle_tag.last, turtle_id)
        end
    end

    def Select_turtle_id
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT Description_Id from Describing_features").last
    end

    def Delete_x(tabel, description_id)
        db = Connect_to_db("db/db.db")
        db.execute("DELETE FROM #{tabel} WHERE Description_Id = ?", description_id)
    end
    def Select_all_Tags
        db = Connect_to_db("db/db.db")
        tags = db.execute("Select * FROM Describing_tags")
    return tags
    end

    def Insert_new_Turtle(turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
        db = Connect_to_db("db/db.db")
        db.execute("INSERT INTO Describing_features (Turt_Name, Size, Species, Weight, Special_notes, User_Id) VALUES (?, ?, ?, ?, ?, ?)", turtle_name, turtle_size, turtle_species, turtle_weight, turtle_notes, user_id)
    end

    def Select_current_user(user_id)
        db = Connect_to_db("db/db.db")
        return db.execute("SELECT * FROM Users WHERE User_Id=?", user_id)
    end
end
