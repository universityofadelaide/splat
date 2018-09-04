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

RSpec.describe GroupUser, { type: :model } do

  it "has a valid factory" do
    group_user = FactoryBot.create(:group_user)
    expect(group_user).to be_valid
  end

  it "fails validation if the same association already exists" do
    group_user = FactoryBot.create(:group_user)
    expect do
      FactoryBot.create(:group_user, { group: group_user.group, user: group_user.user })
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
