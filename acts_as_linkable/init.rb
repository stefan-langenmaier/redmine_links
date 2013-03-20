require File.dirname(__FILE__) + '/lib/acts_as_linkable'
ActiveRecord::Base.send(:include, Redmine::Acts::Linkable)
