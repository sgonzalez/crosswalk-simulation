#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

Car = Struct.new(:speed, :position, :acceleration, :direction, :waiting, :wait_start, :wait_finish)

# NOTE: position is in miles