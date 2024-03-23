class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.string :name
      t.string :description
      t.boolean :completed
      t.string :notes
      t.string :upload

      t.timestamps
    end
  end
end
