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

RSpec.describe ResponsesController, { type: :controller } do
  render_views

  describe "#delete" do

    before(:example) do
      @canvas_service = double("CanvasService")
      allow(CanvasService).to receive(:new).and_return(@canvas_service)
      allow(controller).to receive(:canvas_service).and_return(@canvas_service)

      @user = FactoryBot.create(:user)
      allow(User).to receive(:find).and_return(@user)

      @assignment = FactoryBot.create(:assignment)
      allow(controller).to receive(:check_login).and_return(true)
      controller.session[:roles] = "Instructor"
      allow(Assignment).to receive(:find_by).and_return(@assignment)

      allow(controller.helpers).to receive(:canvas_user_ids).and_return("")
    end

    it "deletes responses successfully and sends message" do
      allow(@assignment).to receive(:clear_responses).and_return(true)
      allow(@canvas_service). to receive(:create_conversation).and_return(true)
      delete(:delete, { params: { format: "json", user_id: "", message: "", send_message: "true" } })
      expect(response).to have_http_status(:ok)
    end

    it "deletes responses successfully and does not send message" do
      allow(@assignment).to receive(:clear_responses).and_return(true)
      allow(@canvas_service).to receive(:create_conversation).and_return(true)
      delete(:delete, { params: { format: "json", user_id: "", message: "", send_message: "false" } })
      expect(@canvas_service).not_to receive(:create_conversation)
      expect(response).to have_http_status(:ok)
    end

    it "fails to delete responses and returns error" do
      allow(@assignment).to receive(:clear_responses).and_raise("boom!")
      delete(:delete, { params: { format: "json", user_id: "", message: "", send_message: "false" } })
      expect(response).to have_http_status(:internal_server_error)
    end

  end
end
