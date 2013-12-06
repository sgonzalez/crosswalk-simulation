#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
## With help from    ##
## Matt Buland       ##
#######################

Event = Struct.new :type, :data

class Simulation
  
  def output_trace ev
    # update pedestrian and automobile positions
    car_strings = reevaluate_positions
    
    # people positions string
    ped_string = ""
    @people.each do |person|
      ped_string += "#{person.position.round.to_s},"
    end
    ped_string = ped_string[0..-2]
    if ped_string == "" then ped_string = "-20000" end # prevents a weird malloc bug in the C++ Vis
    
    @trace_file.write "#{@trace_number}:#{@t.round.to_s}:#{@stoplight_state.to_s}:#{car_strings}:#{ped_string}\n"
    @trace_number += 1
    
    # Queue next trace event
    queue_event @t+TRACE_PERIOD, Event.new(:output_trace, {})
  end
  
  
  
  def spawn_car ev, direction=false
    @carid ||= 0
    # Queue up new car
    if @t < @run_time
      when_t = @t+Exponential(MINUTE.to_f/4, @rands.get_random(STREAM_CARS))
      car = Car.new(
        Uniform(25, 35, @rands.get_random(STREAM_CARS)),    # Speed
        0,                                                  # Position is initialized to 0
        Uniform(7, 12, @rands.get_random(STREAM_CARS)),     # Acceleration
        (ev) ? ev.data[:car].direction : direction,         # Direction
        false,                                              # Waiting
        @carid,                                             # UID: Unique identifier
        0,                                                  # Old position (same place as current position)
        when_t                                              # Old time: NOW
      )

      @carid += 1
      car.current_speed = car.speed
      car.current_acceleration = 0 # stay at a constant speed
      event = Event.new(:spawn_car, {:car => car})
      queue_event when_t, event # spawn a new car every 1/4 of minute
    end
    
    # Car arrives
    if ev
      print_time
      @cars << ev.data[:car]
      puts "New \x1b[37mCAR\x1b[0m #{direction_arrow_for_car ev.data[:car]} w/ speed: #{"%0.4f" % ev.data[:car].speed}"
      
      # Queue intersection event
      # queue_event @t+(DISTANCE_EDGE_MIDDLE-WIDTH_CROSSWALK/2)/MPH_FTPS/ev.data[:car].speed, Event.new(:car_crosswalk_intersection, {:car => ev.data[:car]})
      # Tell the car to immediately evaluate its strategy
      car_reevaluate_strategy Event.new(:car_reevaluate_strategy, {:car => ev.data[:car]})
    end
  end
  
  def spawn_person ev
    # Queue up new person
    if @t < @run_time
      when_t = @t+Exponential(MINUTE.to_f/4, @rands.get_random(STREAM_PEOPLE))
      person = Person.new(Uniform(6, 13, @rands.get_random(STREAM_PEOPLE)), 0, false)
      event = Event.new(:spawn_person, {:person => person})
      queue_event when_t, event # spawn a new person every 1/4 of minute
    end

    # Person arrives
    if ev
      print_time
      @people << ev.data[:person]
      puts "New \x1b[36mPERSON\x1b[0m w/ speed: #{"%0.4f" % ev.data[:person].speed}"
      
      # Queue intersection event
      queue_event @t+(DISTANCE_TO_CROSSWALK)/ev.data[:person].speed, Event.new(:person_crosswalk_intersection, {:person => ev.data[:person]})
    end
  end
  
  
  
  def car_crosswalk_intersection ev
    # With the way accelaration, and the non-collisions of cars, this event is now to be unused

    # print_time
    # puts "Car #{direction_arrow_for_car ev.data[:car]} arrived at \x1b[33mstoplight\x1b[0m"
    # 
    # ev.data[:car].waiting = true
    # ev.data[:car].wait_start = @t
    # 
    # if @stoplight_state == :GREEN
    #   ev.data[:car].waiting = false
    #   ev.data[:car].wait_finish = @t
    #   add_wait_point_for_car ev.data[:car]
    #   # Queue finished event
    #   queue_event @t+(DISTANCE_EDGE_MIDDLE+WIDTH_CROSSWALK/2)*MPH_FTPS/ev.data[:car].speed, Event.new(:car_finished, {:car => ev.data[:car]})
    # end
  end
  
  def person_crosswalk_intersection ev
    print_time
    puts "Person arrived at crosswalk"
    
    ev.data[:person].waiting = true
    ev.data[:person].wait_start = @t
    
    case @stoplight_state
    when :GREEN # don't walk
      attempt_walk_request ev.data[:person]
      queue_event @t+MINUTE, Event.new(:person_waited_one_minute, {:person => ev.data[:person]})
    when :YELLOW # don't walk
      attempt_walk_request ev.data[:person]
      queue_event @t+MINUTE, Event.new(:person_waited_one_minute, {:person => ev.data[:person]})
    when :RED # can walk
      if (LENGTH_CROSSWALK)/ev.data[:person].speed <= TIME_RED - (@t-@last_transition_to_red) # ensure that person crosses only if it has enough time to
        ev.data[:person].waiting = false
        ev.data[:person].wait_finish = @t
        add_wait_point_for_person ev.data[:person]
        # Queue finished crossing event
        queue_event @t+(LENGTH_CROSSWALK)/ev.data[:person].speed, Event.new(:person_finished, {:person => ev.data[:person]})
      end
    end
  end
  
  
  
  def person_waited_one_minute ev
    if ev.data[:person].waiting == true
      print_time
      puts "Person waiting over 1 Minute"
      walk_requested
    end
  end
  
  
  
  def car_finished ev
    print_time
    puts "Car ##{ev.data[:car].uid} #{direction_arrow_for_car ev.data[:car]} \x1b[31mfinished\x1b[0m"
    
    @cars.delete ev.data[:car]
  end
  
  def person_finished ev
    print_time
    puts "Person \x1b[31mfinished\x1b[0m"
    
    @people.delete ev.data[:person]
  end
  
  
  
  
  
  def walk_delay_timer_expired ev
    print_time
    puts "Light turned \x1b[1;33mYELLOW\x1b[0m"
    @walk_delay_state = false
    @stoplight_state = :YELLOW
    
    queue_event @t+TIME_YELLOW, Event.new(:yellow_timer_expired, {})
  end
  
  def yellow_timer_expired ev
    print_time
    puts "Light turned \x1b[1;31mRED\x1b[0m"
    @stoplight_state = :RED
    @last_transition_to_red = @t
    
    queue_event @t+TIME_RED, Event.new(:red_timer_expired, {})
    
    waiting_people = @people.select { |p| p.waiting == true }
    waiting_people.each do |person|
      person.waiting = false
      person.wait_finish = @t
      add_wait_point_for_person person
      # Queue finished event
      queue_event @t+(LENGTH_CROSSWALK)/person.speed, Event.new(:person_finished, {:person => person})
    end
  end
  
  def red_timer_expired ev
    print_time
    puts "Light turned \x1b[1;32mGREEN\x1b[0m"
    @stoplight_state = :GREEN
    @last_transition_to_green = @t

    # instantaneously change all the waiting cars strategies
    reevaluate_all_car_strats()
    # queue_event @t+(DISTANCE_EDGE_MIDDLE+WIDTH_CROSSWALK/2)*MPH_FTPS/car.speed, Event.new(:car_finished, {:car => car})
  end

  # Meant to be called instantaneously (on emergency basically)
  def reevaluate_all_car_strats
    # separation of left and right allows for easier short-circuiting the re-evaluations
    lefts = @cars.select { |c| c.direction == false }
    rights = @cars.select { |c| c.direction == true }
    reeval_carlist lefts
    reeval_carlist rights
  end

  def reeval_carlist cars
    cars.each do |car|
      # Evaluate the current position
      current_pos = calculate_current_position @t, car

      if current_pos > STOP_AT_LIGHT
        # Skip cars that won't change because of the light. TODO: Assume that the only reason this function is called is because the light changed
        # This also bodes well with the short-circuiting
        next
      end

      # Strip out re-evaluations of this car
      strip_car_reevals car

      start_strat = car.strategy
      car_reevaluate_strategy Event.new(:car_reevaluate_strategy, {:car => car})
      end_strat = car.strategy
      if start_strat == end_strat
        # Stop re-evaluating when a car does not change strategy
        break
      end
    end
  end

  def car_reevaluate_strategy ev
    # Check the current surroundings to evaluate what to do next
    car = ev.data[:car]
    puts "Evaluating the strategy of car #{car.uid}"

    ahead_car = get_car_ahead car

    # We have to do an evaluation of the position of that ahead-car, since we don't store inter-mediate positions
    # Save the ahead car's position. we may need it later
    nearest_pts = []
    if !ahead_car.nil?
      ahead_car_pos = calculate_current_position @t, ahead_car
    else
      ahead_car_pos = nil
    end

    if !ahead_car_pos.nil?
      # Subtract the buffer behind the car (follow dist)
      ahead_car_pos -= 20

      nearest_pts <<  ahead_car_pos
    end
    # Idk why I had a condition on stopping at the light. We definitely want to consider that as a stopping point
    nearest_pts << STOP_AT_LIGHT
    nearest_pts << 2*DISTANCE_EDGE_MIDDLE


    # The closest re-evaluation will be the minimum of the breaking-point, the stoplight breaking-point, and the end
    ahead_critical_pos = nearest_pts.min

    # We need to know if we need to apply braking distances. If the end was chosen (last), then we'll say we do NOT need to. Otherwise, no
    apply_braking = true
    if ahead_critical_pos == nearest_pts[-1]
      apply_braking = false
    end

    if apply_braking
      added_event = recalculate_braking_distance ahead_critical_pos, car
    else
      # TODO: The nearest point is the exit. Schedule a leave
    end

  end

  # Calculate where we should next reevaluate our strategy
  # Change our acceleration first
  # Then re-evaluate our final speed
  # Then re-evaluate our final position (essentially evaluate an integral. Ick)

  # Takes the closest place that must be stopped at and the car heading towards it, and figures out where/when the next re-evaluation event should happen
  # Returns the event. Note, this event HAS been added to the queue
  def recalculate_braking_distance stop_point, car
    # Note: hopefully, current_pos will equal car.position
    current_pos = calculate_current_position @t, car
    # Note: current_pos is in ft, and car.position is in Miles
    if current_pos != car.position*MILES_FT
      puts "Warning: when recalculating braking distances, the car(#{car.uid}) was not on an even event spacing. current_pos calculation != car.position"
      puts "\tExpected: #{car.position}. Got: #{current_pos}. Current time: #{@t}. OldTime: #{car.old_t}"
    end

    curr_speed = car.current_speed * MPH_FTPS
    curr_accel = car.current_acceleration * MPHH_FTPSS
    max_speed = car.speed * MPH_FTPS
    max_accel = car.acceleration * MPHH_FTPSS

    # Calculation of possible braking distances
    # Distance to stop from full-speed
    full_brake_dist = max_speed * (max_speed / max_accel) / 2
    # Time to accelerate from current speed to top speed
    time_to_full_speed = (max_speed - curr_speed) / max_accel
    # Distance to accelerate to top speed
    full_accel_dist = (curr_speed * time_to_full_speed) + ( (max_speed - curr_speed) * time_to_full_speed / 2 )

    # Distance to brake from our current speed. Note: this COULD be the same as full_brake_dist
    brake_currspeed_dist = curr_speed * curr_speed / max_accel / 2

    if current_pos == stop_point - brake_currspeed_dist
      # BRAKE NOW!
      # TODO: Should I match the car in front of me's speed?
      # Time to brake from current speed to zero
      brake_time = curr_speed**2 / (2 * max_accel)
      car = car_transition(car, # Transition the car into how it will be at the next event
                           ahead_car_pos - brake_currspeed_dist,  # new position
                           0, # New speed
                           -max_accel)
      nextevent = Event.new(:car_reevaluate_strategy, {:car => car})
      queue_event @t+brake_time, nextevent
      return nextevent
    elsif current_pos < stop_point - full_brake_dist - full_accel_dist
      # We have space to accelerate to full-speed, then stop again
      if curr_speed < max_speed
        # schedule the next event to be the acceleration to full speed
        car = car_transition(car,
                             current_pos + full_accel_dist, # New position
                             max_speed, # New speed
                             max_accel)
        nextevent = Event.new(:car_reevaluate_strategy, {:car => car})
        queue_event @t + time_to_full_speed, nextevent
        return nextevent
      elsif curr_speed == max_speed
        # Continue at full speed until we have to brake
        timetillbrake = (stop_point - full_brake_dist - current_pos) / curr_speed
        car = car_transition(car,
                             stop_point - full_brake_dist, # New position
                             max_speed, # New speed
                             0)
        nextevent = Event.new(:car_reevaluate_strategy, {:car => car})
        queue_event @t + timetillbrake, nextevent
        return nextevent
      else
        puts "Woah guys. We have a magic car over here... It's going faster than it's maximum speed!"
        return nil
      end
    elsif current_pos > stop_point - brake_currspeed_dist
      puts "Car #{car.uid} doesn't have enough room to stop. Currently at #{current_pos}. Need to stop at #{stop_point}. Braking distance: #{brake_currspeed_dist}"
      puts "This should be a simulation impossibility. BREAK."
      exit -1
    else
      # We don't have time to fully accelerate, and we're not going at full speed already
      # Algorithm from Hellman:
      # We don't have time to FULLY accelerate. Partial acceleration...
      # We know that we definitely have to brake from our current speed (at some point).. If we accelerate then decel, we're going to come back to our current speed

      # We now know that we have a specific distance where we can do whatever we want... as long as we're braking at brake_currspeed_dist
      whatever_dist = stop_point - brake_currspeed_dist - current_pos

      # Since we have acceleration/deceleration symmetry, we can accelerate for half that distance, and decelerate for the other half
      accel_dist = whatever_dist / 2

      # Find the peak speed in that distance
      # D = (s_f - s_c) * ((s_f - s_c) / a) / 2
      # D = (s_f - s_c)**2 / (2a)
      # sqrt(2 D a) = s_f - s_c
      # s_f = s_c + sqrt(2 D a)
      speed_final = current_speed + sqrt(2*accel_dist*max_accel);

      # Time to accelerate to that speed
      accel_time = (speed_final - curr_speed) / max_accel

      # Schedule the event for accelerating to this partial speed
      car = car_transition(car,
                           current_pos + accel_dist, # New position
                           speed_final, # New Speed
                           max_accel)
      nextevent = Event.new(:car_reevaluate_strategy, {:car => car})
      queue_event @t+accel_time, nextevent
    end
  end

  # new Position is in FEET
  # new speed is in FPS
  # new acceleration is in FEET / S**2
  def car_transition car, newpos, newspeed, newaccel
    car.old_pos = car.position
    car.old_t = @t

    car.position = newpos/MILES_FT
    car.current_speed = newspeed/MPH_FTPS
    car.current_acceleration = newaccel/MPHH_FTPSS

    return car
  end
end
