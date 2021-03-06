require 'rails_helper'

RSpec.describe "events/new", type: :view do
  before(:each) do
    assign(:event, Event.new(
      :title => "MyString",
      :location => "MyString",
      :agenda => "MyText",
      :address => "MyText"
    ))
  end

  it "renders new event form" do
    render

    assert_select "form[action=?][method=?]", events_path, "post" do

      assert_select "input#event_title[name=?]", "event[title]"

      assert_select "input#event_location[name=?]", "event[location]"

      assert_select "textarea#event_agenda[name=?]", "event[agenda]"

      assert_select "textarea#event_address[name=?]", "event[address]"
    end
  end
end
