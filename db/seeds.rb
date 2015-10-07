# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
event = Event.create(
  :title=>"Dinner at Longrain CBD",
  :start_date=>"2015-09-18 19:00:00",
  :end_date=>"2015-09-18 22:00:00",
  :location=>"Melbourne, Victoria, Australia",
  :agenda=>"Dinner @ Longrain, Thai-Western Fusion style cooking.",
  :address=>"44 Little Bourke Street, Melbourne"
)