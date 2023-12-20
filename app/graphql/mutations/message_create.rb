module Mutations
    class MessageCreate < BaseMutation
        argument :room_id, Integer, required: true
        argument :user_id, Integer, required: true
        argument :content, String, required: true

        field :message, Types::MessageType, null: false


        def resolve(room_id:, user_id:, content:)
            Message.create(room_id: room_id, user_id: user_id, content: content)
        end



    end

end