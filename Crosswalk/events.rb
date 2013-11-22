#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

Event = Struct.new :type, :data

class Simulation
  
  def spawn_car ev, direction=false
    # Queue up new car
    if @t < @run_time
      when_t = @t+Exponential(MINUTE.to_f/4, @rands.get_random(STREAM_CARS))
      car = Car.new(Uniform(25, 35, @rands.get_random(STREAM_CARS)), (ev) ? ev.data[:car].direction : direction, false)
      event = Event.new(:spawn_car, {:car => car})
      queue_event when_t, event # spawn a new car every 1/4 of minute
    end
    
    # Car arrives
    if ev
      print_time
      @cars << ev.data[:car]
      puts "New \x1b[37mCAR\x1b[0m #{direction_arrow_for_car ev.data[:car]} w/ speed: #{"%0.4f" % ev.data[:car].speed}"
      
      # Queue intersection event
      queue_event @t+(DISTANCE_EDGE_MIDDLE-WIDTH_CROSSWALK/2)*MPH_FTPS/ev.data[:car].speed, Event.new(:car_crosswalk_intersection, {:car => ev.data[:car]})
    end
  end
  
  def spawn_person ev
    # Queue up new person
    if @t < @run_time
      when_t = @t+Exponential(MINUTE.to_f/4, @rands.get_random(STREAM_PEOPLE))
      person = Person.new(Uniform(6, 13, @rands.get_random(STREAM_PEOPLE)), false)
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
    print_time
    puts "Car #{direction_arrow_for_car ev.data[:car]} arrived at \x1b[33mstoplight\x1b[0m"
    
    ev.data[:car].waiting = true
    ev.data[:car].wait_start = @t
    
    if @stoplight_state == :GREEN
      ev.data[:car].waiting = false
      ev.data[:car].wait_finish = @t
      add_wait_point_for_car ev.data[:car]
      # Queue finished event
      queue_event @t+(DISTANCE_EDGE_MIDDLE+WIDTH_CROSSWALK/2)*MPH_FTPS/ev.data[:car].speed, Event.new(:car_finished, {:car => ev.data[:car]})
    end
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
    puts "Car #{direction_arrow_for_car ev.data[:car]} \x1b[31mfinished\x1b[0m"
    
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
    
    waiting_cars = @cars.select { |c| c.waiting == true }
    waiting_cars.each do |car|
      car.waiting = false
      car.wait_finish = @t
      add_wait_point_for_car car
      # Queue finished event
      queue_event @t+(DISTANCE_EDGE_MIDDLE+WIDTH_CROSSWALK/2)*MPH_FTPS/car.speed, Event.new(:car_finished, {:car => car})
    end
  end
  
end