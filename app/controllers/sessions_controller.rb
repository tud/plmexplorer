class SessionsController < ApplicationController

  def create
    session[:password] = params[:password]
    flash[:notice] = 'Successfully logged in'
    redirect_to :controller => 'brecords'
  end

  def destroy
    reset_session
    flash[:notice] = 'Successfully logged out'
    redirect_to :action => 'login'
  end

#  def login
#    session[:user_id] = nil
#    if request.post?
#      user = User.authenticate(params[:name], params[:password])
#      if user
#	session[:user_id] = user.id
#	uri = session[:original_uri]
#	session[:original_uri] = nil
#	redirect_to(uri || { :action => "index" })
#      else
#	flash[:notice] = "Invalid user/password combination"
#      end
#    end
#  end
#
#  def logout
#    session[:user_id] = nil
#    flash[:notice] = "Logged out"
#    redirect_to(:action => "login")
#  end

end
