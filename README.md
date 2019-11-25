# MusicLoader CLI application

### Introduction

This program is a CLI batch application that applies a batch of changes to a input file in order to create an output file.

**Author:** Bogdan Kulbida
November 23, 2019. Seattle, USA

### Considerations

Assuming we are building a real-word batch script that can be used in a semi-production environment, the following decisions have been made.
1. Using streams instead of pure files (still, the input data file  supported as requested)

2. Input data validation, the program has to gracefully process bad data in the changeset files without bad data propagation down the stream. Instructions that do not pass validation are captured in a separate `error.log` file for further investigation and a potential rerun of the batch command.

3. Security. In our proposed solution we have used streams instead of files as you need to persist the file, make sure it is securely stored and deleted afterward. Streams are, on the other hand, can be easily consumed and produced via using secure transport, such as HTTPS, for example, or HTTP socket. Another consideration is there is a potential security vulnerability due to the nature of the `changes.json` file since it serializes the class name. For further improvements, the additional layer for changeset files validation can be implemented.

4. Using streams, we can easily distribute the load across the workers that are dispersed across the wire.

5. We used data serialization and de-serialization to provide data integrity checks and data validation. It slows down the performance a little bit, but since we are building real-world batch applications, data consistency is our priority over performance.

6. The proposed solution should process small to medium-sized JSON files, close to 500MB per file. For larger files, our suggestion is to replace in-memory storage with NoSQL database.

7. The design of the application allows to chain commands and apply various command (changes.json) files by using UNIX STDIN and STDOUT interfaces

8. Scalability. Due to the distributed nature of the batch command, the proposed solution can be deployed into multiple nodes, which allows applying changes incrementally.

9. The proposed solution uses lazy-loading design pattern when possible to consume resources efficiently.

10. Exceptions for exceptional cases, we have designed this solution to consume bad data and void bad data propagation. However, this may not be the best idea for some specific instances in which data integrity is a significant factor.

11. The proposed design can serve as a base foundation for a simple ETL. Data validation allows you to call external services to check for e-mail validness or making database requests to get additional information. See the details below for a complete list of features.

12. Note: for simplicity's sake, we do not check for the uniqueness of the data objects when we add to the collection as well as other extra features. The proposed solution allows for developing additional functionality in a modular way using public or private API. For example, we could move some of the logic into separate methods or classes for this example, we decided to keep things simple.

### Dependencies

Our program is written in **Ruby 2.x** and has only one optional dependency, `yajl`. We used this library as it provides support for JSON loading via TCPSocket, URL, etc. It is optional can be removed with a standard Ruby JSON library.

### Execution

#### 1. Checking Ruby version:

`ruby --version` => ruby 2.3

#### 2. Installing dependencies (using rubygems:

`gem install yajl-ruby`
```
Building native extensions.  This could take a while...
Successfully installed yajl-ruby-1.4.1
Parsing documentation for yajl-ruby-1.4.1
Done installing documentation for yajl-ruby after 0 seconds
1 gem installed
```

#### 3. Diff-file (or changes.json)

We named our change files such as `ops0.json` ... `ops4.json`. We will call these files **changeset files**.

`cat ops4.json`

```json
[
  {
    "optype" : "AddSong",
    "playlist__id" : "1",
    "song_id" : "1"
  },
  {
    "optype" : "RemovePlaylist",
    "id" : "1"
  },
  {
    "optype" : "RemovePlaylist",
    "id" : "3"
  },
  {
    "optype" : "AddPlaylist",
    "user_id" : "1",
    "payload" : [
      {"song_id" : "1"}
    ]
  },
  {
    "optype" : "RemovePlaylist",
    "id" : "3"
  },
  {
    "optype" : "AddPlaylist",
    "user_id" : "2",
    "payload" : [
      {"song_id" : "1"}
    ]
  },
  {
    "optype" : "AddSong",
    "playlist_id" : "1",
    "song_id" : "6"
  },
  {
    "optype" : "AddSong",
    "playlist_id" : "2",
    "song_id" : "7"
  },
  {
    "optype" : "AddSong",
    "playlist_id" : "3",
    "song_id" : "5"
  },
  {
    "optype" : "AddPlaylist",
    "user_id" : "1",
    "payload" : [
      {"song_id" : "1"},
      {"song_id" : "2"},
      {"song_id" : "3"},
      {"song_id" : "4"},
      {"song_id" : "5"},
      {"song_id" : "6"}
    ]
  }
]
```

