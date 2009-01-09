# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  STARS = '****************************** '

  def log(message)
    logger.error(STARS + message)
  end

end
