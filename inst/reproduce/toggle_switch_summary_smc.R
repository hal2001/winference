### READ: Make sure Bonassi et al.'s summary statistic has been generated before loading it.
### To generate it, run the script in toggle_switch_summary.R. Once the files generated by that script have
### been saved, generate the summary statistic by sourcing toggle_switch_load_summary.R as below. 
### Make sure that the parameter settings in toggle_switch_load_summary.R are the same as those in
### toggle_switch_summary.R, and that appropriate file paths are used.

library(winference)
registerDoParallel(cores = detectCores())
rm(list = ls())
setmytheme()
set.seed(11)

prefix = ""

target <- get_toggleswitch()

# number of observations
nobservations <- 2000
load(file = paste0(prefix,"toggleswitchdata.RData"))
obs <- obs[1:nobservations]

#Load summary stat
source(paste0(prefix,"toggle_switch_load_summary.R"))

s_obs = summary.stat(obs)

#function to compute distance between observed data and data generated given theta
compute_d <- function(y){
  s_fake = summary.stat(y)
  dist = sqrt(sum((s_obs-s_fake)^2))
  return(dist)
}

target$simulate <- function(theta) matrix(target$robservation(nobservations, theta, target$parameters, target$generate_randomness(nobservations)), nrow = 1)

#test
y_sim <- target$simulate(target$rprior(1, target$parameters))
compute_d(y_sim)

param_algo <- list(nthetas = 2048, nmoves = 1, proposal = mixture_rmixmod(),
                   minimum_diversity = 0.5, R = 2, maxtrials = 1000)

filename <- paste0(prefix,"toggleswitchw.summary.smc.n", nobservations, ".RData")
#results <- wsmc(compute_d, target, param_algo, savefile = filename, maxsimulation = 1e6)
load(filename)
#results <- wsmc_continue(results, savefile = filename, maxsim = (1e6 - 166035))


