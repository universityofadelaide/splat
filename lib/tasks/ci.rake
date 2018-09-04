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

desc "Continuous integration (linting and tests)"
task :ci do
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
  print "** " # Rubocop announces itself...
  Rake::Task["rubocop"].execute
  puts "** Running tests..."
  Rake::Task["spec"].execute
end

desc "Continuous integration (tests)"
task :ci_spec do
  puts "** Running tests..."
  Rake::Task["spec"].execute
end
