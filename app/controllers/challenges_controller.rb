class ChallengesController < ApplicationController
  # GET /challenges
  # GET /challenges.json
  def index
    @challenges = Challenge.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @challenges }
    end
  end

  # GET /challenges/1
  # GET /challenges/1.json
  def show
    @challenge = Challenge.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @challenge }
    end
  end

  # GET /challenges/new
  # GET /challenges/new.json
  def new
    @challenge = Challenge.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @challenge }
    end
  end

  # GET /challenges/1/edit
  def edit
    @challenge = Challenge.find(params[:id])
  end

  # POST /challenges
  # POST /challenges.json
  def create
    @challenge = Challenge.new(params[:challenge])

    respond_to do |format|
      if @challenge.save
        format.html { redirect_to @challenge, notice: 'Challenge was successfully created.' }
        format.json { render json: @challenge, status: :created, location: @challenge }
      else
        format.html { render action: "new" }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /challenges/1
  # PUT /challenges/1.json
  def update
    @challenge = Challenge.find(params[:id])

    respond_to do |format|
      if @challenge.update_attributes(params[:challenge])
        format.html { redirect_to @challenge, notice: 'Challenge was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /challenges/1
  # DELETE /challenges/1.json
  def destroy
    @challenge = Challenge.find(params[:id])
    @challenge.destroy

    respond_to do |format|
      format.html { redirect_to challenges_url }
      format.json { head :no_content }
    end
  end

  # Enters the current user into the challenge
  def enter
    @challenge = Challenge.find(params[:id])

    current_user.update_attribute(:challenge_id, @challenge.id)
    @challenge.users << current_user
    redirect_to :back, :notice => "You have entered this challenge!"
  end

  private
  def is_entered challenge
    if user_signed_in?
      challenge.users.each { |u|
        if u.email == current_user.email
          return true
        end
      }
      return false
    else
      return false
    end
  end
  helper_method :is_entered

  private
  def has_started challenge
    now = Time.new

    return challenge.starttime < now.inspect
  end
  helper_method :has_started

  private
  def has_ended challenge
    now = Time.new

    return challenge.endtime < now.inspect
  end
  helper_method :has_ended

  def send_compile
    puts params
    Rabbitq::Client::publish(params[:editor], self)
    throw :async
  end
  helper_method :send_compile

  def call(result)
    request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, result]
  end
end
