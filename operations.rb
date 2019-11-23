require_relative "json_serializable"

class BaseOperation

  attr_accessor :optype, :errors

  include JSONSerializable

  def initialize(data)
    @optype = data["optype"]
    @errors = []
  end

  def run!
    raise "Please implement in child class"
  end

  def valid?
    raise "Please implement in child class"
  end

end

class AddSong < BaseOperation

  attr_accessor :playlist_id, :song_id

  def initialize(data)
    super
    @playlist_id = data['playlist_id']
    @song_id = data['song_id']
  end

  def run!(storage)
    if song = storage[Song::SCOPE].detect{|s| s.id == self.song_id}
      if playlist = storage[Playlist::SCOPE].detect{|p| p.id == self.playlist_id}
        playlist.song_ids.push(song.id)
      else
        self.errors.push("Playlist not found. Operation #{self.class.name} failed.")
        STDERR.puts(self.to_json)
      end
    else
      self.errors.push("Song not found. Operation #{self.class.name} failed.")
      STDERR.puts(self.to_json)
    end
  end

  def valid?
    # for simplicity sake we will keep this method simple
    true
  end
end

class AddPlaylist < BaseOperation

  attr_accessor :user_id, :payload

  def initialize(data)
    super
    @payload = data['payload']
    @user_id = data['user_id']
  end

  def run!(storage)
    if user = storage[User::SCOPE].detect{|u| u.id == self.user_id}

      song_ids = self.payload.map{|p| p['song_id']}
      if songs = storage[Song::SCOPE].select{|s| song_ids.include?(s.id) } and songs.any?
        last_pl = storage[Playlist::SCOPE].max_by(&:id)
        data = {
          id: ((last_pl ? last_pl.id : "0").to_i+1).to_s,
          user_id: user.id,
          song_ids: songs.map(&:id)
        }
        storage[Playlist::SCOPE].push(Playlist.new(data))
      else
        self.errors.push("No songs were found. Operation #{self.class.name} failed.")
        STDERR.puts(self.to_json)
      end

    else
      self.errors.push("User not found. Operation #{self.class.name} failed.")
      STDERR.puts(self.to_json)
    end
  end

  def valid?
    # for simplicity sake we will keep this method simple
    return true if self.payload.all?{|pl| pl["song_id"] }

    self.errors.push("Operation validation failied with data #{self.payload}")
    STDERR.puts(self.to_json)
  end
end

class RemovePlaylist < BaseOperation

  attr_accessor :id

  def initialize(data)
    super
    @id = data['id']
  end

  def run!(storage)
    if playlist = storage[Playlist::SCOPE].detect{|p| p.id == self.id}
      # Here we have a performance concern. Since Ruby works with memory more and more
      # efficiently, for large (500Mb or more) JSON files this may be a concern.
      storage[Playlist::SCOPE] = storage[Playlist::SCOPE] - [playlist]
    else
      self.errors.push("Playlist not found. Operation #{self.class.name} failed.")
      STDERR.puts(self.to_json)
    end
  end

  def valid? ; id ; end

end
