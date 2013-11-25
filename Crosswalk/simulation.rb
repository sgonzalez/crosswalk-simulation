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
MPH_FTPS = 1.46667

STREAM_PEOPLE = 1
STREAM_CARS = 2

TRACE_PERIOD = 1 # how often to write to trace file in seconds

EPSILON = 0.1 # how often do we reevaluate the cars' strategy

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
      
      if @people == [] && @cars == [] && ev.type != :output_trace then break end

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
	
	def reevaluate_car_strategies
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	  ######################################################################
	end
	
	def print_time
	  print "\x1b[34mT=#{@t.round} \x1b[0m".ljust(18)
	end
	
	def direction_arrow_for_car c
	  (c.direction) ? "⫷ " : "⫸ "# "->" : "<-"
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
