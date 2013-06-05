class UsersController < ActionController::Base

  def show
    @user = User.find(params[:id])

    @challenges = Entry.select('*').
                        joins('JOIN challenges ON challenges.id = entries.challenge_id').
                        where('entries.user_id = ?', params[:id]).
                        order('challenges.endtime desc').
                        limit(3)

    respond_to do |format|
      format.js
    end
  end

end
