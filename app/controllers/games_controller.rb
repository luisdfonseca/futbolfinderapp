class GamesController < ApplicationController
	include GamesHelper
	before_action :signed_in_business_or_user?, only: [:index, :show, :new, :create, :destroy]
	before_action :correct_business_or_user_to_see,   only: [:show]
	before_action :correct_business_or_user_to_delete, only: [:destroy]

	def index
		@user = current_user
		if logged_in?
			@games = current_business.games.order(created_at: :desc)
			#@games = Game.where(business_id: @business).order(created_at: :desc)
		elsif signed_in?
			@games = Game.joins(game_lines: :user).where(game_lines: {user_id: current_user.id}).order(created_at: :desc)
		end
	end

	def show
		@game = Game.find(params[:id])
		@game_lines = @game.game_lines
		@game_line = GameLine.new	
	end

	def new
		@game = Game.new
	end

	def create
		if logged_in?
			@game = current_business.games.build(game_params)
			@b = current_business
			@game[:business_id] = @b.id 
		end

		if signed_in?
			@game = current_user.games.build(game_params)
			@u = current_user
			@game[:user_id] = @u.id
		end

		# available_field = assign_field_id(@game[:number_players], @game[:business_id], @game[:date], @game[:time])
		# if !(available_field = nil)
		# 	@game[:field_id] = available_field
		# else
		# 	flash[:warning] = "hey" + available_field.to_s
		# end

		if @game.save
			redirect_to games_path
			flash[:success] = "Game was created"
			GameLine.create(user_id: @game.user_id, game_id: @game.id)
		else
			render 'new'
		end
	end

	def destroy
		@game.destroy
		redirect_to root_path
	end

	private

	def game_params
		params.require(:game).permit(:date, :time, :user_id, :business_id, :field_id, :end_time)
	end

	# def assign_field_id(number_players, business_id, date, time)
	# 	fields = Field.where(business_id: business_id, number_players: number_players)
	# 	games = Game.where(date: date, time: time, number_players: number_players)

	# 	field_ids_in_games = Array.new

	# 	#check if there are fields availble at that time
	# 	if games.count >= fields.count
 #          return nil
 #        end

          
 #        games.each do |g|
 #        	field_ids_in_games.push(g.field_id)
 #        end
	    

	# 	fields.each do |f|			
	# 		if !(field_ids_in_games.include?(f.id))
	# 			return f.id
	# 		end
	# 	end

	# 	return nil
	# end
end
