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

# This controller holds methods to send notifications to the students
class NotificationsController < ApplicationController

  def create_conversation
    no_access("AssignmentController#show not instructor") && return unless helpers.instructor?(session[:roles])
    recipients_lms_ids = params[:users_lms_ids].split
    recipients_canvas_user_ids = helpers.canvas_user_ids(canvas_service, recipients_lms_ids)
    subject = params[:subject]
    body = params[:body]
    # If true, this will be a group conversation (i.e. all recipients may see all messages and replies).
    # We discoved that if a conversation is private (i.e. group_conversation = false), we are not able to change the subject. It uses the subject of the first private conversation with that user.
    group_conversation = true # Default is false
    as_user_id = session[:current_user]

    rest_client_action(
      {
        not_found:    { json: "Data could not be found." },
        unauthorized: { json: "An authorisation error occurred when collecting data." },
        exception:    { json: "An error occurred when sending notifications.", status: 500 }
      }
    ) do
      canvas_service.create_conversation(recipients_canvas_user_ids, subject, body, group_conversation, as_user_id)
    end
    if response.status == 200
      new_notification = _add_notifications(recipients_lms_ids, subject, body)
      render({ json: new_notification.to_json, status: :ok })
    end
  rescue ActiveRecord::RecordInvalid => e
    logger.error(e.inspect)
    flash[:danger] = "An error occurred when saving notifications"
  rescue StandardError => e
    logger.error(e.inspect)
    render({ file: Rails.root.join("public", "500.html"), status: :internal_server_error })
  end

  def search_students
    no_access("AssignmentController#show not instructor") && return unless helpers.instructor?(session[:roles])
  end

  private

  def _add_notifications(recipients_lms_ids, subject, body)
    new_notification = []
    ActiveRecord::Base.transaction do
      notified_users = []
      @message = Message.create!({ subject: subject, body: body, assignment: @assignment, created_by: session[:current_user], updated_by: session[:current_user] })
      recipients_lms_ids.each do |recipient_lms_id|
        user = User.find_by({ lms_id: recipient_lms_id })
        Notification.create!({ message: @message, user: user, created_by: session[:current_user], updated_by: session[:current_user] })
        notified_users << @assignment.users.where({ id: user.id }).pluck(:first_name, :last_name).join(" ")
      end
      new_notification <<
        {
          subject:          @message.subject,
          body:             @message.body,
          users:            notified_users,
          no_of_users_sent: notified_users.length,
          created_at:       helpers.format_date(@message.created_at)
        }
    end
    return new_notification
  end

end
