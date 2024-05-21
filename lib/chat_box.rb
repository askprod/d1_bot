class ChatBox < BaseBox
  def initialize(above_box)
    super(2.0 / 4, above_box.top_offset + above_box.box_height, 2)
  end
end