desc 'update link fileaddress'

namespace :redmine do
  task :update_links => [:environment] do
    

    puts "Update links..."
    Link.record_timestamps = false
    nf = []
    Link.find_each(:conditions => "fileaddress IS NOT NULL") do |l|
      puts "Link #{l.id}"
      fa = l.fileaddress
      op = l.fileaddress
      fa = fa.gsub("\\", "/") #transform the file sperator to linux
      fa = fa.sub("file:///", "") #remove the file:/// prefix
      fa = fa.sub(/^[a-zA-Z]:\//, "") #remove possible drive letter
      fa = fa.sub(/^\/\/raid\d?\//i, "") #remove possible raid<DIGIT>
      fa = fa.sub(/^\/\/subnet\-homes\//i, "") #remove possible //subnet-homes/
      fa = fa.sub(/^psdaten\//i, "") #remove possible PSDaten folder

      l.fileaddress = fa.to_s

      l.save
      unless l.readable?
#        puts "ERROR #{l.id} - #{l.errors.inspect}"
#      else
				l.description = "#{l.description} // Orginal path: #{op}"
				l.save
        puts "NOT FOUND #{l.id} - #{l.diskfile}"
        nf << l.id
      end
    end
    puts "Update link fileaddress done"
    puts nf.join(", ")

    
  end
end

