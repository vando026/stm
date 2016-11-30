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
today <- format(Sys.time(), "%d_%b_%Y")

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

  # set the vars
  long <- dat[[x]]
  lat <- dat[[y]]
  bslong <- bsdat[[x]]
  bslat <- bsdat[[y]]
  # get the min/max ranges of the coords
  allx <- c(bslong, long)
  ally <- c(bslat, lat)
  xmin <- min(allx); xmax <- max(allx)
  ymin <- min(ally); ymax <- max(ally)

  # Set the paramters for imput dataset
  params <- list(
    x=long, y=lat,
    xrange=c(xmin, xmax),
    yrange=c(ymin, ymax))

  # Create the ppp object for input dataset
  set <- do.call(ppp, 
    c(params, list(marks = cvlvar)))

  # Now smooth over input dataset
  sfun <- Smoothfun(set, 
    weights=weightname,
    at="points")

# browser()
  # and get predicted values at all BSIntID
  mat <- matrix(ncol=4, nrow=nrow(bsdat))
  for (i in seq(nrow(bsdat))) {
    bsrow <- bsdat[i, ]
    list2env(bsrow, envir=environment())
    mat[i, 1] <- BSIntID
    mat[i, 2] <- Longitude
    mat[i, 3] <- Latitude
    mat[i, 4] <- sfun(Longitude, Latitude)
  }
  out <- as.data.frame(mat)
  names(out) <- c("BSIntID", x, y, newname)
  cat(paste('Summary of ', newname,': \n'))
  print(summary(out[[newname]]))
  return(out)
}
# debugonce(ipolate)

###############################################################################################
######################################## Analysis #############################################
###############################################################################################
dat <- read.csv(file.path(derived, "Ind_PVL_All_30Nov2016.csv")) 
bsdat <- read.csv(file.path(derived, "BSIntID_Coords.csv")) 
pvl <- ipolate(dat, bsdat, cvlname="ViralLoad", newname="PVL")
ppdv <- ipolate(dat, bsdat, cvlname="DetectViremia", newname="P_PDV")
pcti <- ipolate(dat, bsdat, cvlname="TransIndex", newname="P_TI")
hiv_prev <- ipolate(dat, bsdat, cvlname="HIVResult", newname="HIV_Prev")

# lets merge vars
cvars <- c("BSIntID", "Longitude", "Latitude")
ndat <- merge(bsdat, pvl, by=cvars, all.x=TRUE)
ndat <- merge(ndat, ppdv, by=cvars, all.x=TRUE)
ndat <- merge(ndat, pcti, by=cvars, all.x=TRUE)
ndat <- merge(ndat, hiv_prev, by=cvars, all.x=TRUE)
ndat <- ndat[order(ndat$BSIntID), ]
write.csv(ndat, file.path(Source, paste0('VL_Estimation_', today, '.csv')), row.names=FALSE)


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
