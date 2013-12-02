#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

require_relative "eventlist"
require_relative "welford"
require_relative "lehmers"
require_relative "person"
require_relative "events"
require_relative "rvgs"
require_relative "car"

DISTANCE_EDGE_MIDDLE = 1155 # distance from where cars spawn to the middle of the crosswalk (i.e. 7*330/2)
DISTANCE_TO_CROSSWALK = 165 # distance person has to walk to get to the crosswalk (i.e. 330/2)
WIDTH_CROSSWALK = 24
LENGTH_CROSSWALK = 46

TIME_RED = 12
TIME_YELLOW = 8

MINUTE = 60
MILES_FT = 5280
MPH_FTPS = 1.46667

STREAM_PEOPLE = 1
STREAM_CARS = 2

TRACE_PERIOD = 0.1 # how often to write to trace file in seconds

class Simulation
	  
	def initialize( experiment, time, seed, trace )
		puts "\x1b[0;1mExperiment #{experiment}; Tracefile #{trace}; Time #{time} minutes; Seed #{seed}\x1b[0m\n\n"
	  
	  @run_time = time*MINUTE
    @rands = StreamedLehmerGen.new(seed)
    @wlf_car_waits = Welford.new(20)
    @wlf_person_waits = Welford.new(20)
    @t = 0 # world clock (seconds)

    # Setup I/O
    @log_file = File.open("acwait.dat", "w")
    @trace_file = File.open(trace, "w")
    @trace_number = 0
    @trace_fire_yet = false
    
    # State
    @people = []
    @cars = []
    @stoplight_state = :GREEN
    @walk_delay_state = false
    @last_transition_to_green = -100 # assume that the stoplight has been green for a while
    @last_transition_to_red = -100
    
    # Simulation initialization
    init_eventlist
    spawn_car nil, true # create first car in direction 1
    spawn_car nil, false # create first car in direction 2
    spawn_person nil # create first person

  	while @eventlist.size != 0 do

      # Create first trace event when first event happens
      if @trace_fire_yet == false
        output_trace nil
        @trace_fire_yet = true
      end

  		ev = next_event
  		if ev then method(ev.type).call(ev) end
      
      if @people == [] && @cars == [] && ev.type != :output_trace && ev.type != :reevaluate_positions then break end

  	end
  	
  	# Write autocorrelations to file
  	n = 1
  	while n <= 20
  	  @log_file.write "#{@wlf_person_waits.get_autocorrelation n} #{@wlf_car_waits.get_autocorrelation n}\n"
  	  n += 1
  	end

  	@log_file.close
    @trace_file.close

    puts ""
    puts "OUTPUT num_pedestrians       #{@wlf_person_waits.get_count}"
    puts "OUTPUT num_autos             #{@wlf_car_waits.get_count}"
    puts "OUTPUT sim_duration          #{"%0.4f" % (@t.to_f/MINUTE)}"
    puts "OUTPUT pedwait_min #{@wlf_person_waits.get_min}  pedwait_mean #{@wlf_person_waits.get_mean}  pedwait_stdev #{@wlf_person_waits.get_stdev}  pedwait_max #{@wlf_person_waits.get_max}"
    puts "OUTPUT carwait_min #{@wlf_car_waits.get_min}  carwait_mean #{@wlf_car_waits.get_mean}  carwait_stdev #{@wlf_car_waits.get_stdev}  carwait_max #{@wlf_car_waits.get_max}"

  	return 0;
	end
	
	# # # # # # # # # #
	# Utility functions
	
	def reevaluate_positions
	  ############################
	  # for now reevaluate strategies each time, since it is not next event yet ;-) A silly workaround
	  ############################
	  reevaluate_car_strategies
	  ############################
	  
	  # Update car positions
	  ################
	  ################
	  ################
	  ################
    
    # Update people positions
    @people.each do |person|
      if !person.waiting
        person.position += person.speed * TRACE_PERIOD
      end
    end
	end
  
  # Naive strategies 1: Ignore acceleration. Either go or don't go
	def reevaluate_car_strategies
    # puts "Evaluating strategies. Current time is #{@t}"

    if @t > 300
      puts "Cars left at time 300 (much to late):"
      @cars.each { |c| puts c.uid }
      exit -1
    end

    #if @t < 200 and @t < @t.round + 0.05 and @t > @t.round - 0.05
    #  puts "Time #{@t}. Car positions are:"
    #  @cars.each { |c| puts "#{c.uid}\tat #{c.position}" }
    #end

	  @cars.each do |car|
      # If the car is past the simulation, stop moving it, and schedule its leave event
      if car.position*MILES_FT >= 2*DISTANCE_EDGE_MIDDLE
        puts "Scheduling that #{car.uid} must leave at time #{@t}. It's at #{car.position*MILES_FT}"
        # Schedule that the car leaves ALMOST now
        queue_event @t+0.0000001, Event.new(:car_finished, {:car => car})
      end

      # Move the car first to calculate is current position
      if !car.waiting
        car.position += car.current_speed * TRACE_PERIOD / (MINUTE*MINUTE) # position is in miles
      end

      # Re-evaluate the speed to be taken
      if car.position*MILES_FT <= DISTANCE_EDGE_MIDDLE - DISTANCE_TO_CROSSWALK/2 and car.position*MILES_FT > DISTANCE_EDGE_MIDDLE - DISTANCE_TO_CROSSWALK/2 - car.speed * MPH_FTPS * TRACE_PERIOD
        puts "Car #{car.uid} is near the stoplight. It's at position #{car.position*MILES_FT}. Stoplight is #{@stoplight_state}"
        if @stoplight_state == :GREEN
          # We're good to go forth
          car.at_stoplight = false
          car.waiting = false
          car.current_speed = car.speed

          # Both are conditionally set, since the light may be green, and thus we have no wait time
          car.wait_start ||= @t
          car.wait_finish ||= @t
          add_wait_point_for_car car
        else
          # Stop for the light
          car.at_stoplight = true
          car.waiting = true
          car.current_speed = 0

          # Conditional set, since this will continually happen as the light is waited on
          car.wait_start ||= @t
        end
      else
        # Not at the stoplight yet.
        car.at_stoplight = false
        ahead = get_car_ahead car
        if ahead.nil?
          # Go ahead normally; at full speed, no acceleration (those are default current_speed and current_acceleration)
          car.waiting = false
          car.current_speed = car.speed
        else
          car_bubble = 40
          brake_distance = 0
          # if where i will wind up (including the evolution of what my speed could be) is going to wind up inside (or after) the car in front's bubble, then stop
          if car.position*MILES_FT + brake_distance + car.speed*MPH_FTPS*TRACE_PERIOD >= ahead.position*MILES_FT - car_bubble
            car.waiting = true
            car.current_speed = 0
          else
            # Full speed ahead!
            car.waiting = false
            car.current_speed = car.speed
          end

          # inherit the ahead car's wait times iff we haven't reached the crosswalk yet (which is why it's a conditional set)
          justset_start = false
          justset_finish = false
          if !ahead.wait_start.nil? and car.wait_start.nil?
            car.wait_start ||= ahead.wait_start
            justset_start = true
          end
          if !ahead.wait_finish.nil? and car.wait_finish.nil?
            car.wait_finish ||= ahead.wait_finish
            justset_finish = true
          end

          if (justset_start or justset_finish) and !car.wait_start.nil? and !car.wait_finish.nil?
            add_wait_point_for_car car
          end
        end
      end
    end
	end

  # Gets the car ahead of the specified car from the @cars list
  def get_car_ahead c
    # Called bestcar because it assumes no passing, which until is WRONG the entire strategies logic is done
    bestcar = nil
    @cars.each do |ocar|
      # Get the car that is headed the same direction,
      # is ahead of the current car,
      # and is the best: is CLOSEST to the current car
      # Note the synergy between 'ahead of the current car' and 'minimum distance' results in 'closest ahead of'
      # Also not the lack of position equivalence. It's reasoned that cars CANNOT be in the same position
      if ocar.direction == c.direction and ocar.position > c.position and (bestcar.nil? or ocar.position < bestcar.position)
        bestcar = ocar
      end
    end
    return bestcar
  end
	
	def print_time
	  print "\x1b[34mT=#{@t.round} \x1b[0m".ljust(18)
	end
	
	def direction_arrow_for_car c
	  (c.direction) ? "->" : "<-" #"⫷ " : "⫸ "
	end
	
	def attempt_walk_request person
	  waiting_people = @people.select { |p| p.waiting == true }
	  press_button = 0
	  if @t - person.wait_start > MINUTE # person waiting for more than one minute
	    press_button = 1
	  elsif waiting_people.size == 1 # person alone
	    press_button = Bernoulli(2.0/3.0, @rands.get_random(STREAM_PEOPLE))
	  else # person with others
	    press_button = Bernoulli(1.0/waiting_people.size, @rands.get_random(STREAM_PEOPLE))
	  end
	  if press_button == 1 then walk_requested end
	end
	
	def walk_requested
	  if @stoplight_state == :GREEN && @walk_delay_state == false
	    @walk_delay_state = true
	    queue_event @t+[1, @last_transition_to_green-@t+14].max, Event.new(:walk_delay_timer_expired, {}) 
	  end
	end
	
	def add_wait_point_for_car c
	  wait = c.wait_finish - c.wait_start
	  @wlf_car_waits.add_point wait
	end
	
	def add_wait_point_for_person p
	  wait = p.wait_finish - p.wait_start
	  @wlf_person_waits.add_point wait
	end
end
