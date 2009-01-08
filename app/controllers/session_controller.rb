class SessionController < ApplicationController

  before_filter :authorize, :except => [ :login, :logout ]

  def index
    redirect_to('/')
  end

  def login
    session[:user] = nil
    if request.post?
      user = Bdbuser.authenticate(params[:username], params[:password])
      if user
        session[:user] = user
        redirect_to('/')
      else
        flash[:notice] = 'Invalid user/password combination'
      end
    end
  end

  def logout
    session[:user] = nil
    flash[:notice] = 'Logged out'
    redirect_to(:action => 'login')
  end

end
