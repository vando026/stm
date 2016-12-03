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
today <- format(Sys.time(), "%d%b%Y")

###############################################################################################
######################################## Library ##############################################
###############################################################################################
library(maptools)
library(spatstat)
library(sp)


###############################################################################################
######################################## Input ################################################
###############################################################################################
shpfile <- file.path(Source,  'AC Area projected' ,'Boundaries projected.shp')
getinfo.shape(shpfile)
S <- readShapeSpatial(shpfile)
SP <- as(S, "SpatialPolygons")
W <- as(SP, "owin")

###############################################################################################
######################################## Functions ############################################
###############################################################################################
ipolate <- function(
  dat, bsdat,
  cvlname="ViralLoad", 
  newname=NULL,
  weight=1,
  sigma=NULL) {

  # Make vars for analytic dataset
  cvlvar <- dat[[cvlname]]
  # If a new name is not given
  if (is.null(newname)) 
    newname <-  cvlname

  # set the vars
  long <- dat[["Longitude"]]
  lat <- dat[["Latitude"]]
  bslong <- bsdat[["Longitude"]]
  bslat <- bsdat[["Latitude"]]
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
    at="points")

  # and get predicted values at all BSIntID
  mat <- matrix(ncol=4, nrow=nrow(bsdat))
  for (i in seq(nrow(bsdat))) {
    bsrow <- bsdat[i, ]
    mat[i, 1] <- bsrow[["BSIntID"]]
    mat[i, 2] <- bsrow[["Longitude"]]
    mat[i, 3] <- bsrow[["Latitude"]]
    mat[i, 4] <- sfun(bsrow[["Longitude"]], bsrow[["Latitude"]])
  }
  out <- as.data.frame(mat)
  names(out) <- c("BSIntID", "Longitude", "Latitude", newname)
  out[newname] <- out[newname] * weight
  cat(paste('Summary of ', newname,': \n'))
  print(summary(out[[newname]]))
  return(out)
}
# debugonce(ipolate)

###############################################################################################
######################################## Analysis #############################################
###############################################################################################
# Note for dat: You must have variable names BSIntID, Latitude, Longitude, Female, AgeGrp
dat <- read.csv(file.path(derived, "Ind_PVL_All_1Dec2016.csv")) 
bsdat <- read.csv(file.path(derived, "BSIntID_Coords.csv")) 
wdat <-  read.csv(file.path(derived, "HIV2011_weights.csv")) 


pvl <- ipolate(dat, bsdat, cvlname="ViralLoad", newname="PVL")
ppdv <- ipolate(dat, bsdat, cvlname="DetectViremia", newname="P_PDV")
pcti <- ipolate(dat, bsdat, cvlname="TransIndex", newname="P_TI")
gpvl <- ipolate(dat, bsdat, cvlname="Log10VL", newname="G_PVL")


hiv_prev <- ipolate(dat, bsdat, weight=100, cvlname="HIVResult", newname="HIV_Prev")






# lets merge vars
cvars <- c("BSIntID", "Longitude", "Latitude")
ndat <- merge(bsdat, pvl, by=cvars, all.x=TRUE)
ndat <- merge(ndat, ppdv, by=cvars, all.x=TRUE)
ndat <- merge(ndat, pcti, by=cvars, all.x=TRUE)
ndat <- merge(ndat, gpvl, by=cvars, all.x=TRUE)
ndat <- merge(ndat, hiv_prev, by=cvars, all.x=TRUE)
ndat <- ndat[order(ndat$BSIntID), ]
write.csv(ndat, file.path(Source, paste0('VL_Estimation_', today, '.csv')), row.names=FALSE)


getEst <- function(indat, bsdat, wdat, cvlname) {
  cvars <- c("BSIntID", "Longitude", "Latitude")
  out <- bsdat[, cvars]
  age <- unique(wdat$AgeGrp)
  for (age in Age) {
    for (fem in c(0, 1)) {
      prop <- subset(wdat, Female==fem & AgeGrp==age, 
        select=Proportion)
      adat <- subset(indat, Female==fem & AgeGrp==age)
      label <- paste0('dat', substring(age,1,2), '_', fem)
      print(label)
browser()
      idat <- ipolate(
        adat, bsdat, 
        weight=prop, 
        cvlname=cvlname,
        newname=label)
      out <- merge(out, idat, by=cvars, all.x=TRUE)
    }
  }
}
# debugonce(getEst)
getEst(dat, bsdat, wdat, cvlname="HIVResult")




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
