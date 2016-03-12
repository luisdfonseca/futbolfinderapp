module SessionsHelper

	# Logs in the given business.
	def log_in(business)
		session[:business_id] = business.id
	end

	 # Remembers a business in a persistent session.
  def remember(business)
    business.remember
    cookies.permanent.signed[:business_id] = business.id
    cookies.permanent[:remember_token] = business.remember_token
  end

	 # Returns the current logged-in business (if any).
  def current_business
    if (business_id = session[:business_id])
      @current_business ||= Business.find_by(id: business_id)
    elsif (business_id = cookies.signed[:business_id])
      business = Business.find_by(id: business_id)
      if business && business.authenticated?(cookies[:remember_token])
        log_in business
        @current_business = business
      end
    end
  end

  # Returns true if the business is logged in, false otherwise.
  def logged_in?
    !current_business.nil?
  end

  # Forgets a persistent session.
  def forget(business)
    business.forget
    cookies.delete(:business_id)
    cookies.delete(:remember_token)
  end

  #logs out the current business
  def log_out
  	forget(current_business)
  	session.delete(:business_id)
  	@current_business = nil
  end
end
