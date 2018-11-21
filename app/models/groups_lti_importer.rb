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

# Persists the Group and Member data
class GroupsLtiImporter

  def initialize(assignment, data, app_user)
    @assignment = assignment
    @data = data
    @app_user = app_user
  end

  def import
    ActiveRecord::Base.transaction do
      @data.each do |group, members|
        group.assign_attributes({ created_by: @app_user, updated_by: @app_user })
        group.save
        @assignment.groups << group
        members.each do |member|
          member_found = User.find_by({ lms_id: member[:lms_id] })
          if member_found
            member_found.assign_attributes({ first_name: member[:first_name], last_name: member[:last_name] })
            if member_found.changed?
              member_found.assign_attributes({ updated_by: @app_user })
              member_found.save
            end
            member = member_found
          else
            member.assign_attributes({ created_by: @app_user, updated_by: @app_user })
            member.save
          end
          member.groups << group
          @assignment.users << member
        end
      end
    rescue StandardError
      raise(GroupsLtiImporterPersistError, "An error occurred importing the Groups and Users")
    end
  end

end
