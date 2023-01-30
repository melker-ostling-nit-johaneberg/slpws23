require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'sqlite3'
enable :sesions

get('/') do
    slim(:start)
end