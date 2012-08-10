require 'spec_helper'

describe StorybooksController do
  let!(:user) { Factory(:user) }
  
  context "authenticated user" do
    it "is authenticated" do
      user.authenticate("supersecret").should == user
      #this works
    end
  end
  
  describe 'GET #index' do
    it "populates an array of storybooks" do
      user.authenticate "supersecret"
      #user.should be signed in?
      storybook = Factory.create(:storybook)
      get :index, :format => :json
      #assigns(:storybooks).should eq [storybook]
      response.body.should have_content storybook.to_json
      #puts "story book #{storybook}"
      #response.body.should  have_conten storybook
    end
    
    it "renders the :index view" do
      user.authenticate "password"
      get :index, :format => :json
      response.should render_template :index
    end
  end
  
  describe 'GET #show' do
    it "assigns the requested storybook to @storybook" do
      storybook = Factory.create(:storybook).attributes
      get :show, id: storybook 
      assigns(:storybook).should eq storybook
    end
    it "renders the :show json" do 
      storybook = Factory.create(:storybook).attributes
      get :show, id: storybook, :format => :json
      puts "show response #{response.body}"
      response.body.should eq storybook
    end
  end
end