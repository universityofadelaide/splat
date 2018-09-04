# Copyright (C) 2018 The University of Adelaide
#
# This file is part of SPLAT - Self & Peer Learning Assessment Tool.
#
# SPLAT - Self & Peer Learning Assessment Tool is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SPLAT - Self & Peer Learning Assessment Tool is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SPLAT - Self & Peer Learning Assessment Tool.  If not, see <http://www.gnu.org/licenses/>.
#

# Instance of a calculator that calculates the sapa score for a student
# within an assignment

# "The SAPA (self-assessment over peer assessment) is the score that
# the student has given themselves (ScoreSelf) over the average of
# the scores that all the other students have given them"
# from: "A peer assessment tool for teams" University of Adelaide 2015
class SAPACalculator

  SCORE_FOR_NO_RESPONDERS = 1.0

  attr_reader :assignment, :lookup

  def initialize(assignment, force=false)
    @assignment = assignment
    @lookup = {
      responses: assignment.responses_data(force)
    }
  end

  # The calculate function gathers all the required information to calculate the SAPA score for
  # a single user.
  def calculate(user_id, only_used_scores=false)
    user_id = user_id.to_i
    own_scores = lookup[:responses].dig(user_id, user_id)
    sum_own_scores = !own_scores || (only_used_scores && !own_scores[:used]) ? nil : own_scores[:score]

    sum_others_scores = 0
    has_others_scores = false
    responder_count = 0
    lookup[:responses][user_id]&.each do |from_id, response|
      next if user_id == from_id
      next unless !only_used_scores || response[:used]
      has_others_scores = true
      sum_others_scores += response[:score]
      responder_count += 1
    end

    sum_others_scores = nil unless has_others_scores

    return _sapa_score(sum_own_scores, sum_others_scores, responder_count)
  end

  private

  # Returns the calculated SAPA score
  def _sapa_score(sum_own_scores, sum_others_scores, responders)
    if sum_own_scores.nil?
      nil
    elsif sum_others_scores.nil? || sum_others_scores.zero?
      SCORE_FOR_NO_RESPONDERS
    else
      sum_own_scores.to_f / (sum_others_scores.to_f / responders)
    end
  end

end
