class UsersController < ApplicationController

  # GET '/ad/listuser/id/:id'
  def listads
    # ads lists for user
    @user = User.find(params[:id])
    @type = type_scope
    @status = status_scope

    @ads = @user.ads
                .includes(:user)
                .public_send(@type)
                .paginate(:page => params[:page])

    @ads = @ads.public_send(@status) if @status
  end

  # GET '/profile/:username'
  def profile
    # public profile for user
    @user = User.find_by_username(params[:username])
    if @user.nil? 
      # not username, but ID
      @user = User.find(params[:username])
    end
  end

  private

  def status_scope
    return unless %w(available booked delivered).include?(params[:status])

    params[:status]
  end

  helper_method :status_scope
end
