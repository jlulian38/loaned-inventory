class ApplicationController < ActionController::Base
	protect_from_forgery
	layout 'application'
    helper_method :current_user

	before_filter :check_sign_in
	before_filter :set_current_administrator
 
	def current_user
		@current_user ||= Administrator.find_by_remember_token(session[:user_token]) if session[:user_token]
		@current_user
	end
  
	def check_sign_in
		if current_user.nil? then
			flash[:info] = "You're not logged in!"
			redirect_to login_path
		end
	end
	
	#haha wow this naming scheme is really confused...
	def set_current_administrator
      Administrator.current = current_user
    end
end
