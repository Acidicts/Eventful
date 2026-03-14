class HomeController < ApplicationController
  def index
    if current_user
      render :index
    else
      render :unregistered
    end
  end

  def events
    @events = Event.where.not(finished: true).order(applied: :desc)
    render :events
  end
end
