class Admin::BaseController < ApplicationController
  before_action :require_browser_session!
end
