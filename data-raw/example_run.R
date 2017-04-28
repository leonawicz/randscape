library(parallel)
library(raster)
library(dplyr)
rasterOptions(chunksize=10^12,maxmemory=10^11)

setwd("/workspace/UA/mfleonawicz/projects/randscape/workspaces")
source("../code/functions.R")
load("example_inputs.RData")

n.sim <- 2
n.parsim <- 32
r.veg.list <- mclapply(1:n.parsim, function(i, ...) lapply(1:n.sim, function(x) r.veg), n.sim, r.veg)
r.age.list <- mclapply(1:n.parsim, function(i, ...) lapply(1:n.sim, function(x) r.age), n.sim, r.age)
r.spruce.list <- mclapply(1:n.parsim, setSpruceTypes, n=n.sim, r=r.spruce, slope=r.slope, aspect=r.site, mc.cores=n.parsim)
n.strikes <- 500
ignit <- 5 # Ignition factor
sens <- 10 # Sensitivity factor
set.seed(856)
n <- nlayers(b.flam)
SimBurnProbByYear <- Sim1AgeByYear <- Sim1VegByYear <- vector("list", n)

# testing...
results <- simulate(1, n.strikes=n.strikes, ignit=ignit, sens=sens,
                    b.flam=subset(b.flam, 1:3), r.burn=r.burn, r.veg=r.veg.list, r.age=r.age.list, r.spruce.type=r.spruce.list,
                    prob=fire.prob, tr.br=tr.br, ignore.veg=0,
                    Maps=T)

# Simulation version 3: year loop inside parallel sim
system.time({ results <- mclapply(1:n.parsim, simulate, n.strikes=n.strikes, ignit=ignit, sens=sens,
                                  b.flam=b.flam, r.burn=r.burn, r.veg=r.veg.list, r.age=r.age.list, r.spruce.type=r.spruce.list,
                                  prob=fire.prob, tr.br=tr.br, ignore.veg=0,
                                  Maps=T, mc.cores=n.parsim) })

SimBurnProbByYear[[z]] <- Reduce("+", lapply(results, "[[", 1))/(n.sim*n.parsim) #results$SimBurnProb

# Analyze and save results
flam.out <- as.numeric(cellStats(do.call(brick, SimBurnProbByYear), mean))
flam.in <- as.numeric(cellStats(b.flam, mean))
cor(flam.in, flam.out)^2

keep.obj <- c("fire.prob", "b.flam", "r.flam.age", "SimBurnProbByYear", "r.age", "Sim1AgeByYear", "r.veg")
save(list=keep.obj, file="example_outputs.RData")