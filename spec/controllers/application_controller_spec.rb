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

RSpec.describe GroupCategoriesController, { type: :controller } do

  before(:each) do
    allow_any_instance_of(GroupCategoriesController).to receive(:check_login)
  end

  context "within an action using RestClient" do

    it "renders the notfound target when a HTTP 404 error occurs" do
      allow(RestClient::Request).to receive(:execute) { raise RestClient::NotFound }
      session[:course_id] = 0
      get :index
      expect(response).to render_template({ file: Rails.root.join("public", "404.html").to_s })
    end

    it "renders the unauthorized target when a HTTP 401 error occurs" do
      allow(RestClient::Request).to receive(:execute) { raise RestClient::Unauthorized }
      session[:course_id] = 0
      get :index
      expect(response).to render_template({ file: Rails.root.join("public", "401.html").to_s })
    end

    it "renders the notfound target when a RestClient::Exception error occurs" do
      allow(RestClient::Request).to receive(:execute) { raise RestClient::Exception }
      session[:course_id] = 0
      get :index
      expect(response).to render_template({ file: Rails.root.join("public", "500.html").to_s })
    end

  end

end
