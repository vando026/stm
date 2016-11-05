## Description: Make plots for CVL analysis
## Project: CVL
## Author: AV / Created: 09Apr2016 

library(readstata13)
library(foreign)
library(plotrix)

###########################################################################################################
######################################## Functions ########################################################
###########################################################################################################
Ratio <- function(dat) {
  out <- with(dat, round(mean[Female==0]/mean[Female==1], 2))
  out
}

# Rpar <- par(no.readonly = TRUE)
cols <- c('dodgerblue4', 'indianred4')
plotCVL <- function(dat, main, cols, ylim2, ylab2="") {
  
  # Make labels
  len <- length(unique(dat$Age))/2
  agelab <- paste0(seq(15, 45, 5), "-")
  scols <- c(rep(cols[1], len),rep(cols[2], len))

  # par(mar=c(4.2, 3.0, 5, 2))  
  with(dat, plotCI(Age, mean, ui=ub, li=lb, ylim=ylim2, xlim=c(-0.1, 6.5), 
    xlab="Age Groups", ylab=ylab2, xaxt="n", yaxt="n", axes=FALSE, 
    lwd=2, cex=1, pch=16, col=scols, main=main))
    axis(side=1, at = seq(0, 6, 1), labels = agelab)
}

###########################################################################################################
######################################## bring in Data ####################################################
###########################################################################################################
root  =  file.path(Sys.getenv("USERPROFILE"), "Dropbox/AfricaCentre/Projects/CommunityVL/")
derived  =  file.path(root, "derived")
output  =  file.path(root, "output")

gmn <- read.dta13(file.path(derived, "gmean2011.dta"), convert.factors=FALSE) 
# Add to Age to offset the graph
gmn <- transform(gmn, Age = ifelse(Female==1, Age + 0.15, Age - 0.15))
fmn <- subset(gmn, Data=="FVL")
fmn$ub <- with(fmn, ifelse(ub > 19000, ub - 12000, ub))
gmn <- subset(gmn, Data=="CVL")
gmn$ub <- with(gmn, ifelse(ub > 90000, ub - 30000, ub))
transform(gmn, Ratio=Ratio(gmn))
transform(fmn, Ratio=Ratio(fmn))

###########################################################################################################
######################################## Make plots #######################################################
###########################################################################################################
png(file=file.path(output, "MVL_mn_2011.png"), 
  units="in", width=8, height=8, pointsize=14, res=300, type="cairo")
plotCVL(gmn, main="",
  ylab2="Geometric mean viral load (copies/mL)", cols=cols, ylim2=c(0, 65000))
axis(side=2, at = seq(0, 60000, 10000), 
  labels = formatC(c(seq(0, 50000, 10000), 90000), format="d", big.mark=" "))