The script supports the following mutation classes:

1. AddSong
2. RemovePlaylist
3. AddPlaylist

If you would like to add more operations to the stack, please do the following:

1. Create a new mutation operation in `reducers.rb` file. For example:

```ruby
class RemovePlaylist < BaseReducer

  attr_accessor :id

  def initialize(data)
    super
    @id = data['id']
  end

  def run!(storage)
    if playlist = storage[Playlist::SCOPE].detect{|p| p.id == self.id}
      storage[Playlist::SCOPE] = storage[Playlist::SCOPE] - [playlist]
    else
      self.errors.push("Playlist not found. Operation #{self.class.name} failed.")
      STDERR.puts(self.to_json)
    end
  end

  def valid? ; id ; end

end
```

2. Inherit from the base class `BaseReducer`
3. Define attributes and implement `constructor`, `run!` and `valid?` methods.

1 `run!`   - this method will be executed by the `Processor` class as an operation. Here you can define all the logic to mutate the input data or report the issue to the log file.
2 `valid?` - this method is used for the object integrity checks to avoid missing fields and broked inter-object relations.

#### 4. Supported collections:

At this point the program supports 3 types of collections:

1. `users`
2. `songs`
3. `playlists`

If you would like to add more collections for the input data file, please do the following:

1. Create a new mutation (serializer) class in `serializers.rb`, for example:

```ruby
class User < BaseSerializer

  SCOPE = :users
  attr_accessor :id, :name

  def valid?
    id && name
  end
end
```

Here the `SCOPE` key has to correspond to the JSON key in the input data file, in this case we use `:users`.

Here is an example from the input JSON file for `SCOPE` users:

```json
  "users" : [
    {
      "id" : "1",
      "name" : "Albin Jaye"
    },
    {
      "id" : "2",
      "name" : "Dipika Crescentia"
    },
    {
      "id" : "3",
      "name" : "Ankit Sacnite"
    },
    {
      "id" : "4",
      "name" : "Galenos Neville"
    },
    {
      "id" : "5",
      "name" : "Loviise Nagib"
    },
    {
      "id" : "6",
      "name" : "Ryo Daiki"
    },
    {
      "id" : "7",
      "name" : "Seyyit Nedim"
    }
  ],
```

As you can see both attributes, `id` and `name` are defined in the `User` class as attributes.

2. Inherit the class form the `BaseSerializer`
3. Define attributes and implement `valid?` method to make sure the change action from the changeset files (see above) validates.

1 `valid?` method here is used when we add a new object to the output file. We serialization layer for data validation for now.

4. Add the new class to facade collection in the `entrypoint.rb` file, L16

```ruby
collector = Collector.new(processor, [User, Song, Playlist])
```

#### 5. Ready. Steady. Go!

1. Close this repository
2. Make sure you have at least **Ruby 2.3** installed.
3. Run the command:

To run our programm, please run the following command:

```bash
cat mixtape-data.json | ruby entrypoint.rb ops0.json 2> error.log | ruby entrypoint.rb ops1.json 2>> error.log | ruby entrypoint.rb ops2.json 2>> error.log | ruby entrypoint.rb ops3.json 2>> error.log | ruby entrypoint.rb ops4.json 2>> error.log > output.json
```

Here we use 4 changeset files, each has 3 to 11 commands. You may add as many commands as you would like. For simplicity sake we have limited commands per file to 6 in this example.

