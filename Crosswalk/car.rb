#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

Car = Struct.new(:speed, :position, :acceleration, :direction, :waiting, :uid, :wait_start, :wait_finish, :current_speed, :current_acceleration, :at_stoplight)

# NOTE: position is in miles
