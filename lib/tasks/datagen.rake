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

ASSIGNMENT_ID = "54321".freeze

namespace :datagen do

  desc "create data for splat demonstrations"
  task create_data: :environment do
    a = Assignment.find_by(lms_id: ASSIGNMENT_ID)
    add_questions_and_generate_score_for_assignment a
  end

  desc "destroy the splat demo data"
  task destroy_data: :environment do
    a = Assignment.find_by(lms_id: ASSIGNMENT_ID)
    if a.present?
      Response.where(assignment_id: a).destroy_all
      Comment.where(assignment_id: a).destroy_all
    end
  end

  # control method for the create_data task
  def add_questions_and_generate_score_for_assignment(assignment)
    raise "No assignment found to insert data into" if assignment.nil?
    raise "No questions in the assignment" if assignment.questions.count.zero?

    if assignment.groups.empty?
      puts "Please import the csv data file to provide the groups and users for this assignment"
      puts "When done, please rerun this task"
      raise "No groups imported yet"
    end
    raise "Scores are already entered for this assignment. Please run the data delete task and try again" if !assignment.responses.empty?

    generate_peer_scores assignment
  end
  COMMENTS = ["An excellent assignment, thank you.", "This is a test", nil].freeze

  def generate_peer_scores(assignment)
    assignment.groups.each do |grp|
      members = grp.users.count
      grp.users.each do |marker|
        comment_text = COMMENTS[rand(0..2)]
        unless comment_text.nil?
          Comment.create({ user_id: marker.id, assignment_id: assignment.id,
                     comments: comment_text,
           created_by: marker.id, updated_by: marker.id })
        end
        assignment.questions.each do |question|
          remaining = 100
          recipient_num = 0 # member number, the last member gets the remaining marks
          grp.users.each do |recipient|
            recipient_num += 1
            if recipient_num == members
              score = remaining
              remaining = 0
            else
              score = rand(0..remaining)
              remaining -= score
            end
            r = Response.new
            r.question = question
            r.created_by = "system"
            r.updated_by = "system"
            r.from_user = marker
            r.for_user = recipient
            r.score = score
            r.assignment = assignment
            throw "Error saving response: #{ r.errors.full_messages }" if r.save == false
          end
        end
      end
    end
  end
end
