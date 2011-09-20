require 'spec_helper'

describe PagesController do
  render_views  # This is to get the controller spec to make the views happen
                # so that the title in the views is available to the testing suite.
                
before(:each) do
  @base_title = "Ruby on Rails Tutorial Sample App"
end


  describe "GET 'home'" do
    it "should be successful" do
      get 'home'
      response.should be_success
    end
    
    it  "should have the right title" do
      get 'home'
      response.should have_selector("title",    # used to be called "have_tag"
                            :content => "#{@base_title} | Home")
    end
    it "should have a non-blank body"  do
      get 'home'
      response.body.should_not =~ /<body>\s*<\/body>/
    end
  end

  describe "GET 'contact'" do
    it "should be successful" do
      get 'contact'
      response.should be_success
    end
    it  "should have the right title" do
      get 'contact'
      response.should have_selector("title", 
                            :content => "#{@base_title} | Contact")
    end
  end

  describe "GET 'about'" do
    it "should be successful" do
      get 'about'
      response.should be_success
    end
    it  "should have the right title" do
      get 'about'
      response.should have_selector("title", 
                            :content => "#{@base_title} | About")
    end
  end

  describe "GET 'help'" do
    it "should be successful" do
      get 'help'
      response.should be_success
    end
    it  "should have the right title" do
      get 'help'
      response.should have_selector("title", 
                            :content => "#{@base_title} | Help")
    end
  end

end
