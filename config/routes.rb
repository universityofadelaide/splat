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

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post "/", to: "assignments#launch"
  get "/welcome", to: "assignments#start"

  resources :assignments, only: %i[lti_launch export instruction nonmember calculator] do
    collection do
      post  :lti_launch, to: "assignments#launch"
      get   :show
      post  :set_groups
      get   :export, to: "assignments#export_csv"
      get   :instruction, to: "assignments#instruction"
      post  :instruction, to: "assignments#instruction"
      get   :nonmember, to: "assignments#nonmember"
      get   :preview, to: "assignments#preview"
      get   :moderation, to: "assignments#inline_moderation_data"
      put   :gradebook_integration
    end
  end

  resources :responses, only: %i[new create show score] do
    collection do
      put    :score
      delete :delete
    end
  end

  resources :notifications, only: %i[create_conversation] do
    collection do
      post :create_conversation, to: "notifications#create_conversation"
      get :search_students, to: "notifications#search_students"
    end
  end

  resources :group_categories, only: %i[index show]

  resources :groups, only: %i[show]

  get "/probe" => "probe#index"
end
