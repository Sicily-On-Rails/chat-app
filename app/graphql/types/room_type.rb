module Types
    class RoomType < BaseObject
        field :id, Integer, null: false
        field :name, String, null: false
    end
end