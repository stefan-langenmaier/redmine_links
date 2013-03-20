module LinksHelper
  # Displays view/delete links to the links of the given object
  # Options:
  #   :author -- author names are not displayed if set to false
  def link_to_links(container, options = {})
    options.assert_valid_keys(:author)
    
    if container.links.any?
      options = {:deletable => container.links_deletable?, :author => true}.merge(options)
      render :partial => 'links/links', :locals => {:links => container.links, :options => options}
    end
  end
  
  def render_api_link(link, api)
    api.link do
      api.id link.id
      api.filename link.filename
      api.filesize link.filesize
      api.content_type link.content_type
      api.description link.description
      api.content_url url_for(:controller => 'links', :action => 'download', :id => link, :filename => link.filename, :only_path => false)
      api.author(:id => link.author.id, :name => link.author.name) if link.author
      api.created_on link.created_on
    end
  end
end
