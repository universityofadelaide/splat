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

RSpec.describe AssignmentGroup, { type: :model } do

  it "has a valid factory" do
    assignment_group = FactoryBot.create(:assignment_group)
    expect(assignment_group).to be_valid
  end

  it "fails validation if the same association already exists" do
    assignment_group = FactoryBot.create(:assignment_group)
    expect do
      FactoryBot.create(:assignment_group, {
                          assignment: assignment_group.assignment, group: assignment_group.group
                        })
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

end
