require 'spec_helper'
require 'server_settings'

describe ServerSettings do
  let (:config1) {
          yaml_text = <<-EOF
role1:
  port: 1000
  hosts:
    - 1.1.1.1
    - 2.2.2.2
role2:
  hosts:
    - 3.3.3.3
EOF
  }

  let (:config2) {
          yaml_text = <<-EOF
role2:
  hosts:
    - 4.4.4.4
EOF
  }

  after do
    ServerSettings.destroy
  end

  describe "config_load" do
    context "when config file exists" do
      before do
        filepath = "config.yml"
        allow(IO).to receive(:read).with(filepath).and_return(config1)
        allow(File).to receive(:mtime).with(filepath).and_return(Time.now)
      end
      it 'can load yaml file' do
        ServerSettings.load_config("config.yml")
      end

      it 'raise error when found duplicate role' do
        ServerSettings.load_from_yaml("role1: { hosts: [ 1.1.1.1 ] }")
        expect do
          ServerSettings.load_from_yaml("role1: { hosts: [ 2.2.2.2 ] }")
        end.to raise_error(ServerSettings::DuplicateRole)
      end

      it 'raise error not array hosts' do
        expect do
          ServerSettings.load_from_yaml("role: { hosts: 1.1.1.1 }")
        end.to raise_exception(ServerSettings::HostCollection::InvalidHosts)
      end
    end

    context "when config file does not exist" do
      it 'raise error' do
        expect { ServerSettings.load_config "does_not_exist.yml" }.to raise_error
      end
    end
  end

  describe "load_config_dir" do
    it 'can load yaml files from directory pattern' do
      ServerSettings.load_config_dir("spec/test-yaml/*.yml")
      expect( ServerSettings.roles.keys.sort ).to eq(["role1", "role2"])
    end

    context "when any yaml does not exist" do
      it "not raise error, but not define any role" do
        ServerSettings.load_config_dir("spec/does_not_exist/*.yml")
        expect(ServerSettings.roles.keys.sort).to eq []
      end
    end

    context "when argument is directory" do
      it "raise error" do
        expect { ServerSettings.load_config_dir("spec/test-yaml") }.to raise_error
      end
      context "when does not exist directory " do
        it "not raise error, but not define any role" do
          ServerSettings.load_config_dir("spec/does_not_exist")
          expect(ServerSettings.roles.keys.sort).to eq []
        end
      end
    end
  end

  describe "#reload" do
    before do
      ServerSettings.load_config_dir("spec/test-yaml/*.yml")
    end

    context 'when file has not changes' do
      it 'not reload yaml files' do
        expect(ServerSettings).to_not receive(:load_config)
        ServerSettings.reload
      end
    end

    context 'when file modified' do
      it 'reload yaml files' do
        allow(File).to receive(:mtime).with("spec/test-yaml/role1.yml").and_return(Time.now)
        allow(File).to receive(:mtime).with("spec/test-yaml/role2.yml").and_return(Time.at(0))
        expect(ServerSettings).to receive(:load_config).with("spec/test-yaml/role1.yml")
        ServerSettings.reload
      end
    end
  end

  describe "role accessor" do
    context "exist role" do
      it 'return array of hosts corresponds to role' do
        ServerSettings.load_from_yaml(config1)
        expect(ServerSettings.role1.hosts.with_format("%host")).to eq(["1.1.1.1", "2.2.2.2"])
      end
    end

    context "not exist role" do
      it 'return nil' do
        ServerSettings.load_from_yaml(config1)
        expect(ServerSettings.not_found_role).to be_nil
      end
    end
  end

  describe "each role" do
    it 'can iterate each server' do
      ServerSettings.load_from_yaml(config1)
      expect { |b|  ServerSettings.each_role(&b) }.to  yield_successive_args([String, Array],
                                                                             [String, Array])
    end
  end

  describe "with_format" do
    it 'can format host string with configuration params' do
      ServerSettings.load_from_yaml(config1)
      expect(ServerSettings.role1.with_format("%host:%port")).to eq(["1.1.1.1:1000", "2.2.2.2:1000"])
    end
  end

  describe "render erb yaml" do
    it 'can render yaml file using erb' do
      ip = "4.4.4.4"
      ServerSettings.load_from_yaml_erb(<<-EOF, erb_binding: binding)
role:
  hosts:
    - <%= ip %>
EOF
      expect(ServerSettings.role.hosts.first.host).to eq("4.4.4.4")
    end
  end

  describe 'databases' do
    let (:db_config)  { <<EOS }
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
  shards:
    user_shard_1:
      :database: app_user_shard1
      :master: 192.168.30.86
      :backup: 192.168.30.85
    user_shard_2:
      :database: app_user_shard2
      :master: 192.168.30.86
      :backup: 192.168.30.85
  db2:
    :database: app_db2
    :master: 192.168.30.86
    :backup: 192.168.30.85
    :slaves: [  192.168.30.87, 192.168.30.88 ]
  group1:
    db3:
      :master: 192.168.30.86
      :backup: 192.168.30.85
    db4:
      :database: db4
      :master: 192.168.30.86
      :backup: 192.168.30.85
  db4:
    :database: another_db4
    :master: 192.168.30.86
    :backup: 192.168.30.85
