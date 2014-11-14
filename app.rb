#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
require 'data_mapper'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'omniauth-github'
require 'omniauth-facebook'
require 'chartkick'
require 'base64'
require 'RMagick'
%w( dm-core dm-timestamps dm-types restclient xmlsimple).each  { |lib| require lib}

enable :sessions
set :session_secret, '*&(^#234a)'

configure :development do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

configure :test do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/test.db")
end

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true 

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

#OmniAuth y get's de autenticación
#use OmniAuth::Builder do
#  config = YAML.load_file 'config/config.yml'
#  provider :google_oauth2, config['identifier_google'], config['secret_google']
#  provider :github, config['identifier_github'], config['secret_github']
#  provider :facebook, config['identifier_facebook'], config['secret_facebook']
#end

get '/auth/:name/callback' do
  @auth = request.env['omniauth.auth']
  session[:plt] = (params[:name] == 'google_oauth2') ? 'google' : params[:name]
  session[:uid] = @auth['uid'];
  if params[:name] == 'google_oauth2' || params[:name] == 'facebook'
    session[:name] = @auth['info'].first_name + " " + @auth['info'].last_name
    session[:email] = @auth['info'].email
  elsif params[:name] == 'github' 
    session[:name] = @auth['info'].nickname
    session[:email] = @auth['info'].email
  end
  redirect "/upload"
end

get '/auth/logout' do
  session.clear
  redirect '/'
end

get '/' do
  @images = Image.all()
  if session['error'] && session['error'] == 'not_coordinates'
    @error = 'Esta imagen se almacenará pero no se puede ubicar en el mapa debido a que no tiene coordenadas.'
    session.delete('error') 
  end
  haml :index, :layout => :base
end

get "/upload" do
  @imagenes = Image.all()
  @str = map()
  haml :upload
end      
    
# Handle POST-request (Receive and save the uploaded file)
post "/upload" do 
  #File.open('uploads/' + params['myfile'][:filename], "w") do |f|
    image   = Magick::Image.read(params['myfile'][:tempfile].path)[0]
    latitude = image.get_exif_by_entry("GPSLatitude")
    longitude = image.get_exif_by_entry("GPSLongitude")
    GPSLatitudeRef = image.get_exif_by_entry("GPSLatitudeRef")
    GPSLongitudeRef = image.get_exif_by_entry("GPSLongitudeRef")
    var = latitude[0][1]
    var2 = longitude[0][1]
    if var == nil || var2 == nil
      session['error'] = 'not_coordinates'
      redirect "/"
    end
    var = var.delete(',')
    var2 = var2.delete(',')
    var = var.split(' ')
    var2 = var2.split(' ')
    lat = []
    lon = []
    var.each do |v|
      lat << v.split('/')[0]
    end
    var2.each do |v|
      lon << v.split('/')[0]
    end
    lat = "#{lat[0]} #{lat[1]}.#{lat[2]} #{GPSLatitudeRef[0][1]}"
    lon = "#{lon[0]} #{lon[1]}.#{lon[2]} #{GPSLongitudeRef[0][1]}"
    image.format = 'JPEG'
    # Se comprime la imagen al 25%
    puts params
    image = image.resize(0.25)
    img = Base64.encode64(image.to_blob).gsub(/\n/, "") 
    Image.create(:image => img, :latitude => lat, :longitude => lon)
    image = image.resize(0.1)
    image.write(params['myfile'][:filename])
  #end
  redirect "/upload"
end

get "/info" do
  @str = map()
  #uts @str
  haml :info
end

def map()
  str = ''
  imagenes = Image.all()
  signo = Hash.new
  signo = {'N'=>1,'S'=>-1,'E'=>1,'W'=>-1}
  imagenes.each do |item|
    if (item.latitude != nil)
      city = "{}"
      count = 0
      lat = item.latitude.split(" ");
      val_lat = ((lat[0]).to_f + (lat[1]).to_f/60)*signo[lat[2]]
      lng = item.longitude.split(" ");
      val_lng = ((lng[0]).to_f + (lng[1]).to_f/60)*signo[lng[2]]
      #puts "Latitud: " + (val_lat).to_s
      #puts "Longitud: " + (val_lng).to_s
      str += "var pos = new google.maps.LatLng(#{(val_lat).to_s},#{(val_lng).to_s});

              var infowindow = new google.maps.InfoWindow({
                  map: map,
                  position: pos,
                  content: \" FOTO \"
              });
              map.setCenter(pos);"
    end
  end
  str
end