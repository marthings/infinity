class CreateCaptures < ActiveRecord::Migration[8.1]
  def change
    create_table :captures do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :source_url
      t.string :source_name
      t.string :title
      t.text :description
      t.text :note
      t.datetime :published_at

      t.timestamps
    end

    add_index :captures, [ :user_id, :created_at ]
  end
end
