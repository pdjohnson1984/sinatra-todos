require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do

end

not_found do
  redirect "/lists"
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_listname(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  end
end

def load_list(index)
  list = session[:lists][index] if index
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_listname(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/'
  end
end

get '/edit/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  @name = @list[:name]
  erb :edit, layout: :layout
end

get '/lists/:id' do
  @id = params[:id].to_i
  @list = load_list(@id)
  puts @list
  erb :list, layout: :layout
end

# Change name of list
post '/edit/:id' do
  @id = params[:id].to_i
  @list = load_list(@id)

  new_list_name = params[:list_name].strip

  error = error_for_listname(new_list_name)
  if error
    @name = @list[:name]
    session[:error] = error
    erb :edit, layout: :layout
  else
    @list[:name] = new_list_name
    erb :list, layout: :layout
  end
end

post "/delete/:id" do
  list = session[:lists][params[:id].to_i]

  session[:lists].delete(list)
  session[:success] = 'The list has been deleted.'

  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Add a new todo to the list
post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = load_list(@id)
  todo = params[:todo].strip

  error = error_for_listname(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: todo, completed: false}
    session[:success] = 'Todo has been added.'
    redirect "/lists/#{@id}"
  end
end

post "/lists/:id/delete_todo/:todo_id" do
  @id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  @list = load_list(@id)
  @list[:todos].delete_at(todo_id)

  redirect "/lists/#{@id}"
end

# Update the status of a todo
post "/lists/:id/mark_todo/:todo_id" do
  @id = params[:id].to_i
  todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == 'true'
  @list = load_list(@id)
  @list[:todos][todo_id][:completed] = is_completed

  session[:success] = 'Todo has been completed.'

  redirect "/lists/#{@id}"
end

post "/lists/:id/complete_all" do
  @id = params[:id].to_i
  @list = load_list(@id)
  @todos = @list[:todos]

  @todos.each do |todo|
    todo[:completed] = true
  end
  session[:success] = 'All todos completed.'

  redirect "/lists/#{@id}"
end
