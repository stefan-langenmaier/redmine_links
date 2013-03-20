require_dependency 'application_helper'

# Patches Redmine's Attachment dynamically.
module OVLinks
  module ApplicationHelperPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
  
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        # Generates a link to an attachment.
        # Options:
        # * :text - Link text (default to attachment filename)
        # * :download - Force download (default: false)
        def link_to_link(link, options={})
          text = options.delete(:text) || link.filename
          action = options.delete(:download) ? 'download' : 'show'
          opt_only_path = {}
          opt_only_path[:only_path] = (options[:only_path] == false ? false : true)
          options.delete(:only_path)
          link_to(h(text),
                 {:controller => 'links', :action => action,
                  :id => link, :filename => link.filename}.merge(opt_only_path),
                 options)
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
ApplicationHelper.send(:include, OVLinks::ApplicationHelperPatch)