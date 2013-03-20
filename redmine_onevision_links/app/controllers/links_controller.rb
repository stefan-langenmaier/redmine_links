class LinksController < ApplicationController
  before_filter :find_project, :except => [:upload, :add, :browse]
  before_filter :file_readable, :read_authorize, :only => [:show, :download]
  before_filter :delete_authorize, :only => :destroy
  before_filter :authorize_global, :only => :upload
  
  accept_api_auth :show, :download, :upload
  
  def add
    @base_folder = Redmine::Configuration['links_storage_path'] || "/Net/raid3/PSDaten/"
    
    path = File.join(@base_folder, params[:path])
    unless File.expand_path(path).start_with?(@base_folder)
      redirect_to :controller => 'issues', :action => 'show', :id => issue.id
    end
    issue = Issue.find(params[:id])

    l = Link.new
    l.file = path
    l.author = User.current
    issue.links << l
    issue.save
    
    redirect_to :controller => 'issues', :action => 'show', :id => issue.id

  end
  
  def browse
    @base_folder = Redmine::Configuration['links_storage_path'] || "/Net/raid3/PSDaten/"
    
    @current_folder_short = ""
    @current_folder_short = params[:path] if params[:path]
    
    @current_folder = File.realpath(@current_folder_short, @base_folder)
    
    unless @current_folder.start_with?(@base_folder) || (File.realpath(@base_folder) == File.realpath(@current_folder))
      @current_folder = @base_folder
      @current_folder_short = ""
    end
    
    respond_to do |format|
      format.html { render :action => 'browse' }
    end
  end
      
  def show
    respond_to do |format|
      format.html {
        if @link.is_diff?
          @diff = File.new(@link.diskfile, "rb").read
          @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
          @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
          # Save diff type as user preference
          if User.current.logged? && @diff_type != User.current.pref[:diff_type]
            User.current.pref[:diff_type] = @diff_type
            User.current.preference.save
          end
          render :action => 'diff'
        elsif @link.is_text? && @link.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
          @content = File.new(@link.diskfile, "rb").read
          render :action => 'file'
        else
          download
        end
      }
      format.api
    end
  end
  
  def download
    if @link.container.is_a?(Version) || @link.container.is_a?(Project)
      @link.increment_download
    end
    
    # images are sent inline
    send_file @link.diskfile, :filename => filename_for_content_disposition(@link.filename),
                                    :type => detect_content_type(@link), 
                                    :disposition => (@link.image? ? 'inline' : 'link')   
  end
  
  def upload
    render :nothing => true, :status => 406
    return
  end
  
  def destroy
    if @link.container.respond_to?(:init_journal)
      @link.container.init_journal(User.current)
    end
    # Make sure association callbacks are called
    @link.container.links.delete(@link)
    redirect_to_referer_or project_path(@project)
  end
  
private
  def find_project
    @link = Link.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @link.filename
    @project = @link.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Checks that the file exists and is readable
  def file_readable
    @link.readable? ? true : render_404
  end
  
  def read_authorize
    @link.visible? ? true : deny_access
  end
  
  def delete_authorize
    @link.deletable? ? true : deny_access
  end
  
  def detect_content_type(link)
    content_type = link.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(link.filename)
    end
    content_type.to_s
  end
end
