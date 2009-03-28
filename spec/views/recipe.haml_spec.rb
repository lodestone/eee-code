require File.expand_path(File.dirname(__FILE__) + '/../spec_helper' )

describe "recipe.haml" do
  before(:each) do
    @title  = "Recipe Title"
    @recipe = {
      'title' => @title,
      'preparations' => [
        { 'quantity' => 1, 'ingredient' => { 'name' => 'egg' } }
      ]

    }

    assigns[:recipe] = @recipe
  end

  it "should display the recipe's title" do
    render("/views/recipe.haml")
    response.should have_selector("h1", :content => @title)
  end

  it "should render ingredient preparations" do
    render("views/recipe.haml")
    response.should have_selector(".preparations") do |preparations|
      prepartions.should have_selector(".ingredient .name", :content => 'egg')
    end
  end
end