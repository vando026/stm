## Description: Make plots for CVL analysis
## Project: CVL
## Author: AV / Created: 09Apr2016 

library(readstata13)
library(foreign)
library(plotrix)

###########################################################################################################
######################################## Functions ########################################################
###########################################################################################################
Ratio <- function(Age, dat) {
  out <- with(dat, round(mean[Age==Age & Data=="CVL"]/mean[Age==Age & Data=="FVL"], 2))
  out
}

# Rpar <- par(no.readonly = TRUE)
cols <- c('dodgerblue4', 'indianred4')
plotCVL <- function(dat, main, cex2=1) {
  
  # Make labels
  len <- length(unique(dat$Age))/2
  agelab <- paste0(seq(15, 45, 5), "-")
  scols <- c(rep(cols[1], len),rep(cols[2], len))
  scex <- c(rep(1, len), rep(cex2, len))

  par(mar=c(0.1, 1.0, 0.8, 2))  
  with(dat, plotCI(Age, mean, ui=ub, li=lb, xlim=c(0, 6.5), 
    xlab="", ylab="", xaxt="n", yaxt="n", axes=FALSE, scol=scol,
    lwd=2, cex=scex, pch=21, pt.bg=cols[1], col=scols, main=main))
    axis(side=1, at = seq(0, 6, 1), labels = agelab)
  with(dat[dat$Data=="CVL", ], text(Age, mean, Ratio, pos=4, cex=0.8))
}

###########################################################################################################
######################################## bring in Data ####################################################
###########################################################################################################
root  =  file.path(Sys.getenv("USERPROFILE"), "Dropbox/AfricaCentre/Projects/CommunityVL/")
derived  =  file.path(root, "derived")
output  =  file.path(root, "output")

# Cut off UB for fem gmn plot
gmn <- read.dta(file.path(derived, "gmean2011.dta"), convert.factors=FALSE) 

fem_gmn <- subset(gmn, Female==1)
fem_gmn$Ratio <- Ratio(Age=Age, dat=fem_gmn)
fem_gmn$ub <- with(fem_gmn, ifelse(ub > 30000, ub - 10000, ub))
# Add to Age to offset the graph
fem_gmn <- transform(fem_gmn, Age = ifelse(Data=="FVL", Age + 0.30, Age))

# Cut off UB for men gmn plot
men_gmn <- subset(gmn, Female==0)
men_gmn$Ratio <- Ratio(Age=Age, dat=men_gmn)
men_gmn$ub <- with(men_gmn, ifelse(ub > 90000, ub - 30000, ub))
men_gmn <- transform(men_gmn, Age = ifelse(Data=="FVL", Age + 0.30, Age))


###########################################################################################################
######################################## Make plots #######################################################
###########################################################################################################
png(file=file.path(output, "VL_gmn_2011.png"), 
  units="in", width=12, height=8, pointsize=14, res=120, type="cairo")
par(oma=c(0.1, 3.5, 1,0.2))  
nf <- layout(matrix(c(1,2,3,3), ncol=2, byrow=TRUE),
  heights=c(4.0, 1.0))
layout.show(nf)

plotCVL(fem_gmn, main="Females", cex2=0.6)
axis(side=2, at = seq(0, 30000, 5000), labels = c(0, 5000, 10000, 15000, 20000, 25000, 40000))
axis.break(axis=2, breakpos=27500, style = "slash", brw=0.02)

plotCVL(men_gmn, main="Males", cex2=0.6)
axis(side=2, at = seq(0, 60000, 10000), labels = c(seq(0, 50000, 10000), 90000))
axis.break(axis=2, breakpos=57500, style = "slash", brw=0.02)

plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", c("PVL mean and 95% CI", "FVL mean and 95% CI"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(0, 0.2))
  
mtext("Viral load copies/ml", line=2, 
  cex=1, side=2, outer=TRUE, at=0.6)
mtext("Age", line=-6, side=1, outer=TRUE, at=0.48, cex=1)
dev.off()


###########################################################################################################
######################################## Prop #############################################################
###########################################################################################################
over50 <- read.dta(file.path(derived, "over50_2011.dta"), convert.factors=FALSE) 

fem50 <- subset(over50, Female==1)
fem50$Ratio <- Ratio(Age=Age, dat=fem50)
fem50 <- transform(fem50, Age = ifelse(Data=="FVL", Age + 0.30, Age))

men50 <- subset(over50, Female==0)
men50$Ratio <- Ratio(Age=Age, dat=men50)
men50 <- transform(men50, Age = ifelse(Data=="FVL", Age + 0.30, Age))

png(file=file.path(output, "VL_50_2011.png"), 
  units="in", width=12, height=8, pointsize=14, res=120, type="cairo")
par(oma=c(0.1, 3.5, 1,0.2))  
nf <- layout(matrix(c(1,2,3,3), ncol=2, byrow=TRUE),
  heights=c(4.0, 1.0))

plotCVL(fem50, main="Females")
axis(side=2, at = seq(0, 0.5, 0.1))

plotCVL(men50, main="Males")
axis(side=2, at = seq(0, 0.8, 0.2), label=TRUE)

plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", c("PVL proportion and 95% CI", "FVL proportion and 95% CI"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(0, 0.2))
  
mtext("Proportion viral load >50000 copies/ml", line=2, 
  cex=1, side=2, outer=TRUE, at=0.6)

mtext("Age", line=-6, side=1, outer=TRUE, at=0.48, cex=1)
dev.off()
