## Description: plots for ecoefficients
## Project: CVL
## Author: AV / Created: 28Sep2016 

library(readstata13)
library(foreign)
library(plotrix)
library(epitools)

root  =  file.path(Sys.getenv("USERPROFILE"), "Dropbox/AfricaCentre/Projects/CommunityVL/")
derived  =  file.path(root, "derived")
output  =  file.path(root, "output")

len = 4
scex <- c(rep(1, len), rep(1, len))
cols <- c('dodgerblue4', 'indianred4')
scols <- c(rep(cols[1], len),rep(cols[2], len))

mat <- read.table(file.path(output, "StdQuartile.txt"), header=TRUE)
MVL <- mat[mat$Label=="G_MVL", ]
PMVL <- mat[mat$Label=="G_PVL", ]
PDV <- mat[mat$Label=="PDV", ]
PPDV <- mat[mat$Label=="P_PDV", ]
TI <- mat[mat$Label=="TI", ]
PTI <- mat[mat$Label=="P_CTI", ]

# Now apply direct standard weight
directStd <- function(obj) {
  mat <- matrix(nrow=8, ncol=6)
  i  <- 1
  for (fem in c(0,1)) {
    for (qq in seq(1:4)) {
      est <- subset(obj, Q==qq & Female==fem)
      res <- ageadjust.direct(est[,"D"],est[,"PY"],stdpop=est$Count)
      mat[i,1]  <- fem 
      mat[i,2]  <- qq 
      mat[i, 3:6]  <- res 
      i <- i + 1
    } 
  } 
  mat <- as.data.frame(mat)
  mat <- transform(mat, Label=as.character(obj$Label[1]))
  colnames(mat) <- c("Female", "Q", "Crude", "rate", "lb", "ub", "Label")
  mat <- transform(mat, Q=ifelse(Female==1, Q + 0.15, Q - 0.15))
  mat
}
# debugonce(directStd)
# directStd(PMVL)

out <- list(MVL=MVL, PDV=PDV, TI=TI, PMVL=PMVL, PTI=PTI, PPDV=PPDV)
Out <- lapply(out, directStd)

coefPlot <- function(
  mat, pmain, scols,
  ylim2=c(0, 6)) {
  par(mar=c(5.0,2.6,3.6,0.1))
  Ylab=expression(bold("Seroconversion rate per 100 person-years"))
  with(mat, 
    plotCI(Q, rate, ui=ub, li=lb,
    ylim=ylim2,
    # main=pmain, 
    lwd=1.5, cex=1, pch=19, 
    col=scols, 
    xlab="",
    ylab=Ylab,
    xaxt="n", yaxt="n", bty="n"))
  title(main=pmain[1:2],cex.main=1.9, line=-1)
  title(xlab="PVL Quartile", font.lab=2, cex.lab=1.8)
  axis(1, at=c(1:4), cex.axis=1.5)
  axis(2, at=c(0:6), cex.axis=1.5)
}

# png(file=file.path(output, "CVL_quant_Std_05Oct2017.png"), 
  # units="in", width=10, height=10, pointsize=10, res=1200, type="cairo")
pdf(file=file.path(output, "CVL_quant_Std_22Nov2017.pdf"), 
  width=7.3, height=7.3, pointsize=7)
par(oma=c(0.0, 3.0, 0.3,0.2))  
nf <- layout(matrix(c(1:6,rep(7, 3)), ncol=3, byrow=TRUE),
  heights=c(5.7, 5.7, 1.0))
cti <- "Community Transmission Index"
pdv <- "Prevalence of detectable viremia"
gvl <- "Geometric mean viral load"
hiv1 <- "(HIV+ only)"
hiv2 <- "(HIV+ and HIV-)"
coefPlot(Out$MVL, pmain=paste("A:", gvl, "\n", hiv1), scols=scols)
coefPlot(Out$PDV, pmain=paste("B:", pdv, "\n", hiv1), scols=scols)
coefPlot(Out$TI,  pmain=paste("C:", cti, "\n", hiv1), scols=scols)
coefPlot(Out$PMVL, pmain=paste("D:", gvl, "\n", hiv2), scols=scols)
coefPlot(Out$PPDV, pmain=paste("E:", pdv, "\n", hiv2), scols=scols)
coefPlot(Out$PTI,  pmain=paste("F:", cti, "\n", hiv2), scols=scols)
par(mar=c(0.5, 4.5, 0.0,1.2))  
plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", bty="n",  
  c("Males  ", "Females"), cex=2.4,
  ncol=2, lty=1, pt.cex=1.7, lwd=1.5, pch=20, col=cols,
  inset=c(3.8,  0.2))
mtext(expression(bold("Seroconversions per 100 person-years")), line=1, cex=1.4, side=2, outer=TRUE, at=0.55)
dev.off()

###############################################################################################
######################################## No SEX ###############################################
###############################################################################################
mat <- read.table(file.path(output, "StdQuartileNoFEM.txt"), header=TRUE)
MVL <- mat[mat$Label=="G_MVL", ]
PMVL <- mat[mat$Label=="G_PVL", ]
PDV <- mat[mat$Label=="PDV", ]
PPDV <- mat[mat$Label=="P_PDV", ]
TI <- mat[mat$Label=="TI", ]
PTI <- mat[mat$Label=="P_TI", ]

png(file=file.path(output, "CVL_quantNoSEX.png"), 
  units="in", width=10, height=10, pointsize=10, res=300, type="cairo")
par(oma=c(0.0, 3.0, 0.3,0.2))  
nf <- layout(matrix(c(1:6,rep(7, 3)), ncol=3, byrow=TRUE),
  heights=c(6, 6, 1.0))
layout.show(nf)
gvl <- "Geometric mean viral load"
hiv1 <- "(HIV+ only)"
hiv2 <- "(HIV+ and HIV-)"
coefPlot(MVL, pmain=paste("A:   ", gvl, hiv1), scols=cols[1])
coefPlot(PDV, pmain=paste("B:   ", pdv, hiv1), scols=cols[1])
coefPlot(TI,  pmain=paste("C:   ", cti, hiv1), scols=cols[1])
coefPlot(PMVL, pmain=paste("D:  ", gvl, hiv2), scols=cols[2])
coefPlot(PPDV, pmain=paste("E:  ", pdv, hiv2), scols=cols[2])
coefPlot(PTI,  pmain=paste("F:  ", cti, hiv2), scols=cols[2])
mtext("Seroconversions per 100 person-years", line=1, cex=1, side=2, outer=TRUE, at=0.55)
mtext("Quartile", line=-7, side=1, outer=TRUE, at=0.5, cex=1)
dev.off()



