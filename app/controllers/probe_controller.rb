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

# controller for displaying probe page for Load balancer.
class ProbeController < ActionController::Base

  def index
    public = "public"
    render({ plain: "#{ Rails.application.class.parent.name } can not connect to database", status: 500 }) && return unless Question.first
    render({ plain: "#{ Rails.application.class.parent.name } server not in pool",          status: 404 }) && return unless File.exist?(Rails.root.join(public, "probe.txt"))
    render({ plain: "#{ Rails.application.class.parent.name } is operational" })
  end

end
