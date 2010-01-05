# RSI: implementation idea taken from JDBC adapter
def redefine_task(*args, &block)
  task_name = Hash === args.first ? args.first.keys[0] : args.first
  existing_task = Rake.application.lookup task_name
  if existing_task
    class << existing_task; public :instance_variable_set; end
    existing_task.instance_variable_set "@prerequisites", FileList[]
    existing_task.instance_variable_set "@actions", []
  end
  task(*args, &block)
end

namespace :db do

  namespace :structure do
    redefine_task :dump => :environment do
      abcs = ActiveRecord::Base.configurations
      ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
      File.open("db/#{RAILS_ENV}_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
      if ActiveRecord::Base.connection.supports_migrations?
        File.open("db/#{RAILS_ENV}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
      end
    end
  end

  namespace :test do
    redefine_task :clone_structure => [ "db:structure:dump", "db:test:purge" ] do
      abcs = ActiveRecord::Base.configurations
      ActiveRecord::Base.establish_connection(:test)
      IO.readlines("db/#{RAILS_ENV}_structure.sql").join.split("\n\n").each do |ddl|
        ActiveRecord::Base.connection.execute(ddl.chop)
      end
    end

    redefine_task :purge => :environment do
      abcs = ActiveRecord::Base.configurations
      ActiveRecord::Base.establish_connection(:test)
      ActiveRecord::Base.connection.structure_drop.split("\n\n").each do |ddl|
        ActiveRecord::Base.connection.execute(ddl.chop)
      end
    end

  end
end
