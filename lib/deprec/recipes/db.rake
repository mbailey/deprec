require 'find'
namespace :deprec do

  namespace :db do

    # Task written by Craig Ambrose <craigambrose.com>
    desc "Backup the database to a file. Options: DIR=backup_dir RAILS_ENV=production MAX=20" 
    task :backup => :environment do
      unless defined? RAILS_ENV
        RAILS_ENV = ENV['RAILS_ENV'] ||= 'development'
      end
      max_backups = (ENV['MAX'] || 20).to_i
      datestamp = Time.now.strftime("%Y%m%d-%H%M%S")    
      backup_dir = ENV['DIR'] || "db/backups"
      backup_file = File.join(backup_dir, "#{RAILS_ENV}-#{datestamp}.sql.gz")    
      FileUtils.mkdir_p(backup_dir)
      db_config = ActiveRecord::Base.configurations[RAILS_ENV]    
      pass = ''
      pass = '-p' + db_config['password'] if db_config['password']
      sh "mysqldump -u #{db_config['username']} #{pass} #{db_config['database']} -Q --add-drop-table -O add-locks=FALSE -O lock-tables=FALSE | gzip -c > #{backup_file}"     
      puts "Created backup: #{backup_file}"     
      dir = Dir.new(backup_dir)
      all_backups = dir.entries[2..-1].sort.reverse
      unwanted_backups = all_backups[max_backups..-1] || []
      for unwanted_backup in unwanted_backups
        FileUtils.rm_rf(File.join(backup_dir, unwanted_backup))
        puts "deleted #{unwanted_backup}" 
      end
      puts "Deleted #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available" 
    end

    desc "Restore database [Pending]"
    task :restore => :environment do
      puts "This task is looking for a volunteer!"
    end

  end
end
