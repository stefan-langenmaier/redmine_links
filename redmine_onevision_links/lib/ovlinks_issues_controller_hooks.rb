module OVLinksPlugin
  module Hooks

     class ControllerIssuesNewAfterSaveHook < Redmine::Hook::ViewListener
      def controller_issues_new_before_save(context={})

        context[:issue].save_links(context[:params][:links] || (context[:issue] && context[:issue][:uploads]))

        return ''
      end

    end
    
  end
end
