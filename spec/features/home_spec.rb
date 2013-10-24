# coding: utf-8
require 'spec_helper'

feature HomeController do
  background do
    visit root_path
  end

  scenario "Show top page" do
    page.should have_content 'Home#index'
    page.should have_content 'Find me in app/views/home/index.html.slim'
  end
end