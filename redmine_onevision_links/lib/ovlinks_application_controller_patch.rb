require_dependency 'issues_controller'
require_dependency 'projects_controller'

# Patches Redmine's Attachment dynamically.
module OVLinks
  module ApplicationControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
  
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        helper :links
        include LinksHelper
        
        before_filter :set_ip
        before_filter :set_network
        
        alias_method_chain :update, :links # no hook in update method available so the complete method has to be overriden
        alias_method_chain :render_attachment_warning_if_needed, :links
      end
  
    end

    module ClassMethods
    end
    
    module InstanceMethods
      
      def set_ip  
    
        cip = request.env['HTTP_X_FORWARDED_FOR']
        cip = request.env['REMOTE_ADDR'] unless cip
        if (["192", "168", "9"] == cip.split(".")[0..2] || ["192", "168", "100"] == cip.split(".")[0..2])  
          @viewer_is_external = false
        else
          @viewer_is_external = true
        end
      end
      
      def set_network
        # DO NOT use "REMOTE_ADDR" because that only retrieves the address of the apache proxy and is always 127.0.0.1
        cip = request.env['HTTP_X_FORWARDED_FOR']
        cip = request.env['REMOTE_ADDR'] unless cip
        if (["192", "168", "9"] == cip.split(".")[0..2] || ["192", "168", "100"] == cip.split(".")[0..2])  
           Link.is_internal(true)
        else
           Link.is_internal(false)
        end
      end
      
      # Renders a warning flash if obj has unsaved attachments or links
      def render_attachment_warning_if_needed_with_links(obj)
      	render_attachment_warning_if_needed_without_links(obj)
        flash[:warning] = l(:warning_links_not_saved, obj.unsaved_links.size) if obj.unsaved_links.present?
      end
      
      def update_with_links
        return unless update_issue_from_params
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        @issue.save_links(params[:links] || (params[:issue] && params[:issue][:uploads]))
        saved = false
        begin
          saved = @issue.save_issue_with_child_records(params, @time_entry)
        rescue ActiveRecord::StaleObjectError
          @conflict = true
          if params[:last_journal_id]
            if params[:last_journal_id].present?
              last_journal_id = params[:last_journal_id].to_i
              @conflict_journals = @issue.journals.all(:conditions => ["#{Journal.table_name}.id > ?", last_journal_id])
            else
              @conflict_journals = @issue.journals.all
            end
          end
        end
    
        if saved
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
    
          respond_to do |format|
            format.html { redirect_back_or_default({:action => 'show', :id => @issue}) }
            format.api  { head :ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.api  { render_validation_errors(@issue) }
          end
        end
      end
      
    end
  end
end

# Add module to Issue
IssuesController.send(:include, OVLinks::ApplicationControllerPatch)
ProjectsController.send(:include, OVLinks::ApplicationControllerPatch)