###################################
# calculating test statistics for different
# null hypothesis alongside with permutations
##################################"
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(ggplot2)
library(foreach)
library(gridExtra)
library(reshape2)
theme_set(theme_bw())


dat <- read.table("../data/data_xy_colombia_20200327.txt", header = TRUE)
#dat <- read.table("../data/data_xy_colombia_20200616.txt", header = TRUE)
dat <- dat[order(dat$PolygonID),]
n <- nrow(dat)
nt <-  length(unique(dat$Year))     #19
ns <- length(unique(dat$PolygonID)) #11350

c <- dat$nr_fatalities>0 # binary conflict indicator
f <- dat$xFor_ge25 # forest
fl <- dat$FL_km # forestloss
popdens <- dat$PopDens
roaddist <- dat$RoadDist

############ Define Neighborhood ############
library(tidyverse)
dat$X <- dat$nr_fatalities>0

poligons <- dat %>% group_by(PolygonID , lon, lat, country_name ) %>% summarise(count=n())

poligons$lat_rel <- (poligons$lat-min(poligons$lat))/10000
poligons$lon_rel <- (poligons$lon-min(poligons$lon))/10000
#poligons$lat_id <- poligons %>% group_indices(lat_rel)
#poligons$lon_id <- poligons %>% group_indices(lon_rel)

coordinates <- poligons[,6:7]

distances2 <- fields::rdist(as.matrix(coordinates)) #computes euclidean distances between all the spatail grid elements 11350 x 11350

dat$mean_X_prev <- rep(NA,n)
dat$max_X_prev <- rep(NA,n)

min.dist <-1.5 #how far away each tile is at 1

for (i in (1:nrow(poligons))) { 
  #i=1
  neig<-which(distances2[-i,i] <= min.dist)
  aux <- poligons$PolygonID[neig]
  #a<-dat[dat$PolygonID %in% aux,]
  
  neighbours <- (dat %>% subset(PolygonID %in% aux) %>% group_by(Year) %>% 
    summarise(mean_X = mean(X), max_X = max(X)))
  neighbours <- rbind(c(0,0,0),neighbours)[-nrow(neighbours)-1,]
  
  #save values
  a<-which(dat$PolygonID == poligons$PolygonID[i]) 
  dat$mean_X_prev[a] <- neighbours$mean_X
  dat$max_X_prev[a] <-neighbours$max_X
}

rm(distances2, poligons)

prev_c<-dat$mean_X_prev
prev_c_bin <- dat$max_X_prev
############ absolute forest loss ############ 

# average deforestation rate
mean(fl,na.rm=1) # 0.193
# average deforestation at conflict
mean(fl[c],na.rm=1) # 0.266
# average deforestation NOT at conflict
mean(fl[!c],na.rm=1) # 0.193
# t-test
t.test(fl~c)$p.value # 8.416e-10 , H0: true difference in means is equal to 0
## therefore there is a difference  in deforestation in quadrants with and without conflicts

t.test(fl~prev_c_bin)$p.value # 5.382379e-58 , H0: true difference in means is equal to 0
## therefore there is a difference  in deforestation in quadrants with and without conflicts


########### Network Inference #########
devtools::install_github("isabelfulcher/autognet", ref = "nuterms")


########### test statistics ###########

##########
## no confounder
##########
#'@param c, binary varaible, conflict or not conflict
#'@param fl, continus variable, deforestation
#'@return diference of means (c - !c)
ts.noconf <- function(c,fl){
  mean(fl[c],na.rm=1)-mean(fl[!c],na.rm=1)
}

##########
## only confounder: population density
##########
n.popdens.quant <- 100
qseq <- quantile(popdens, prob = seq(0,1-1/n.popdens.quant,1/n.popdens.quant)) # 100-quantiles of pop density
w <- sapply(1:n, function(i) max(which(popdens[i]-qseq >=0))) # assign each data point to a quantile index
popdens.quantile.groups <- lapply(1:n.popdens.quant, function(i) which(w==i)) # lists with indices of data points belonging to respective quantile group
# removing quantile groups without conflict
n.confl.popdens.quantile.groups <- sapply(popdens.quantile.groups, function(i) sum(c[i])) 
popdens.quantile.groups <- popdens.quantile.groups[n.confl.popdens.quantile.groups>0]
n.popdens.quant <- length(popdens.quantile.groups) #77 groups of 100
zz <- unlist(popdens.quantile.groups) # 171916 datapoints of 215650

