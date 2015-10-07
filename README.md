About Caching

Testing on the Rails 4.2.3 and Ruby 2.2.1, using Dalli gem and memcached for cache store.

Fragment Caching

Fragment Caching allows a fragment of view logic to be wrapped in a cache block and served out of the cache store when the next request comes in.

From the Rails guild for caching, for example, If we wanna show all the events placed on the website in real time and didn't want to cache that part of the page, but did want to cache the part of the page which lists all events available, we could do this:

    <% cache cache_key_for_events do %>
        <% @events.each do |event| %>
          <tr>
                <td><%= event.title %></td>
                <td><%= event.start_date %></td>

    def cache_key_for_events
      count = Event.count
      max_updated_at = Event.maximum(:updated_at).try(:utc).try(:to_s, :number)
      "events/all-#{count}-#{max_updated_at}"
    end
It does 2 simple DB call Event.count and Event.maximum(:updated_at) to avoid doing a much more expensive call Event.all:

Started GET "/events" for ::1 at 2015-10-06 11:52:32 +1100
Processing by EventsController#index as HTML
   (0.2ms)  SELECT COUNT(*) FROM "events"
   (0.1ms)  SELECT MAX("events"."updated_at") FROM "events"
  Cache digest for app/views/events/index.html.erb: ca56ea987eb8ca17dd4852b8a2060d3d
Cache read: views/events/all-3-20151005093155/ca56ea987eb8ca17dd4852b8a2060d3d
Read fragment views/events/all-3-20151005093155/ca56ea987eb8ca17dd4852b8a2060d3d (4.2ms)
We can also nests the multiple fragments, if just a single event is updated, other events would still not be effected and we can still pull them from the cache. <% cache event do %> <%= event.title %>

With eager load

But what if we have to do eager loader, we have to do this expensive call because the first cache read for the collection missed. In Rails, this is typically done using includes. If a Event has many Attendees:

    <% cache @cache_key_for_events do %>
      <% @events.each do |event| %>
        <tr>
          <% cache event do %>
            <td><%= event.title %></td>
            <td><%= event.start_date %></td>
            <td><%= event.end_date %></td>
            <td><%= event.location %></td>
            <td>
                <% event.users.each do |user| %>
                <%= user.name %>,
                <% end %>
            </td>
The first time, it will use the inner join to do the expensive query:

    Started GET "/events" for ::1 at 2015-10-06 18:13:51 +1100
    ActiveRecord::SchemaMigration Load (0.6ms)  SELECT "schema_migrations".* FROM "schema_migrations"
    Processing by EventsController#index as HTML
       (0.6ms)  SELECT COUNT(*) FROM "events"
       (0.2ms)  SELECT MAX("events"."updated_at") FROM "events"
    Cache digest for app/views/events/index.html.erb: a6fc9d29103a0b152fe44d7a7fe3a68e
    Cache read: views/events/all-8-20151006042329/a6fc9d29103a0b152fe44d7a7fe3a68e
    Dalli::Server#connect 127.0.0.1:11211
    Read fragment views/events/all-8-20151006042329/a6fc9d29103a0b152fe44d7a7fe3a68e (3.3ms)
      SQL (0.7ms)  SELECT "events"."id" AS t0_r0, "events"."title" AS t0_r1, "events"."start_date" AS t0_r2, "events"."end_date" AS t0_r3, "events"."location" AS t0_r4, "events"."agenda" AS t0_r5, "events"."address" AS t0_r6, "events"."created_at" AS t0_r7, "events"."updated_at" AS t0_r8, "users"."id" AS t1_r0, "users"."name" AS t1_r1, "users"."event_id" AS t1_r2, "users"."created_at" AS t1_r3, "users"."updated_at" AS t1_r4 FROM "events" INNER JOIN "users" ON "users"."event_id" = "events"."id"
      Cache digest for app/views/events/index.html.erb: a6fc9d29103a0b152fe44d7a7fe3a68e
    Cache read: views/events/1-20151006033600344917000/a6fc9d29103a0b152fe44d7a7fe3a68e
    Read fragment views/events/1-20151006033600344917000/a6fc9d29103a0b152fe44d7a7fe3a68e (1.2ms)
    Cache write: views/events/1-20151006033600344917000/a6fc9d29103a0b152fe44d7a7fe3a68e
