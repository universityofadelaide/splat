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

# parameters here were gotten from a real canvas request in the following way:
# 1. Set up splat-int environment to have the consumer_key: "test" and the shared_secret: "secret"
# 2. Configure canvas to point to splat-int
# 5. delete "controller" and "action" from the params hash
GOOD_REQUEST = {
  host:          "our_host",
  path:          "/assignments/lti_launch",
  scheme:        "https://",
  client_secret: "secret",
  headers:       { "X-XSS-Protection" => "1; mode=block", "X-Content-Type-Options" => "nosniff" },
  params:        {
    "oauth_consumer_key"                       => "test",
    "oauth_signature_method"                   => "HMAC-SHA1",
    "oauth_timestamp"                          => "1501026991",
    "oauth_nonce"                              => "urenckniZ9Ra4D0rGvJuYAyUKpmcQ4T4EXfdWJIAgq0",
    "oauth_version"                            => "1.0",
    "context_id"                               => "d28a4e89c6f47dc581a618ddb35eae638f33c1b6",
    "context_label"                            => "AU_TA_TEST_0001",
    "context_title"                            => "AU_UNIAD_TA_TEST_0001",
    "custom_canvas_api_domain"                 => "beta.instructure.com",
    "custom_canvas_assignment_id"              => "43909",
    "custom_canvas_assignment_points_possible" => "0",
    "custom_canvas_assignment_title"           => "splat-int test assignment",
    "custom_canvas_course_id"                  => "27151",
    "custom_canvas_enrollment_state"           => "active",
    "custom_canvas_user_id"                    => "9",
    "custom_canvas_user_login_id"              => "a000000",
    "custom_canvas_workflow_state"             => "available",
    "ext_ims_lis_basic_outcome_url"            => "https://beta.instructure.com/api/lti/v1/tools/510/ext_grade_passback",
    "ext_lti_assignment_id"                    => "e41b2022-8836-4ce0-aed6-f464a8a7c1e4",
    "ext_outcome_data_values_accepted"         => "url,text",
    "ext_outcome_result_total_score_accepted"  => "true",
    "ext_outcomes_tool_placement_url"          => "https://beta.instructure.com/api/lti/v1/turnitin/outcomes_placement/510",
    "ext_roles"                                => "urn:lti:instrole:ims/lis/Administrator,urn:lti:instrole:ims/lis/Instructor,"\
      "urn:lti:instrole:ims/lis/Student,urn:lti:role:ims/lis/Instructor,urn:lti:sysrole:ims/lis/User",
    "launch_presentation_document_target"      => "iframe",
    "launch_presentation_locale"               => "en-GB",
    "launch_presentation_return_url"           => "https://beta.instructure.com/courses/27151/external_content/success/external_tool_redirect",
    "lis_course_offering_sourcedid"            => "AU_TEACHING_TEST",
    "lis_outcome_service_url"                  => "https://beta.instructure.com/api/lti/v1/tools/510/grade_passback",
    "lis_person_contact_email_primary"         => "a000000@test.com",
    "lis_person_name_family"                   => "Tester",
    "lis_person_name_full"                     => "My Tester",
    "lis_person_name_given"                    => "My",
    "lis_person_sourcedid"                     => "000000",
    "lti_message_type"                         => "basic-lti-launch-request",
    "lti_version"                              => "LTI-1p0",
    "oauth_callback"                           => "about:blank",
    "resource_link_id"                         => "718d39ebbb54bbf4cdb8c7bb88e0edabd2bc9535",
    "resource_link_title"                      => "splat-int test assignment",
    "roles"                                    => "Instructor,urn:lti:instrole:ims/lis/Administrator",
    "tool_consumer_info_product_family_code"   => "canvas",
    "tool_consumer_info_version"               => "cloud",
    "tool_consumer_instance_contact_email"     => "notifications@instructure.com",
    "tool_consumer_instance_guid"              => "brjTnXnelSfPEosicuEqo8jssZIhA3DFvfFytnDx:canvas-lms",
    "tool_consumer_instance_name"              => "The University of Adelaide",
    "user_id"                                  => "45536fbf7515db571ec4f665cae175cd12e005c3",
    "user_image"                               => "https://secure.gravatar.com/avatar/9627f96c5db0f32e78e44970e6dfsdf9f2194?s=50&d="\
      "https%3A%2F%2Fcanvas.instructure.com%2Fimages%2Fmessages%2Favatar-50.png",
    "oauth_signature"                          => "JaulyYlD1PlE1mn/hssZuHpVkzc="
  }
}.freeze

