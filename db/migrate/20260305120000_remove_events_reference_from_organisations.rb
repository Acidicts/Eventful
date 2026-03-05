class RemoveEventsReferenceFromOrganisations < ActiveRecord::Migration[8.1]
  def change
    # previously we stored a foreign key to `events` on the organisations
    # table.  that column was added by an earlier migration, but the
    # application actually expresses the relationship in the opposite
    # direction (`Event belongs_to :organisation` and
    # `Organisation has_many :events`).  keeping the extraneous
    # `events_id` column only served to force a non-null constraint and
    # circular foreign key dependency, which in turn made it impossible to
    # create an organisation without also creating a throwaway event.  the
    # column is no longer used anywhere in the code, so we drop it entirely.

    remove_reference :organisations, :events, foreign_key: true
  end
end
