# ServerSettings

ServerSettings is useful configuration scheme for any where.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'server_settings'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install server_settings

## Usage

### Prepare
First of all, you must define servers and role in YAML

```yaml
(rolename):
  (option_param): (option_value)
  (...)
  hosts:
    - host1
    - host2
```
Then, You can load yaml files.

```ruby
require 'server_settings'

ServerSettings.load_config("path/to/yaml")
```

#### Load from directory
If you have many roles and servers, you can split yaml file and put
into directory.

```ruby

ServerSettings.load_config_dir("path/to/yamls-dir/*.yml")
```

### Render YAML with ERB
When your server configuration has dynamic parameter, you can use ERB
syntax in yaml.

`load_config_dir()` will rendering  ERB template every time.
Or  `load_from_yaml_erb()` also rendering ERB for yaml content

### For Dalli

```yaml
memcached_servers:
  port: 11211
  hosts:
    - 192.168.100.1
    - 192.168.100.2
```

```ruby
ServerSettings.load_config("config/production/server-config.yaml")

ActiveSupport::Cache::DalliStore.new ServerSettings.memcached_servers.with_format("%host:%port"), options

```

### For Resque host
```yaml
redis_endpoint:
  port: 6379
  hosts:
   - 192.168.100.1
```
When hosts have single record, host accessor return string value
instend of Array.
```
Resque.redis = ServerSettings.redis_endpoint.with_format("%host:%port")

```
### For DB

```yaml
databases:
  :adapter: mysql2
  :encoding: utf8
  :reconnect: true
  :database: app
  :pool: 10
  :username: db_user1
  :password: db_pass1
  :master: 192.168.30.86
  :backup: 192.168.30.85
  db1:
    :database: app_db1
    :master: 192.168.30.86
    :backup: 192.168.30.85
    :slaves: [  192.168.30.87, 192.168.30.88 ]
  group1:
    db2:
      :master: 192.168.30.86
      :backup: 192.168.30.85
```
#### Access DB configuration
```ruby
ServerSettings.load_config("config/production/server-config.yaml")

ServerSettings.databases.find("db1").config(:master)
# => {:adapter=>"mysql2", :encoding=>"utf8", :reconnect=>true, :database=>"app_db1", :pool=>10, :username=>"db_user1", :password=>"db_pass1", :host=>"192.168.30.86"}
ServerSettings.databases.find("db1").config(:backup)
# => {:adapter=>"mysql2", :encoding=>"utf8", :reconnect=>true, :database=>"app_db1", :pool=>10, :username=>"db_user1", :password=>"db_pass1", :host=>"192.168.30.85"}
ServerSettings.databases.find("db1").config(:slaves)
# =>[ {:adapter=>"mysql2", :encoding=>"utf8", :reconnect=>true, :database=>"app_db1", :pool=>10, :username=>"db_user1", :password=>"db_pass1", :host=>"192.168.30.87"},
# {:adapter=>"mysql2", :encoding=>"utf8", :reconnect=>true, :database=>"app_db1", :pool=>10, :username=>"db_user1", :password=>"db_pass1", :host=>"192.168.30.88"}]
```
#### Iterator for all db config
```ruby
ServerSettings.load_config("config/production/server-config.yaml")

ServerSettings.databases.each do |db|
  db.master      # => 192.168.30.86
  db.backup      # => 192.168.30.85
  db.slaves      # => [ 192.168.30.87, 192.168.30.88 ]
  db.has_slave?  # => true
  db.settings    # => {:adapter=>"mysql2", :encoding=>"utf8", :reconnect=>true, :database=>"app_db1", :pool=>10, :username=>"db_user1", :password=>"db_pass1"}
end
```

#### Tasks for mysql

If you use Rails, ServerSettings define following tasks.

```ruby
rake server_settings:db:create:execute  # Confirm and execute CREATE DATABASE for each new database
rake server_settings:db:create:status   # Show status of new databases not created yet
rake server_settings:db:drop            # Confirm and execute Drop DATABASE for all database
```

If not use Rails, you writes in `Rakefile` as follows, define tasks.

```ruby
require 'server_settings/tasks'
```

### For Rails

When use Rails, place yaml file in the following pattern.

ServerSettings autoload this yaml file and define roles.

`#{Rails.root}/config/servers/#{Rails.env}/*.yml`

### For Capistrano2
```ruby
require  'server_settings/capistrano'

load_servers("config/production/*.yaml")

```

### For Capistrano3

in Capfile

```ruby
require "capistrano/server_settings"
```

in deploy.rb

```ruby
load_servers("config/production/*.yaml")
```

## For other application configuration

```ruby
ServerSettings.load_config("config/production/server-config.yaml")
ServerSettings.each_role do |role, config|
  puts "#{role}, #{config.hosts}"
end
```

```ruby
puts ServerSettings.memcached_servers.to_a

```
## Contributing

1. Fork it ( https://github.com/monsterstrike/server_settings/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