#'@param c, binary varaible, conflict or not conflict
#'@param fl, continus variable, deforestation %
#'@return diference of means (c - !c) weighted per quantile group
ts.popdens <- function(c,fl){
  # difference in sample averages per quantile group
  t <- sapply(1:n.popdens.quant, function(i){
    ind.qi <- popdens.quantile.groups[[i]]
    confl.qi <- intersect(which(c), ind.qi)
    noconfl.qi <- intersect(which(!c), ind.qi)
    mean(fl[confl.qi],na.rm=1) - mean(fl[noconfl.qi],na.rm=1)
  })
  # remove possible NAs
  w.not.NA <- which(!is.na(t))
  t <- t[w.not.NA]
  popdens.quantile.groups <- popdens.quantile.groups[w.not.NA]
  
  # empirical distribution of discretized population density
  weights <- sapply(popdens.quantile.groups, length) # weigtin per number of cases in each gorup
  weights <- weights / sum(weights)
  sum(t*weights)
}

##########
## only confounder: distance to road
##########
n.roaddist.quant <- 100
qseq <- quantile(roaddist, prob = seq(0,1-1/n.roaddist.quant,1/n.roaddist.quant)) # quantiles
w <- sapply(1:n, function(i) max(which(roaddist[i]-qseq >=0))) # assign each data point to a quantile index
roaddist.quantile.groups <- lapply(1:length(qseq), function(i) which(w==i)) # lists with indices of data points belonging to respective quantile group
n.confl.roaddist.quantile.groups <- sapply(roaddist.quantile.groups, function(i) sum(c[i])) # removing quantile groups without conflict
roaddist.quantile.groups <- roaddist.quantile.groups[n.confl.roaddist.quantile.groups>0]
n.roaddist.quant <- length(roaddist.quantile.groups)

#'@param c, binary varaible, conflict or not conflict
#'@param fl, continus variable, deforestation %
#'@return diference of means (c - !c) weighted per quantile group
ts.roaddist <- function(c,fl){
  # difference in sample averages per quantile group
  t <- sapply(1:n.roaddist.quant, function(i){
    ind.qi <- roaddist.quantile.groups[[i]]
    confl.qi <- intersect(which(c), ind.qi)
    noconfl.qi <- intersect(which(!c), ind.qi)
    mean(fl[confl.qi],na.rm=1) - mean(fl[noconfl.qi],na.rm=1)
  })
  # remove possible NAs
  w.not.NA <- which(!is.na(t))
  t <- t[w.not.NA]
  roaddist.quantile.groups <- roaddist.quantile.groups[w.not.NA]
  weights <- sapply(roaddist.quantile.groups, length) # empirical distribution of discretized population density
  weights <- weights / sum(weights)
  sum(t*weights)
}

##########
## LSCM (Hidden variable)
##########
cmat <- matrix(c, nrow=nt, ncol=ns) # [#periods, #locations] 
cmatt <- matrix(rep(colSums(cmat),each=nt), nrow=nt, ncol=ns) # matix with the sum of confilcts per location
ind <- c(cmatt)>0 & c(cmatt) < nt # true for all locations containing conflicts as well as no conflicts

ts.lscm <- function(c, fl){
  # removing irrelevant data 
  c <- c[ind] 
  fl <- fl[ind]
  ns.ind <- length(c)/nt #number of locations with variabilty in conflict
  
  dfa <- foreach(s=1:ns.ind, .combine = "c") %do% {
    w <- (s-1)*nt + 1:nt  # select each location
    cs <- c[w]            # 
    fls <- fl[w]
    w0 <- which(!cs & !is.na(fls))
    w1 <- which(cs & !is.na(fls))
    mean(fls[w1])-mean(fls[w0])
  }
  mean(dfa,na.rm=1)
}

### Results: Avg.differences selecting different groups ###############
(ts.noconf.data <- ts.noconf(c,fl))     # 0.073   #without groupping 
(ts.popdens.data <- ts.popdens(c,fl))   # 0.038   #by groupping by population density quantile
(ts.roaddist.data <- ts.roaddist(c,fl)) # 0.039   #by groupping by roaddistiance quantile 
(ts.lscm.data <- ts.lscm(c,fl))         # -0.0180 #by groupping by location

