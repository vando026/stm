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
plotCVL <- function(dat, main, cols, ylim2) {
  
  # Make labels
  len <- length(unique(dat$Age))/2
  agelab <- paste0(seq(15, 45, 5), "-")
  scols <- c(rep(cols[1], len),rep(cols[2], len))

  par(mar=c(4.1, 4.5, 1,0.6))  
  with(dat, plotCI(Age, mean, ui=ub, li=lb, ylim=ylim2, xlim=c(-0.1, 6.5), 
    font.lab=2, xlab="",  ylab="", xaxt="n", yaxt="n", axes=FALSE, 
    lwd=2, pch=16, col=scols, main=main))
    axis(side=1, at = seq(0, 6, 1), labels = agelab, cex.axis=1.2)
    title(xlab="Age Groups", line=2.5, cex.lab=1.3, font.lab=2)
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
gmn$ub <- with(gmn, ifelse(ub > 90000, ub - 50000, ub))
transform(gmn, Ratio=Ratio(gmn))

###########################################################################################################
######################################## Make plots #######################################################
###########################################################################################################
# png(file=file.path(output, "CVL_mn_2011_05Oct2017.png"), 
  # units="in", width=8, height=8, pointsize=14, res=1200, type="cairo")
pdf(file=file.path(output, "CVL_mn_2011_05Oct2017.pdf"), 
  width=6, height=6, pointsize=10)
plotCVL(gmn, main="",
  cols=cols, ylim2=c(0, 65000))
axis(side=2, at = seq(0, 60000, 10000), 
  labels = formatC(c(seq(0, 50000, 10000), 110000), format="d", big.mark=" "))
axis.break(axis=2, breakpos=57000, style = "slash", brw=0.02)
title(ylab="Geometric mean viral load (copies/mL)",
  line=2.8, font.lab=2, cex.lab=1.2)
legend("top", c("Males", "Females"), cex=1.4,
  ncol=2, lty=1, pt.cex=1.7, lwd=2.5, pch=20, col=cols, bty="n")
dev.off()

###########################################################################################################
######################################## Prop #############################################################
###########################################################################################################
over50 <- read.dta(file.path(derived, "over50_2011.dta"), convert.factors=FALSE) 
over50 <- transform(over50, Age = ifelse(Female==1, Age + 0.15, Age - 0.15))
p50 <- subset(over50, Data=="CVL")
f50 <- subset(over50, Data=='FVL')
transform(p50, Ratio=Ratio(p50))
transform(f50, Ratio=Ratio(f50))

# png(file=file.path(output, "P50_5Oct2017.png"), 
  # units="in", width=8, height=8, pointsize=14, res=1200, type="cairo")
pdf(file=file.path(output, "P50_5Oct2017.pdf"), 
  width=6, height=6, pointsize=10)
plotCVL(p50, main="",
  ylim2=c(0, 1), cols=cols)
axis(side=2, at = seq(0, 1, 0.2), cex.axis=1.0)
title(ylab="Proportion >50,000 copies/mL ",
  line=2.8, font.lab=2, cex.lab=1.2)
legend("top", 
  c("Males", "Females"), cex=1.4,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()

png(file=file.path(output, "F50_12Oct2017.png"), 
  units="in", width=8, height=8, pointsize=14, res=1200, type="cairo")
plotCVL(f50, main="", ylim2=c(0,0.6), cols=cols)
axis(side=2, at = seq(0, 0.6, 0.1))
title(ylab="Proportion >50,000 copies/mL",
  line=2.8, font.lab=2, cex.lab=1.2)
legend("top", 
  c("Males", "Females"), cex=1.2,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols, bty="n")
dev.off()

###############################################################################################
######################################## COmbine Fig 1 A B#####################################
###############################################################################################
pdf(file=file.path(output, "Figure1_16Oct2017.pdf"), 
  width=9, height=6, pointsize=10)

par(mar=c(0.0, 4.5, 1,1.2))  
nf <- layout(matrix(c(1, 2, 3, 3), ncol=2, byrow=TRUE),
  heights=c(5.5, 1.0))

plotCVL(gmn, main="",
  cols=cols, ylim2=c(0, 65000))
axis(side=2, at = seq(0, 60000, 10000), cex.axis=1.2,
  labels = formatC(c(seq(0, 50000, 10000), 110000), format="d", big.mark=" "))
axis.break(axis=2, breakpos=57000, style = "slash", brw=0.02)
title(ylab="Geometric mean viral load (copies/mL)",
  line=2.8, font.lab=2, cex.lab=1.3)

plotCVL(p50, main="",
  ylim2=c(0, 1), cols=cols)
axis(side=2, at = seq(0, 1, 0.2), cex.axis=1.2)
title(ylab="Proportion >50,000 copies/mL ",
  line=2.8, font.lab=2, cex.lab=1.3)

plot(0,0,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", c("Males", "Females"), inset=c(0, -0.6), cex=1.6,
  ncol=2, lty=1, pt.cex=1.7, lwd=2.6, pch=20, col=cols, bty="n")

dev.off()