axis.break(axis=2, breakpos=55000, style = "slash", brw=0.02)
legend("top", c("Males", "Females"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()

png(file=file.path(output, "FMVL_mn_2011.png"), 
  units="in", width=8, height=8, pointsize=14, res=300, type="cairo")
plotCVL(fmn, main="",
  ylab2="Geometric mean viral load (copies/mL)", cols=cols, ylim2=c(0, 8000))
axis(side=2, at = seq(0, 8000, 2000), labels=c(0, 2000, 4000, 6000, 20000))
axis.break(axis=2, breakpos=6500, style = "slash", brw=0.02)
legend("top", c("Males", "Females"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()

###########################################################################################################
######################################## Prop #############################################################
###########################################################################################################
over50 <- read.dta(file.path(derived, "over50_2011.dta"), convert.factors=FALSE) 
over50 <- transform(over50, Age = ifelse(Female==1, Age - 0.15, Age + 0.15))
p50 <- subset(over50, Data=="CVL")
f50 <- subset(over50, Data=='FVL')
transform(p50, Ratio=Ratio(p50))

png(file=file.path(output, "P50.png"), 
  units="in", width=8, height=8, pointsize=14, res=300, type="cairo")
plotCVL(p50, 
  main="",
  ylim2=c(0, 1),
  ylab="Proportion  >50,000 copies/mL" , cols=cols)
axis(side=2, at = seq(0, 1, 0.2))
legend("top", 
  c("Males", "Females"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()

png(file=file.path(output, "F50.png"), 
  units="in", width=8, height=8, pointsize=14, res=300, type="cairo")
plotCVL(p50, main="",
  ylim2=c(0,1),
  ylab="Proportion >50,000 copies/mL ", cols=cols)
axis(side=2, at = seq(0, 1, 0.2))
legend("top", 
  c("Males", "Females"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()


###########################################################################################################
###################  WARNING MAKE SURE THIS IS THE NO ART DATASET #########################################
###########################################################################################################
over50_na <- read.dta(file.path(derived, "over50_2011.dta"), convert.factors=FALSE) 
# Add to Age to offset the graph
over50_na <- transform(over50_na, Age = ifelse(Data=="CVL", Age + 0.15, Age - 0.15))
over50_na$ub <- with(over50_na, ifelse(ub > 1, 1, ub))

fem50_na <- subset(over50_na, Female==1)
fem50_na$Ratio <- Ratio(Age=Age, dat=fem50_na)

# Cut off UB for men gmna plot
men50_na <- subset(over50_na, Female==0)
men50_na$Ratio <- Ratio(Age=Age, dat=men50_na)

png(file=file.path(output, "VL_50_2011_NA.png"), 
  units="in", width=12, height=8, pointsize=14, res=120, type="cairo")
par(oma=c(0.1, 3.5, 1,0.2))  
nf <- layout(matrix(c(1,2,3,3), ncol=2, byrow=TRUE),
  heights=c(4.0, 1.0))

plotCVL(fem50_na, main="Females (Pre-ART)")
axis(side=2, at = seq(0, 0.7, 0.1))

plotCVL(men50_na, main="Males (Pre-ART)")
axis(side=2, at = seq(0, 1.0, 0.2), label=TRUE)

plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", c("PVL proportion and 95% CI", "FVL proportion and 95% CI"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(0, 0.2))
  
mtext("Proportion viral load >50000 copies/ml", line=2, 
  cex=1, side=2, outer=TRUE, at=0.6)

mtext("Age", line=-6, side=1, outer=TRUE, at=0.48, cex=1)
dev.off()

###########################################################################################################
###########################################################################################################
###########################################################################################################
gmn <- read.dta(file.path(derived, "gmean2011.dta"), convert.factors=FALSE) 
gmn <- transform(gmn, Age = ifelse(Data=="CVL", Age + 0.15, Age - 0.15))

fem_gmn <- subset(gmn, Female==1)
fem_gmn$Ratio <- Ratio(Age=Age, dat=fem_gmn)
fem_gmn$ub <- with(fem_gmn, ifelse(ub > 1e5, ub - 9e4, ub))

# Cut off UB for men gmn plot
men_gmn <- subset(gmn, Female==0)
men_gmn$Ratio <- Ratio(Age=Age, dat=men_gmn)
men_gmn$ub <- with(men_gmn, ifelse(ub > 1e6, ub - 1e6, ub))

png(file=file.path(output, "VL_gmn_2011_NA.png"), 
  units="in", width=12, height=8, pointsize=14, res=120, type="cairo")
par(oma=c(0.1, 3.5, 1,0.2))  
nf <- layout(matrix(c(1,2,3,3), ncol=2, byrow=TRUE),
  heights=c(4.0, 1.0))
layout.show(nf)

plotCVL(fem_gmn, main="Females (Pre-ART)", cex2=0.6)
axis(side=2, at = seq(0, 60000, 10000), 
  labels = formatC(c(seq(0, 50000, 10000),  150000), format="d", big.mark=" "))
axis.break(axis=2, breakpos=55000, style = "slash", brw=0.02)

plotCVL(men_gmn, main="Males (Pre-ART)", cex2=0.6)
axis(side=2, at = seq(0, 1.5e5, 25000), 
  labels = formatC(c(seq(0, 125000, 25000), 1.5e6), format="d", big.mark=" "))
axis.break(axis=2, breakpos=1.4e5, style = "slash", brw=0.02)

plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", c("PVL mean and 95% CI", "FVL mean and 95% CI"),
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(0, 0.2))
  
mtext("Viral load copies/ml", line=2, 
  cex=1, side=2, outer=TRUE, at=0.6)
mtext("Age", line=-6, side=1, outer=TRUE, at=0.48, cex=1)
dev.off()

