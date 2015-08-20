require 'spec_helper'
require 'server_settings'

describe "ServerSettings::DatabaseConfig" do
  let (:config1) do
          yaml_text = <<-EOF
---
databases: &default
  :adapter: mysql2
  :encoding: utf8
  :reconnect: true
  :database: server_settings
  :pool: 5
  :username: monsterstrike
  :password: monsterstrike
  :master: localhost
  user:
    <<: *default
    :database: server_settings_user
  has_slave:
    <<: *default
    :database: server_settings_has_slave
    :slaves: [ localhost ]
  archive:
    archive_me:
      <<: *default
  has_backup:
    <<: *default
    :backup: 'backup.com'
  no_backup:
    <<: *default
EOF
  end
  before do
    filepath = "config.yml"
    allow(IO).to receive(:read).with(filepath).and_return(config1)
    allow(File).to receive(:mtime).with(filepath).and_return(Time.now)
    ServerSettings.load_config("config.yml")
  end
  after do
    ServerSettings.destroy
  end
  describe ".slave_name" do
    it { expect(ServerSettings::DatabaseConfig.slave_name("hoge", 1)).to eq "hoge_slave1" }
  end
  describe ".generate_database_config" do
    context "check configuration" do
      let(:database_config) { database_config = ServerSettings::DatabaseConfig.generate_database_config(:master) }
      it "contain `user` key" do
        expect(database_config["user"].class).to eq Hash
      end
      context "when has slave" do
        it "contain slave key" do
          expect(database_config["has_slave_slave1"].class).to eq Hash
        end
      end
      context "when has group" do
        it "create nest configuration" do
          expect(database_config["archive"]["archive_me"].class).to eq Hash
        end
      end
      context "when no slaves options" do
        it "does not exist slave key" do
          no_slave_config = ServerSettings::DatabaseConfig.generate_database_config(:master, with_slave: false)
          expect(no_slave_config.has_key? "has_slave_slave1").to be false
        end
      end
      context "when use backup role" do
        let(:backup_config) { ServerSettings::DatabaseConfig.generate_database_config :backup }
        it "change host to backup" do
          expect(backup_config["has_backup"][:host]).to eq "backup.com"
        end
        it "does not set key, when not set backup" do
          expect(backup_config.has_key? "no_backup").to eq false
        end
      end
    end
    context "when use rails" do
      before do
        module Rails
          def self.env
          end
        end
        allow(Rails).to receive(:env).and_return("test")
      end
      it "contain environment key" do
        database_config = ServerSettings::DatabaseConfig.generate_database_config(:master)
        expect(database_config["test"]).not_to eq nil
      end
      it "returns configs with string keys" do
        database_config = ServerSettings::DatabaseConfig.generate_database_config(:master)
        expect(database_config["user"].keys.all? { |k| k.is_a? String }).to be true
        expect(database_config["has_slave_slave1"].keys.all? { |k| k.is_a? String }).to be true
      end
    end
  end
end
