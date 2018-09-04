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

RSpec.describe ApplicationHelper, { type: :helper } do

  describe "instructor?" do

    it "returns true for roles with instructor privileges" do
      expect(helper.instructor?("urn:lti:sysrole:ims/lis/Administrator")).to be true
      expect(helper.instructor?("Instructor")).to be true
      expect(helper.instructor?("TeachingAssistant")).to be true
    end

    it "returns false for roles without instructor privileges" do
      expect(helper.instructor?("Learner")).to be false
    end

  end

  describe "learner?" do

    it "returns true for roles with student privileges" do
      expect(helper.learner?("urn:lti:instrole:ims/lis/Student")).to be true
      expect(helper.learner?("Learner")).to be true
    end

    it "returns false for roles without student privileges" do
      expect(helper.learner?("urn:lti:sysrole:ims/lis/Administrator")).to be false
      expect(helper.learner?("Instructor")).to be false
      expect(helper.learner?("TeachingAssistant")).to be false
      expect(helper.learner?("urn:lti:instrole:ims/lis/Staff")).to be false
      expect(helper.learner?("Invalid role")).to be false
    end

  end

  describe "responses?" do

    before :example do
      do_login
      @user = User.find_by({ lms_id: session[:current_user] })
      @user ||= FactoryBot.create(:user, { lms_id: session[:current_user] })
      @question = FactoryBot.create(:question)
      @assignment = @question.assignment
    end

    it "returns a Response when the user has submitted responses" do
      FactoryBot.create(:response, { from_user: @user, assignment: @assignment, question: @question })
      expect(helper.responses?(@assignment)).to be_instance_of(Response)
    end

    it "returns nil when a nil assignment is provided" do
      expect(helper.responses?(nil)).to be nil
    end

    it "returns nil when the user has not submitted responses" do
      expect(helper.responses?(@assignment)).to be nil
    end

  end

  describe "canvas_user_ids" do

    before(:each) do
      services_config = YAML.load_file(Rails.root.join("config", "services.yml").to_s)
      @canvas_service = CanvasService.new(services_config["canvas"], self)

      @expected_output = []
      @sis_user_id1 = 123
      @sis_user_id2 = 456
      @canvas_response_data = { @sis_user_id1 => { id: 321, name: "dummy1" }, @sis_user_id2 => { id: 654, name: "dummy2" } }

      allow(@canvas_service).to receive(:canvas_user_by_sis_user_id).with(@sis_user_id1).and_return(@canvas_response_data[@sis_user_id1])
      @expected_output << @canvas_response_data[@sis_user_id1][:id]
      allow(@canvas_service).to receive(:canvas_user_by_sis_user_id).with(@sis_user_id2).and_return(@canvas_response_data[@sis_user_id2])
      @expected_output << @canvas_response_data[@sis_user_id2][:id]
    end

    it "returns canvas user_id for a supplied sis_id" do
      expect(canvas_user_ids(@canvas_service, [@sis_user_id1, @sis_user_id2])).to eq(@expected_output)
    end
  end

end
