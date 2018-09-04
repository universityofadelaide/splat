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

LTI_1_0 = %w[
  lti_message_type
  lti_version
  resource_link_id
  resource_link_title
  resource_link_description
  user_id
  user_image
  roles
  lis_person_name_given
  lis_person_name_family
  lis_person_name_full
  lis_person_contact_email_primary
  context_id
  context_type
  context_title
  context_label
  launch_presentation_locale
  launch_presentation_document_target
  launch_presentation_width
  launch_presentation_height
  launch_presentation_return_url
  tool_consumer_instance_guid
  tool_consumer_instance_name
  tool_consumer_instance_description
  tool_consumer_instance_url
  tool_consumer_instance_contact_email
].freeze

LTI_1_2 = %w[
  role_scope_mentor
  launch_presentation_css_url
  tool_consumer_info_product_family_code
  tool_consumer_info_version
].freeze

CANVAS = %w[
  custom_canvas_api_domain
  custom_canvas_assignment_id
  custom_canvas_assignment_points_possible
  custom_canvas_assignment_title
  custom_canvas_course_id
  custom_canvas_enrollment_state
  custom_canvas_user_id
  custom_canvas_user_login_id
  custom_canvas_workflow_state
  ext_ims_lis_basic_outcome_url
  ext_lti_assignment_id
  ext_outcome_data_values_accepted
  ext_outcome_result_total_score_accepted
  ext_outcomes_tool_placement_url
  ext_roles
  lis_course_offering_sourcedid
  lis_outcome_service_url
  lis_person_sourcedid
  oauth_callback
  oauth_consumer_key
  oauth_nonce
  oauth_signature
  oauth_signature_method
  oauth_timestamp
].freeze

# module to include for canvas LTI
# rubocop:disable Style/ClassVars
module CanvasLti

  @@credentials = {}
  @@session_params = [].to_set
  @@consumer_keys = []
  @@authentication_failure_path = "public/401"

  class NonceReused < ArgumentError
  end

  NONCE_DIR = Rails.root.join("tmp", "nonce")

  def self.before(controller)
    Rails.logger.debug("checking authentication")
    self.check_authentication(controller)
  end

  def self.check_authentication(controller)
    controller.session[:lti_launch_valid] = false
    # from https://github.com/instructure/ims-lti
    r_url = controller.request.url
    r_params = controller.request.request_parameters
    sourcedid = r_params[:lis_person_sourcedid] || "unknown_sourcedid"
    Rails.logger.debug("#{ sourcedid }: Resetting session launch status")
    # check that the consumer key is known
    return false unless check_consumer_key(controller.request.request_parameters[:oauth_consumer_key])
    Rails.logger.debug("#{ sourcedid }: Consumer key ok")
    authenticator = IMS::LTI::Services::MessageAuthenticator.new(r_url, r_params, @@credentials[controller.request.request_parameters[:oauth_consumer_key]])

    # Check if the signature is valid
    return false unless authenticator.valid_signature?
    Rails.logger.debug("#{ sourcedid }: valid authenticator signature")

    # check if the message is too old
    return false if DateTime.strptime(controller.request.request_parameters[:oauth_timestamp], "%s") < 5.minutes.ago
    Rails.logger.debug("#{ sourcedid }: oauth timestamp ok")

    begin
      nonce = controller.request.request_parameters[:oauth_nonce]
      return false unless nonce
      # check if `params['oauth_nonce']` has already been used
      write_nonce(nonce)
    rescue NonceReused
      Rails.logger.debug("#{ sourcedid }: nonce key has been already used")
      return false
    end
    controller.lti_parameters(controller.request.request_parameters) if controller.respond_to?(:lti_parameters)
    @@session_params.each do |key|
      controller.session[key.to_sym] = controller.request.request_parameters[key.to_s]
    end

    Rails.logger.debug("#{ sourcedid }: logged in ok; marking session as logged in")
    controller.session[:lti_launch_valid] = true
    return true # everything checks out
  end

  def self.reset
    @@credentials = {}
    @@session_params = [].to_set
    @@consumer_keys = []
  end

  def self.config(options={})
    @@credentials = options[:credentials] if options[:credentials]
    @@authentication_failure_path = options[:unauthorized_access_path] if options[:unauthorized_access_path]
    self.session_parameters = options[:session_parameters] # calling the setter for session_parameters
  end

  def self.session_parameters=(params)
    @@session_params.merge(params) if params # & is a set intersection for arrays
  end

  def self.check_consumer_key(key)
    return @@credentials.keys.include?(key)
  end

  def self.authentication_failure_path
    @@authentication_failure_path
  end

  def self.write_nonce(nonce)
    Dir.mkdir(NONCE_DIR) unless File.directory?(NONCE_DIR)
    nonce_file = NONCE_DIR.join(nonce)
    File.open(nonce_file, File::CREAT | File::EXCL)
  rescue Errno::EEXIST => e
    Rails.logger.error("could not create unique nonce: #{ e.inspect }")
    raise NonceReused, "This is not the nonce you were looking for, move along"
  end

  def self.purge_nonces
    raise "WTF?" unless NONCE_DIR.to_s.include?("/nonce")
    FileUtils.rm_rf(NONCE_DIR)
  end

  # Generic application wide controller methods
  class CanvasLtiApplicationController < ActionController::Base

    before_action :reset_session, { only: [:launch] }
    before_action CanvasLti, { only: [:launch] }
    before_action :allow_iframe
    before_action :check_login

    # The launch point for the application, this method triggers the canvas lti authentication checks
    # and thus creates the session to enable other actions to execute.
    # The application may need to do fancy redirections on launch and in this case, the controller method :start
    # should be implemented otherwise the following redirect to welcome_path will cause a double redirect.
    def launch
      start && return if respond_to?(:start)
      redirect_to welcome_path({ lti_launch_params: params.to_unsafe_h })
    end

    def allow_iframe
      response.headers.delete("X-Frame-Options")
    end

    def no_access(reason=nil)
      logger.debug("no_access reason: #{ reason }") if reason
      respond_to?(:authentication_failure) && authentication_failure && return
      render({ file: CanvasLti.authentication_failure_path, status: :unauthorized })
      return true # this permits usage like: no_access and return ...
    end

    def check_login
      no_access("CanvasLtiApplicationController#check_login session[:lti_launch_valid] is false") && return unless session[:lti_launch_valid]
    end

    # The user application may implement a method such as the example authentication_failure, below,
    # to render the desired authorisation error page. If this method is not implemented, a static file will
    # be rendered using the name returned by the authentication_failure_path method.
    #
    # def authentication_failure
    #   respond_to do |format|
    #     format.html { render body: Rails.root.join('public/401.html').read }
    #   end
    # end

  end

  # add a launch route?
  # load config ( secret etc)
  # get params and validate LTI
  # put specifed LTI params into the session
  ## add config method to specify params to put into session
  ## only consider specified params as LTI params.
  ## add custom params to consider as LTI params.

  # supply action to be called as before action in controllers

end
