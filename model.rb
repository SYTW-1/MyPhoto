require 'dm-core'
require 'dm-migrations'
require 'restclient'
require 'xmlsimple'
require 'dm-timestamps'

class Image
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    property  :latitude,    String
    property  :longitude,   String
    property :name, String
    property :email, String
end