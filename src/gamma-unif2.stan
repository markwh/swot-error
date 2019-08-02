// This one samples theta and backs out alpha. 
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
  // real<lower=0,upper=1> wfrac;
  real<lower=mu_l / nlooks, upper=mu_w / nlooks> theta;
}

// transformed parameters {
//   real<lower=0> theta;
//   
//   theta = nlooks / (wfrac * (mu_w - mu_l) + mu_l);
// }

// The model to be estimated. We model the output
model {
  y ~ gamma(nlooks, 1 / theta);
  theta ~ uniform(mu_l / nlooks, mu_w / nlooks);
}

generated quantities {
  real wfrac;
  wfrac = (theta * nlooks - mu_l) / (mu_w - mu_l);
}

