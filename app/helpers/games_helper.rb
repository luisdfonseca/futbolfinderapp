module GamesHelper
	def correct_business
	      game = current_business.games.find_by(id: params[:id])
          redirect_to root_url if game.nil?
    end

    def correct_user_to_see(game)
    	game_line = current_user.game_lines.find_by(game_id: params[:id])

        # Check if current user is  admin, is on the game list, or is allow to see by public setting.
		if (game.user_id != current_user.id && game_line.nil?) && !is_allow_to_see_from_game_public_setting?(game)
	      redirect_to root_url 
	  	end	
    end

    def is_allow_to_see_from_game_public_setting?(game)
       if game.public == "Friends"
            if game.user.is_a_friend?(current_user)
                return true
            end
        elsif game.public == "Friends of friends"
            if game.user.is_a_friend?(current_user) || game.user.is_a_friend_of_a_friend?(current_user)
                return true
            end
        end
        return false               
    end

    def correct_user_to_delete
    	 game = current_user.games.find_by(id: params[:id])

    	 if game.nil?
	      redirect_to root_url 
	  	end	
    end

    def correct_business_or_user_to_delete
    	if logged_in?
    		correct_business
    	elsif signed_in?
    		correct_user_to_delete
    	else
    		return false
    	end
    end

    #simplify this method. 
    def correct_business_or_user_to_edit_page
        if logged_in?
            g = current_business.games.find_by(id: params[:id])
            if !g.nil?
                return true
            end
        elsif signed_in?
             game = current_user.games.find_by(id: params[:id])

             if !game.nil?
              return true
            end 
        else
            return false
        end
    end

    def correct_business_or_user_to_see
    	game = Game.find_by(id: params[:id])

        if game.public == "Public"
            return true
        else
            if logged_in?
        		correct_business
        	elsif signed_in?
        		correct_user_to_see(game)
        	else
        		return false
        	end  
        end		
    end

    def correct_user_for_game_line
    	game_line = current_user.game_lines.find_by(id: params[:id])

    	if game_line.nil?
    		return false
    	end

    	return true
    end

    def is_correct_user_or_business_associated_with_game_line?(game_line)
    	correct_user = false

        if game_line.game.reservation && game_line.game.reservation.checkin_time
            return false
        end
		
		if logged_in?
			game = current_business.games.find_by(id: game_line.game_id)		
    	elsif signed_in?
            
    		game = current_user.games.find_by(id: game_line.game_id)

    		if game_line.user_id == current_user.id
    			correct_user = true
    		end
        else
            return false
    	end

    	if correct_user || !game.nil? 
    		return true
    	end

    	return false
    end

    def are_there_games?
      if signed_in?
          if current_user.games_involved.count == 0 
              return false
          end
       elsif logged_in?
          if current_business.games.count == 0 
            return false
          end
      end
      return true   
    end

    def find_user_with_email(email)
        user = User.find_by(email: email)
        return user
    end

    def get_user_name_for_comment(id)
        
        if id.nil?
        return "Unknown"
        else
            user = User.find(id)
            return user.first_name
        end
    end

    def get_field(id)
        if id.nil?
            return 
        end

        if Field.exists?(id)
            field = Field.find(id)
        end

        if !field.nil?
            return field
        end
        
        return 
    end

    def get_field_size(n)
        n2 = (n/2).to_s
        n2 + "vs" + n2
    end

    def set_fields_collection
        if logged_in?
            @fields = current_business.fields
        end
    end

    def set_businesses_collection
        if signed_in?
            @businesses = Business.all
        end
    end

    def get_reservation_date_from_game(game_id)
        g = Game.find(game_id)
        if g.reservation.nil?
            return "N/A"
        else
            return g.reservation.date.strftime("%D")
        end
    end

    def get_reservation_month_and_day_from_game(game_id)
        g = Game.find(game_id)
        if g.reservation.nil?
            return "N/A"
        else
            return g.reservation.date.strftime("%^b %d")
        end
    end

    def get_reservation_time_from_game(game_id)
        g = Game.find(game_id)
        if g.reservation.nil?
            return "N/A"
        else
            return g.reservation.time.strftime("%l:%M %p")
        end
    end

    def get_reservation_end_time_from_game(game_id)
        g = Game.find(game_id)
        if g.reservation.nil?
            return "N/A"
        else
            return g.reservation.end_time.strftime("%l:%M %p")
        end
    end

     def get_reservation_location_from_game(game_id)
        g = Game.find(game_id)
        if g.reservation.nil?
            return "N/A"
        else
            return g.reservation.business
        end
    end

    def get_number_of_players_ready(game_id)
        g = Game.find(game_id)
        return g.game_lines.where(accepted: true).count
    end

    def public_or_private(public)
        if public == true
            return "Public"
        end
        return "Private"
    end

    def get_game_creator_name(game)
        if !game.user.nil?
            return game.user.first_name
        end

        if !game.business.nil?
            return game.business.name
        end
    end

    def get_game_creator(game)
        if !game.user.nil?
            return game.user
        end

        if !game.business.nil?
            return game.business
        end
    end

    def get_game
        if params[:game]
            Game.find(params[:game])
        elsif @game_line
            @game_line.game
        elsif @charge
            @charge.reservation.game
        end
        
    end

    
    def get_venue_date       
        if params[:date]
            params[:date]
        elsif @game_line
            @game_line.game.reservation.date
        elsif @charge
            @charge.reservation.date
        end 
    end

    def get_venue_time
        if session[:res_time]
            session[:res_time]
        elsif params[:time]
                params[:time]
        elsif @charge
            @charge.reservation.time
        end 
    end

    def get_duration
        if params[:duration]
            params[:duration]
        elsif @game_line
            (@game_line.game.reservation.end_time - @game_line.game.reservation.time) / 3600
        elsif @charge
            (@charge.reservation.game.reservation.end_time - @charge.reservation.game.reservation.time) / 3600
        end
                
    end

    def get_subtotal_amount_to_pay_by_player
        number_players = get_game.number_players
        amount = get_field_venue.price * get_duration.to_f / number_players
        ActionController::Base.helpers.number_to_currency(amount)
    end

    def get_total_amount_to_pay_by_player
        number_players = get_game.number_players
        amount = (get_field_venue.price * get_duration.to_f / number_players) + 1
        ActionController::Base.helpers.number_to_currency(amount)
    end

    def get_subtotal_charged_each_player
        number_players = @charge.reservation.charges.count
        if @charge.reservation.field_price
            price = @charge.reservation.field_price / 100
        else
            price = get_field_venue.price 
        end
        amount = (price * get_duration / number_players.to_f)
        ActionController::Base.helpers.number_to_currency(amount)
    end

    def get_total_charged_each_player
        number_players = @charge.reservation.charges.count
        if @charge.reservation.field_price
            price = @charge.reservation.field_price / 100
        else
            price = get_field_venue.price 
        end
        amount = (price * get_duration.to_f / number_players) + 1
        ActionController::Base.helpers.number_to_currency(amount)
    end



    def get_venue_total(field, game, duration, fee)
        if fee.nil?
            amount = field.price * duration / game.number_players
        else
            amount = (field.price * duration / game.number_players) + fee
        end

        ActionController::Base.helpers.number_to_currency(amount)
    end

    def get_duration_from_time_and_endtime
        # (Time.zone.parse(params[:end_time]) - Time.zone.parse(params[:time])) / 1.hours
        1
    end

    def get_business
        if params[:business]
            Business.find(params[:business])
        elsif @game_line
            @game_line.game.reservation.business
        end
    end

    def get_field_price
        if @charge.reservation.field_price
            @charge.reservation.field_price / 100
        else
            get_field_venue.price 
        end     
    end

    def get_field_venue
        if  params[:field]
           f = params[:field]
        elsif @game_line
            f = @game_line.game.reservation.field_id
        elsif @charge
            f = @charge.reservation.field_id
        end
        Field.find(f)
    end

    def get_field_size_on_words
        np = get_field_venue.number_players
        n = np/2
        n.to_s + "vs" + n.to_s
    end

    def get_end_time
        if params[:time]
            get_end_time_from_time_and_duration
        elsif @game_line
            @game_line.game.reservation.end_time
        elsif @charge
            @charge.reservation.end_time
        end
    end

    def get_end_time_from_time_and_duration
        Time.zone.parse(params[:time]) + (params[:duration].to_f).hour 
    end

    def get_public_or_private_string_from_game
        if @game.public == true
            return "Public"
        else
            return "Private"
        end 
    end

    def are_there_any_details_on_custom_venue?
        if @game.custom_venue.ground.empty? && 
            @game.custom_venue.number_players.nil? &&
            @game.custom_venue.field_type.empty?
            false
        else
            true
        end
    end

    def is_venue_still_current?
        if @game.reservation
            if !@game.reservation.checkin_time.nil?
                return false
            end
        elsif @game.custom_venue
            if @game.custom_venue.date < Date.current || 
                (@game.custom_venue.date == Date.current && 
                    @game.custom_venue.time.strftime('%H:%M') <= Time.zone.now.strftime('%H:%M'))
                return false
            end
        end
        return true
    end

    def is_at_one_of_index_games?
        if current_page?(controller: '/games/upcoming_games', action: 'index') ||
            current_page?(controller: '/games/planning', action: 'index')  ||
            current_page?(controller: '/games', action: 'index') ||
            current_page?(controller: '/games/old_games', action: 'index') ||
            current_page?(controller: '/games/invited', action: 'index')

            return true
        end

        return false
    end

    def is_it_at_least_3_hours_before?
        if @game.reservation.date == Date.current
            if @game.reservation.time.strftime("%H:%M") >= (Time.zone.now + 3.hours).strftime("%H:%M")
                return true
            end
        else
            return true
        end
        return false
    end

    def get_random_background_image
        random = rand(4)
        case random
        when 0
            return "https://s3-us-east-2.amazonaws.com/futfinder.com/soccer-game.png"
        when 1 
            return "https://s3-us-east-2.amazonaws.com/futfinder.com/soccer-field-background.png"
        when 2
            return "https://s3-us-east-2.amazonaws.com/futfinder.com/soccer-field.png"
        else    
            return "https://s3-us-east-2.amazonaws.com/futfinder.com/soccer-ball-field.png"
        end
    end

    def get_user_from_comment(user_id)
        u = User.find(user_id)
        return u
    end

    def user_has_avatar?(user_id)
         u = User.find(user_id)

         if u.avatar_file_name.nil? 
            return false
         end
         return true
    end

    def get_invites_real_string(invites)
        if invites 
            return "Allowed"
        else
            return "Not Allowed"
        end
    end

end
