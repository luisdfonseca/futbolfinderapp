class UsersController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update]
  before_action :redirect_back_when_is_already_logged_in?, only: [:new, :create]
  before_action :correct_user,   only: [:edit, :update]

  def index
    @users = User.paginate(page: params[:page], per_page: 15)
  end

  def show
    @user = User.friendly.find(params[:id])
    @games = Game.this_week_public_games_with_reservation(@user)
  end

  def new
  	@user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
    	sign_in @user
      flash[:success] = "Welcome to futbol finder app"
    	redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.friendly.find(params[:id])
  end

  def update
    @user = User.friendly.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

    def user_params
      params.require(:user).permit(:first_name,:last_name,:location,:gender,:phone,:slug,:dob, :email, :password,
                                   :password_confirmation, :avatar)
    end

    def correct_user
      @user = User.friendly.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end
end
