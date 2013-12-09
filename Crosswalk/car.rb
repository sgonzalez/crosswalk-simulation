#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

Car = Struct.new(
  # Suggested to be required
  :speed,
  :position,  # NOTE: position is in miles
  :acceleration,
  :direction,
  :waiting,
  :uid,
  :old_pos,
  :old_t,
  :old_s,
  # Suggested Optional (not used immediately)
  :strategy,
  :wait_start,
  :wait_finish,
  :current_speed,
  :current_acceleration,
  :at_stoplight
)

