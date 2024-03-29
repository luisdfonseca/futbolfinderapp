class GameLinesController < ApplicationController
	include GamesHelper
	before_action :signed_in_business_or_user?, only: [:create, :update, :destroy]

	def create
		# todo- sanitize inputs
		srch_term = game_line_params[:user_id]
		user = User.where('slug = ? OR email = ? OR phone = ?', srch_term, 
			srch_term, srch_term).first
	  	@game_line = GameLine.new(game_line_params)

	  	msg_error = "Unable to add player"
	  	
	  	if !user.nil?
			@game_line[:user_id] = user.id
		else
			msg_error = "I am sorry, we couldn't find a player with " + '"' +srch_term + '"'
		end

	  	if @game_line.save
	      flash[:success] = "Player added"
	      redirect_to players_path(@game_line.game_id)
	      if @game_line.user != current_business_or_user
	      		Notification.create(recipientable: @game_line.user, actorable: current_business_or_user, 
	      				action: "Invited You", notifiable: @game_line.game)
	      end
	      # if @game_line.accepted == "Accepted" && !@game_line.game.business.nil?
	      # 	Notification.create(recipientable: @game_line.game.business, actorable: current_user, 
	      # 				action: "Confirmed You", notifiable: @game_line.game)
	      # end
	      if @game_line.user == current_user
	      	@game_line.update(accepted: "Requested")
	      	@game_line.save
	      	Notification.create(recipientable: @game_line.game.user, actorable: current_user, 
	      	      	action: "Requested", notifiable: @game_line.game)
	      end
	    else
	    	flash[:danger] = msg_error
	    	redirect_back fallback_location: root_path
	    end
	end


	def update
  		@game_line = GameLine.find_by(id: params[:id])

  		flash_msg = choose_flash_message(params[:accepted], @game_line)
  		
		if @game_line.update(accepted: params[:accepted])
			flash[:success] = flash_msg
			redirect_back fallback_location: root_path
			if @game_line.user != current_business_or_user
				Notification.create(recipientable: @game_line.user, actorable: current_business_or_user, 
	      				action: get_update_notification_message(params[:accepted], @game_line), notifiable: @game_line.game)
			else
				Notification.create(recipientable: @game_line.game.user, actorable: current_business_or_user, 
				      	action: get_update_notification_message(params[:accepted], @game_line), notifiable: @game_line.game)
			end
			# if !@game_line.game.business.nil?
			# 	Notification.create(recipientable: @game_line.game.business, actorable: current_user, 
	  #     				action: get_update_notification_message(params[:accepted], @game_line), notifiable: @game_line.game)
			# end
		else
			flash[:danger] = "Error, please try refresh and try again"
			redirect_back fallback_location: root_path
		end	  			
  	end

  	def destroy
	  	@game_line = GameLine.find(params[:id])

	  	if is_correct_user_or_business_associated_with_game_line?(@game_line)
		  	@game_line.destroy
		  	flash[:success] = @game_line.user.first_name + " was deleted"
		  	if @game_line.user != current_business_or_user
		  		Notification.create(recipientable: @game_line.user, actorable: current_business_or_user, 
	      				action: "Removed You", notifiable: @game_line.game)
		  	else
		  		Notification.create(recipientable: @game_line.game.user, actorable: current_business_or_user, 
		  		      	action: "Removed Themselves", notifiable: @game_line.game)
		  	end
		end
		redirect_back fallback_location: root_path
  	end


	private

	def choose_flash_message(accepted_value, gl)
		user_pronoun = ""
		if gl.user == current_user
			user_pronoun = "You are "
		else	
			user_pronoun = gl.user.first_name + " is "
		end

		return user_pronoun + accepted_value.downcase
	end

	def get_update_notification_message(accepted_value, gl)

		if accepted_value == "Accepted"  
			if !gl.game.business.nil?
				return "Confirmed"
			end
			return "Confirmed for you"
		elsif accepted_value == "Approved"
			return "Approved you"
		else
			if !gl.game.business.nil?
				return "Declined"
			end
			if gl.user == current_user
				return "Declined"
			end
			return "Declined for you"

		end
	end

	def game_line_params
  		params.require(:game_line).permit(:user_id, :game_id, :accepted, :invited_by)
	end
	
end



			