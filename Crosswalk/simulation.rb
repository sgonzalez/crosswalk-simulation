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

STOP_AT_LIGHT = DISTANCE_EDGE_MIDDLE - WIDTH_CROSSWALK/2 # position where cars are to stop for the light

TIME_RED = 12
TIME_YELLOW = 8

MINUTE = 60
MILES_FT = 5280

# MPH -> FPS
MPH_FTPS = 5280 / 3600

# Miles per hour squared -> Feet per second squared
MPHH_FTPSS = 5280 / 3600 / 3600

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
    # Update people positions
    @people.each do |person|
      if !person.waiting
        person.position += person.speed * TRACE_PERIOD
      end
    end
	
	  # Find the current positions of the cars
    poses = [[],[]]
    # The car-position must be independent of the positions used by the strategies
    @cars.each do |car|
      # car.position (used by strats) It represents the position when the event occurs. This should be in the future
      # car.speed (used by strats) It's the speed of the car after the time has passed (when the event occurs)
      #
      # car.old_pos
      # car.old_t
      # These are used to state where the car USED to be when it changed its strategy last
      #
      # We can calculate the car's current position based on where it used to be, when it used to be there, how fast it's accelerating, and how fast it WILL be going
      curr_pos = calculate_current_position @t, car
      if car.direction
        poses[0] << curr_pos
      else
        poses[1] << curr_pos
      end
      puts "Time: #{@t}. Car: #{car.uid} is at #{curr_pos}"
    end

    # left-lane car positions string
    lcar_string = ""
    poses[0].each do |cpos|
      lcar_string += "#{cpos.round},"
    end
    lcar_string = lcar_string[0..-2]
    if lcar_string == "" then lcar_string = "-20000" end # prevents a weird malloc bug in the C++ Vis

    # right-lane car positions string
    rcar_string = ""
    poses[1].each do |cpos|
      rcar_string += "#{cpos.round},"
    end
    rcar_string = rcar_string[0..-2]
    if rcar_string == "" then rcar_string = "-20000" end # prevents a weird malloc bug in the C++ Vis

    return "#{lcar_string}:#{rcar_string}"
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

  def strip_car_reevals car
    @eventlist = @eventlist.select { |e| ! ( e.type == :car_reevaluate_strategy and e.data[:car] == car) }
  end

  # Return the current position of the car in FT
  def calculate_current_position time, car
    # start at where it used to be
    # CONVERT THE POSITION TO FEET
    current_pos = car.old_pos*MILES_FT
    # Definitely need to convert this to FPS
    curr_speed = car.current_speed * MPH_FTPS
    curr_accel = car.current_acceleration * MPHH_FTPSS

    # perform the evolution from car.old_t to time
    if curr_accel == 0
      current_pos += (time - car.old_t)*curr_speed
    else
      # Either accelerating or decelerating
      old_speed = curr_speed - (time - car.old_t)*curr_accel
      # Integral under the speed-square
      current_pos += (time - car.old_t) * [curr_speed, old_speed].min

      # Integral under the upper speed-triangle
      current_pos += (time - car.old_t) * ( [curr_speed, old_speed].max - [curr_speed, old_speed].min ) / 2
    end
    return current_pos
  end
end
