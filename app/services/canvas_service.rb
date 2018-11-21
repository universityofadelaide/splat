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

require "rest_client"
require "json"

# CanvasService handles the communication with Canvas API.
# All methods return JSON as returned from Canvas API.
class CanvasService

  DEFAULT_MAX_RETRIES = 3
  DEFAULT_PER_PAGE_COUNT = 1000

  def initialize(app_config, controller)
    @base_url = app_config["base_url"].freeze
    @api_prefix = app_config["api_prefix"].freeze
    @token = app_config["token"].freeze
    @controller = controller
  end

  # Send email notification to the supplied recipients
  # Uses POST /api/v1/conversations API
  def create_conversation(recipients, subject, body, group_conversation, as_user_id)
    params = {
      method:  :post,
      url:     "#{ base_url }#{ api_prefix }conversations",
      payload: { recipients: recipients, subject: subject, body: body, group_conversation: group_conversation, as_user_id: "sis_user_id:" + as_user_id }
    }
    return _make_call(params)
  end

  # Send email notification to the supplied recipients
  # Uses POST /api/v1/conversations API
  def create_custom_gradebook_column(course_id, column_name)
    params = {
      method:  :post,
      url:     "#{ base_url }#{ api_prefix }courses/#{ course_id }/custom_gradebook_columns",
      payload: { "column[title]" => column_name, "column[position]" => 1, "column[hidden]" => false, "column[teacher_notes]" => false, "column[read_only]" => true }
    }
    return _make_call(params)
  end

  def get_assignments(course_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignments"
    }
    return _make_paginated_call(params)
  end

  def get_assignment(course_id, assignment_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignments/#{ assignment_id }"
    }
    return _make_call(params)
  end

  def update_assignment(course_id, assignment_id, fields)
    params = {
      method:  :put,
      url:     "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignments/#{ assignment_id }",
      payload: _transform_params_for_assignment(fields)
    }
    return _make_call(params)
  end

  def get_course(course_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }"
    }
    return _make_call(params)
  end

  # Get custom gradebook columns
  def get_gradebook_columns(course_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/custom_gradebook_columns"
    }
    return _make_paginated_call(params)
  end

  # List groups in a supplied group category
  def get_grades(course_id, assignment_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignment/#{ assignment_id }/grades" # TODO: work out get_grades
    }
    return _make_paginated_call(params)
  end

  def get_grading_standard_account(standard_id, account_id=1)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }accounts/#{ account_id }/grading_standards/#{ standard_id }"
    }
    return _make_call(params)
  end

  def get_grading_standard_course(standard_id, course_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/grading_standards/#{ standard_id }"
    }
    return _make_call(params)
  end

  # List group categories in a supplied course
  def get_group_categories(course_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }courses/#{ course_id }/group_categories"
    }
    return _make_paginated_call(params)
  end

  def get_group_category(group_category_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }group_categories/#{ group_category_id }"
    }
    return _make_call(params)
  end

  # List groups in a supplied group category
  def get_groups(group_category_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }group_categories/#{ group_category_id }/groups"
    }
    return _make_paginated_call(params)
  end

  def get_students(course_id)
    params = {
      method:  :get,
      url:     "#{ base_url }#{ api_prefix }courses/#{ course_id }/users",
      payload: { enrolment_type: ["student"] }
    }
    return _make_paginated_call(params)
  end

  # https://canvas.instructure.com/doc/api/submissions.html#method.submissions_api.index
  # GET /api/v1/courses/:course_id/assignments/:assignment_id/submissions
  def get_submissions_for_assignment(course_id, assignment_id)
    params = {
      method:  :get,
      url:     "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignments/#{ assignment_id }/submissions",
      payload: { include: ["user"] }
    }
    result = _make_paginated_call(params)
    result.each do |r|
      r[:sis_user_id] = r[:user][:sis_user_id]
    end
    return result
  end

  # List users in a supplied group
  def get_users(group_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }groups/#{ group_id }/users"
    }
    return _make_paginated_call(params)
  end

  # update the grades for the given assignment with the given grades
  # POST /api/v1/courses/:course_id/assignments/:assignment_id/submissions/update_grades
  # grades is a hash: { student_id: lms-id, grade: string }
  def update_grades(course_id, assignment_id, grade_data)
    params = {
      method:  :post,
      url:     "#{ base_url }#{ api_prefix }courses/#{ course_id }/assignments/#{ assignment_id }/submissions/update_grades",
      payload: _transform_grade_data_for_canvas(grade_data)
    }
    return _make_call(params)
  end

  # List users in a supplied group
  # Uses GET /api/v1/users/:id API
  def canvas_user_by_sis_user_id(sis_user_id)
    params = {
      method: :get,
      url:    "#{ base_url }#{ api_prefix }users/sis_user_id:#{ sis_user_id }"
    }
    return _make_call(params)
  end

  private

  attr_reader :base_url, :api_prefix, :token, :canvas_auth_url, :canvas_username, :canvas_password, :cookies

  # Handles a paginated call
  def _make_paginated_call(params)
    responses = []
    loop.with_index(1) do |_, page|
      response = _make_request(_add_authentication(_add_pagination_parameters(params, page)))
      responses += _response_body_json(response)
      break unless response.headers[:link].include?("rel=\"next\"")
    end
    return responses
  end

  def _make_call(params)
    return _response_body_json(_make_request(_add_authentication(params)))
  end

  def _response_body_json(response)
    body = response.body
    return JSON.parse(body, { symbolize_names: true }) unless body.empty?

    return {}
  end

  def _make_request(params, max_retries=DEFAULT_MAX_RETRIES)
    max_retries.times do
      return RestClient::Request.execute(params)
    rescue RestClient::ExceptionWithResponse => e
      @controller.helpers.log_error(Logger::ERROR, e)
      raise e if e.instance_of?(RestClient::NotFound)
    end
    return RestClient::Request.execute(params)
  end

  # Adds credentials
  def _add_authentication(params)
    params[:headers] = {} unless params.key?(:headers)
    params[:headers][:params] = {} unless params[:headers].key?(:params)
    params[:headers][:params][:access_token] = token
    params[:headers][:Authorization] = "Bearer #{ token }"
    return params
  end

  # Adds pagination parameters
  def _add_pagination_parameters(params, page)
    params[:headers] = {} unless params.key?(:headers)
    params[:headers][:params] = {} unless params[:headers].key?(:params)
    params[:headers][:params][:page] = page
    params[:headers][:params][:per_page] = DEFAULT_PER_PAGE_COUNT
    return params
  end

  # input: [{student_id:3, grade: 88},{student_id:4, grade: 77}]
  # output { "grade_data[3][posted_grade]": 88], "grade_data[4][posted_grade]": 95}
  # when form encoded, the output has the form:
  # "grade_data[3][posted_grade]=88&grade_data[4][posted_grade]=95"
  # as required by canvas (https://canvas.instructure.com/doc/api/submissions.html#method.submissions_api.update)
  def _transform_grade_data_for_canvas(grade_data)
    hash = {}
    grade_data.each do |item|
      hash["grade_data[#{ item[:student_id] }][posted_grade]"] = item[:grade].to_s
    end
    return hash
  end

  def _transform_params_for_assignment(params)
    hash = {}
    params.each do |key, value|
      hash["assignment[#{ key }]"] = value
    end
    return hash
  end

end
