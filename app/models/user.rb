class User < ActiveRecord::Base

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.hashed_password != expected_password
	user = nil
      end
    end
    user
  end

end
