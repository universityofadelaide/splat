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

# module for Application wide helpers
module ApplicationHelper

  INSTRUCTOR_ROLES = [
    "urn:lti:sysrole:ims/lis/Administrator",
    "urn:lti:instrole:ims/lis/Administrator",
    "Administrator",
    "ContentDeveloper",
    "Instructor",
    "Teacher",
    "TeachingAssistant"
  ].freeze

  LEARNER_ROLES = [
    "urn:lti:instrole:ims/lis/Student",
    "Learner"
  ].freeze

  def instructor?(roles)
    return false unless roles
    roles_array = roles.split(",")

    roles_array.each do |role|
      return true if INSTRUCTOR_ROLES.include?(role)
    end

    return false
  end

  def learner?(roles)
    return false unless roles
    roles_array = roles.split(",")

    roles_array.each do |role|
      return true if LEARNER_ROLES.include?(role)
    end

    return false
  end

  def responses?(assignment)
    return nil unless assignment
    user = User.find_by({ lms_id: session[:current_user] })
    return assignment.responses.find_by({ from_user_id: user.id })
  end

  def register_flash_message(key, message)
    flash[key] = message
  end

  def display_flash_messages
    render "shared/flash_messages"
  end

  def trim_special_characters(string, allow)
    string.gsub(/#{allow}/, "") unless allow.nil?
  end

  def log_error(severity, error)
    logger.add(severity, _build_error_message(error))
  end

  def format_score(score)
    score.nil? ? nil : format("%.2f", score)
  end

  def format_date(passed_date)
    return passed_date.localtime.strftime("%d %B %Y at %H:%M")
  end

  def canvas_user_ids(canvas_service, recipients)
    recipients_canvas_user_ids = []
    recipients.each do |recipient|
      response = canvas_service.canvas_user_by_sis_user_id(recipient)
      recipients_canvas_user_ids << response[:id]
    end
    return recipients_canvas_user_ids
  rescue RestClient::Exceptions => e
    logger.error(e.inspect)
    raise e
  end

  private

  def _build_error_message(error)
    return _build_error_message_lines(error).join("\n")
  end

  def _build_error_message_lines(error)
    error_message_lines = []
    error_message_lines.push(error.message, *error.backtrace)
    while (error = error.cause)
      error_message_lines.push("Caused by:", error.message, *error.backtrace)
    end
    return error_message_lines
  end

end
