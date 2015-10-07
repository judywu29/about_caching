class Event < ActiveRecord::Base
  has_and_belongs_to_many :organizers, class_name: "User"
end
