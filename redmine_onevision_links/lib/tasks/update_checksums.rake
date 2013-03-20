desc 'update link checksums'

namespace :redmine do
  task :update_checksums => [:environment] do
    

    puts "Update link checksums..."
    Link.record_timestamps = false
    $stdout.sync = true
    
    Link.find_each() do |l|
      puts "Link #{l.id}"

      if l.readable?
        begin
        print "CALCULATING "
        f = File.new(l.diskfile)

        md5 = Digest::MD5.new
        if f.respond_to?(:read)
          buffer = ""
          while (buffer = f.read(8192))
            md5.update(buffer)
            print "."
          end
        else
          md5.update(f)
        end
        l.digest = md5.hexdigest
        puts ""
        l.save
        rescue
        end
      end
    end
    puts "Update link checksums done"

    
  end
end

