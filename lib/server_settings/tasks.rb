spec = Gem::Specification.find_by_name "server_settings"
load "#{spec.gem_dir}/lib/server_settings/tasks/db.rake"
