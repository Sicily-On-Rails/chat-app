class RoomsController < ApplicationController
  def index
    @current_user = current_user
    redirect_to '/signin' unless @current_user
    @rooms = Room.publics_rooms
    @users = User.all
    @room = Room.new
  end


  def show
    @current_user = current_user
    @single_room = Room.find(params[:id])
    @rooms = Room.publics_rooms
    @users = User.all
    @room = Room.new
    @message = Message.new
    @messages = @single_room.messages

    render "index"
  end



  def create 
    @room = Room.create(name: params["room"]["name"])
  end

end
