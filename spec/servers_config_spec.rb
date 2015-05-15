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

  describe "config_load" do
    before do
      filepath = "config.yml"
      allow(IO).to receive(:read).with(filepath).and_return(config1)
      allow(File).to receive(:mtime).with(filepath).and_return(Time.now)
    end

    it 'can load yaml file' do
      ServerSettings.load_config("config.yml")
    end

    it 'can override role by another config' do

      ServerSettings.load_config("config.yml")
      expect(ServerSettings.role2.hosts.with_format("%host")).to eq(["3.3.3.3"])
      allow(IO).to receive(:read).with("config2.yml").and_return(config2)
      allow(File).to receive(:mtime).with("config2.yml").and_return(Time.now)

      # load again
      ServerSettings.load_config("config2.yml")
      expect(ServerSettings.role2.hosts.with_format("%host")).to eq(["4.4.4.4"])
    end

    ## TODO check invalid yaml

    after do
      ServerSettings.destroy
    end
  end

  describe "load_config_dir" do
    it 'can load yaml files from directory pattern' do
      ServerSettings.load_config_dir("spec/test-yaml/*.yml")
      expect( ServerSettings.roles.keys.sort ).to eq(["role1", "role2"])
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
end
