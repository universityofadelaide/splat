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

# GroupCategoriesController
class GroupCategoriesController < ApplicationController

  def index
    rest_client_action do
      @group_categories = canvas_service.get_group_categories(session[:course_id]) || []
      session[:group_categories] = @group_categories.map { |gc| gc[:id].to_s }
      session[:groups] = {}
    end
  rescue StandardError => e
    logger.error(e.inspect)
    flash[:danger] = "An application error occurred displaying group categories for the assignment."
  end

  def show
    group_category_id = params[:id]
    if !_group_category_id_valid?(group_category_id)
      respond_to do |format|
        format.json { render({ json: "Invalid group category for course #{ session[:course_id] }", status: :internal_server_error }) }
      end
      logger.error("Invalid group category for course #{ session[:course_id] }")
      return
    end
    rest_client_action(
      {
        not_found:    { json: "Data could not be found." },
        unauthorized: { json: "An authorisation error occurred when collecting data." },
        exception:    { json: "An error occurred getting group category groups.", status: 500 }
      }
    ) do
      @groups = canvas_service.get_groups(group_category_id)
      session[:groups][group_category_id] = @groups.map { |g| g[:id].to_s }
      logger.debug("Found groups: #{ session[:groups][group_category_id].inspect }")
      respond_to do |format|
        format.json { render({ json: @groups }) }
      end
    end
  rescue StandardError => e
    logger.error(e.inspect)
    flash[:danger] = "An error occurred when collecting group categories"
  end

end
