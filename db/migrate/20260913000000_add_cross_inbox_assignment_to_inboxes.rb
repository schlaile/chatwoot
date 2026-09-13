class AddCrossInboxAssignmentToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :allow_cross_inbox_assignment, :boolean, default: false, null: false
  end
end
