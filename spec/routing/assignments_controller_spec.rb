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

RSpec.describe AssignmentsController, { type: :routing } do
  describe "routing" do

    it "routes to #launch from the legacy launch url" do
      expect({ post: "/assignments/lti_launch" }).to route_to("assignments#launch")
    end

    it "routes to #launch given an empty path" do
      expect({ get: "/welcome" }).to route_to("assignments#start")
    end

    it "routes to #start from the welcome url" do
      expect({ get: "/welcome" }).to route_to("assignments#start")
    end

    it "routes to #update when posting to assignment instructions" do
      expect({ post: "/assignments/instruction" }).to route_to("assignments#instruction")
    end

  end
end
