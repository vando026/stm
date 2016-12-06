## Description: plots for ecoefficients
## Project: CVL
## Author: AV / Created: 28Sep2016 

library(readstata13)
library(foreign)
library(plotrix)

root  =  file.path(Sys.getenv("USERPROFILE"), "Dropbox/AfricaCentre/Projects/CommunityVL/")
derived  =  file.path(root, "derived")
output  =  file.path(root, "output")

len = 4
scex <- c(rep(1, len), rep(1, len))
cols <- c('dodgerblue4', 'indianred4')
scols <- c(rep(cols[1], len),rep(cols[2], len))

coefPlot <- function(
  mat, pmain, scols,
  ylim2=c(0, 6)) {
  par(mar=c(3.5,2.4,2.6,0.1))
  Ylab="Seroconversion rate per 100 person-years"
  with(mat, 
    plotCI(Q, rate, ui=ub, li=lb,
    ylim=ylim2,
    main=pmain, lwd=2, cex=1, pch=19, 
    col=scols, 
    xlab="", 
    ylab=Ylab,
    xaxt="n", bty="n"))
  axis(1, at=c(1:4))
  axis(2, at=c(1:6))
}

mat <- read.table(file.path(output, "StdQuartile.txt"), header=TRUE)
mat <- transform(mat, Q=ifelse(Female==1, Q - 0.15, Q + 0.15))
MVL <- mat[mat$Label=="G_MVL", ]
PMVL <- mat[mat$Label=="G_PVL", ]
PDV <- mat[mat$Label=="PDV", ]
PPDV <- mat[mat$Label=="P_PDV", ]
TI <- mat[mat$Label=="TI", ]
PTI <- mat[mat$Label=="P_CTI", ]

png(file=file.path(output, "CVL_quant.png"), 
  units="in", width=10, height=10, pointsize=10, res=300, type="cairo")
par(oma=c(0.0, 3.0, 0.3,0.2))  
nf <- layout(matrix(c(1:6,rep(7, 3)), ncol=3, byrow=TRUE),
  heights=c(6, 6, 1.0))
layout.show(nf)
cti <- "Community Transmission Index"
pdv <- "Percent detectable virus"
gvl <- "Geometric mean viral load"
hiv1 <- "(HIV+ only)"
hiv2 <- "(HIV+ and HIV-)"
coefPlot(MVL, pmain=paste("A:   ", gvl, hiv1), scols=scols)
coefPlot(PDV, pmain=paste("B:   ", pdv, hiv1), scols=scols)
coefPlot(TI,  pmain=paste("C:   ", cti, hiv1), scols=scols)
coefPlot(PMVL, pmain=paste("D:  ", gvl, hiv2), scols=scols)
coefPlot(PPDV, pmain=paste("E:  ", pdv, hiv2), scols=scols)
coefPlot(PTI,  pmain=paste("F:  ", cti, hiv2), scols=scols)
plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", bty="n",  
  c("Females  ", "Males"), cex=1.5,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(3.8,  -1.2))
mtext("Seroconversions per 100 person-years", line=1, cex=1, side=2, outer=TRUE, at=0.55)
mtext("Quartile", line=-7, side=1, outer=TRUE, at=0.5, cex=1)
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



