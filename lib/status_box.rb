class StatusBox < BaseBox
  def initialize(above_box)
    super(1.0 / 4, above_box.top_offset + above_box.box_height, 3) # StatusBox will be below the InfoBox with a blue border
  end
end