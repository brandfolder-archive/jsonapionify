class Schema < ActiveRecord::Migration
  def change
    create_table :users, force: true do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_digest
    end

    create_table :things, force: true do |t|
      t.belongs_to :user
      t.string :name
      t.integer :weight
      t.string :color
    end
  end
end