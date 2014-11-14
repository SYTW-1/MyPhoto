require 'dm-core'
require 'dm-migrations'
require 'restclient'
require 'xmlsimple'
require 'dm-timestamps'

class Image
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    property :image, Text ,:length => 99999999
    property  :latitude,    String
    property  :longitude,   String
end