#### 6. Errors investigation

The command above produces a file `errors.log` and populates error for each run. Here is an output:

```cat error.log```

```bash
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"1"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"3"}
{"optype":"AddSong","errors":["Song not found. Operation AddSong failed."],"playlist_id":"1","song_id":"100"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"1"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"3"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"3"}
{"optype":"AddSong","errors":["Playlist not found. Operation AddSong failed."],"playlist_id":"200","song_id":"1"}
{"optype":"AddSong","errors":["Playlist not found. Operation AddSong failed."],"playlist_id":null,"song_id":"1"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"1"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"3"}
{"optype":"RemovePlaylist","errors":["Playlist not found. Operation RemovePlaylist failed."],"id":"3"}
{"optype":"AddSong","errors":["Playlist not found. Operation AddSong failed."],"playlist_id":"3","song_id":"5"}
```

#### 7. Results

As requested the results are available in the `output.json` file. It does not have extra spaces to use space efficiently, but we have provided here pretty-print version:

```json
{
  "users": [
    {
      "id": "1",
      "name": "Albin Jaye"
    },
    {
      "id": "2",
      "name": "Dipika Crescentia"
    },
    {
      "id": "3",
      "name": "Ankit Sacnite"
    },
    {
      "id": "4",
      "name": "Galenos Neville"
    },
    {
      "id": "5",
      "name": "Loviise Nagib"
    },
    {
      "id": "6",
      "name": "Ryo Daiki"
    },
    {
      "id": "7",
      "name": "Seyyit Nedim"
    }
  ],
  "songs": [
    {
      "id": "1",
      "artist": "Camila Cabello",
      "title": "Never Be the Same"
    },
    {
      "id": "2",
      "artist": "Zedd",
      "title": "The Middle"
    },
    {
      "id": "3",
      "artist": "The Weeknd",
      "title": "Pray For Me"
    },
    {
      "id": "4",
      "artist": "Drake",
      "title": "God's Plan"
    },
    {
      "id": "5",
      "artist": "Bebe Rexha",
      "title": "Meant to Be"
    },
    {
      "id": "6",
      "artist": "Imagine Dragons",
      "title": "Whatever It Takes"
    },
    {
      "id": "7",
      "artist": "Maroon 5",
      "title": "Wait"
    },

    ...

    },
    {
      "id": "20",
      "artist": "Taylor Swift",
      "title": "Delicate"
    },
    {
      "id": "21",
      "artist": "Calvin Harris",
      "title": "One Kiss"
    },
    {
      "id": "22",
      "artist": "Ed Sheeran",
      "title": "Perfect"
    },
    {
      "id": "23",
      "artist": "Meghan Trainor",
      "title": "No Excuses"
    },
    {
      "id": "24",
      "artist": "Niall Horan",
      "title": "On The Loose"
    },
    {
      "id": "25",
      "artist": "Halsey",
      "title": "Alone"
    },
    {
      "id": "26",
      "artist": "Charlie Puth",
      "title": "Done For Me"
    },
    ...
  ],
  "playlists": [
    {
      "id": "1",
      "user_id": "1",
      "song_ids": [
        "1",
        "6"
      ]
    },
    {
      "id": "2",
      "user_id": "2",
      "song_ids": [
        "1",
        "7"
      ]
    },
    {
      "id": "3",
      "user_id": "1",
      "song_ids": [
        "1",
        "2",
        "3",
        "4",
        "5",
        "6"
      ]
    }
  ]
}
```

**Note**: Some lines are omitted.

#### 8. Testing

What we have developed is a tiny micro framework that allows you to add more functionality. Out goal was also provide proper testing ergonomics. The code can be easily tested, since there is explicit convention in place, dependent objects can be stubbed or mocked on tests which makes testing simpler.

#### 9. Thank you

If you have more questions, please feel free to reach out.
