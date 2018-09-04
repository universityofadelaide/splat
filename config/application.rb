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

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# app wide module
module SplatApi

  # All the configuration for the Rails app globally goes here. This includes middlewares you might want to inject.
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # semantic logging config, look at http://rocketjob.github.io/semantic_logger/rails.html for details
    SemanticLogger.add_appender({ file_name: "log/#{ Rails.env }.json", formatter: :json })

    SemanticLogger.backtrace_level = :info
    config.log_tags = {
      request_id: :request_id,
      ip:         :remote_ip,
      user:       ->(request) { request.cookie_jar["login"] }
    }

    require "canvas_lti"
    CanvasLti.config(
      { credentials:              { Rails.application.secrets.lti_consumer_key => Rails.application.secrets.lti_secret },
        session_parameters:       %w[user_id roles],
        unauthorized_access_path: "public/401" }
    )

    Rails.configuration.x.app = YAML.load_file(Rails.root.join("config", "app.yml").to_s)

  end

end
