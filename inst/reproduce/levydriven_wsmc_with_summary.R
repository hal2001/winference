library(winference)
registerDoParallel(cores = 10)
rm(list = ls())
setmytheme()

set.seed(13)

target <- get_levydriven()

# number of observations
prefix <- ""

load(file = paste0(prefix, "levydrivendata.RData"))

nobservations <- 10000
obs <- obs[1:nobservations]

lagvalue <- 1
# #
lag_obs <- create_lagmatrix(matrix(obs, nrow = 1), lagvalue)
lag_obs <- lag_obs[,seq(from=1, to=ncol(lag_obs), by=2)]
compute_hilbert <- get_hilbert_to_y(lag_obs)

filename <- paste0(prefix, "levydriven.n", nobservations, ".lag", lagvalue, ".wsmc.hilbert.RData")
# filename <- paste0(prefix, "levydriven.n", nobservations, ".lag", lagvalue, ".wsmc.swap.RData")
load(file = filename)


f <- function(dataset){
  return(sum(acf(dataset^2, plot = F, lag.max = 50)$acf[,,1][1:50]))
}
f_obs <- f(obs)
fs <- as.numeric(foreach(i = 1:results$param_algo$nthetas, .combine = c) %dorng% {
  f(results$latest_y[[i]])
})
hist(fs, nclass = 30)
abline(v = f_obs)

thetas <- tail(results$thetas_history, 1)[[1]]
plot(thetas[,5], fs)
summary(tail(results$distances_history, 1)[[1]])
threshold1 <- tail(results$threshold_history, 2)[[1]]

compute_d1 <- results$compute_d
compute_d_summary <- function(z){
  first_part <- compute_d1(z)
  if (first_part > threshold1){
    return(Inf)
  } else {
    return(abs(f(z) - f_obs))
  }
}

filename2 <- paste0(prefix, "levydriven.n", nobservations, ".lag", lagvalue, ".wsmc.hilbert.summary.RData")

ds <- as.numeric(foreach(i = 1:results$param_algo$nthetas, .combine = c) %dorng% {
  compute_d_summary(results$latest_y[[i]])
})
results2 <- results
results2$compute_d <- compute_d_summary
results2$param_algo$threshold <- max(ds)
results2$distances_history[[length(results2$distances_history)]] <- ds
results2$param_algo$proposal <- mixture_rmixmod()
#
results2 <- wsmc_continue(results2, savefile = filename2, maxtime = 60*60)
# load(filename2)
# library(Rmixmod)
# results2 <- wsmc_continue(results, savefile = filename2, maxtime = 2*60*60)
#
library(gridExtra)
grid.arrange(plot_threshold_time(results2) + scale_y_log10(), plot_ncomputed(results2))
#
plot_bivariate(results2, 4, 5)
plot_marginal(results2, 1)
plot_marginal(results2, 2)
plot_marginal(results2, 4) + scale_x_log10()
plot_marginal(results2, 5) + scale_x_log10()

# names(results2)
# results2$param_algo$proposal$param_update()
# results2$thetas_history %>% length
thetas <- results2$thetas_history[[results2$thetas_history %>% length]]
fit <- mixmodCluster(data = data.frame(thetas), nbCluster = 5, dataType = "quantitative")
results2$param_algo$proposal$r
results2$param_algo$proposal$d


##

## timings
library(microbenchmark)
microbenchmark(target$simulate(true_theta), times = 100)
microbenchmark(compute_d_summary(target$simulate(true_theta)), times = 100)

