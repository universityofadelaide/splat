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

# Default applications Controller where everything every controller in this app needs go.
class ApplicationController < CanvasLti::CanvasLtiApplicationController

  protect_from_forgery({ with: :exception })
  skip_before_action :verify_authenticity_token, { only: [:launch] }
  before_action :init_assignment
  before_action :set_current_user

  REQUIRED_LAUNCH_PARAMS = %w[lis_person_sourcedid roles ext_lti_assignment_id resource_link_title context_label].freeze

  @@canvas_service = nil # rubocop:disable Style/ClassVars

  def lti_parameters(lti_params)
    _check_required_launch_params(lti_params)
    logger.debug("before session[:assignment_id]: #{ session[:assignment_id] } - lti_params[ext_lti_assignment_id]: #{ lti_params["ext_lti_assignment_id"] }")
    session[:user_id] = lti_params["lis_person_sourcedid"]
    session[:current_user] = session[:user_id]
    session[:roles] = lti_params["roles"]
    session[:assignment_id] = lti_params["ext_lti_assignment_id"] # canvas specific, but no other value suitable
    session[:assignment_title] = lti_params["resource_link_title"]
    session[:course_id] = lti_params["custom_canvas_course_id"]
    session[:canvas_assignment_id] = lti_params["custom_canvas_assignment_id"]
    session[:launch_presentation_document_target] = lti_params["launch_presentation_document_target"]
    logger.debug("after session[:assignment_id]: #{ session[:assignment_id] } - lti_params[ext_lti_assignment_id]: #{ lti_params["ext_lti_assignment_id"] }")
  end

  def set_current_user
    User.current_user_id = session[:current_user] if session[:current_user]
  end

  def bad_request
    render({ file: "public/400.html", status: :bad_request })
  end

  def init_assignment
    logger.debug("init_assignment called")
    @assignment = Assignment.find_by({ lms_id: session[:assignment_id] })
    @assignment_name = session[:assignment_title]
  end

  def canvas_service
    unless @@canvas_service
      services_config = YAML.load_file(Rails.root.join("config", "services.yml").to_s)
      @@canvas_service = CanvasService.new(services_config["canvas"], self) # rubocop:disable Style/ClassVars
    end
    return @@canvas_service
  end

  # By default exceptions from the RestClient are rendered using template files
  DEFAULT_RESTCLIENT_ERROR_CONFIG = {
    unauthorized: { action: "render", file: "public/401.html", status: :unauthorized },
    not_found:    { action: "render", file: "public/404.html", status: :not_found },
    exception:    { action: "render", file: "public/500.html", status: 500 }
  }.freeze

  # rest_client_action provides default handling of errors returned by methods of the RestClient class.
  # The default error config may be overridden but if this is done, the caller must provide the necessary keys for the render() method
  # for example:
  #   rest_client_action({ exception: { json: "An error occurred ..." }}) do; end
  # will render a JSON entity instead of a file for an exception
  def rest_client_action(error_config={})
    error_config.reverse_merge!(DEFAULT_RESTCLIENT_ERROR_CONFIG)
    yield
  rescue RestClient::Unauthorized => e
    _handle_rest_exception(error_config[:unauthorized], e)
  rescue RestClient::NotFound => e
    _handle_rest_exception(error_config[:not_found], e)
  rescue RestClient::Exception => e
    _handle_rest_exception(error_config[:exception], e)
  end

  private

  def _check_required_launch_params(lti_params)
    missing = []
    REQUIRED_LAUNCH_PARAMS.each do |parameter|
      missing << parameter unless lti_params[parameter]
    end
    return true if missing.blank?
    # if we get here there is missing params
    logger.error "LTI launch attempted with the following parameters missing: #{ missing }, Nothing good can come of this"
    bad_request && return
  end

  def _handle_rest_exception(error_config, exception)
    error_config.reverse_merge!({ status: exception.http_code }) # provide a status for render() if not provided by the caller
    logger.error(exception.inspect)
    render(error_config) if error_config[:action].nil? || error_config[:action] == "render"
  end

  # Returns true if the given group_category_id is the ID of one of the group categories of the
  # course, otherwise returns false.
  def _group_category_id_valid?(group_category_id)
    valid_group_category_ids = session[:group_categories]
    return valid_group_category_ids.include?(group_category_id)
  end

  # Returns true if the given group_id is the ID of one of the groups of one of the group
  # categories of the course, otherwise returns false.
  def _group_id_valid?(group_id)
    valid_group_ids = session[:groups].values.flatten
    return valid_group_ids.include?(group_id)
  end

end
