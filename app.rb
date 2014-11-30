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
use OmniAuth::Builder do
  config = YAML.load_file 'config/config.yml'
#  provider :google_oauth2, config['identifier_google'], config['secret_google']
#  provider :github, config['identifier_github'], config['secret_github']
  provider :facebook, config['facebook-client'], config['facebook-secret']
end

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
  redirect "/"
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

get '/view/:id' do
  data = Image.first(:id => params['id'])
  "<img src=\"data:image/png;base64,#{data.image}\" />"
end

get '/thumb/:id' do
  "<img src=\"/thumb/#{params['id']}\" />"
end

get '/delete/all' do
  Image.all.destroy
  system("rm -rf public/thumb/*.jpg")
  redirect '/'
end

get '/delete/:id' do
  id = Image.first(:id => params['id'])
  id.destroy
  system("rm -f public/thumb/#{params['id']}-thumb.jpg")

get "/upload" do
  @imagenes = Image.all()
  @str = map()
  haml :upload
end


# Handle POST-request (Receive and save the uploaded file)

post "/upload" do
  image   = Magick::Image.read(params['myfile'][:tempfile].path)[0]
  latitude = image.get_exif_by_entry("GPSLatitude")
  longitude = image.get_exif_by_entry("GPSLongitude")
  GPSLatitudeRef = image.get_exif_by_entry("GPSLatitudeRef")
  GPSLongitudeRef = image.get_exif_by_entry("GPSLongitudeRef")
  var = latitude[0][1]
  var2 = longitude[0][1]
  if var == nil || var2 == nil
    session['error'] = 'not_coordinates'
    lat = nil
    lon = nil
  else
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
  end
  image.format = 'JPEG'
  # Se comprime la imagen al 50%
  image.resize(0.25)
  img = Base64.encode64(image.to_blob).gsub(/\n/, "")
  id_image = Image.create(:image => img, :latitude => lat, :longitude => lon)
  image.resize_to_fit(48,48).write("public/thumb/#{id_image.id}-thumb.jpg")
  redirect "/"
end

get "/map" do
  @str = map()
  haml :map, :layout => :base
end

get '/places/:id' do
  place = Image.first(:id => params['id'])
  if(place.latitude == nil && place.longitude == nil)
    redirect "/"
  else
    signo = Hash.new
    signo = {'N'=>1,'S'=>-1,'E'=>1,'W'=>-1}
    lat = place.latitude.split(" ");
    @val_lat = (((lat[0]).to_f + (lat[1]).to_f/60)*signo[lat[2]]).to_s
    lng = place.longitude.split(" ");
    @val_lng = (((lng[0]).to_f + (lng[1]).to_f/60)*signo[lng[2]]).to_s
    haml :place, :layout => :base
  end
end

def map()
  str = ''
  imagenes = Image.all()
  signo = Hash.new
  signo = {'N'=>1,'S'=>-1,'E'=>1,'W'=>-1}
  imagenes.each do |item|
    if (item.latitude != 'nil')
      lat = item.latitude.split(" ");
      val_lat = ((lat[0]).to_f + (lat[1]).to_f/60)*signo[lat[2]]
      lng = item.longitude.split(" ");
      val_lng = ((lng[0]).to_f + (lng[1]).to_f/60)*signo[lng[2]]
      str += "var pos = new google.maps.LatLng(#{(val_lat).to_s},#{(val_lng).to_s}); var marker = new google.maps.Marker({ map: map, position: pos, icon: \"/thumb/#{item.id}-thumb.jpg\" }); google.maps.event.addListener(marker, 'click', function(){ document.location = \"/view/#{item.id}\"; }); map.setCenter(pos);"
    end
  end
  str
end
