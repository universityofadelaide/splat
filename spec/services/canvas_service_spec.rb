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

RSpec.describe CanvasService, { type: :service } do

  before(:each) do
    config          = { "base_url" => "https://example.com/", "api_prefix" => "api/v1/", "token" => "NOT-A-TOKEN" }
    @canvas_service = CanvasService.new(config, self)
    @base_url        = config["base_url"]
    @api_prefix      = config["api_prefix"]
  end

  it "uses correct URL to #create_conversation" do
    recipients = [12_345, 45_678]
    subject = "Subject for the conversation"
    body = "Body for the conversation"
    group_conversation = true
    as_user_id = 1_234_567.to_s
    expected_url = URI.join(@base_url, @api_prefix, "conversations").to_s
    expected_payload = { recipients: recipients, subject: subject, body: body, group_conversation: group_conversation, as_user_id: "sis_user_id:" + as_user_id }
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :post, url: expected_url, payload: expected_payload })).and_raise("URL ok")
    expect { @canvas_service.create_conversation(recipients, subject, body, group_conversation, as_user_id) }.to raise_error("URL ok")
  end

  context "when creating a custom gradebook column" do

    # https://canvas.instructure.com/doc/api/custom_gradebook_columns.html
    # POST /api/v1/courses/:course_id/custom_gradebook_columns
    it "uses the correct URL" do
      course_id = 1111
      expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/custom_gradebook_columns").to_s
      column_name = "sample column"
      allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :post, url: expected_url })).and_raise("URL ok")
      expect { @canvas_service.create_custom_gradebook_column(course_id, column_name) }.to raise_error("URL ok")
    end

    it "requires the correct parameters" do
      skip
      # TODO: test that the POST provides title, position, hidden (false), teacher_notes (false), read_only (true)
      # note: position is reletive to other customer columns
    end

  end

  it "uses correct URL to get #canvas_user_by_sis_user_id" do
    sis_user_id = 1_234_567
    expected_url = URI.join(@base_url, @api_prefix, "users/sis_user_id:#{ sis_user_id }").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.canvas_user_by_sis_user_id(sis_user_id) }.to raise_error("URL ok")
  end

  it "uses correct URL to get #get_assignments" do
    course_id = 1111
    expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/assignments").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_assignments(course_id) }.to raise_error("URL ok")
  end

  it "uses correct URL to get #get_group_categories" do
    course_id = 1111
    expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/group_categories").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_group_categories(course_id) }.to raise_error("URL ok")
  end

  # https://canvas.instructure.com/doc/api/custom_gradebook_columns.html
  # GET /api/v1/courses/:course_id/custom_gradebook_columns
  it "uses correct URL to get #get_gradebook_columns" do
    course_id = 1111
    expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/custom_gradebook_columns").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_gradebook_columns(course_id) }.to raise_error("URL ok")
  end

  it "uses correct URL to get #get_grades" do
    course_id = 1111
    assignment_id = 1234
    expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/assignment/#{ assignment_id }/grades").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_grades(course_id, assignment_id) }.to raise_error("URL ok")
  end

  it "uses correct URL to get #get_group_category" do
    group_category_id = 6532
    expected_url = URI.join(@base_url, @api_prefix, "group_categories/#{ group_category_id }").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_group_category(group_category_id) }.to raise_error("URL ok")
  end

  it "uses correct URL to get #get_groups" do
    group_category_id = 1111
    expected_url = URI.join(@base_url, @api_prefix, "group_categories/#{ group_category_id }/groups").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_groups(group_category_id) }.to raise_error("URL ok")
  end

  context "#get_submissions_for_assignment" do

    it "uses the correct api endpoint" do
      course_id = 1234
      assignment_id = 888
      expected_url = URI.join(@base_url, @api_prefix, "courses/#{ course_id }/assignments/#{ assignment_id }/submissions").to_s
      allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
      expect { @canvas_service.get_submissions_for_assignment(course_id, assignment_id).to raise_error("URL ok") }
    end

  end

  it "uses correct URL to get #get_users for a group" do
    group_id = 5435
    expected_url = URI.join(@base_url, @api_prefix, "groups/#{ group_id }/users").to_s
    allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :get, url: expected_url })).and_raise("URL ok")
    expect { @canvas_service.get_users(group_id) }.to raise_error("URL ok")
  end

  context "when updating grades" do

    before(:example) do
      @course_id = 1111
      @assignment_id = 4322
      @grade_data = [{ student_id: 123, grade: 18 }, { student_id: 456, grade: 87 }]
      @expected_url = URI.join(@base_url, @api_prefix, "courses/#{ @course_id }/assignments/#{ @assignment_id }/submissions/update_grades").to_s
      @expected_payload = { "grade_data[123][posted_grade]" => "18", "grade_data[456][posted_grade]" => "87" }
    end

    # https://canvas.instructure.com/doc/api/submissions.html
    # POST /api/v1/courses/:course_id/assignments/:assignment_id/submissions/update_grades
    it "uses the correct URL to post #update_grades" do
      allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :post, url: @expected_url })).and_raise("URL ok")
      expect { @canvas_service.update_grades(@course_id, @assignment_id, @grade_data) }.to raise_error("URL ok")
    end

    it "encodes the grade data for the canvas api" do
      allow(RestClient::Request).to receive(:execute).with(hash_including({ method: :post, payload: @expected_payload })).and_raise("POST data ok")
      expect { @canvas_service.update_grades(@course_id, @assignment_id, @grade_data) }.to raise_error("POST data ok")
    end

  end
end
