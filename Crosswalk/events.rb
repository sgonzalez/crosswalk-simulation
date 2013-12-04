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
    
    @trace_file.write "#{@trace_number}:#{@t.round.to_s}:#{@stoplight_state.to_s}:#{lcar_string}:#{rcar_string}:#{ped_string}\n"
    @trace_number += 1
    
    # Queue next trace event
    queue_event @t+TRACE_PERIOD, Event.new(:output_trace, {})
  end
  
  
  def reevaluate_positions ev
    # Update car positions
    reevaluate_car_strategies
    
    # Update people positions
    @people.each do |person|
      if !person.waiting
        person.position += person.speed * EPSILON
      end
    end
    
    # Queue next trace event
    queue_event @t+EPSILON, Event.new(:reevaluate_positions, {})
  end
  
  
  def spawn_car ev, direction=false
    @carid ||= 0
    # Queue up new car
    if @t < @run_time
      when_t = @t+Exponential(MINUTE.to_f/4, @rands.get_random(STREAM_CARS))
      car = Car.new(Uniform(25, 35, @rands.get_random(STREAM_CARS)), 0, Uniform(7, 12, @rands.get_random(STREAM_CARS)), (ev) ? ev.data[:car].direction : direction, false, @carid)
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
      queue_event @t+(DISTANCE_EDGE_MIDDLE-WIDTH_CROSSWALK/2)/MPH_FTPS/ev.data[:car].speed, Event.new(:car_crosswalk_intersection, {:car => ev.data[:car]})
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

    ahead_car = get_car_ahead car

    # We have to do an evaluation of the position of that ahead-car, since we don't store inter-mediate positions
    # Save the ahead car's position. we may need it later
    choices = []
    ahead_car_pos = get_instantaneous_position ahead_car

    if !ahead_car_pos.nil?
      # Subtract the buffer behind the car (follow dist)
      ahead_car_pos -= 20

      choices <<  ahead_car_pos
    end
    if @stoplight_state == :GREEN
      nearest_pts << STOP_AT_LIGHT
    end
    nearest_pts << 2*DISTANCE_EDGE_MIDDLE

    recalculate_braking_distances choices, car

    # The closest re-evaluation will be the minimum of the breaking-point, the stoplight breaking-point, and the end
    ahead_critical_pos = choices.min


    # Calculate where we should next reevaluate our strategy
    # Change our acceleration first
    # Then re-evaluate our final speed
    # Then re-evaluate our final position (essentially evaluate an integral. Ick)
  end

  def recalculate_braking_distances choices, car
    current_pos = calculate_current_position @t, car

    # Calculation of possible braking distances
    # Triangle area from top speed to 0 speed over the time to go from top speed to 0
    full_brake_dist = car.speed * (car.speed / car.acceleration) / 2
    time_to_full_speed = (car.speed - car.current_speed) / car.acceleration
    full_accel_dist = (car.current_speed * time_to_full_speed) + ( (car.speed - car.current_speed) * time_to_full_speed / 2 )

    # Perform braking-distance modifications to the first and maybe the second, but not the last
    if car.current_speed == car.speed
      # We can predict that we won't accelerate. Now we can use the braking distance with full deceleration
    else
      # Schedule acceleration to full speed
      car.position += full_accel_dist
      car.current_speed = car.speed
      car.current_acceleration = car.acceleration

      queue_event @t + time_to_full_speed, Event.new(:car_reevaluate_strategy, {:car => car})
    end


      if car.position == ahead_car_pos
        # Then we can't go forth anymore. Just... wait... until there's a reevaluate_all interjection
        return
      elsif car.position + full_accel_dist + full_brake_dist <= ahead_car_pos
        # we have time to fully accelerate before getting to the start of braking
          # If we're already travelling at full speed, check when we should re-evaluate braking
          ahead_car_pos -= full_brake_dist
      else
        # We don't have time to full accelerate. Partial acceleration? Stay at constant speed?
        # TODO: Let's say that we stay at current speed until the braking point
      end
      #
      # If we are NOT outside that range, then we need to do the following
      # TODO: How is this calculated?
      # Find the point where speed evolution meets the braking distance
      # Maximum deceleration = -car.acceleration
      # time to go from speed to 0 = speed / acceleration
      #
      # Braking distance is the triangle-area going from start speed to 0
      # braking distance = entrance_speed * (entrance_speed / acceleration) / 2
      #
      # Now, what is the entrance_speed???
      # t is the time from now until we start braking
      # evaluate using an unknown t: (current_speed + t*acceleration) = entrance_speed
      # braking distance = (current_speed + t*acceleration)**2 / acceleration / 2
      #
      # In finding t...
      # t >= 0
      # ....
      #
      # Intersection between two position curves?

  end
end
