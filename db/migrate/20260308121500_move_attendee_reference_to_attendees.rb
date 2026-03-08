class MoveAttendeeReferenceToAttendees < ActiveRecord::Migration[8.1]
  def up
    # add new foreign key on attendees
    add_reference :attendees, :event, foreign_key: true

    # migrate existing associations: for each event that points to an attendee,
    # update that attendee to belong to the event
    say_with_time "migrating attendee event relationships" do
      Event.reset_column_information
      Attendee.reset_column_information

      Event.where.not(attendee_id: nil).find_each do |event|
        attendee = Attendee.find_by(id: event.attendee_id)
        next unless attendee

        attendee.update!(event_id: event.id)
      end
    end

    # remove column from events
    remove_reference :events, :attendee, foreign_key: true
  end

  def down
    # restore attendee_id column on events
    add_reference :events, :attendee, foreign_key: true

    say_with_time "reverting attendee event relationships" do
      Event.reset_column_information
      Attendee.reset_column_information

      Attendee.where.not(event_id: nil).find_each do |attendee|
        Event.where(id: attendee.event_id).update_all(attendee_id: attendee.id)
      end
    end

    remove_reference :attendees, :event, foreign_key: true
  end
end
