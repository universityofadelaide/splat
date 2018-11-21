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

# model which represents a group category of the LMS
class LmsGroupCategory

  def initialize(lms_group_category_id, canvas_service)
    @lms_group_category_id = lms_group_category_id
    @canvas_service = canvas_service
  end

  def import_data
    data = {}
    group_category = @canvas_service.get_group_category(@lms_group_category_id)
    groups = @canvas_service.get_groups(@lms_group_category_id)
    groups.each do |group_hash|
      users = @canvas_service.get_users(group_hash[:id])
      next if users.blank?

      group = Group.new({ lms_id: group_hash[:id], group_set_name: group_category[:name], name: group_hash[:name] })
      data[group] = []
      users.each do |member_hash|
        last_name, first_name = member_hash[:sortable_name].strip.split(/\s*,\s*/, 2)
        member = User.new({ lms_id: member_hash[:sis_user_id], login_id: member_hash[:login_id], last_name: last_name, first_name: first_name })
        data[group] << member
      end
    end
    raise(GroupsLtiImporterPersistError, "All groups are empty") if data.empty?

    return data
  end

end
