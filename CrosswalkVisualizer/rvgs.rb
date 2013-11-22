#!/usr/bin/env ruby

#######################
## Santiago Gonzalez ##
#######################

#    Bernoulli(p)    
#    Binomial(n, p)  
#    Equilikely(a, b)
#    Geometric(p)    
#    Pascal(n, p)    
#    Poisson(m)      
#                    
#    Uniform(a, b)   
#    Exponential(m)  
#    Erlang(n, b)    
#    Normal(m, s)    
#    Lognormal(a, b) 
#    Chisquare(n)    
#    Student(n)      

def Bernoulli(p, random)
  return ((random < (1.0 - p)) ? 0 : 1)
end

def Binomial(n, p, random)
  i, x = 0

  n.times do
    x += Bernoulli(p)
  end
  
  return (x)
end

def Equilikely(a, b, random)
  return (a + ((b - a + 1) * random).to_i)
end

def Geometric(p, random)
  return (log(1.0 - random) / log(p)).to_i
end

def Pascal(n, p, random)
  i, x = 0

  n.times do
    x += Geometric(p, random)
  end
  
  return x
end

def Poisson(m, random)
  t = 0.0
  x = 0

  while (t < m) do
    t += Exponential(1.0, random)
    x += 1
  end
  return (x - 1)
end

def Uniform(a, b, random)
  return (a + (b - a) * random)
end

def Exponential(m, random)
  return (-m * Math.log(1.0 - random))
end

def Erlang(n, b)
  x = 0.0

  n.times do
    x += Exponential(b, random)
  end
  return (x)
end

def Normal(m, s, random)
  p0 = 0.322232431088;     q0 = 0.099348462606;
  p1 = 1.0;                q1 = 0.588581570495;
  p2 = 0.342242088547;     q2 = 0.531103462366;
  p3 = 0.204231210245e-1;  q3 = 0.103537752850;
  p4 = 0.453642210148e-4;  q4 = 0.385607006340e-2;
  u = 0.0
  t = 0.0
  p = 0.0
  q = 0.0
  z = 0.0

  u   = random
  if (u < 0.5)
    t = sqrt(-2.0 * log(u))
  else
    t = sqrt(-2.0 * log(1.0 - u))
  end
  p   = p0 + t * (p1 + t * (p2 + t * (p3 + t * p4)))
  q   = q0 + t * (q1 + t * (q2 + t * (q3 + t * q4)))
  if (u < 0.5)
    z = (p / q) - t
  else
    z = t - (p / q)
  end
  return (m + s * z)
end

def Lognormal(a, b, random)
  return (exp(a + b * Normal(0.0, 1.0, random)))
end

def Chisquare(n, random)
  i = 0
  z, x = 0.0

  n.times do
    z  = Normal(0.0, 1.0, random)
    x += z * z
  end
  return (x);
end

def Student(n, random)
  return (Normal(0.0, 1.0, random) / Math.sqrt(Chisquare(n, random) / n))
end