EOS

    describe ServerSettings::Database do

      context "db in group" do
        it 'describe database with group' do
          ServerSettings.load_from_yaml(db_config)
          db = ServerSettings.databases.find("user_shard_1", "shards")

          expect(db.group).to eq("shards")
          expect(db.config(:master)).to eq({
                                             :adapter => "mysql2",
                                             :database => "app_user_shard1",
                                             :encoding => "utf8",
                                             :host => "192.168.30.86",
                                             :password => "db_pass1",
                                             :pool => 10,
                                             :reconnect => true,
                                             :username => "db_user1"})
          expect(db.config(:backup)).to eq({
                                             :adapter => "mysql2",
                                             :database => "app_user_shard1",
                                             :encoding => "utf8",
                                             :host => "192.168.30.85",
                                             :password => "db_pass1",
                                             :pool => 10,
                                             :reconnect => true,
                                             :username => "db_user1"})
          expect(db.has_slave?).to be_falsey

        end
        context "when yaml has another same db setting" do
          it "" do
            ServerSettings.load_from_yaml(db_config)
          end
        end
      end

      context "db not in group" do
        it 'describe database instance without group' do
          ServerSettings.load_from_yaml(db_config)
          db = ServerSettings.databases.find("db1")
          expect(db.group).to be_nil
          expect(db.config(:master)).to eq({
                                             :adapter => "mysql2",
                                             :database => "app_db1",
                                             :encoding => "utf8",
                                             :host => "192.168.30.86",
                                             :password => "db_pass1",
                                             :pool => 10,
                                             :reconnect => true,
                                             :username => "db_user1"})
          expect(db.config(:backup)).to eq({
                                             :adapter => "mysql2",
                                             :database => "app_db1",
                                             :encoding => "utf8",
                                             :host => "192.168.30.85",
                                             :password => "db_pass1",
                                             :pool => 10,
                                             :reconnect => true,
                                             :username => "db_user1"})
          expect(db.has_slave?).to be_falsey
        end
      end

      context 'db has slaves' do
        it 'has slaves and return slave configurations' do
          ServerSettings.load_from_yaml(db_config)
          db = ServerSettings.databases.find("db2")
          expect(db.has_slave?).to be_truthy
          expect(db.config(:slaves)[0]).to eq({
                                             :adapter => "mysql2",
                                             :database => "app_db2",
                                             :encoding => "utf8",
                                             :host => "192.168.30.87",
                                             :password => "db_pass1",
                                             :pool => 10,
                                             :reconnect => true,
                                             :username => "db_user1"})

        end
      end

    end

    describe "hosts" do
      it 'return array of db instance' do
        ServerSettings.load_from_yaml(db_config)
        expect(ServerSettings.databases.hosts).to include(instance_of(ServerSettings::Database))
      end
    end

    describe "find" do
      it 'return db instance ' do
        ServerSettings.load_from_yaml(db_config)
        db1 = ServerSettings.databases.find("db1")
        expect(db1.master).to eq("192.168.30.86")
        expect(db1.backup).to eq("192.168.30.85")
        expect(db1.settings[:database]).to eq("app_db1")
        expect(db1.settings[:username]).to eq("db_user1")
      end

      it 'return nil if not found' do
        ServerSettings.load_from_yaml(db_config)
        db = ServerSettings.databases.find("not-found")
        expect(db).to be_nil
      end
    end


    describe "each" do
      it 'loop 8 times yield with db argument' do
        ServerSettings.load_from_yaml(db_config)
        args = 8.times.map {ServerSettings::Database}
        expect { |b| ServerSettings.databases.each(&b)}.to yield_control.exactly(8).times
        expect { |b| ServerSettings.databases.each(&b)}.to yield_successive_args(*args)
      end
    end
  end

  describe "structured hosts" do
    describe "ServerSettings::HostCollection#with_hash" do
      context "with default port" do
        let(:structured_hosts_config) { <<EOS }
memcached:
  port: 11211
  hosts:
    -
      name: test-1
      host: 127.0.0.1
    -
      name: test-2
      host: 192.168.0.2
EOS

        before do
          ServerSettings.load_from_yaml(structured_hosts_config)
        end

        it "returns array with hash" do
          expect(ServerSettings.memcached.hosts.with_hash).to include(
            {"name" => "test-1", "host" => "127.0.0.1", "port" => 11211},
            {"name" => "test-2", "host" => "192.168.0.2", "port" => 11211}
          )
        end
      end

      context "with default host and port" do
        let(:structured_hosts_config) { <<EOS }
memcached:
  port: 11211
  host: 127.0.0.1
  hosts:
    -
      name: test-1
    -
      name: test-2
      host: 192.168.0.2
EOS

        before do
          ServerSettings.load_from_yaml(structured_hosts_config)
        end

        it "returns array with hash" do
          expect(ServerSettings.memcached.hosts.with_hash).to include(
            {"name" => "test-1", "host" => "127.0.0.1", "port" => 11211},
            {"name" => "test-2", "host" => "192.168.0.2", "port" => 11211}
          )
        end
      end
    end

    describe "ServerSettings::HostCollection#with_format" do
      context "with default host and port" do
        let(:structured_hosts_config) { <<EOS }
memcached:
  port: 11211
  host: 127.0.0.1
  hosts:
    -
      name: test-1
    -
      name: test-2
      host: 192.168.0.2
EOS

        before do
          ServerSettings.load_from_yaml(structured_hosts_config)
        end

        it "returns Array with string" do
          expect(ServerSettings.memcached.hosts.with_format("%host:%port")).to include(
            "127.0.0.1:11211",
            "192.168.0.2:11211"
          )
        end
      end
    end
  end
end
