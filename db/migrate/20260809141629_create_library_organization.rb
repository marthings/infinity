class CreateLibraryOrganization < ActiveRecord::Migration[8.1]
  def change
    create_table :collections do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :collections, [ :user_id, :created_at ]

    create_table :collection_captures do |t|
      t.references :collection, null: false, foreign_key: true, index: false
      t.references :capture, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end
    add_index :collection_captures, [ :collection_id, :capture_id ], unique: true
    add_index :collection_captures, [ :collection_id, :position ], unique: true
    add_check_constraint :collection_captures, "position >= 0", name: "collection_captures_position_non_negative"

    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :tags, [ :user_id, :name ], unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true, index: false
      t.references :capture, null: false, foreign_key: true

      t.timestamps
    end
    add_index :taggings, [ :tag_id, :capture_id ], unique: true
  end
end
