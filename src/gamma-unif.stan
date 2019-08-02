//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N;
  vector[N] y;
  real<lower=0> mu_l;
  real<lower=mu_l> mu_w;
  int<lower=1> nlooks;
}

// The parameters accepted by the model. Our model
// accepts two parameters 'mu' and 'sigma'.
parameters {
  real<lower=0,upper=1> wfrac;
  // real<lower=0> sigma;
}

transformed parameters {
  real<lower=0> theta;
  
  theta = (wfrac * (mu_w - mu_l) + mu_l) / nlooks;
}

// The model to be estimated. We model the output
model {
  y ~ gamma(nlooks, 1 / theta);
  wfrac ~ uniform(0, 1);
}

