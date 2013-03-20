module Redmine
  module Acts
    module Linkable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_linkable(options = {})
          cattr_accessor :linkable_options
          self.linkable_options = {}
          linkable_options[:view_permission] = options.delete(:view_permission) || "view_#{self.name.pluralize.underscore}".to_sym
          linkable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{self.name.pluralize.underscore}".to_sym
          
          has_many :links, options.merge(:as => :container,
                                               :order => "#{Link.table_name}.created_on",
                                               :dependent => :destroy)
          send :include, Redmine::Acts::Linkable::InstanceMethods
          before_save :attach_saved_links
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        def links_visible?(user=User.current)
          (respond_to?(:visible?) ? visible?(user) : true) &&
            user.allowed_to?(self.class.linkable_options[:view_permission], self.project)
        end

        def links_deletable?(user=User.current)
          (respond_to?(:visible?) ? visible?(user) : true) &&
            user.allowed_to?(self.class.linkable_options[:delete_permission], self.project)
        end

        def saved_links
          @saved_links ||= []
        end

        def unsaved_links
          @unsaved_links ||= []
        end

        def save_links(links, author=User.current)
          if links.is_a?(Hash)
            links = links.values
          end
          if links.is_a?(Array)
            links.each do |link|
              l = nil
              fa = link['fileaddress']
              unless fa.nil? || fa==""
#                next unless fa.size > 0
                l = Link.create(:file => fa, :author => author)
#              elsif token = link['token']
#                l = Link.find_by_token(token)
#                next unless l
#                l.filename = link['filename'] unless link['filename'].blank?
#                l.content_type = link['content_type']
              end
              next unless l
              l.description = link['description'].to_s.strip
              if l.new_record?
                unsaved_links << l
              else
                saved_links << l
              end
            end
          end
          {:files => saved_links, :unsaved => unsaved_links}
        end

        def attach_saved_links
          saved_links.each do |link|
            self.links << link
          end
        end

        module ClassMethods
        end
      end
    end
  end
end