But then it will check the cache first, if there's no update, it will just get the fragment from the cache without query:

    Started GET "/events" for ::1 at 2015-10-06 18:14:12 +1100
    Processing by EventsController#index as HTML
   (0.2ms)  SELECT COUNT(*) FROM "events"
   (0.2ms)  SELECT MAX("events"."updated_at") FROM "events"
   Cache digest for app/views/events/index.html.erb: a6fc9d29103a0b152fe44d7a7fe3a68e
   Cache read: views/events/all-8-20151006042329/a6fc9d29103a0b152fe44d7a7fe3a68e
   Read fragment views/events/all-8-20151006042329/a6fc9d29103a0b152fe44d7a7fe3a68e (2.4ms)
   Rendered events/index.html.erb within layouts/application (7.3ms)
   Completed 200 OK in 207ms (Views: 205.3ms | ActiveRecord: 0.4ms)
We can also use the touch: method if we want the parent element expire when its associated child is updated. With touch set to true, in this case, any action which changes updated_at for a attendee/user record will also change it for the associated event, thereby expiring the cache. From the bottom to the top, the single event that has been touched and also cache for all events will be updated:

    Cache read: views/events/1-20151006074846596169000/a6fc9d29103a0b152fe44d7a7fe3a68e
    Read fragment views/events/1-20151006074846596169000/a6fc9d29103a0b152fe44d7a7fe3a68e (1.5ms)
    Cache write: views/events/1-20151006074846596169000/a6fc9d29103a0b152fe44d7a7fe3a68e
    Write fragment views/events/1-20151006074846596169000/a6fc9d29103a0b152fe44d7a7fe3a68e (1.6ms)
      Cache digest for app/views/events/index.html.erb: a6fc9d29103a0b152fe44d7a7fe3a68e

    Cache read: views/events/2-20151005092449106634000/a6fc9d29103a0b152fe44d7a7fe3a68e
    Read fragment views/events/2-20151005092449106634000/a6fc9d29103a0b152fe44d7a7fe3a68e (1.7ms)
      Cache digest for app/views/events/index.html.erb: a6fc9d29103a0b152fe44d7a7fe3a68e
    Cache read: views/events/3-20151005093155609052000/a6fc9d29103a0b152fe44d7a7fe3a68e
    Read fragment views/events/3-20151005093155609052000/a6fc9d29103a0b152fe44d7a7fe3a68e (1.6ms)

    Cache write: views/events/all-8-20151006074846/a6fc9d29103a0b152fe44d7a7fe3a68e
    Write fragment views/events/all-8-20151006074846/a6fc9d29103a0b152fe44d7a7fe3a68e (2.1ms)
Conditional get:

We can also use the 304(Not Modified) response to let browsers to pull from the client cache:

It's still based on the updated_at and we can just use the fresh_when helper to render:

      def show
        fresh_when last_modified: @event.updated_at, etag: @event
      end

    Started GET "/events/3" for ::1 at 2015-10-06 14:34:24 +1100
    Processing by EventsController#show as HTML
      Parameters: {"id"=>"3"}
      Event Load (0.1ms)  SELECT  "events".* FROM "events" WHERE "events"."id" = ? LIMIT 1  [["id", 3]]
      Cache digest for app/views/events/show.html.erb: 62ec1adf0505f487dd47308f8da14b41
    Completed 304 Not Modified in 5ms (ActiveRecord: 0.1ms)
    
But there's a problem: if user logs in after that and goes back to click the show, it will also trigger 304 and
the page will be the same without changing user's status. But we can add the current_user.id into the etag: 
	
	fresh_when last_modified: @event.updated_at, etag: [@event, current_user.try(:id)]
	
Or cleaner way: 

	class EventsController < ApplicationController
  		etag { current_user.try(:id) }
  	    ...
        def show
    	  fresh_when(@event)
        end
	
