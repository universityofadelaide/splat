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

# CanvasAssignment models an assignment from Canvas
class CanvasAssignment

  POINTS_GRADE  = "points".freeze
  PERCENT_GRADE = "percent".freeze
  LETTER_GRADE  = "letter_grade".freeze

  SUPPORTED_GRADING_TYPES = [
    POINTS_GRADE,
    PERCENT_GRADE,
    LETTER_GRADE
  ].freeze

  def initialize(course_id, canvas_assignment_id, paf_calculator, canvas_service)
    @course_id = course_id
    @assignment_id = canvas_assignment_id
    @paf_calculator = paf_calculator
    @canvas_service = canvas_service
  end

  def apply_paf_grades(splat_assignment_id)
    grading_data = _verify_assignment_config(splat_assignment_id)
    grading_schema = _get_grading_schema(grading_data[:standard_id]) if grading_data[:type] == LETTER_GRADE
    student_grades = _collect_student_grades
    student_ids = CanvasCourse.get_students(@course_id, @canvas_service).pluck(:id)
    updates = []
    student_grades.each do |student, submission|
      next if submission[:score].nil?

      user = User.find_by({ lms_id: student })
      next if user.nil?

      begin
        paf = @paf_calculator.calculate(user.id, true)
      rescue PafError
        next
      end
      grade = _calculate_grade(grading_data, grading_schema, paf, submission[:score])
      next if grade.nil?

      updates << { student_id: submission[:user_id], grade: grade }
    end
    blank_user = student_ids - updates.pluck(:student_id)
    blank_user.each do |user_id|
      updates << { student_id: user_id, grade: nil }
    end
    @canvas_service.update_grades(@course_id, splat_assignment_id, updates) unless updates.empty?
  rescue StandardError => e
    Rails.logger.error("Error while updating SPLAT assignment '#{ splat_assignment_id }' for course '#{ @course_id }': #{ e.inspect }")
    raise e
  end

  private

  def _verify_assignment_config(splat_assignment_id)
    grading_fields = %i[points_possible grading_type grading_standard_id]
    assignment = @canvas_service.get_assignment(@course_id, @assignment_id)
    unless SUPPORTED_GRADING_TYPES.include?(assignment[:grading_type])
      raise(
        UnsupportedGradeTypeError,
        "This assignment is using an unsupported grading type. Please select an assignment that is set to display grades as one of the following supported types: Percentage, Points, or Letter grade."
      )
    end
    splat_assignment = @canvas_service.get_assignment(@course_id, splat_assignment_id)
    config_different = assignment.slice(*grading_fields) != splat_assignment.slice(*grading_fields)
    @canvas_service.update_assignment(@course_id, splat_assignment_id, assignment.slice(*grading_fields)) if config_different
    return {
      type:            assignment[:grading_type],
      standard_id:     _get_grading_standard_id(assignment),
      points_possible: assignment[:points_possible]
    }
  end

  def _collect_student_grades
    all_submissions = @canvas_service.get_submissions_for_assignment(@course_id, @assignment_id)
    submissions_by_student = _organise_assignment_submissions_by_student({ assignment_submissions: all_submissions })
    @student_grades = {}
    submissions_by_student.each do |student_id, submissions|
      submission = _latest_graded({ assignment_id: @assignment_id, submissions: submissions })
      @student_grades[student_id] = submission if submission
    end
    return @student_grades
  end

  # return a hash of submission details by student, given an array of assignment submissions
  # key: student id
  # value: hash with all assignments submitted by the student
  #   key: assignment id
  #   value: submission details
  def _organise_assignment_submissions_by_student(assignment_submissions: nil)
    raise ArgumentError, "assignment_submissions cannot be nil" unless assignment_submissions

    # collect interesting fields for an submission and group submissions by student
    grade_cols = %i[sis_user_id user_id assignment_id score grade attempt workflow_state]
    student_submissions = assignment_submissions.map { |s| s.slice(*grade_cols) }
    return student_submissions.group_by { |h| h[:sis_user_id] }
  end

  # canvas submissions have a "workflow_state" that indicates if the work has been graded
  # and an "attempt" field that indicates how many times an assignment has been attempted.
  # The latest graded submission can be found by sorting the submissions in reverse
  # order on "attempt" and looking for the first one that is graded
  def _latest_graded(assignment_id: nil, submissions: [])
    raise ArgumentError, "assignment_id must be provided" if assignment_id.blank?

    sorted_submissions = submissions.select { |s| s[:assignment_id].to_s == assignment_id }.sort_by { |submission| -submission[:attempt].to_i }
    latest_submission = sorted_submissions.find do |s|
      Rails.logger.debug("skipping ungraded submission #{ s.inspect }") unless s[:workflow_state] == "graded"
      s[:workflow_state] == "graded" # note: if this returns true, the find completes
    end
    return latest_submission
  end

  def _calculate_grade(grading_data, grading_schema, paf, score)
    paf = paf.nil? ? 1.0 : paf.round(2)
    result = paf * score
    # score of a letter grade is always in points, but grading schema works with percentage
    result = _convert_letter_grade(grading_schema, result / grading_data[:points_possible]) if grading_data[:type] == LETTER_GRADE
    return result
  end

  def _convert_letter_grade(grading_schema, score)
    grade = nil
    grading_schema.each do |entry|
      grade = entry[:name] if score >= entry[:value]
    end
    return grade
  end

  def _get_grading_schema(id)
    # BALONEY!!!!!!
    # Who in their right mind returns an ID without a context. Canvas allows grading standards to be
    # defined on account AND course level but the API doesn't return the context ...
    # Most of the time getting the grading standard from the course will fail and generate a log error,
    # but I think it's better to check course first in case a lecturer has defined its own standard.
    begin
      schema = @canvas_service.get_grading_standard_course(id, @course_id)
    rescue StandardError
      begin
        schema = @canvas_service.get_grading_standard_account(id)
      rescue StandardError => e
        Rails.logger.error("Error while getting grading standard for assignment '#{ @assignment_id }' for course '#{ @course_id }': #{ e.inspect }")
        raise e
      end
    end
    return schema[:grading_scheme].sort_by { |grade| grade[:value] }
  end

  def _get_grading_standard_id(assignment)
    return nil unless assignment[:grading_type] == LETTER_GRADE

    # if the assignment doesn't override the grading schema it's nil
    grading_standard_id = assignment[:grading_standard_id]
    # fallback to course setting, we set an account grading schema by default
    if grading_standard_id.nil?
      course = @canvas_service.get_course(@course_id)
      grading_standard_id = course[:grading_standard_id]
    end
    return grading_standard_id
  end

end
