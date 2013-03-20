require 'redmine'

ActionDispatch::Callbacks.to_prepare do
  require "ovlinks_application_controller_patch"
  require "ovlinks_application_helper_patch"
  require "ovlinks_issue_patch"
  require "ovlinks_issues_controller_hooks"
end

Redmine::Plugin.register :redmine_onevision_links do
  name 'Redmine Onevision Links plugin'
  author 'Stefan Langenmaier'
  description 'This is a plugin for Redmine that adds the ability to create links instead of attachments from the local filesystem'
  version '0.0.1'
  url 'http://www.onevision.com'
  author_url 'http://www.onevision.com/about/Stefan.Langenmaier'
end
