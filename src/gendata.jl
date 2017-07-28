"""

  invers_gen(x::Vector{Float64}, theta::Float64)

Returns: Vector{Float64} of data transformed using inverse of Clayton Copula
generator with parametr theta
"""
invers_gen(x::Vector{Float64}, theta::Float64) = (1 + theta.*x).^(-1/theta)

"""

  clcopulagen(t::Int, n::Int)

Returns: t x n Matrix{Float}, t realisations of n-variate data generated from Clayton
 copula with Weibull marginals
"""

function clcopulagen(t::Int, n::Int, step::Float64 = 0.01, w1 = 1.)
  theta = 1.02
  qamma_dist = Gamma(1,1/theta)
  x = rand(t)
  u = rand(t, n)
  matrix = zeros(Float64, t, n)
  for i = 1:n
    unif_ret = invers_gen(-log(u[:,i])./quantile(qamma_dist, x), theta)
    @inbounds matrix[:,i] = quantile(Weibull(w1+step*i,1), unif_ret)
  end
  matrix
end

"""
  covmatgen(band_n::Int)

Returns: symmetric correlation and covariance matrix
"""

function cormatgen(n::Int)
  x = clcopulagen(3*n, n, -28/n, 30.)
  for i in 1:n
    x[:,i] = rand([-1, 1])*x[:,i]
  end
  cor(x)
end

"""
  tcopulagen(cormat::Matrix{Float}, nu::Int)

Generates data using t-student Copula given a correlation  matrix and degrees of freedom
"""

function tcopulagen(cormat::Matrix{Float64}, t::Int, nu::Int=20)
  y = rand(MvNormal(cormat),t)'
  z = copy(y)
  d = Chisq(nu)
  U = rand(d, size(y, 1))
  p = TDist(nu)
  for i in 1:size(cormat, 1)
    z[:,i] = cdf(p, y[:,i].*sqrt(nu./U))
  end
  z
end

"""
  u2normal(y::Matrix{Float}, covmat::Matrix{Float})

Returns matrix of multivariate data with gaussian marginals
"""
function u2normal(y::Matrix{Float64}, cormat::Matrix{Float64})
  x = copy(y)
  for i in 1:size(y, 2)
    d = Normal(0, sqrt(cormat[i,i]))
    x[:,i] = quantile(d, y[:,i])
  end
  x
end


gendata(cormat::Matrix{Float64} = [[1. 0.5];[0.5 1.]], t::Int = 10000, nu::Int = 10) =
  u2normal(tcopulagen(cormat, t, nu) , cormat)

"""
  stats(n::Int, t::Int, wsize::Int, mu::Int, m::Int, r::Int)

Raturns statistics for randmly generfated data with gaussian marginals and different copulas
"""


function getstats(t::Int = 200000, n::Int = 20, wsize::Int = 10000, mu::Int = 10,
                                                                        m::Int = 4,
                                                                        r::Int = 5)
  cormat = cormatgen(n);
  x = transpose(rand(MvNormal(cormat),t));
  c = cumulants(x, 4, 3);
  cup = c;
  k = div(t, wsize)
  cumnorms = zeros(k+1, m)
  tup = [wsize*i/t for i in 0:k]
  sk = zeros(k+1)
  ku = zeros(k+1)
  stats = zeros(k+1, 4)
  sk[1] = maximum(abs([skewness(x[:,p]) for p in 1:n]))
  ku[1] = maximum(abs([kurtosis(x[:,p]) for p in 1:n]))
  stats[1,:] = [mean(x[:,r]), var(x[:,r]), skewness(x[:,r]), kurtosis(x[:,r])]
  for j in 1:m
    cumnorms[1,j] = vecnorm(c[j])
  end
  for i in 1:k
    xup = gendata(cormat, wsize, mu)
    cup = cumulantsupdat(cup, x, xup)
    x = vcat(x, xup)[(size(xup, 1)+1):end,:]
    sk[i+1] = maximum(abs([skewness(x[:,p]) for p in 1:n]))
    ku[i+1] = maximum(abs([kurtosis(x[:,p]) for p in 1:n]))
    stats[i+1,:] = [mean(x[:,r]), var(x[:,r]), skewness(x[:,r]), kurtosis(x[:,r])]
    for j in 1:m
      cumnorms[i+1,j] = vecnorm(cup[j])
    end
    println(tup[i])
  end
  cumnorms, sk, ku, stats, tup
end
