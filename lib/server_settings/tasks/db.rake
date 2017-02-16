namespace :server_settings do
  namespace :db do
    namespace :create do
      require "colorize"

      def build_new_db_configs
        ServerSettings::DatabaseConfig.generate_database_config(:master).each_with_object([]) do |(_, config), new_db_configs|
          client = Mysql2::Client.new(username: config["username"], password: config["password"], host: config["host"])
          if client.query("SHOW DATABASES LIKE '#{ config['database'] }'").to_a.blank?
            new_db_configs << [config, client]
          else
            client.close
          end
        end
      end

      def show_all_databases(all_db_configs)
        if all_db_configs.blank?
          puts "There is no databases."
        else
          all_db_configs.each do |config, _|
            puts format("* %-15s: exists database '%s'", config["host"], config["database"]).colorize(:green)
          end
        end
      end

      def show_new_databases(new_db_configs)
        if new_db_configs.blank?
          puts "There is no new databases."
        else
          new_db_configs.each do |config, _|
            puts format("* %-15s: new database '%s'", config["host"], config["database"]).colorize(:green)
          end
        end
      end

      def close_connections(new_db_configs)
        new_db_configs.each { |_, client| client.close }
      end

      def confirm_and_execute(prompt, &block)
        print "#{ prompt } (yes/N): "
        if $stdin.gets.strip == "yes"
          block.call
        else
          puts "Operation canceled."
        end
      end

      def perform_show_status(new_db_configs)
        show_new_databases(new_db_configs)
        close_connections(new_db_configs)
      end

      def perform_create_databases(new_db_configs)
        show_new_databases(new_db_configs)
        confirm_and_execute "Are you sure you want to execute above?" do
          new_db_configs.each do |config, client|
            command = "CREATE DATABASE IF NOT EXISTS #{ config['database'] }"
            puts "Executing '#{ command }' on #{ config['host'] }"
            client.query(command)
          end
        end
      ensure
        close_connections(new_db_configs)
      end

      desc "Show status of new databases not created yet"
      task :status => :environment do
        new_db_configs = build_new_db_configs
        perform_show_status(new_db_configs)
      end

      desc "Confirm and execute CREATE DATABASE for each new database"
      task :execute => :environment do
        new_db_configs = build_new_db_configs
        next if new_db_configs.blank?
        perform_create_databases(new_db_configs)
      end
    end

    desc "Confirm and execute Drop DATABASE for all database"
    task :drop => :environment do
      all_db_configs = build_all_db_configs
      next if all_db_configs.blank?
      perform_drop_databases(all_db_configs)
    end

    def build_all_db_configs
      ServerSettings::DatabaseConfig.generate_database_config(:master).each_with_object([]) do |(_, config), all_db_configs|
        client = Mysql2::Client.new(username: config["username"], password: config["password"], host: config["host"])
        all_db_configs << [config, client]
      end
    end

    def perform_drop_databases(all_db_configs)
      show_all_databases(all_db_configs)
      confirm_and_execute "Are you sure you want to execute above?" do
        all_db_configs.each do |config, client|
          command = "DROP DATABASE IF EXISTS #{ config['database'] }"
          puts "Executing '#{ command }' on #{ config['host'] }"
          client.query(command)
        end
      end
    ensure
      close_connections(all_db_configs)
    end
  end
end
