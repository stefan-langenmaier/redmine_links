RedmineApp::Application.routes.draw do
  # additional routes for having the file name at the end of url
  match 'links/:id/:filename', :controller => 'links', :action => 'show', :id => /\d+/, :filename => /.*/, :via => :get
  match 'links/download/:id/:filename', :controller => 'links', :action => 'download', :id => /\d+/, :filename => /.*/, :via => :get
  match 'links/download/:id', :controller => 'links', :action => 'download', :id => /\d+/, :via => :get
  resources :links, :only => [:show, :destroy]
  
  match '/issues/:id/browse', :to => 'links#browse', :id => /\d+/
  match '/issues/:id/add_link', :to => 'links#add', :id => /\d+/
end
