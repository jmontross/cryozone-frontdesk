# Name  TheCryoZone Internal App
# URL   http://www.thecryozone.herokuapp.com
# Callback URL  http://www.thecryozone.herokuapp.com/reports
# Support URL   
# Client ID   s5JxQ4RQpm0feKtPHQZJAK97zrGqnlopI6bValSM
# Client Secret   FVYXzDzpYdwiDunSA0NkG7vMyTNOElWabw7hqn9V 
# https://developer.frontdeskhq.com/oauth_clients/64

# https://developer.frontdeskhq.com/docs/api/v2#endpoint-account-people
# https://developer.frontdeskhq.com/docs/api/v2

require 'rubygems'
require 'sinatra'
require 'oauth2'

use Rack::Logger

helpers do
  def logger
    request.logger
  end
end


configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  if !session[:identity] then
    session[:previous_url] = request.path
    @error = 'Sorry guacamole, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'

  @client_id=ENV['CLIENT_ID']
  @client_secret=ENV['CLIENT_SECRET']
  @client = OAuth2::Client.new(@client_id, @client_secret, :site => 'https://frontdeskhq.com/oauth/authorize')

  url = @client.auth_code.authorize_url(:redirect_uri => 'http://thecryozone.herokuapp.com/reports')
  "login at <a href='#{url}'>#{url}</a>"
  redirect url
# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
  #   grant_type=authorization_code&
  # code=AUTH_CODE&
  # redirect_uri=REDIRECT_URL&
  # client_id=CLIENT_ID&
  # client_secret=SECRET
  # token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://thecryozone.herokuapp.com/reports', :headers => {'Authorization' => 'Basic some_password'})
  # response = token.get('/api/resource', :params => { 'access_token' => 'bar' })
  # response.class.name
end

get '/reports' do
  erb "reports and params :#{params.inspect} "
  @code = params["code"]
  puts "code #{@code}"
  logger.info("@code #{@code}")
#   Desk and granting access to your application:
# https://myapp.com/calback?code=AUTH_CODE

# Your server exchanges the authorization code for an access token:

# POST https://frontdeskhq.com/oauth/token
#   grant_type=authorization_code&
#   code=AUTH_CODE&
#   redirect_uri=REDIRECT_URL&
#   client_id=CLIENT_ID&
#   client_secret=SECRET
@client_id=ENV['CLIENT_ID']
@client_secret=ENV['CLIENT_SECRET']

@client ||= OAuth2::Client.new(@client_id, @client_secret, :site => 'https://thecryozone.frontdeskhq.com/')
headers = {
    :grant_type => "authorization_code",
    :code => @code,
    :redirect_uri => "http://thecryozone.herokuapp.com/reports", :client_id => @client_id, :client_secret => @client_secret}
  # token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://thecryozone.herokuapp.com/reports', :headers => {'Authorization' => 'Basic some_password'})
  @token = @client.auth_code.get_token(@code, :redirect_uri => 'http://thecryozone.herokuapp.com/reports', :headers => headers)
  # response = @token.get('/api/resource', :params => { 'access_@token' => 'bar' })
  puts "@token #{@token}"
  logger.info( "@token #{@token}")
  # @token.
  response = @token.get('/api/v2/desk/people')
  logger.info(response.inspect)
  logger.info(response.class.name)
  "code: #{@code}... token: #{@token.inspect}"
  erb :menu
end

get '/all_customers' do
  erb :people
end

get '/monthly_customers' do
 @client_id=ENV['CLIENT_ID']
 @client_secret=ENV['CLIENT_SECRET']

 @client ||= OAuth2::Client.new(@client_id, @client_secret, :site => 'https://thecryozone.frontdeskhq.com/')
 headers = {
    :grant_type => "authorization_code",
    :code => @code,
    :redirect_uri => "http://thecryozone.herokuapp.com/reports", :client_id => @client_id, :client_secret => @client_secret}
  @token = @client.auth_code.get_token(code, :redirect_uri => 'http://thecryozone.herokuapp.com/reports', :headers => headers)

  response = @token.get('/api/v2/desk/people', :params => { 'page' => '1' })
  erb :monthly_customers
end

get '/weekly_reports' do 
  erb :weekly_reports
end

get '/login/form' do 
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from 
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end


get '/secure/place' do
  erb "This is a secret place that only <%=session[:identity]%> has access to!"
end
