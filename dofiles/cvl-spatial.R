## Description: Attempt spatial analysis
## Project:  CVL
## Author: AV / Created: 29Nov2016 

###############################################################################################
######################################## File paths ###########################################
###############################################################################################
dropbox <- "Dropbox/AfricaCentre/Projects/CommunityVL"
fpath <- file.path(Sys.getenv("USERPROFILE"), dropbox )
dofile <- file.path(fpath, "dofiles")
Source <- file.path(fpath, "source")
derived <- file.path(fpath, "derived")
output  <- file.path(fpath, "output")

###############################################################################################
######################################## Library ##############################################
###############################################################################################
library(spatstat)


###############################################################################################
######################################## Functions ############################################
###############################################################################################
ipolate <- function(
  dat, bsdat,
  x="Longitude",
  y="Latitude",
  cvlname="ViralLoad", 
  newname=NULL,
  weightname=NULL,
  sigma=NULL) {

  # Make vars for analytic dataset
  cvlvar <- dat[[cvlname]]
  if (!is.null(weightname)) 
    weightname <- dat[[weightname]]
  if (is.null(newname)) 
    newname <-  cvlname

  doCords <- function(
    cdat, xx=x, yy=y) {
    # Get range of coords
    long <- cdat[[xx]]
    lat <- cdat[[yy]]
    xmin <- min(long); xmax <- max(long)
    ymin <- min(lat); ymax <- max(lat)
    cout <- list(
      long=long, lat=lat, 
      xmin=ymin, xmax=xmax,
      ymin=ymin, ymax=ymax)
    return(cout)
  }
  #get coords for input dataset
  ds <- doCords(dat) 
  #get coords for predicted dataset
  bs <- doCords(bsdat) 
  
  # Set the paramters for imput dataset
  ds_params <- list(
    x=ds$long, y=ds$lat,
    xrange=c(ds$xmin, ds$xmax),
    yrange=c(ds$ymin, ds$ymax))

  # Set parameters for predicted dataset
  bs_params <- list(
    x=bs$long, y=bs$lat,
    xrange=c(bs$xmin, bs$xmax),
    yrange=c(bs$ymin, bs$ymax))

  # Create the ppp object for input dataset
  ds_set <- do.call(ppp, 
    c(ds_params, list(marks = cvlvar)))

  # Create ppp object for predicted dataset
  bs_set <- do.call(ppp, bs_params)

  # Now smooth over input dataset
  sfun <- Smoothfun(ds_set, 
    weights=weightname,
    at="points")

  # and get predicted values at all BSIntID
  bs_predict <- sfun(coords(bs_set))
  names(bs_predict) <- newname
  cat(paste('Summary of ', newname,': \n'))
  print(summary(bs_predict))
  out <- cbind(coords(bs_set), bs_predict)
  return(out)
}
debugonce(ipolate)

###############################################################################################
######################################## Analysis #############################################
###############################################################################################
dat <- read.csv(file.path(derived, "Ind_PVL_All_30Nov2016.csv")) 
bsdat <- read.csv(file.path(derived, "BSIntID_Coords.csv")) 
pvl <- ipolate(dat, bsdat, cvlname="ViralLoad", newname="PVL")
ppdv <- ipolate(dat, cvlname="DetectViremia", newname="P_PDV")
pcti <- ipolate(dat, cvlname="TransIndex", newname="P_TI")
hiv_prev <- ipolate(dat, cvlname="HIVResult", newname="HIV_Prev")

# lets merge vars
cvars <- c("Latitude", "Longitude")
ndat <- merge(bsdat, pvl, by=cvars, all.x=TRUE)
ndat <- ndat[order(ndat$BSIntID), ]



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
