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

# CanvasCourse offers all operations on Canvas course level
class CanvasCourse

  def self.get_assignments(course_id, canvas_service)
    assignments = canvas_service.get_assignments(course_id)
    assignments = assignments.map { |hash| hash.slice(:id, :name) }
    # Don't offer SPLAT assignments
    splat_assignments = splat_assignments_ids
    return assignments.reject { |hash| splat_assignments.include?(hash[:id].to_s) }
  end

  def self.get_students(course_id, canvas_service)
    return canvas_service.get_students(course_id)
  end

  def self.splat_assignments_ids
    splat_assignments = []
    Assignment.all.find_each do |assignment|
      splat_assignments << assignment.lms_assignment_id unless assignment.lms_assignment_id.nil?
    end
    return splat_assignments
  end

end
