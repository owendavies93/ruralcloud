# This class is run by delayed_job. It performs all necessary tasks at the end of a challenge
require 'rabbitq/client'
require 'rabbitq/rural.pb'

class ChallengeEnder < Struct.new(:challenge_id)
  def perform
    # run tests

    @challenge = Challenge.find(challenge_id)
    @challenge.users.each do |u|
      filename = "M" + challenge_id.to_s + "_" + current_user.id.to_s
      Rabbitq::Client::publish("", self, 2, filename, :challenge_id)
      throw :async
    end
  end

  def test_result(result, user_id)
    entry = Entry.where(:challenge_id => challenge_id.to_i, :user_id => user_id.to_i).first

    passed_count = 0

    response = RuralTestResponse.new
    response.parse_from_string result

    response.outcome.each do |output|
      outcome = TestOutcome.new do |o|
        o.entry_id = entry.id
        o.passed   = output.passed
        o.expected = output.expectedOutput
        o.recieved = output.userOutput

        if output.passed
          passed_count += 1
        end
      end
      outcome.save
    end

    entry.update_attribute("test_score", passed_count)
  end
end
