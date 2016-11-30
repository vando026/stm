## Description: Attempt spatial analysis
## Project:  CVL
## Author: AV / Created: 29Nov2016 

###############################################################################################
######################################## File paths ###########################################
###############################################################################################
fpath <- file.path(Sys.getenv("USERPROFILE"), 
  "Dropbox/AfricaCentre/Projects/CommunityVL")
dofile <- file.path(fpath, "dofiles")
Source <- file.path(fpath, "source")
derived <- file.path(fpath, "derived")
output  <- file.path(fpath, "output")

###############################################################################################
######################################## Library ##############################################
###############################################################################################
library(spatstat)


###############################################################################################
######################################## Data #################################################
###############################################################################################
dat <- read.csv(file.path(derived, "Ind_PVL_All_29Nov2016.csv")) 
xmin <- min(dat$Longitude)-0.1
xmax <- max(dat$Longitude)+0.1
ymin <- min(dat$Latitude)-0.1
ymax <- max(dat$Latitude)+0.1

params <- list(
  x=dat$Longitude, y=dat$Latitude,
  xrange=c(xmin, xmax),
  yrange=c(ymin, ymax))

setPPDV <- do.call(ppp, c(params, list(marks = dat$Over1500)))
funPPDV <- Smoothfun(setPPDV, at="points")
PPDV=funPPDV(coords(setPPDV))

ppdv <- cbind(coords(setPPDV), PPDV)
summary(dat$PPDV)


setCTI <- do.call(ppp, c(params, list(marks = dat$Quin)))


ipolate <- function(dat,
  x="Longitude",
  y="Latitude",
  cvlname="ViralLoad", 
  weightname=NULL,
  sigma=NULL) {

  # Make vars
  long <- dat[[x]]
  lat <- dat[[y]]
  cvlname <- dat[[cvlname]]
  if (!is.null(weightname)) 
    weightname <- dat[[weightname]]

  # Get range of coords
  xmin <- min(long)-0.1
  xmax <- max(long)+0.1
  ymin <- min(lat)-0.1
  ymax <- max(lat)+0.1
  
  # Set the paramters for ppp object
  params <- list(
    x=long, y=lat,
    xrange=c(xmin, xmax),
    yrange=c(ymin, ymax))

  # Create the ppp object
  set <- do.call(ppp, 
    c(params, 
    list(marks = cvlname)))

  sfun <- Smoothfun(set, 
    weights=weightname,
    at="points")
  # predicted values at the coords
  predict <- sfun(coords(set))
  out <- cbind(coords(set), predict)
  return(out)
}
debugonce(ipolate)
ipolate(dat)

}
ipolate(dat)


  # Now make parameters for ppp object
}



###############################################################################################
######################################## Eg code ##############################################
###############################################################################################
data(longleaf)
npoints(longleaf)
summary(longleaf$x)
summary(longleaf$y)
datl <- as.data.frame(longleaf)
head(datl)

# Smooth and then obtain smoothed point at location
est <- Smoothfun(longleaf, sigma=0)
est(199.3, 10)
est <- Smoothfun(longleaf, sigma=10)
est(199.3, 10)

f <- Smoothfun(longleaf)
f
f(120, 80)
f(coords(longleaf))
