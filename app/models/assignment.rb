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

require "csv"

# model which represents the Assignments which are initlated from Canvas
class Assignment < ApplicationRecord

  CSV_UNUSED_FLAG = " (e)".freeze

  has_many :assignment_groups
  has_many :groups, { through: :assignment_groups }
  has_many :assignment_users
  has_many :users, { through: :assignment_users }
  has_many :assignment_questions
  has_many :questions
  has_many :responses
  has_many :messages

  validates :name, :lms_id, { presence: true }
  validates :instructions, { length: { maximum: 5000, too_long: "5000 characters is the maximum allowed" } }

  HEADERS = [
    "Group Name",
    "User ID",
    "First Name",
    "Last Name",
    "Group Member #",
    "PAF",
    "NEW PAF",
    "SAPA",
    "NEW SAPA",
    "Comment",
    "Group Member [n] Score", # this is a repeated header with the [n] replaced. see _dynamic_headers
  ].freeze

  def update_instructions(new_instructions)
    update!({ instructions: new_instructions })
    return true
  end

  def update_questions(updated_question_data)
    categorised_questions = JSON.parse(updated_question_data)
    unless _enabled_questions?(categorised_questions)
      raise "Please make sure you have at least one question created or selected for this assignment."
    end

    ActiveRecord::Base.transaction do
      begin
        # clear the positions; also get the retained questions and delete the rest. predefined questions are always retained
        delete_ids = _prepare_to_update_questions(categorised_questions)
        logger.info("deleting #{ delete_ids.size } old questions")
        Question.where({ id: delete_ids }).destroy_all if delete_ids.size
        _update_retained_questions(categorised_questions)
      end
    end
  end

  def to_csv(options={ headers: true })
    CSV.generate(options) do |csv|
      csv << _dynamic_headers

      # Get a list of all student responses for this assignment
      student_responses = responses_data

      calculators = {
        paf:  PAFCalculator.new(self),
        sapa: SAPACalculator.new(self)
      }

      data = []
      groups.order({ group_set_name: :asc, name: :asc }).each do |group|
        # Extract all data for a single group
        data += _csv_group_data(group, student_responses, calculators)
      end

      # add all data to CSV
      data.each do |row|
        csv << row
      end
    end
  end

  def to_json
    # Get a list of all student responses for this assignment
    student_responses = responses_data

    # Calculate a list of all students that responded
    list_of_students_responded = students_responded

    # Initialize calculators
    sapa_calculator = SAPACalculator.new(self)
    paf_calculator = PAFCalculator.new(self)

    report = {}
    groups.order({ group_set_name: :asc, name: :asc }).each do |group|
      # generate the resultant rows. Note that this leaves columns blank rather
      # than populating all blank fields with zero
      group_users_info = group.users.order({ first_name: :asc, last_name: :asc }).map do |u, _user_position|
        {

          student_id:         u.id.to_s,
          student_first_name: u.first_name.to_s,
          student_last_name:  u.last_name.to_s,
          new_paf_score:      _helpers.format_score(paf_calculator.calculate(u.id, true)),
          paf_score:          _helpers.format_score(paf_calculator.calculate(u.id)),
          new_sapa_score:     _helpers.format_score(sapa_calculator.calculate(u.id, true)),
          sapa_score:         _helpers.format_score(sapa_calculator.calculate(u.id)),
          scores:             group.users.order({ first_name: :asc, last_name: :asc }).map do |from_user|
                                student_responses.dig(u.id, from_user.id)
                              end,
          comment:            (Comment.find_by({ user_id: u, assignment_id: group.assignment }).nil? ? "" : Comment.find_by({ user_id: u, assignment_id: group.assignment }).comments)
        }
      end
      report[group.name] =
        {
          data:                     group_users_info,
          total_student:            group.users.order({ first_name: :asc, last_name: :asc }).map(&:id).uniq.size,
          total_students_responded: group.users.order({ first_name: :asc, last_name: :asc }).map { |u| list_of_students_responded.include?(u.id) ? 1 : 0 }.count(1)
        }
    end
    return report.to_json
  end

  # Calculates a list of all student responses, sum of all question scores used
  def responses_data(force=false)
    return @responses_data if !force && @responses_data
    data = {}
    extract = responses.all.pluck(:from_user_id, :for_user_id, :score, :score_used)
    extract.each do |from, to, score, used|
      data[to] = {} unless data[to]
      data[to][from] = { score: 0, used: used, for: to, from: from } unless data[to][from]
      data[to][from][:score] += score
    end
    @responses_data = data
    return data
  end

  # Generates lookup tables for student -> group and group -> students
  def groups_data
    data = { group_users: {}, user_group: {} }
    groups.each do |group|
      data[:group_users][group.id] = []
      group.users.each do |user|
        data[:group_users][group.id] << user.id
        data[:user_group][user.id] = group.id
      end
    end
    return data
  end

  # Calculates a list of all the students that responded
  def students_responded
    student_responses = responses_data
    responded = []
    student_responses.each do |_to, from|
      responded += from.keys
    end
    return responded.uniq
  end

  def number_of_students_total
    groups.includes(:users).map(&:users).flatten.size
  end

  def number_of_students_completed
    responses.map(&:from_user_id).uniq.size
  end

  def not_responded_user_lms_ids
    responded_users_ids = responses.map(&:from_user_id).uniq
    return users.where.not({ id: responded_users_ids }).pluck(:lms_id)
  end

  def not_responded_user_data(assignment)
    user_data = []
    not_responded_users_lms_ids = not_responded_user_lms_ids
    not_responded_users_lms_ids.each do |lms_id|
      user = users.find_by({ lms_id: lms_id })
      next unless user
      group = user.assignment_group(assignment)
      user_data <<
        {
          lms_id:     lms_id.to_s,
          login_id:   user.login_id.to_s,
          first_name: user.first_name.to_s,
          last_name:  user.last_name.to_s,
          group_id:   group.id.to_s,
          group_name: group.name.to_s
        }
    end
    return user_data.sort { |a, b| [a[:group_id], a[:first_name], a[:last_name]] <=> [b[:group_id], b[:first_name], b[:last_name]] }
  end

  def users_responded
    responded_users_ids = responses.map(&:from_user_id).uniq
    responded_users = []
    users.where({ id: responded_users_ids }).find_each do |user|
      responded_users << {
        id:       user.id,
        lms_id:   user.lms_id,
        login_id: user.login_id,
        name:     "#{ user.last_name }, #{ user.first_name }"
      }
    end
    return responded_users.sort_by { |h| h[:name].downcase }
  end

  def clear_responses(user_id)
    logger.info("Deleting responses for user #{ user_id } on assignment #{ self.id }")
    ActiveRecord::Base.transaction do
      begin
        responses.where({ from_user_id: user_id })&.destroy_all
        Comment.find_by({ user_id: user_id, assignment_id: self.id })&.destroy
        logger.info("Deleted responses for user #{ user_id } on assignment #{ self.id }")
      end
    end
  end

  def list_notifications
    notifications = []
    messages.order({ id: :desc }).each do |m|
      notifications <<
        {
          subject:          m.subject,
          body:             m.body,
          users:            _notified_users(m.id),
          no_of_users_sent: _notified_users(m.id).length,
          created_at:       _helpers.format_date(m.created_at)
        }
    end
    return notifications
  end

  private

  def _dynamic_headers
    # headers are generated dynamically; we start with the first n-1 columns from
    # HEADERS, above and repeat the final column header as many times as necessary
    # depending on the number of people in the largest group
    headers = HEADERS[0..-2]
    template_header = HEADERS[-1]
    largest_group = groups.map { |group| group.users.count }.max
    return headers if largest_group.to_i.zero?

    (1..largest_group).each do |user_number|
      headers << template_header.sub("[n]", user_number.to_s)
    end
    return headers
  end

  # extract all CSV data for a single group
  def _csv_group_data(group, scores, calculators)
    csv_group_data = []
    group.users.sorted.each.with_index(1) do |u, user_position|
      score_data_for_student = _csv_score_data_for_student(group, scores, u.id)
      unused_score           = score_data_for_student[:unused_score]
      student_scores         = score_data_for_student[:scores]
      new_paf_score          = unused_score ? _helpers.format_score(calculators[:paf].calculate(u.id, true)) : ""
      new_sapa_score         = unused_score ? _helpers.format_score(calculators[:sapa].calculate(u.id, true)) : ""
      new_paf_score          = "n/a" if new_paf_score.nil?
      new_sapa_score         = "n/a" if new_sapa_score.nil?
      comment                = Comment.find_by({ user_id: u, assignment_id: group.assignment })

      row = []
      row << group.name.to_s
      row << u.lms_id.to_s
      row << u.first_name.to_s
      row << u.last_name.to_s
      row << user_position.to_s
      row << _helpers.format_score(calculators[:paf].calculate(u.id))
      row << new_paf_score
      row << _helpers.format_score(calculators[:sapa].calculate(u.id))
      row << new_sapa_score
      row << (comment.nil? ? "" : comment.comments)
      row += student_scores
      csv_group_data << row
    end
    return csv_group_data
  end

  # get all scores from peers for a student within a group
  def _csv_score_data_for_student(group, scores, for_user_id)
    student_scores = []
    unused_score = false
    group.users.sorted.each do |from|
      score_obj = scores.dig(for_user_id, from.id)
      score = score_obj.nil? ? "" : score_obj[:score]
      cell = score.to_s
      unless score_obj.nil? || score_obj[:used]
        cell += CSV_UNUSED_FLAG
        unused_score = true
      end
      student_scores << cell
    end
    return {
      scores:       student_scores,
      unused_score: unused_score
    }
  end

  # prepare_to_update_questions resets question positions to nil and works out what questions are to be deleted
  def _prepare_to_update_questions(categorised_questions)
    all_ids = questions.pluck(:id)
    keep_ids = []
    categorised_questions.each do |_, updated_questions|
      updated_questions.each do |updated_question|
        next unless updated_question["id"]
        question = Question.find_by({ id: updated_question["id"] })
        question.update({ position: nil })
        keep_ids << updated_question["id"]
      end
    end
    return all_ids - keep_ids
  end

  def _update_retained_questions(categorised_questions)
    position = 0
    categorised_questions.each do |category, updated_questions|
      updated_questions.each do |updated_question|
        position += 1 # questions is nested by category which rules out the use of each.with_index
        updates = { question_text: updated_question["question_text"], enabled: updated_question["enabled"], position: position }
        question = Question.find_by({ id: updated_question["id"] })
        logger.debug("question: #{ position }: #{ updated_question["question_text"] } #{ question ? "" : " (new)" }")
        unless question
          logger.debug("new question")
          category_id = category.gsub("category_", "").to_i
          question = Question.new({ assignment_id: id, question_category_id: category_id, predefined: false })
        end
        question.update!(updates)
        logger.debug("question changed") if question.changed?
      end
    end
  end

  def _enabled_questions?(categorised_questions)
    categorised_questions.each do |_category, questions|
      questions.each do |question|
        return true if question["enabled"]
      end
    end
    return false
  end

  def _notified_users(message_id)
    notified_users = []
    notifications = Notification.where({ message_id: message_id })
    notifications.each do |n|
      next unless n
      notified_users << users.where({ id: n.user_id }).pluck(:first_name, :last_name).join(" ")
    end
    return notified_users
  end

  def _helpers
    ApplicationController.helpers
  end

end
