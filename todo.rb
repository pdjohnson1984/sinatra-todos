require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
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
  @list = session[:lists][@id]
  erb :list, layout: :layout
end

# Change name of list
post '/edit/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

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

post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  todo = params[:todo].strip

  error = error_for_listname(todo)
  if error
    session[:error] = error
  else
    @list[:todos] << todo
    session[:success] = 'Todo has been added.'
  end


  erb :list, layout: :layout
end
