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

RSpec.describe LmsGroupCategory, { type: :model } do

  before(:example) do
    @mock_canvas_service = double
  end

  describe "get_import_data" do

    it "returns a hash" do
      allow(@mock_canvas_service).to(receive(:get_group_category).and_return({ name: "groupset" }))
      allow(@mock_canvas_service).to(receive(:get_groups).and_return([{ id: 1, name: "group1" }]))
      allow(@mock_canvas_service).to(receive(:get_users).and_return([{ sortable_name: "Doe, John", sis_user_id: "123" }]))
      lms_group_category_id = nil
      lms_group_category = LmsGroupCategory.new(lms_group_category_id, @mock_canvas_service)
      result = lms_group_category.import_data
      expect(result).to be_a Hash
    end

    it "returns a correct hash" do
      allow(@mock_canvas_service).to(receive(:get_group_category).and_return({ name: "group category name" }))
      allow(@mock_canvas_service).to(receive(:get_groups).and_return([{ id: 1, name: "group1" }, { id: 2, name: "group2" }]))
      allow(@mock_canvas_service).to(receive(:get_users).and_return([{ sortable_name: "Doe, John", sis_user_id: "123" }]))
      lms_group_category_id = "1234"
      lms_group_category = LmsGroupCategory.new(lms_group_category_id, @mock_canvas_service)
      result = lms_group_category.import_data
      expect(result.size).to eql(2)
    end

    it "raises exception if all groups are empty" do
      allow(@mock_canvas_service).to(receive(:get_group_category).and_return({ name: "group category name" }))
      allow(@mock_canvas_service).to(receive(:get_groups).and_return([{ id: 1, name: "group1" }]))
      allow(@mock_canvas_service).to(receive(:get_users).and_return([]))
      lms_group_category_id = "1234"
      lms_group_category = LmsGroupCategory.new(lms_group_category_id, @mock_canvas_service)
      expect { lms_group_category.import_data } .to raise_error(GroupsLtiImporterPersistError)
    end

    it "doesn't return empty groups" do
      allow(@mock_canvas_service).to(receive(:get_group_category).and_return({ name: "group category name" }))
      allow(@mock_canvas_service).to(receive(:get_groups).and_return([{ id: 1, name: "group1" }, { id: 2, name: "group2" }]))
      allow(@mock_canvas_service).to(receive(:get_users).and_return([{ sortable_name: "Doe, John", sis_user_id: "123" }], []))
      lms_group_category_id = "1234"
      lms_group_category = LmsGroupCategory.new(lms_group_category_id, @mock_canvas_service)
      result = lms_group_category.import_data
      expect(result.size).to eql(1)
    end

  end

end
