require File.expand_path(File.dirname(__FILE__) + '/../spec_helper' )

describe "recipe.haml" do
  before(:each) do
    @title  = "Recipe Title"
    @summary = "Recipe Summary"
    @instructions = "Recipe Instructions"
    assigns[:recipe] = @recipe = {
      'id'           => '2009-06-02-recipe',
      'date'         => '2009-06-02',
      'title'        => @title,
      'summary'      => @summary,
      'instructions' => @instructions
    }

    assigns[:recipes_by_date] = [{ "key" => "2009-06-01",
                                   "value" => {
                                     'id'    => "2009-06-01-foo",
                                     'date'  => '2009-06-01',
                                     'title' => "Foo"
                                   } },
                                 { "key" => "2009-06-12",
                                   "value" => {
                                     'id'    => "2009-06-12-bar",
                                     'date'  => "2009-06-12",
                                     'title' => "Bar"}
                                 }]

    assigns[:url] = "http://example.org/recipe-1"

    stub!(:partial)
    stub!(:recipe_update_of)
    stub!(:recipe_updated_by)
    stub!(:alternate_preparations)
  end

  it "should display the recipe's title" do
    render("/views/recipe.haml")
    response.should have_selector("h1", :content => @title)
  end

  it "should display the recipe's summary" do
    self.stub!(:wiki).and_return("wiki #{@summary}")

    render("/views/recipe.haml")
    response.should have_selector("#summary",
                                  :content => "wiki #{@summary}")
  end

  it "should link to previous recipe" do
    render("/views/recipe.haml")
    response.should have_selector("a",
                                  :href => "/recipes/2009/06/01/foo",
                                  :content => "June  1, 2009")
  end

  it "should link to previous recipe title" do
    render("/views/recipe.haml")
    response.should have_selector("a",
                                  :href => "/recipes/2009/06/01/foo",
                                  :content => "Foo")
  end

  it "should display the recipe's instructions" do
    self.stub!(:wiki).and_return("wiki #{@instructions}")

    render("/views/recipe.haml")
    response.should have_selector("#instructions",
                                  :content => "wiki #{@instructions}")
  end

  it "should link to the feedback form" do
    render("/views/recipe.haml")
    response.should have_selector("a",
                                  :content => "Send us feedback on this recipe")
  end

  it "should include the recipe's URL in the feedback link" do
    render("/views/recipe.haml")
    response.should have_selector("a",
                                  :href => "/feedback?url=http%3A%2F%2Fexample.org%2Frecipe-1&subject=%5BRecipe%5D+Recipe+Title",
                                  :content => "Send us feedback on this recipe")
  end

  context "a recipe with no tools or appliances" do
    before(:each) do
      @recipe[:tools] = nil
    end

    it "should not render an ingredient preparations" do
      render("views/recipe.haml")
      response.should_not have_selector(".recipe-tools")
    end
  end

  context "a recipe with no ingredient preparations" do
    before(:each) do
      @recipe[:preparations] = nil
    end

    it "should not render an ingredient preparations" do
      render("views/recipe.haml")
      response.should_not have_selector(".preparations")
    end
  end

  context "a recipe with no categories" do
    before(:each) do
      @recipe[:tag_names] = nil
    end

    it "should not have any active categories" do
      render("views/recipe.haml")
      response.should_not have_selector("#categories a.active")
    end
  end

  context "a recipe with 1 egg" do
    before(:each) do
      @recipe['preparations'] =
        [ { 'quantity' => 1, 'ingredient' => { 'name' => 'egg' } } ]

      render("views/recipe.haml")
    end

    it "should render ingredient names" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .name", :content => 'egg')
      end
    end

    it "should render ingredient quantities" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .quantity", :content => '1')
      end
    end

    it "should not render a brand" do
      response.should_not have_selector(".ingredient > .brand")
    end
  end

  context "a recipe with 1 cup of all-purpose, unbleached flour" do
    before(:each) do
      @recipe['preparations'] = []
      @recipe['preparations'] << {
        'quantity' => 1,
        'unit'     => 'cup',
        'ingredient' => {
          'name' => 'flour',
          'kind' => 'all-purpose, unbleached'
        }
      }

      render("views/recipe.haml")
    end

    it "should include the measurement unit" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .unit", :content => 'cup')
      end
    end

    it "should include the specific kind of ingredient" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .kind",
                               :content => 'all-purpose, unbleached')
      end
    end

    it "should read conversationally, with the ingredient kind before the name" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .kind + .name",
                               :content => 'flour')
      end
    end
  end

  context "a recipe with 1 12 ounce bag of Nestle Tollhouse chocolate chips" do
    before(:each) do
      @recipe['preparations'] = []
      @recipe['preparations'] << {
        'quantity' => 1,
        'unit'     => '12 ounce bag',
        'brand'    => 'Nestle Tollhouse',
        'ingredient' => {
          'name' => 'chocolate chips'
        }
      }

      render("views/recipe.haml")
    end

    it "should include the ingredient brand" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .brand",
                               :content => 'Nestle Tollhouse')
      end
    end

    it "should note the brand parenthetically after the name" do
      response.should have_selector(".preparations") do |preparations|
        preparations.
          should have_selector(".ingredient > .name + .brand",
                               :content => '(Nestle Tollhouse)')
      end

    end
  end

  context "a recipe with another recipe on the ingredient list" do
    before(:each) do
      @recipe['preparations'] =
        [ { 'quantity' => 1,
            'ingredient' => {
              'name' => '[recipe:2009/09/18/recipe Recipe]'
            }
          } ]

      self.stub!(:wiki)
    end

    it "should wiki-fy the link to the other recipe" do
      self.should_receive(:wiki).
        with("[recipe:2009/09/18/recipe Recipe]", false).
        and_return(%Q|<a href="http://example.org/">Bar</a>|)

      render("views/recipe.haml")
    end
  end

  # TODO: this should not be necessary.  The blank brands are an
  # artifact of the import-from-rails process
  context "a recipe with a blank brand" do
    it "should not include brand information" do
      @recipe['preparations'] = []
      @recipe['preparations'] << {
        'quantity' => 1,
        'unit'     => '12 ounce bag',
        'brand'    => '',
        'ingredient' => {
          'name' => 'chocolate chips'
        }
      }

      render("views/recipe.haml")

      response.should_not have_selector(".ingredient > .brand")
    end
  end

  context "a recipe with an active and inactive preparation time" do
    before(:each) do
      @recipe['inactive_time'] = 30
      @recipe['prep_time']     = 45

      render("views/recipe.haml")
    end

    it "should include preparation time" do
      response.should contain(/Preparation Time:\s+45 minutes/)
    end

    it "should include inactive time" do
      response.should contain(/Inactive Time:\s+30 minutes/)
    end
  end

  context "a recipe with no inactive preparation time" do
    before(:each) do
      render("views/recipe.haml")
    end

    it "should not include inactive time" do
      response.should_not contain(/Inactive Time:/)
    end
  end

  context "a recipe with 300 minutes of inactive time" do
    before(:each) do
      @recipe['inactive_time'] = 300
      render("views/recipe.haml")
    end
    it "should display 5 hours of Inactive Time" do
      response.should contain(/Inactive Time:\s+5 hours/)
    end
  end

  context "a recipe requiring a colander and a pot" do
    before(:each) do
      colander = {
        'title' => "Colander",
        'asin'  => "ASIN-1234"
      }
      pot = {
        'title' => "Pot",
        'asin'  => "ASIN-5678"
      }

      @recipe['tools'] = [colander, pot]
      render("views/recipe.haml")
    end
    it "should contain a link to the colander on Amazon" do
      response.should have_selector("a", :content => "Colander",
                                    :href => "http://www.amazon.com/exec/obidos/ASIN/ASIN-1234/eeecooks-20")
    end
    it "should contain a link to the pot on Amazon" do
      response.should have_selector("a", :content => "Pot",
        :href => "http://www.amazon.com/exec/obidos/ASIN/ASIN-5678/eeecooks-20")
    end
  end

  context "a vegetarian recipe" do
    before(:each) do
      @recipe['tag_names'] = ['vegetarian']
      render("views/recipe.haml")
    end
    it "should highlight the vegetarian category at the top of the page" do
      response.should have_selector("a",
                                    :content => "Vegetarian",
                                    :class   => "active")
    end
  end

  context "a vegetarian, italian recipe" do
    before(:each) do
      @recipe['tag_names'] = ['vegetarian', 'italian']
      render("views/recipe.haml")
    end
    it "should highlight the vegetarian category at the top of the page" do
      response.should have_selector("a",
                                    :content => "Vegetarian",
                                    :class   => "active")
    end
    it "should highlight the italian category at the top of the page" do
      response.should have_selector("a",
                                    :content => "Italian",
                                    :class   => "active")
    end
  end

  context "a recipe with an image" do
    it "should include an image in the recipe summary" do
      self.stub!(:image_link).and_return("<img/>")
      render("views/recipe.haml")
      response.should have_selector("#summary > img")
    end

  end

  context "a recipe without an image" do
    it "should not include an image" do
      self.stub!(:image_link).and_return(nil)
      render("views/recipe.haml")
      response.should_not have_selector("#summary > img")
    end
  end
end
