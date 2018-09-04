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

# This controller is manages users responses
class ResponsesController < ApplicationController

  def show
    no_access && return unless helpers.learner?(session[:roles])
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: 500 })
  end

  def new
    no_access && return unless helpers.learner?(session[:roles])
    session.delete(:flash)
    @user = User.find_by({ lms_id: session[:current_user] })
    @questions = @assignment.questions.active.sorted
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: 500 })
  end

  def create
    no_access && return unless helpers.learner?(session[:roles])
    @user = User.find_by({ lms_id: session[:current_user] })

    if helpers.responses?(@assignment)
      redirect_to response_path({ id: @assignment.id })
    else
      begin
        ActiveRecord::Base.transaction do
          _create_comment(@assignment, @user, params[:comments]) unless params[:comments].nil?
          _create_responses(@assignment, @user, params[:questions])
          redirect_to response_path({ id: @assignment.id })
        end
      rescue ResponseException
        flash[:danger] = @errors
        render :new, { flash: flash }
      rescue ActiveRecord::RecordInvalid => e
        logger.error(e.inspect)
        flash[:danger] = e.message
        render :new, { flash: flash }
      rescue StandardError => e
        logger.error(e.inspect)
        flash[:danger] = "An error occured saving the responses."
        render :new, { flash: flash }
      end
    end
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: 500 })
  end

  def score
    used = ActiveRecord::Type::Boolean.new.cast(params[:used])
    ActiveRecord::Base.transaction do
      @assignment.responses.where({ from_user_id: params[:from], for_user_id: params[:for] }).each do |response|
        response.update({ score_used: used })
      end
    end
    response = {
      params:     params,
      paf_score:  helpers.format_score(PAFCalculator.new(@assignment).calculate(params[:for], true)),
      sapa_score: helpers.format_score(SAPACalculator.new(@assignment).calculate(params[:for], true))
    }
    respond_to do |format|
      format.json { render({ json: response }) }
    end
  rescue StandardError => e
    logger.error(e.inspect)
    respond_to do |format|
      format.json { render({ json: params, message: e.message, status: 500 }) }
    end
  end

  def delete
    send_message = ActiveRecord::Type::Boolean.new.cast(params[:send_message])
    @assignment.clear_responses(params[:user_id])

    if send_message
      lms_id = User.find(params[:user_id])[:lms_id]
      canvas_user_id = helpers.canvas_user_ids(canvas_service, [lms_id])
      subject = "SPLAT response reset"
      # If true, this will be a group conversation (i.e. all recipients may see all messages and replies).
      # We discoved that if a conversation is private (i.e. group_conversation = false), we are not able to change the subject. It uses the subject of the first private conversation with that user.
      group_conversation = true # Default is false
      as_user_id = session[:current_user]
      canvas_service.create_conversation(canvas_user_id, subject, params[:message], group_conversation, as_user_id)
    end

    response = {
      params:  params,
      success: true
    }
    respond_to do |format|
      format.json { render({ json: response }) }
    end
  rescue StandardError => e
    logger.error(e.inspect)
    respond_to do |format|
      format.json { render({ json: params, message: e.message, status: 500 }) }
    end
  end

  # This controller is to catch data errors in the responses
  class ResponseException < RuntimeError
  end

  private

  def _create_responses(assignment, from_user, questions)
    @errors = []

    assignment.questions.active.sorted.each do |question|
      total = 0
      from_user.assignment_group(assignment).users.each do |for_user|
        score = questions[question.id.to_s][:responses][for_user.id.to_s][:score]
        if score.empty?
          @errors << "Score for '#{ question.question_text }' for #{ for_user.first_name } #{ for_user.last_name } is blank"
        else
          begin
            Response.create!({ assignment_id: assignment.id, question_id: question.id, from_user_id: from_user.id, for_user_id: for_user.id, score: score })
          rescue ActiveRecord::RecordInvalid => e
            logger.error(e.inspect)
            @errors << e.message
            raise ResponseException
          end

          total += score.to_i
        end
      end
      unless total == 100
        @errors << "Total score for '#{ question.question_text }' is #{ total || 0 } but should be 100"
      end
    end
    raise ResponseException unless @errors.count.zero?
  end

  # This method creates comments for current assignment
  def _create_comment(assignment, from_user, comments)
    Comment.create!({ assignment_id: assignment.id, user_id: from_user.id, comments: comments[:text] })
  end

end
