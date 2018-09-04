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

require "rails_helper"

RSpec.describe NotificationsController, { type: :controller } do
  render_views

  context "create_conversation" do

    before(:example) do
      @canvas_service = double("CanvasService")
      allow(CanvasService).to receive(:new).and_return(@canvas_service)
      allow(controller).to receive(:canvas_service).and_return(@canvas_service)

      @assignment = FactoryBot.create(:assignment)
      allow_any_instance_of(ApplicationController).to receive(:check_login).and_return(true)
      controller.session[:roles] = "Instructor"
      allow(Assignment).to receive(:find_by).and_return(@assignment)

      @expected_lms_ids = %w[dummy1 dummy2]
      @expected_canvas_user_ids = %w[response1 response1]
      @subject = "Some subject"
      @body = "Some body"
      @group_conversation = true
      @as_user_id = "dummy"

      allow_any_instance_of(Assignment).to receive(:not_responded_user_lms_ids).and_return(@expected_lms_ids)
      allow_any_instance_of(ApplicationHelper).to receive(:canvas_user_ids).and_return(@expected_canvas_user_ids)
    end

    it "create conversations successfully" do
      allow(@canvas_service).to receive(:create_conversation).and_return([])
      post(:create_conversation, { params: { users_lms_ids: "", subject: @subject, body: @body } })
      expect(response).to have_http_status(:ok)
    end

    it "reports an error due to a bad request" do
      allow(@canvas_service).to receive(:create_conversation) { raise RestClient::BadRequest }
      post(:create_conversation, { params: { users_lms_ids: "", subject: @subject, body: @body } })
      expect(response.body).to include("An error occurred when sending notifications")
      expect(response).to have_http_status(:internal_server_error)
    end

  end
end
