require 'sinatra'
require 'pg'

# Helper method to establish a connection to the PostgreSQL database
def db_connection
  connection = PG.connect(dbname: 'blog_db')
  yield(connection)
ensure
  connection.close
end

# Method to retrieve a specific post from the database
def find_post(post_id)
  db_connection do |conn|
    query = 'SELECT * FROM posts WHERE id = $1'
    conn.exec_params(query, [post_id]).first
  end
end

# Method to retrieve all comments for a specific post from the database
def find_comments(post_id)
  db_connection do |conn|
    query = 'SELECT * FROM comments WHERE post_id = $1 ORDER BY created_at ASC'
    conn.exec_params(query, [post_id]).to_a
  end
end

post '/posts' do
  title = params[:title]
  content = params[:content]

  db_connection do |conn|
    conn.exec_params('INSERT INTO posts (title, content) VALUES ($1, $2)', [title, content])
  end

  redirect '/'
end

get '/' do
  db_connection do |conn|
    @posts = conn.exec('SELECT * FROM posts ORDER BY created_at DESC').to_a
  end
  erb :index
end

get '/posts/:id' do
  @post = find_post(params[:id].to_i)
  @comments = find_comments(params[:id].to_i)
  erb :show, locals: { comments: @comments }
end

get '/posts/:id/edit' do
  @post = find_post(params[:id].to_i)
  erb :edit
end

put '/posts/:id' do
  post_id = params[:id].to_i
  title = params[:title]
  content = params[:content]

  db_connection do |conn|
    conn.exec_params('UPDATE posts SET title = $1, content = $2 WHERE id = $3', [title, content, post_id])
  end

  redirect "/posts/#{post_id}"
end

post '/posts/:id/comments' do
  post_id = params[:id].to_i
  name = params[:name]
  content = params[:content]

  db_connection do |conn|
    conn.exec_params('INSERT INTO comments (post_id, name, content) VALUES ($1, $2, $3)', [post_id, name, content])
  end

  redirect "/posts/#{post_id}"
end

post '/posts/:id/edit' do
  post_id = params[:id].to_i
  title = params[:title]
  content = params[:content]

  db_connection do |conn|
    conn.exec_params('UPDATE posts SET title = $1, content = $2 WHERE id = $3', [title, content, post_id])
  end

  redirect "/posts/#{post_id}"
end

delete '/posts/:post_id/comments/:comment_id' do
  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i

  db_connection do |conn|
    conn.exec_params('DELETE FROM comments WHERE post_id = $1 AND id = $2', [post_id, comment_id])
  end

  redirect "/posts/#{post_id}"
end

# Delete a post
delete '/posts/:id' do
  post_id = params[:id].to_i

  db_connection do |conn|
    # First, delete all associated comments for the post
    conn.exec_params('DELETE FROM comments WHERE post_id = $1', [post_id])

    # Then, delete the post itself
    conn.exec_params('DELETE FROM posts WHERE id = $1', [post_id])
  end

  redirect '/'
end