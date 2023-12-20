# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end


    field :all_rooms, [Tyepes::RoomType], null: false
    def all_rooms
      Room.all
    end

    field :messages_by_room, [Types::MessageType], null: false do
      argument :room_id, Integer, required: true
    end

    def messages_by_room(room_id:) 
      Room.find(room_id: room_id).messages
    end

    field :last_message, Types::MessageType, null: false do
      argument :room_id, Integer, required: true
    end

    def last_message(room_id:)
      Room.find(room_id: room_id).messages.last
    end

    field :room_users, [Type::UserType], null: false do
      argument :room_id, Integer, require: true
    end

    def room_users(room_id: )
      messages_room = Room.find(room_id: room_id).messages
      users_room = []
      messages_room.each do |message|
        user = User.find(message.user_id)
        users_room << user
      end
      users_room
    end


  end
end
