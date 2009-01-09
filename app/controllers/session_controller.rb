class SessionController < ApplicationController

  before_filter :authorize, :except => [ :login, :logout ]

  def index
    redirect_to('/')
  end

  def login
    session[:user] = nil
    if request.post?
      user = Bdbuser.authenticate(params[:username], params[:password])
      if user[:logged_in]
        session[:user] = user
        uri = session[:original_uri]
	session[:original_uri] = nil
	redirect_to(uri || '/')
      else
        flash[:notice] = user[:log_message]
      end
    end
  end

  def logout
    session[:user] = nil
    flash[:notice] = MSG['LOGGED_OUT']
    redirect_to(:action => 'login')
  end

end
