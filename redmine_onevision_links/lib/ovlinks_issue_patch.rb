require_dependency 'issue'

# Patches Redmine's Attachment dynamically.
module OVLinks
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
  
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        acts_as_linkable :after_add => :link_added, :after_remove => :link_removed
        
        # Callback on link addition
        def link_added(obj)
          if @current_journal && !obj.new_record?
            @current_journal.details << JournalDetail.new(:property => 'link', :prop_key => obj.id, :value => obj.fileaddress)
          end
        end
      
        # Callback on link deletion
        def link_removed(obj)
          if @current_journal && !obj.new_record?
            @current_journal.details << JournalDetail.new(:property => 'link', :prop_key => obj.id, :old_value => obj.fileaddress)
            @current_journal.save
          end
        end
      end
  
    end

    module ClassMethods
    end
    
    module InstanceMethods  
    end
    
  end
end

# Add module to Issue
Issue.send(:include, OVLinks::IssuePatch)