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

RSpec.describe GroupsLtiImporter, { type: :model } do

  describe "import" do

    it "imports the correct number of groups - one group" do
      group = FactoryBot.build(:group)
      users = []
      3.times do
        users << FactoryBot.build(:user)
      end
      data = {}
      data[group] = users
      assignment = FactoryBot.create(:assignment)
      app_user = "app user"
      groups_lti_importer = GroupsLtiImporter.new(assignment, data, app_user)
      groups_lti_importer.import
      saved_assignment = Assignment.find(assignment.id)
      expect(saved_assignment.groups.size).to eql(1)
      expect(saved_assignment.groups.first.name).to eql(group.name)
      expect(saved_assignment.groups.first.users.size).to eql(3)
    end

    it "imports the correct number of groups - three groups" do
      data = {}
      3.times do
        group = FactoryBot.build(:group)
        users = []
        4.times do
          users << FactoryBot.build(:user)
        end
        data[group] = users
      end
      assignment = FactoryBot.create(:assignment)
      app_user = "app user"
      groups_lti_importer = GroupsLtiImporter.new(assignment, data, app_user)
      groups_lti_importer.import
      saved_assignment = Assignment.find(assignment.id)
      expect(saved_assignment.groups.size).to eql(3)
      expect(saved_assignment.groups.first.users.size).to eql(4)
      expect(saved_assignment.groups.map { |g| g.users.size }).to eql([4, 4, 4])
    end

    it "updates existing users" do
      data = {}
      saved_user = FactoryBot.create(:user, { first_name: "original name" })
      group = FactoryBot.build(:group)
      assignment = FactoryBot.create(:assignment)
      app_user = "app user"
      groups_lti_importer = GroupsLtiImporter.new(assignment, data, app_user)
      user = saved_user.dup
      data[group] = [user]
      expect(user.id).to be_nil
      user.first_name = "new name"
      user_count_before = User.all.size
      groups_lti_importer.import
      user = User.find(saved_user.id)
      expect(user.first_name).to eql("new name")
      expect(User.all.size).to eql(user_count_before)
    end

    it "transaction fails if user is already linked to assignment" do
      user = FactoryBot.build(:user)
      data = {}
      2.times do
        group = FactoryBot.build(:group)
        users = [user]
        data[group] = users
      end
      assignment = FactoryBot.create(:assignment)
      app_user = "app user"
      GroupsLtiImporter.new(assignment, data, app_user)
      expect(assignment.users.size).to eql(0)
    end

  end

end
