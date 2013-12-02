#!/usr/bin/ruby

#######################
## Santiago Gonzalez ##
#######################

###
# This is a simple implementation of Welford's single pass equations in Ruby
# Calculates mean, max, min, count, stdev, variance, and autocorrelation
###



def welford_test
  wf = Welford.new
  puts "WELFORD adding points: 1,2,3,4,5"
  wf.add_point(1)
  wf.add_point(2)
  wf.add_point(3)
  wf.add_point(4)
  wf.add_point(5)
  puts "WELFORD Mean: #{wf.get_mean} == 3"
  puts "WELFORD Variance: #{wf.get_variance} == 2"
  puts "WELFORD StandardDeviation: #{wf.get_stdev} == #{Math.sqrt(2)}"
  puts "WELFORD Count: #{wf.get_count} == 5"
  puts "WELFORD Min: #{wf.get_min} == 0"
  puts "WELFORD Max: #{wf.get_max} == 5"
end



class Welford
  
  def initialize(max_lag=0)
    reset max_lag
  end
  
  def reset max_lag
    @max_lag = max_lag
    @variance = 0
    @count = 0
    @mean = 0
    @min = 0
    @max = 0
    @w = []
    @x = []
    max_lag.times do
      @w << 0
      @x << 0
    end
  end
  
  def add_point xi
    @count += 1
    if @count == 0
      @min = xi
      @max = xi
    else
      @min = [xi, @min].min
      @max = [xi, @max].max
    end
    
    add_variance xi
    add_mean xi
    
    if @max_lag > 0
			update_wx xi;
		end
  end
  
  def get_autocorrelation lag
		if lag > 0 && lag <= @max_lag
			@w[lag-1] / @variance
		else
		  raise "Welford: Lag value out of range"
    end
	end
  
  def get_variance
    @variance.to_f / @count
  end
  
  def get_stdev
    Math.sqrt ( @variance.to_f / @count )
  end
  
  def get_mean
    @mean
  end
  
  def get_count
    @count
  end
  
  def get_min
    @min
  end
  
  def get_max
    @max
  end
  
private
  
  def update_wx xi
    if @count == 1
			@x[1] = xi
		elsif @count > 1 && @count <= @max_lag
		  j = 1
			while j <= @count-1
				@w[j-1] = @w[j-1] + ((@count - 1).to_f / @count) * (xi - @mean) * (@x[@count-j] - @mean)
				j += 1
			end
			@x[@count] = xi
		else
		  j = 1
			while j <= @max_lag
				@w[j-1] = @w[j-1] + ((@count - 1).to_f / @count) * (xi - @mean) * (@x[ ((@count - j) % @max_lag) + 1 ] - @mean)
				j += 1
			end
			@x[ (@count % @max_lag) + 1 ] = xi
		end
  end
  
  def add_mean xi
    if @count == 0
      @mean = xi
    else
      @mean = @mean + (xi - @mean).to_f / @count
    end
    @mean
  end
  
  def add_variance xi
    if @count > 1
      @variance = @variance + (( @count -1).to_f / @count) * ((xi - @mean) * (xi - @mean))
    else
      @variance = 0
    end
    @variance;
  end
  
end
