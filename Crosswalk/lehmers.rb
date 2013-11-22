#!/usr/bin/env ruby

#####################################################################
## Based on Lehmer Streams Generator by Matt Buland and John Kelley #
#####################################################################


def make_lehmer_gen(a, m)
  return lambda { |x| return a*x % m }
end

def lehmer_func(a, m, x)
  return a*x % m
end

class StreamedLehmerGen
  attr_reader :seeds

  MODULUS    = 2147483647 # DON'T CHANGE THIS VALUE
  MULTIPLIER = 48271      # DON'T CHANGE THIS VALUE
  # CHECK      = 399268537  # DON'T CHANGE THIS VALUE
  STREAMS    = 256        # # of streams, DON'T CHANGE THIS VALUE
  A256       = 22925      # jump multiplier, DON'T CHANGE THIS VALUE
  DEFAULT    = 123456789  # initial seed, use 0 < DEFAULT < MODULUS

  def initialize(x0)
    @a = A256
    @m = MULTIPLIER
    @streams = STREAMS
    @seeds = [0] * STREAMS
    @my_gen = make_lehmer_gen(@a, @m)
    plant_seeds(x0)
  end

  def plant_seeds(first_seed)
    @seeds[0] = first_seed
    q = (@m / @a)
    r = (@m % @a)

    (1...(@streams)).to_a.each do |i|
      x = (@a * (@seeds[i-1] % q)) - r * (@seeds[i-1] / q)

      if x > 0
        @seeds[i] = x
      else
        @seeds[i] = x + @m
      end
    end
  end

  def get_random(stream)
    mgen = @my_gen
    @seeds[stream] = mgen.(@seeds[stream])
    return @seeds[stream]/MULTIPLIER
  end

end
# 
# def get_jump_mult(a, j, m)
#   return a**j % m
# end

# m = 2**63 - 1
# if ARGV.length < 5
#   puts "Required arguments: a j s x0"
# end
# 
# if ARGV.include?('--aj')
#   index = 0
#   aj = ARGV[0].to_i
# else
#   aj = get_jump_mult(ARGV[0].to_i, ARGV[1].to_i, m)
# end
# 
# stream_gen = StreamedLehmerGen.new(aj, m, ARGV[1].to_i, ARGV[2].to_i, ARGV[3].to_i)
# 
# if ARGV.include?('--seeds')
#   stream_gen.seeds.each_with_index do |s, i|
#     puts "Seed #{i}: #{s}"
#   end
# else
#   (0..(ARGV[2].to_i-1)).to_a.each do |j|
#     puts "Stream #{j}"
#     (0...ARGV[4].to_i).to_a.each do |i|
#       puts stream_gen.get_random(j)
#     end
#   end
# end