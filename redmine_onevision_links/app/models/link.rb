require "digest/md5"

class Link < ActiveRecord::Base
  belongs_to :container, :polymorphic => true
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  
  validates_presence_of :filename, :author
  validates_length_of :filename, :maximum => 255
  
  acts_as_event :title => :filename,
                :url => Proc.new {|o| {:controller => 'links', :action => 'download', :id => o.id, :filename => o.filename}}

  acts_as_activity_provider :type => 'files',
                            :permission => :view_files,
                            :author_key => :author_id,
                            :find_options => {:select => "#{Link.table_name}.*", 
                                              :joins => "LEFT JOIN #{Version.table_name} ON #{Link.table_name}.container_type='Version' AND #{Version.table_name}.id = #{Link.table_name}.container_id " +
                                                        "LEFT JOIN #{Project.table_name} ON #{Version.table_name}.project_id = #{Project.table_name}.id OR ( #{Link.table_name}.container_type='Project' AND #{Link.table_name}.container_id = #{Project.table_name}.id )"}
  
  acts_as_activity_provider :type => 'documents',
                            :permission => :view_documents,
                            :author_key => :author_id,
                            :find_options => {:select => "#{Link.table_name}.*", 
                                              :joins => "LEFT JOIN #{Document.table_name} ON #{Link.table_name}.container_type='Document' AND #{Document.table_name}.id = #{Link.table_name}.container_id " +
                                                        "LEFT JOIN #{Project.table_name} ON #{Document.table_name}.project_id = #{Project.table_name}.id"}

  cattr_accessor :storage_path
  @@storage_path = Redmine::Configuration['links_storage_path'] || "/Net/raid3/PSDaten/"
  
