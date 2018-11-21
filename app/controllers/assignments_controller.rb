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

# Default controller for Assignments which the LTI will hit on launch
class AssignmentsController < ApplicationController

  def start
    no_access("AssignmentController#start not instructor or student") && return unless helpers.instructor?(session[:roles]) || helpers.learner?(session[:roles])
    if @assignment || !helpers.instructor?(session[:roles])
      _redirect_user
    else
      begin
        ActiveRecord::Base.transaction do
          @assignment = Assignment.create!(
            {
              name:              session[:assignment_title],
              lms_id:            session[:assignment_id],
              lms_assignment_id: params[:custom_canvas_assignment_id],
              course_name:       params[:context_label],
              created_by:        session[:current_user],
              updated_by:        session[:current_user],
              lti_launch_params: params.to_json
            }
          )
          _add_questions_to_assignment
        end
        redirect_to instruction_assignments_path
      rescue ActiveRecord::RecordInvalid => e
        logger.error(e.inspect)
        flash[:danger] = e.message
      end
    end
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def show
    no_access("AssignmentController#show not instructor") && return unless helpers.instructor?(session[:roles])
    @students_total = @assignment.number_of_students_total
    @students_completed = @assignment.number_of_students_completed
    @course_assignments = CanvasCourse.get_assignments(session[:course_id], canvas_service)
    @source_assignment = @assignment.source_assignment_id
    @source_assignment = "" unless @course_assignments&.find { |a| a[:id].to_s == @source_assignment }
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def inline_moderation_data
    raise "Access denied: No Instructor" unless helpers.instructor?(session[:roles])

    response = @assignment.to_json
    respond_to do |format|
      format.json { render({ json: response }) }
    end
  rescue StandardError => e
    logger.error(e.inspect)
    respond_to do |format|
      format.json { render({ json: { error: e.message }, status: :unauthorized }) }
    end
  end

  def instruction
    no_access("AssignmentController#instruction not instructor") && return unless helpers.instructor?(session[:roles])
    render instruction_assignments_path && return unless params.dig("instructions", "text")
    render instruction_assignments_path && return unless @assignment.update_instructions(params[:instructions][:text])
    render instruction_assignments_path && return unless @assignment.update_questions(params[:updated_questions])
    redirect_to preview_assignments_path
  rescue ActiveRecord::RecordInvalid => e
    logger.error(e.inspect)
    flash[:danger] = "Error during save: #{ e.message }"
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def preview
  rescue StandardError
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  # Sets the groups and users for the assignment.
  def set_groups
    no_access("AssignmentController#set_groups not instructor") && return unless helpers.instructor?(session[:roles])
    begin
      if @assignment.groups.present?
        helpers.register_flash_message(:danger, "Group membership data already uploaded for this assignment.")
      else
        group_category_id = params[:group_category_id]
        if !_group_category_id_valid?(group_category_id)
          helpers.register_flash_message(:danger, "Invalid group category for course.")
        else
          data = LmsGroupCategory.new(group_category_id, canvas_service).import_data
          groups_lti_importer = GroupsLtiImporter.new(@assignment, data, session[:current_user])
          groups_lti_importer.import
          helpers.register_flash_message(:success, "Your import was successful.")
        end
      end
      _redirect_user
    rescue GroupsLtiImporterPersistError => e
      helpers.log_error(Logger::ERROR, e)
      helpers.register_flash_message(:danger, e.message)
      redirect_to group_categories_path
    end
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def export_csv
    no_access && return unless helpers.instructor?(session[:roles])
    filename = "#{ @assignment.course_name }-#{ @assignment_name }-#{ Time.now.getlocal.strftime("%Y-%m-%d") }.csv"
    respond_to do |format|
      format.html
      format.csv { send_data @assignment.to_csv, { filename: filename } }
    end
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def gradebook_integration
    no_access("AssignmentController#gradebook_integration not instructor") && return unless helpers.instructor?(session[:roles])
    raise "No assignment selected" if !params.key?("assignment_id") && params["assignment_id"].empty?

    ca = CanvasAssignment.new(session[:course_id], params["assignment_id"], PAFCalculator.new(@assignment), canvas_service)
    ca.apply_paf_grades(session[:canvas_assignment_id]) # Canvas Assignment ID
    @assignment.source_assignment_id = params["assignment_id"]
    @assignment.save
    response = { success: true }
    respond_to do |format|
      format.json { render({ json: response }) }
    end
  rescue UnsupportedGradeTypeError => e
    respond_to do |format|
      format.json { render({ json: { error: e.message }, status: :not_implemented }) }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render({ json: { error: e.message }, status: :internal_server_error }) }
    end
  end

  private

  def _redirect_user
    if helpers.instructor?(session[:roles])
      if @assignment.groups.present?
        redirect_to assignments_path # if groups are uploaded, redirect to export results (show) view
      else
        redirect_to instruction_assignments_path # if groups are not uploaded, redirect to instruction view
      end
    else
      user = User.find_by({ lms_id: session[:current_user] })
      if user.present? && user.assignment_group(@assignment).present?
        if helpers.responses?(@assignment)
          redirect_to response_path({ id: @assignment.id }) # if responses being submitted, redirect to show view
        else
          redirect_to new_response_path # if responses not being submitted redirect to new path
        end
      else
        redirect_to nonmember_assignments_path # if not a member of an assignment
      end
    end
  end

  def _add_questions_to_assignment
    QuestionTemplate.all.reorder(:id).each.with_index(1) do |question_template, position|
      Question.create!(
        {
          question_text:        question_template.question_text,
          predefined:           true,
          enabled:              false,
          question_category_id: question_template.question_category_id,
          position:             position,
          assignment_id:        @assignment.id
        }
      )
    end
  end

end

# Error class for lti importer errors
class GroupsLtiImporterPersistError < StandardError
end
