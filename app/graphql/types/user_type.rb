module Types
    class UserType < BaseObject
        field :id, Integer, null: false
        field :username, String, null: false
    end
end