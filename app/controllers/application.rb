# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '41d234712db73b178fd610a5d62d048b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  # disable CSRF protection
  self.allow_forgery_protection = false


  protected

  def authorize
    unless admin?
      flash[:notice] = "Unauthorized access"
      redirect_to :controller => 'brecords'
      false
    end
  end

  def admin?
    session[:password] == 'sherpa'
  end

end
