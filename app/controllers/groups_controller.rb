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

# GroupsController
class GroupsController < ApplicationController

  def show
    group_id = params[:id]
    if !_group_id_valid?(group_id)
      respond_to do |format|
        format.json { render({ json: "Invalid group '#{ group_id }' for course #{ session[:course_id] }", status: :internal_server_error }) }
      end
      logger.error("Invalid group '#{ group_id }' for course #{ session[:course_id] }. Groups: #{ session[:groups].flatten.inspect }")
      return
    end
    rest_client_action(
      {
        not_found:    { json: "Group member data could not be found." },
        unauthorized: { json: "An authorisation error occurred when collecting data." },
        exception:    { json: "An error occurred getting group members.", status: 500 }
      }
    ) do
      @members = canvas_service.get_users(group_id)
      respond_to do |format|
        format.json { render({ json: @members }) }
      end
    end
  rescue StandardError => e
    logger.error(e.inspect)
    flash[:danger] = "An error occurred when collecting group members"
  end

end
