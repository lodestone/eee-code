require 'rubygems'
require 'sinatra'
require 'rest_client'
require 'json'
require 'helpers'

configure :test do
  @@db = "http://localhost:5984/eee-test"
end

configure :development, :production do
  @@db = "http://localhost:5984/eee"
end

helpers do
  include Eee::Helpers
end

get '/recipes/search' do
  page = params[:page].to_i
  skip = (page < 2) ? 0 : ((page - 1) * 20) + 1
  data = RestClient.get "#{@@db}/_fti?limit=20&skip=#{skip}&q=#{params[:q]}"
  @results = JSON.parse(data)
  @query = params[:q]

  if @results['rows'].size == 0 && page > 1
    redirect("/recipes/search?q=#{@query}")
    return
  end

  haml :search
end

get '/recipes/:permalink' do
  data = RestClient.get "#{@@db}/#{params[:permalink]}"
  @recipe = JSON.parse(data)

  haml :recipe
end

get '/images/:permalink/:image' do
  content_type 'image/jpeg'
  begin
    RestClient.get "#{@@db}/#{params[:permalink]}/#{params[:image]}"
  rescue
    404
  end
end
