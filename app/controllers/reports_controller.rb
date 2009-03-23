class ReportsController < ApplicationController
  
  def bomnew
    if request.post?
      brecord = params[:brecord]
      brecord.each do |key, value|
        logger.info "key: #{key} -- value: #{value}"
      end
    end
    render :layout=>false
  end
  
  def bomvalnew
    render :layout=>false
  end
  
  def ei
    render :layout=>false
  end
  
  def odm
    render :layout=>false
  end
  
  def req
    render :layout=>false
  end
  
  def wa
    render :layout=>false
  end
end
