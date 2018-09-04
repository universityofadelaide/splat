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

require "spec_helper"

# Simulated Application controller for the tests
class TestController < ActionController::Base

  # lti_parameters will be received when the lti parameters have been validated
  # the method can be used to extract and possibly store application specific
  # information from the LTI interface
  def lti_parameters(_lti_params)
  end

end

RSpec.configure do |config|
  config.after(:suite) do
    CanvasLti.purge_nonces
  end
end

describe CanvasLti do
  let(:credentials) { { "wally_consumer_key" => "well_kept_secret" } }

  before :example do
    @session_parameters = %w[user_id roles]
    @test_controller = TestController.new
    @test_controller.params = double
    @test_controller.request = double
    @session = {}
    allow(@test_controller).to receive(:session).and_return(@session)
    allow(@test_controller.request).to receive(:url).and_return("https://foo.org")
    @request_params = { oauth_timestamp: Time.zone.now.to_i.to_s, oauth_nonce: Random.new_seed.to_s, oauth_consumer_key: credentials.keys.first }.with_indifferent_access
    allow(@test_controller.request).to receive(:request_parameters).and_return(@request_params)
    @message_auth = double
    allow(IMS::LTI::Services::MessageAuthenticator).to receive(:new).with(anything, anything, credentials[credentials.keys.first]).once.and_return(@message_auth)
    allow(@message_auth).to receive(:valid_signature?).and_return(true)
    allow(CanvasLti).to receive(:check_consumer_key).and_return(true)
  end

  context "configuration" do

    context "setting configuration" do

      it "passes the correct secret to validate" do
        CanvasLti.config({ credentials: credentials, session_parameters: @session_parameters })
        expect(IMS::LTI::Services::MessageAuthenticator).to receive(:new).with(anything, anything, credentials[credentials.keys.first]).once.and_return(@message_auth)
        CanvasLti.check_authentication(@test_controller)
      end

      it "stores the correct consumer_keys" do
        test_credentials = credentials
        test_consumer_key = "fruity_canvas"
        test_credentials[test_consumer_key] = "fruity_secret"
        @request_params[:oauth_consumer_key] = test_consumer_key
        allow(@test_controller.request).to receive(:request_parameters).and_return(@request_params)
        CanvasLti.config({ credentials: credentials, session_parameters: @session_parameters })
        expect(IMS::LTI::Services::MessageAuthenticator).to receive(:new).with(anything, anything, test_credentials[test_consumer_key]).once.and_return(@message_auth)
        CanvasLti.check_authentication(@test_controller)
      end

    end

    context "validating params" do

      before(:example) do
        CanvasLti.reset # needed since the module uses class wide variables
        @config = { credentials: credentials, session_parameters: @session_parameters }
        CanvasLti.config(@config)

      end

      context "validation of the signature returned from the LTI MessageAuthenticator" do

        it "fails validation when the signature is invalid" do
          allow(@message_auth).to receive(:valid_signature?).and_return(false)
          expect(CanvasLti.check_authentication(@test_controller)).to be false
        end

        it "succeeds validation when the signature is valid" do
          expect(CanvasLti.check_authentication(@test_controller)).to be true
        end

        it "prevents reuse of nonce" do
          nonce = "not unique"
          CanvasLti.purge_nonces
          @request_params[:oauth_nonce] = nonce
          allow(@test_controller.request).to receive(:request_parameters).and_return(@request_params)
          allow(IMS::LTI::Services::MessageAuthenticator).to receive(:new).with(anything, anything, credentials[credentials.keys.first]).and_return(@message_auth)
          expect(CanvasLti.check_authentication(@test_controller)).to be true
          expect(CanvasLti.check_authentication(@test_controller)).to be false
        end

        it "ensures oauth_consumer_key is in whitelist" do
          @request_params[:oauth_consumer_key] = "not_legal_consumer_key"
          allow(CanvasLti).to receive(:check_consumer_key).and_call_original
          allow(@test_controller.request).to receive(:request_parameters).and_return(@request_params)
          expect(CanvasLti.check_authentication(@test_controller)).to be false
        end

      end

      it "populates the session with user LTI parameters" do
        expect(CanvasLti.check_authentication(@test_controller)).to be true
        # load the user provided session parameters and verify the session has been populated
        expect(@test_controller.session.keys.sort).to include(*@session_parameters.map(&:to_sym)) # include needs a list of arguments rather than an array, so splat it into a list
      end

      it "does not expunge the existing session data" do
        existing_session_data = { gobbeldy_gook: "some random_data!" }
        @session = existing_session_data.dup
        allow(@test_controller).to receive(:session).and_return(@session)
        expect(CanvasLti.check_authentication(@test_controller)).to be true
        # load the user provided session parameters and verify the session has been populated
        expect(@test_controller.session).to include(existing_session_data)
      end

      it "provides collected LTI parameters to the application via a controller method" do
        expect(@test_controller).to receive(:lti_parameters).with(@test_controller.request.request_parameters)
        expect(CanvasLti.check_authentication(@test_controller)).to be true
      end

    end
  end

end
