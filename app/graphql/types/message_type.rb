module Types
    class MessageType < BaseObject
        field :id, Integer, null: false
        field :content, String, null: false
        field :users,[Types::UserType], null: false
    end
end