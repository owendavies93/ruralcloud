require 'rabbitq/client'

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

    @challenge.users << current_user
    redirect_to :back, :notice => "You have entered this challenge!"
  end

  def send_compile
    @entry = get_entry(params[:challenge])
    @entry.update_attributes(:compilations =>  @entry.compilations + 1, :length => params[:length], :lines => params[:lines])
    filename = "M" + params[:challenge] + "_" + current_user.id.to_s
    Rabbitq::Client::publish(params[:input], self, 1, filename)
    throw :async
  end

  def send_eval
    @entry = get_entry(params[:challenge])
    @entry.update_attributes(:evaluations => @entry.evaluations + 1)
    filename = "M" + params[:challenge] + "_" + current_user.id.to_s
    Rabbitq::Client::publish(params[:input], self, 0, filename)
    throw :async
  end

  def call(result)
    request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, result]
  end

  def get_entry challenge_id
    return Entry.find(:first, :conditions => {:user_id => current_user.id, :challenge_id => challenge_id})
  end

  private
    def is_entered challenge
      if user_signed_in?
        challenge.entries.each { |e|
          if e.user_id == current_user.id
            return true
          end
        }
        return false
      else
        return false
      end
    end
    helper_method :is_entered

    def has_started challenge
      now = Time.new

      return challenge.starttime < now.inspect
    end
    helper_method :has_started

    def has_ended challenge
      now = Time.new

      return challenge.endtime < now.inspect
    end
    helper_method :has_ended

    def failed_eval challenge_id
      @entry = get_entry(challenge_id)
      @entry.update_attributes(:failed_evaluations => @entry.failed_evaluations + 1)
    end
    helper_method :failed_eval

    def failed_compilation challenge_id
      @entry = get_entry(challenge_id)
      @entry.update_attributes(:failed_compilations => @entry.failed_compilations + 1)
    end
    helper_method :failed_compilation
end