#  before_save :files_to_final_location
#  after_destroy :delete_from_disk


  # Returns an unsaved copy of the attachment
  def copy(attributes=nil)
    copy = self.class.new
    copy.attributes = self.attributes.dup.except("id", "downloads")
    copy.attributes = attributes if attributes
    copy
  end

  def Link.is_internal(internal)
    @@internal = internal
  end
  
  def is_internal?()
    @@internal
  end
  
  
  def fa_exists(fa)
    link_root = self.class.storage_path
    
    fs = "\\"
    fs = "/" if link_root[0] == "/"
    
    
    fp = fa.gsub(/^[a-zA-Z]:\\/, link_root) .gsub("\\", fs) #if <LETTER>:\
    return fp if File.file?(fp)
    
    fp = fa.gsub(/^[a-zA-Z]:\\PSDaten\\/, link_root).gsub("\\", fs) #if <LETTER>:\PSDaten\
    return fp if File.file?(fp)
    
    fp = fa.gsub(/^\\\\raid\d?\\/, link_root).gsub("\\", fs) #if \\raid<DIGIT>\
    return fp if File.file?(fp)
    
    fp = fa.gsub(/^\\\\raid\d?\\PSDaten\\/, link_root).gsub("\\", fs) #if \\raid<DIGIT>\PSDaten\
    return fp if File.file?(fp)
    
    fp = fa.gsub(/^\/Net\/raid\d?\//, link_root).gsub("/", fs) #if /net/raid<DIGIT>
    return fp if File.file?(fp)
    
    fp = fa.gsub(/^\/Net\/raid\d\/PSDaten\//, link_root).gsub("/", fs) #if /net/raid<DIGIT>/PSDaten
    return fp if File.file?(fp)
    
    return nil
  end

  def file=(fa)
    fp = fa_exists(fa)
    unless fp.nil?
      @temp_file = File.new(fp)

      self.fileaddress = fp.gsub(self.class.storage_path, '')
      if @temp_file.size > 0
        self.filename = File.basename(fp)
        self.filename.force_encoding("UTF-8") if filename.respond_to?(:force_encoding)        
        self.content_type = Redmine::MimeType.of(filename)
        self.filesize = @temp_file.size

        #calculate digest right here because the file does not need to be moved around
        md5 = Digest::MD5.new
        if @temp_file.respond_to?(:read)
          buffer = ""
          while (buffer = @temp_file.read(8192))
            md5.update(buffer)
          end
        else
          md5.update(@temp_file)
        end
        self.digest = md5.hexdigest
        
      end
    end
  end
	
  def file
    nil
  end
  
  def filename=(arg)
    write_attribute :filename, sanitize_filename(arg.to_s)
#    if new_record? && disk_filename.blank?
#      self.disk_filename = Link.disk_filename(filename)
#    end
    filename
  end

#  # Copies the temporary file to its final location
#  # and computes its MD5 hash
#  def files_to_final_location
#    if @temp_file && (@temp_file.size > 0)
#      logger.info("Saving link '#{self.diskfile}' (#{@temp_file.size} bytes)")
#      md5 = Digest::MD5.new
##      File.open(diskfile, "wb") do |f|
#        if @temp_file.respond_to?(:read)
#          buffer = ""
#          while (buffer = @temp_file.read(8192))
##            f.write(buffer)
#            md5.update(buffer)
#          end
#        else
##          f.write(@temp_file)
#          md5.update(@temp_file)
#        end
##      end
#      self.digest = md5.hexdigest
#    end
#    @temp_file = nil
#    # Don't save the content type if it's longer than the authorized length
#    if self.content_type && self.content_type.length > 255
#      self.content_type = nil
#    end
#  end

#  # Deletes the file from the file system if it's not referenced by other attachments
#  def delete_from_disk
#    if Attachment.first(:conditions => ["disk_filename = ? AND id <> ?", disk_filename, id]).nil?
#      delete_from_disk!
#    end
#    nil
#  end

  # Returns file's location on disk
  def diskfile
    File.join(self.class.storage_path, fileaddress)
  end
  
  def increment_download
    increment!(:downloads)
  end

  def project
    container.try(:project)
  end

  def visible?(user=User.current)
    container && container.attachments_visible?(user)
  end

  def deletable?(user=User.current)
    container && container.attachments_deletable?(user)
  end
  
  def image?
    self.filename =~ /\.(bmp|gif|jpg|jpe|jpeg|png)$/i
  end
  
  def is_text?
    Redmine::MimeType.is_type?('text', self.class.storage_path + fileaddress)
  end
  
  def is_diff?
    self.filename =~ /\.(patch|diff)$/i
  end
  
  # Returns true if the file is readable
  def readable?
    File.readable?(diskfile)
  end
  
  # Returns the attachment token
  def token
    "#{id}.#{digest}"
  end

  # Finds an attachment that matches the given token and that has no container
#  def self.find_by_token(token)
#    if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
#      attachment_id, attachment_digest = $1, $2
#      attachment = Attachment.first(:conditions => {:id => attachment_id, :digest => attachment_digest})
#      if attachment && attachment.container.nil?
#        attachment
#      end
#    end
#  end

  # Bulk attaches a set of files to an object
  #
  # Returns a Hash of the results:
  # :files => array of the attached files
  # :unsaved => array of the files that could not be attached
  def self.attach_files(obj, links)
    #result = obj.save_attachments(attachments, User.current)
    #obj.attach_saved_attachments
    #result

    attached = []
    if links && links.is_a?(Hash)
      links.each_value do |link|
        #@@fileaddress = link['fileaddress']
        fa = link['fileaddress']
#        file = link['file']
        #file['fileaddress'] = link['fileaddress']
        next unless file && file.size > 0
        l = Link.create(:container => obj, 
                              :file => fa,
                              :description => link['description'].to_s.strip,
                              :author => User.current)
#        a.fileaddress = fa
#        a.save
        if l.new_record?
          obj.unsaved_links ||= []
          obj.unsaved_links << l
        else
          attached << l
        end
      end
    end
    {:files => attached, :unsaved => obj.unsaved_links}
  end
  
  def self.latest_attach(attachments, filename)
    links.sort_by(&:created_on).reverse.detect {
      |link| link.filename.downcase == filename.downcase
     }
  end

  def self.prune(age=1.day)
    links = Link.all(:conditions => ["created_on < ? AND (container_type IS NULL OR container_type = '')", Time.now - age])
    links.each(&:destroy)
  end

  private

  # Physically deletes the file from the file system
#  def delete_from_disk!
#    if disk_filename.present? && File.exist?(diskfile)
#      File.delete(diskfile)
#    end
#  end
  
  def sanitize_filename(value)
    # get only the filename, not the whole path
    just_filename = value.gsub(/^.*(\\|\/)/, '')

    # Finally, replace invalid characters with underscore
    @filename = just_filename.gsub(/[\/\?\%\*\:\|\"\'<>]+/, '_') 
  end
  
  # Returns an ASCII or hashed filename
  def self.fileaddress(filename)
#    timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
#    ascii = ''
#    if filename =~ %r{^[a-zA-Z0-9_\.\-]*$}
#      ascii = filename
#    else
#      ascii = Digest::MD5.hexdigest(filename)
#      # keep the extension if any
#      ascii << $1 if filename =~ %r{(\.[a-zA-Z0-9]+)$}
#    end
#    while File.exist?(File.join(@@storage_path, "#{timestamp}_#{ascii}"))
#      timestamp.succ!
#    end
#    "#{timestamp}_#{ascii}"
    "#{@@storage_path}#{fileaddress}"
  end
end
