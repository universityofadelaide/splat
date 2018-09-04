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

# Instance of a calculator that calculates the paf score for the students
# within an assignment
class PAFCalculator

  attr_reader :assignment, :lookup, :question_count

  def initialize(assignment, force=false)
    @assignment = assignment
    @lookup = {
      responses: assignment.responses_data(force),
      groups:    @assignment.groups_data
    }
    @question_count = @assignment.questions.active.size
  end

  # This method collects paf score for a student
  def calculate(user_id, only_used_scores=false)
    return nil if question_count.zero?
    user_id = user_id.to_i
    group = lookup[:groups][:user_group][user_id]
    raise(PafError, "user_id '#{ user_id }' not part of PAF assignment") if group.nil?
    user_count = lookup[:groups][:group_users][group].size # count no of users of a group
    responses = lookup[:responses][user_id] # collect responses for the current assignment for a user
    sum_responses = 0
    responder_count = 0
    responses&.each_value do |response|
      if only_used_scores
        if response[:used]
          sum_responses += response[:score]
          responder_count += 1
        end
      else
        sum_responses += response[:score]
        responder_count += 1
      end
    end
    return _paf_score(sum_responses, user_count, question_count, responder_count)
  end

  private

  # This method calculates the PAF score for a provided user of a group
  # The PAF formula can be found here https://jira.adelaide.edu.au/browse/MUT-1151
  def _paf_score(sum_responses, user_count, question_count, responder_count)
    if responder_count.zero?
      nil
    else
      sum_responses.to_f / (question_count * 100) * user_count / responder_count # calculate paf
    end
  end

end
