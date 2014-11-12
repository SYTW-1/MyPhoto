source 'https://rubygems.org'

#gem 'alphadecimal'

gem 'data_mapper'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'
gem 'omniauth-facebook'
gem 'pry' 
gem 'erubis'
gem 'chartkick'
gem 'groupdate'

gem 'rest-client'
gem 'xml-simple'

gem 'rubysl-base64'
gem 'imagemagick-binaries'
gem 'rmagick'

group :production do
	gem 'haml'
    gem "pg"
    gem "dm-postgres-adapter"
end

group :development do
	gem 'haml'
    gem "sqlite3"
    gem "dm-sqlite-adapter"
end

group :test do
	gem "sqlite3"
	gem "dm-sqlite-adapter"
    gem "rack-test"
    gem "rake"
end