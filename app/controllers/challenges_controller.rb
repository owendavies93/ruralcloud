require 'rabbitq/client'
require 'rabbitq/rural.pb'
require "octokit"
require 'uri-handler'

class ChallengesController < ApplicationController
  # GET /challenges
  # GET /challenges.json
  def index
    now = Time.new.utc

    difficulty = current_user.try(:admin?) || !current_user.max_difficulty ? 10 : current_user.max_difficulty

    @not_started = Challenge.where('starttime > ? AND difficulty <= ?', now.inspect, difficulty)
    @running = Challenge.where('starttime < ? AND endtime > ? AND difficulty <= ?', now.inspect, now.inspect, difficulty)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @challenges }
    end
  end

  # GET /challenges/1
  # GET /challenges/1.json
  def show
    @challenge = Challenge.find(params[:id])

    # This is executed for all shows, but only used in the _show_unentered
    # partial. Perhaps this is a bad way of doing it, I can't decide

    @entries = Entry.where(:challenge_id => @challenge.id).order("user_id asc")

    @comp   = @entries.pluck(:compilations)
    @f_comp = @entries.pluck(:failed_compilations)
    @eval   = @entries.pluck(:evaluations)
    @f_eval = @entries.pluck(:failed_evaluations)
    @length = @entries.pluck(:length).map!{ |e| e == nil ? 0 : e }
    @lines  = @entries.pluck(:lines).map!{ |e| e == nil ? 0 : e }

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @challenge }
    end
  end

  # GET /challenges/new
  # GET /challenges/new.json
  def new
    @challenge = Challenge.new

    3.times do
      test = @challenge.challenge_tests.build
      test.outputs.build
    end

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


    # cur_test_line = 0
    # added_to_errors = false
    # if params[:test_suite_file] != nil
    #   File.open(params[:test_suite_file].path) do |f|
    #     f.each_with_index do |line, index|
    #       if index == 0
    #         if line[0] != '>'
    #           @challenge.errors.add(:test_suite, "Test suite must start with test")
    #           added_to_errors = true;
    #         end
    #       else
    #         if line[0] == '>' && (index == cur_test_line + 1 || f.eof?)
    #           @challenge.errors.add(:test_suite, "All tests must have at least one possible output")
    #           added_to_errors = true;
    #         elsif line[0] == '>'
    #           cur_test_line = index
    #         end
    #       end
    #     end
    #   end
    #   @challenge.update_attribute("test_suite", params[:test_suite_file].read)
    # else
    #   @challenge.errors.add(:test_suite, "Must submit test suite file")
    #   added_to_errors = true;
    # end

    respond_to do |format|
      if @challenge.save
        sync_new @challenge
        @challenge.update_attribute("total_tests", @challenge.challenge_tests.count)
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

    @challenge.update_attribute("total_tests", @challenge.challenge_tests.count)

    sync @challenge, :update

    respond_to do |format|
      if @challenge.update_attributes(params[:challenge])
        sync @challenge, :update
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

    sync @challenge, :destroy

    respond_to do |format|
      format.html { redirect_to challenges_url }
      format.json { head :no_content }
    end
  end

  # Enters the current user into the challenge
  def enter
    @challenge = Challenge.find(params[:id])
    @challenge.users << current_user

    @challenge.users.each do |u|
      if u.id != current_user.id
        Pusher['private-' + u.id.to_s].trigger('new_entrant', {:entrant => username_or_email(current_user.id), :id => @challenge.id.to_s})
      end
    end

    sync @challenge, :update

    @owner = User.find(id_from_uoe @challenge.owner)
    Pusher['private-' + @owner.id.to_s].trigger('admin_entrant', {:entrant => username_or_email(current_user.id), :id => @challenge.id.to_s})
    redirect_to :back, :notice => "You have entered this challenge!"
  end

  def id_from_uoe uoe
    user = User.where(:email => uoe).first

    if user == nil
      user = User.where(:username => uoe).first
    end
    return user.id
  end

  def username_or_email id
    user = User.find(id)

    user.username.blank? ? ActionController::Base.helpers.sanitize(user.email) : user.username
  end

  def global_leaderboard
    @ended = Challenge.where('endtime < ?', Time.new.utc.inspect)

    if @ended.count > 0
      @overalls = Entry.group(:user_id).select(
        'user_id,
         SUM(compilations) AS total_comp,
         SUM(failed_compilations) AS failed_comp,
         SUM(evaluations) AS total_eval,
         SUM(failed_evaluations) AS failed_eval,
         ROUND(AVG(length),2) AS av_length,
         ROUND(AVG(lines),2) AS av_lines,
         SUM(test_score) AS total_score').where('challenge_id IN (?)', @ended)

      sql = 'SELECT
              R.user_id, SUM(R.total_tests) AS tt
            FROM
              ((SELECT id, total_tests FROM challenges) C
              JOIN entries E ON E.challenge_id = C.id ) R
            GROUP BY R.user_id'

      @possible_scores = ActiveRecord::Base.connection.execute(sql)
    else
      @overalls = nil
      @possible_scores = nil
    end

  end

  def leaderboard
    @challenge = Challenge.find(params[:id])
    @entries = @challenge.entries.order("test_score desc")
  end

  def show_outcomes
    @entry = Entry.where(:challenge_id => params[:id], :user_id => params[:user_id]).first
    @tests = TestOutcome.where(:entry_id => @entry.id)
    @inputs = ChallengeTest.where(:challenge_id => params[:id]).pluck(:input)

    respond_to do |format|
      format.js
    end
  end

  def kick
    if current_user.try(:admin?)
      @entry = Entry.where(:challenge_id => params[:challenge], :user_id => params[:user]).first
      @entry.destroy

      sync @entry, :destroy

      Pusher['private-' + params[:user].to_s].trigger('kicked', {})

      challenge = Challenge.find(params[:challenge])
      challenge.users.each do |u|
        if u.id != params[:user]
          Pusher['private-' + u.id.to_s].trigger('entrant_kicked', {:entrant => username_or_email(params[:user]), :id => @challenge.id.to_s})
        end
      end

      render :nothing => true, :status => 200
    end
  end

  def report_error
    @challenge = Challenge.find(params[:id])
    @owner = User.find(id_from_uoe @challenge.owner)

    Pusher['private-' + @owner.id.to_s].trigger('challenge_error', {:id => params[:id], :sender => params[:sender], :message => params[:message]})

    render :nothing => true, :status => 200
  end

  def submit
    @entry = get_entry(params[:id])
    @challenge = Challenge.find(params[:id])
    @entry.update_attribute("submitted", true)

    @challenge.users.each do |u|
      if u.id != current_user.id
        Pusher['private-' + u.id.to_s].trigger('entrant_submitted', {:entrant => username_or_email(current_user.id), :id => @challenge.id.to_s})
      end
    end

    @owner = User.find(id_from_uoe @challenge.owner)
    Pusher['private-' + @owner.id.to_s].trigger('admin_submitted', {:entrant => username_or_email(current_user.id), :id => @challenge.id.to_s})

    # Send message to self, to close down interface
    Pusher['private-' + current_user.id.to_s].trigger('self_submitted', {})

    sync @entry, :update

    Rabbitq::Client::publish("", self, 2, @entry.last_code, @challenge.id, current_user.id)

    render :nothing => true, :status => 200
  end

  def send_compile
    @entry = get_entry(params[:challenge])
    @entry.update_attributes(:compilations =>  @entry.compilations + 1, :length => params[:length], :lines => params[:lines], :last_code => params[:code])

    sync @entry, :update

    Rabbitq::Client::publish("", self, 1, params[:code], params[:challenge], current_user.id)
    render :nothing => true, :status => 200
  end

  def send_eval
    @entry = get_entry(params[:challenge])
    @entry.update_attributes(:evaluations => @entry.evaluations + 1)

    sync @entry, :update

    Rabbitq::Client::publish(params[:input], self, 0, @entry.last_code, params[:challenge], current_user.id)
    render :nothing => true, :status => 200
  end

  def run_tests
    @challenge = Challenge.find(params[:challenge])

    @challenge.users.each do |u|
      @entry = Entry.find(:first, :conditions => {:user_id => u.id, :challenge_id => params[:challenge]})

      if !@entry.submitted
        Rabbitq::Client::publish("", self, 2, @entry.last_code, params[:challenge], u.id)
      end
    end
    render :nothing => true, :status => 200
  end

  def call(result, challenge)
    res = JSON.parse(result)

    if res["status"].to_i == -1
      log("POTENTIAL SERVER ATTACK", challenge)
    end

    if res["isCompileJob"]
      if res["status"].to_i > 0
        failed_compilation(challenge)
        log("Failed compilation", challenge)
      else
        log("Successful compilation", challenge)
      end
    else
      if res["status"].to_i > 0
        failed_eval(challenge)
        log("Failed evaluation", challenge)
      else
        log("Successful evaluation", challenge)
      end
    end

    cur_challenge = Challenge.find(challenge)

    @entries = Entry.where(:challenge_id => challenge).order("user_id asc")

    comp   = @entries.pluck(:compilations)
    f_comp = @entries.pluck(:failed_compilations)
    eval   = @entries.pluck(:evaluations)
    f_eval = @entries.pluck(:failed_evaluations)
    length = @entries.pluck(:length).map!{ |e| e == nil ? 0 : e }
    lines  = @entries.pluck(:lines).map!{ |e| e == nil ? 0 : e }

    Pusher['challenge-' + challenge].trigger('update_graphs',
      {:comp => comp, :f_comp => f_comp, :eval => eval, :f_eval => f_eval, :length => length, :lines => lines, :log => cur_challenge.log})
  end

  def failed_eval challenge_id
    @entry = get_entry(challenge_id)
    @entry.update_attributes(:failed_evaluations => @entry.failed_evaluations + 1)
    sync @entry, :update
  end

  def failed_compilation challenge_id
    @entry = get_entry(challenge_id)
    @entry.update_attributes(:failed_compilations => @entry.failed_compilations + 1)
    sync @entry, :update
  end

  def log message, challenge
    cur_challenge = Challenge.find(challenge)
    now = Time.new
    cur_challenge.update_attribute("log", now.inspect + ": " + message + " - " + username_or_email(current_user.id) + "\n" + cur_challenge.log)
  end

  def get_entry challenge_id
    return Entry.find(:first, :conditions => {:user_id => current_user.id, :challenge_id => challenge_id})
  end
  helper_method :get_entry

  def push_github
    begin
      entry = get_entry(params[:challenge])
      cur_challenge = Challenge.find(params[:challenge])
      client = Octokit::Client.new(:login => "current_user.email", :oauth_token => current_user.github_id)
      message = params[:message].presence || "Commit from RuralCloud"
      if(params[:input])
        commit = nil
        jsonresponse = {}
        filename = "#{cur_challenge.description}.hs".to_uri
        file = params[:input]<<"\n"
        unless(entry.github_repo)
          repo = client.create_repository(cur_challenge.description, {:description => "RuralCloud", :auto_init => true, :gitignore_template => "Haskell"})
          entry.update_attribute("github_repo", repo.url[29, repo.url.length])
          commit = client.add_content(entry.github_repo, filename, message, file, params[:branch])
          ghbranch = GhBranch.new(:branch => params[:branch], :file_hash => commit[:content].sha, :entry_id => entry.id)
          ghbranch.save
        else
          if(GhBranch.exists?(:branch => params[:branch]))
            ghbranch = GhBranch.where(:branch => params[:branch], :entry_id => entry.id).first
            commit = client.update_content(entry.github_repo, filename, message, ghbranch.file_hash, file, :branch => ghbranch.branch)
            ghbranch.update_attribute('file_hash', commit[:content].sha)
          else
            ghbranch = GhBranch.last
            oldcommit = client.branch(entry.github_repo, "master")
            client.create_ref(entry.github_repo, "heads/#{params[:branch]}", oldcommit[:commit].sha)
            commit = client.update_content(entry.github_repo, filename, message, ghbranch.file_hash, file, :branch => params[:branch])
            newbranch = GhBranch.new(:branch => params[:branch], :file_hash => commit[:content].sha, :entry_id => entry.id)
            newbranch.save
            jsonresponse.merge!({:branch => newbranch.branch})
          end
        end
        branchname = /https:\/\/api\.github\.com\/repos.*\?ref=(.*)/.match(commit.content.url).captures[0]
        jsonresponse.merge!({:time => commit.commit.author.date, :message => commit.commit.message, :sha => commit.commit.sha})
      end
    rescue
      jsonresponse.merge!({:error_message => "Commit failed. Try again or see if you have a repo already called #{cur_challenge.description}."})
    end
    render :json => jsonresponse
  end
  helper_method :push_github

  def pull_github
    entry = get_entry(params[:challenge])
    jsonresponse = {}
    if(entry.github_repo)
      begin
        client = Octokit::Client.new(:login => "current_user.email", :oauth_token => current_user.github_id)
        code = open(client.commit(entry.github_repo, params[:sha]).files.first.raw_url).read
        jsonresponse.merge!({:code => code})
      rescue
       jsonresponse.merge!({:error_message => 'Failed to recieve GitHub data - doea the repo exist?'})
      end
    else
      jsonresponse.merge!({:error_message => 'Please commit first!'})
    end
    render :json => jsonresponse
  end

  def get_repo_data
    entry = get_entry(params[:challenge])
    commits = []
    branch_names = []
    jsonresponse = {}
    begin
      if(entry.github_repo)
        branches = Octokit.branches(entry.github_repo)
        branches.each do |branch|
          branch_names.push({:id => branch_names.length, :text => branch.name})
          branch_commits = Octokit.commits(entry.github_repo, branch.name)
          branch_commits.each do |commit|
            info = {id: commit.sha, :time => commit.commit.author.date, :text => commit.commit.message}
            commits.push(info)
          end
          jsonresponse.merge!({:branches => branch_names, :commits => commits})
        end
      else
        jsonresponse.merge!({:branches => ['master'], :commits => []})
      end
    rescue
      jsonresponse.merge!({:error_message => 'Github error - try again later.'})
    end
    render :json => jsonresponse
  end

  private
    def is_entered challenge
      if user_signed_in?
        @challenge.entries.each { |e|
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

    def has_submitted challenge
      return get_entry(challenge).submitted
    end
    helper_method :has_submitted
end