########################

############ resampling procedures ############
##-> procedures tha resample only the fl varible so the keeping the other covariables in place
##########
## no confounder
##########
res.noconf <- function(fl){
  # random resampling
  ind.res <- sample(1:n, replace = FALSE)
  fl[ind.res]
}
##########
## only conf: population density
##########
res.popdens <- function(fl){
  # resampling within quantile groups of popdens
  fl.res <- fl
  for(i in 1:n.popdens.quant){
    ind.qi <- popdens.quantile.groups[[i]]
    ind.qi.res <- sample(ind.qi, replace = FALSE)
    fl.res[ind.qi] <- fl[ind.qi.res]
  }
  fl.res
}
##########
## only conf: distance to road
##########
res.roaddist <- function(fl){
  # resampling within quantile groups of roaddist
  for(i in 1:n.roaddist.quant){
    ind.qi <- roaddist.quantile.groups[[i]]
    ind.qi.res <- sample(ind.qi, replace = FALSE) # -> n=?
    fl[ind.qi] <- fl[ind.qi.res]
  }
  fl
}

##########
## LSCM
##########
res.lscm <- function(fl){
  # resampling within the same location (i.e., values of the hidden confounders)
  #generate all the indexes with the times changed for each location
  time.res <- sample(1:nt, replace=FALSE)
  ind.res <- nt*rep(0:(ns-1), each=nt) + rep(time.res, ns)
  fl[ind.res]
}

########################## resampling test statistics ##########################

#'@param c, binary varaible, conflict or not conflict
#'@param fl, continous variable, deforestation %
#'@param test.stat, function that comparates two samples means
#'@param resampler, function that genertes new samples fomr the data
#'@return diference of means (c - !c) weighted per quantile group
ts.resampler <- function(c, fl, test.stat, resampler){
  foreach(b = 1:B, .combine = "c") %do% {
    print(paste(b, " out of ", B))
    set.seed(b)
    fl.res <- resampler(fl)
    test.stat(c,fl.res)
  }
}

B <- 999
ts.noconf.res <- ts.resampler(c,fl,ts.noconf, res.noconf)
ts.popdens.res <- ts.resampler(c,fl,ts.popdens, res.popdens)
ts.roaddist.res <- ts.resampler(c,fl,ts.roaddist, res.roaddist)
ts.lscm.res <- ts.resampler(c,fl,ts.lscm, res.lscm)

#Plotinng 
xmin <- min(ts.noconf.data, 
            ts.popdens.data, 
            ts.roaddist.data, 
            ts.lscm.data, 
            ts.noconf.res, 
            ts.popdens.res, 
            ts.roaddist.res, 
            ts.lscm.res)
xmax <- max(ts.noconf.data, 
            ts.popdens.data, 
            ts.roaddist.data, 
            ts.lscm.data, 
            ts.noconf.res, 
            ts.popdens.res, 
            ts.roaddist.res, 
            ts.lscm.res)

par(mfrow=c(1,4))
hist(ts.noconf.res, breaks = 20, xlim=c(xmin, xmax))
abline(v=ts.noconf.data, col="red",lwd=3)
hist(ts.popdens.res, breaks = 20, xlim=c(xmin, xmax))
abline(v=ts.popdens.data, col="red",lwd=3)
hist(ts.roaddist.res, breaks = 20, xlim=c(xmin, xmax))
abline(v=ts.roaddist.data, col="red",lwd=3)
hist(ts.lscm.res, breaks = 20, xlim=c(xmin, xmax))
abline(v=ts.lscm.data, col="red",lwd=3)

res.frame <- data.frame(ts = c(ts.noconf.data, ts.noconf.res, 
                               ts.popdens.data, ts.popdens.res, 
                               ts.roaddist.data, ts.roaddist.res, 
                               ts.lscm.data, ts.lscm.res), 
                        b = rep(0:B, 4), 
                        model = rep(c("noconf", "popdens", "roaddist", "lscm"), 
                                    each = B+1)
)

write.table(res.frame, "resampling_data.txt", quote = FALSE)
