require_relative "json_serializable"

class BaseSerializer

  include JSONSerializable

  def initialize(attrs)
    attrs.each_pair do |key, value|
      self.public_send("#{key}=", value)
    end
  end

  def self.selector
    self::SCOPE
  end

end

class User < BaseSerializer

  SCOPE = :users
  attr_accessor :id, :name

  def valid?
    id && name
  end
end

class Song < BaseSerializer

  SCOPE  = :songs
  attr_accessor :id, :artist, :title

  def valid?
    id && artist && title
  end
end

class Playlist < BaseSerializer

  SCOPE = :playlists
  attr_accessor :id, :user_id, :song_ids

  def valid?
    [id.is_a?(String), user_id.is_a?(String), song_ids.is_a?(Array)].all?
  end
end