RSpec.describe AssignmentsController, { type: :controller } do

  before(:example) do
    @message_auth = double
    allow(IMS::LTI::Services::MessageAuthenticator).to receive(:new).with(anything, anything, anything).once.and_return(@message_auth)
    allow(@message_auth).to receive(:valid_signature?).and_return(true)
    allow(CanvasLti).to receive(:check_consumer_key).and_return(true)
    @parameters = seeded_required_launch_params
    @parameters[:oauth_timestamp] = Time.zone.now.strftime("%s")
    @parameters[:oauth_nonce] = rand(23**7).to_s(10)

    do_login
    @assignment = FactoryBot.create(:assignment, :with_question, { lms_id: @parameters["ext_lti_assignment_id"].to_s })
    @user = FactoryBot.create(:user, { lms_id: session[:current_user] })
    @category = FactoryBot.create(:question_category)
  end

  context "#start" do

    before(:example) do
      @parameters[:roles] = "Instructor"
      allow_any_instance_of(ApplicationController).to receive(:check_login).and_return(true)
    end

    it "uses the no_access helper method for unauthorised roles" do
      @parameters[:roles] = ""
      expect(controller).to receive(:no_access).at_least(:once)
      post(:start, { params: @parameters })
    end

    it "creates an assignment with the correct lms id if it does not already exist" do
      @assignment.destroy
      @assignment = nil
      assignment = Assignment.find_by({ lms_id: @parameters["ext_lti_assignment_id"].to_s })
      expect(assignment).to be_nil
      new_assignment = FactoryBot.build(:assignment, { lms_id: @parameters["ext_lti_assignment_id"].to_s })
      allow(Assignment).to receive(:create).and_return(new_assignment.save)
      post(:start, { params: @parameters })
      assignment = Assignment.find_by({ lms_id: @parameters["ext_lti_assignment_id"].to_s })
      expect(assignment).to be
    end

    context "redirection for instructor users" do

      before(:example) do
        @parameters[:roles] = "Instructor"
      end

      it "redirects to instructions when there are no groups on the assignment" do
        post(:launch, { params: @parameters })
        expect(response).to have_http_status(302)
        expect(response.location).to start_with(instruction_assignments_url)
      end

      it "redirects to export when there are groups on the assignment" do
        FactoryBot.create(:assignment_group, { assignment: @assignment })
        post(:launch, { params: @parameters })
        expect(response).to have_http_status(302)
        expect(response.location).to start_with(assignments_url)
      end

    end

    context "redirection for student users" do

      before(:example) do
        # fake authentication
        # authenticator = double
        # allow(IMS::LTI::Services::MessageAuthenticator).to receive(:new).and_return(authenticator)
        # allow(authenticator).to receive(:valid_signature?).and_return(true)
        #
        # controller.params[:roles] = "Learner"
        # @parameters = seeded_required_launch_params
        # @parameters[:oauth_timestamp] = Time.zone.now.strftime("%s")
        # @parameters[:roles] = "Learner"
        # session[:assignment_id] = @parameters["ext_lti_assignment_id"].to_s
        @group = FactoryBot.create(:assignment_group, { assignment: @assignment })
        @parameters[:roles] = "Learner"
      end

      it "redirects to the non-member page when the user is not in an assignment group" do
        post(:launch, { params: @parameters })
        expect(response).to redirect_to(nonmember_assignments_path)
      end

      it "redirects to the new response page when the user is in an assignment group" do
        @user.groups << @assignment.groups.first
        post(:launch, { params: @parameters })
        expect(response).to redirect_to(new_response_path)
      end

      it "redirects to the thank you page when the user has submitted a response" do
        @user.groups << @assignment.groups.first
        FactoryBot.create(:response, { assignment: @assignment, from_user: @user,
           for_user: @user, question: @assignment.questions.first, score: 100 })
        post(:launch, { params: @parameters })
        expect(response).to redirect_to(response_path({ id: @assignment.id }))
      end

    end

  end

  context "GET #instruction" do

    before(:example) do
      controller.session[:roles] = "Instructor"
      allow_any_instance_of(ApplicationController).to receive(:check_login).and_return(true)
    end

    context "when the user doesn't have the role of Instructor" do

      before(:example) do
        controller.session[:roles] = "NotInstructor"
      end

      it "no access" do
        get :instruction
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template({ file: Rails.root.join("public", "401.html").to_s })
      end

    end

    context "when no instruction text exists" do

      it "renders the instruction page" do
        controller.session[:roles] = "Instructor"
        get :instruction
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:instruction)
      end

    end

  end

  context "POST #instruction" do

    before(:example) do
      allow_any_instance_of(ApplicationController).to receive(:check_login).and_return(true)
      controller.session[:roles] = "Instructor"
      # @assignment = FactoryBot.create(:assignment)
      allow(Assignment).to receive(:find_by).and_return(@assignment)
      category_id = @category.id
      updated_questions = {}
      updated_questions[category_id] = [{ id: nil, question_text: "This is some text", enabled: true }]
      @parameters = { instructions: { text: "My instruction" }, updated_questions: updated_questions.to_json.to_s }
    end

    context "when assignment update raises an ActiveRecord::RecordInvalid error (e.g. when the submitted instructions exceeds the max size for instructions)" do

      before(:example) do
        @parameters = { instructions: { text: "a" * 5001, updated_questions: { category: [] }.to_json.to_s } }
      end

      it "displays the instruction page with an error message" do
        post(:instruction, { params: @parameters })
        expect(flash[:danger]).to include("Error during save:")
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:instruction)
      end

    end

    context "when some other kind of error occurs" do

      before(:example) do
        allow(@assignment).to receive(:update!).and_raise("some other error")
      end

      it "render internal server error page" do
        post(:instruction, { params: @parameters })
        expect(response).to render_template({ file: Rails.root.join("public", "500.html").to_s })
        expect(response).to have_http_status(:internal_server_error)
      end

    end

    context "when instructions are successfully saved" do

      it "renders the preview page" do
        post(:instruction, { params: @parameters })
        expect(response).to redirect_to(preview_assignments_path)
      end

      it "adds new questions" do
        skip
        question = FactoryBot.build(:question)
        @parameters[:updated_questions] = { category: [question] }.to_json.to_s
        post(:instruction, { params: @parameters })
        expect(@assignment.questions.first.question_text).to eq(question.question_text)
      end

    end

  end

  context "#export_csv" do

    it "no access for non-instructors" do
      controller.session[:roles] = "Learner"
      get :export_csv
      expect(response).to have_http_status(:unauthorized)
    end

    it "correct filename generated" do
      allow_any_instance_of(ApplicationController).to receive(:check_login).and_return(true)
      controller.session[:roles] = "Instructor"
      controller.session[:assignment_id] = @assignment.lms_id
      controller.session[:assignment_title] = @assignment.name

      @assignment.lti_launch_params = GOOD_REQUEST[:params].to_json
      @assignment.course_name = GOOD_REQUEST[:params]["context_label"]
      allow(Assignment).to receive(:find_by).and_return(@assignment)
      allow(@assignment).to receive(:to_csv).and_return("")

      expect(controller).to receive(:send_data).with("", { filename: "#{ GOOD_REQUEST[:params]["context_label"] }-#{ @assignment.name }-#{ Time.now.getlocal.strftime("%Y-%m-%d") }.csv" })

      get :export_csv, { params: { format: "csv" } }
    end

  end

end
