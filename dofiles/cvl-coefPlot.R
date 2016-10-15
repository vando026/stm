## Description: plots for ecoefficients
## Project: CVL
## Author: AV / Created: 28Sep2016 

root  =  file.path(Sys.getenv("USERPROFILE"), "Dropbox/AfricaCentre/Projects/CommunityVL/")
derived  =  file.path(root, "derived")
output  =  file.path(root, "output")

mat <- read.table(file.path(output, "coefMat.txt"))
mat <- transform(mat, Q=ifelse(Female==1, Q - 0.15, Q + 0.15))
MVL <- mat[grep("^MVL", rownames(mat), value=TRUE), ]
PMVL <- mat[grep("^P_MVL", rownames(mat), value=TRUE), ]
PDV <- mat[grep("^PDV", rownames(mat), value=TRUE), ]
PPDV <- mat[grep("^P_PDV", rownames(mat), value=TRUE), ]
TI <- mat[grep("^TI", rownames(mat), value=TRUE), ]
PTI <- mat[grep("^P_TI", rownames(mat), value=TRUE), ]

len = 4
scex <- c(rep(1, len), rep(1, len))
cols <- c('dodgerblue4', 'indianred4')
scols <- c(rep(cols[1], len),rep(cols[2], len))

coefPlot <- function(mat, pmain, fname="", ylim2=6) {
  # par(mar=c(3.5,2.4,2.6,0.1))
  png(file=file.path(output, paste0(fname, ".png")))
  Ylab="Seroconversion rate per 100 person-years"
  with(mat, 
    plotCI(Q, Rate, ui=ub, li=lb,
    ylim=c(0, ylim2),
    main=pmain, lwd=2, cex=1, pch=19, 
    col=scols, 
    xlab="Quartile", 
    ylab=Ylab,
    xaxt="n", bty="n"))
  axis(1, at=c(1:4))
  axis(2, at=c(1:6))
  with(mat, text(Q, lb, round(lb, 2), pos=1, cex=0.8))
  with(mat, text(Q, ub, round(ub, 2), pos=3, cex=0.8))
legend("bottom", bty="n",  
  c("Males  ", "Females"), cex=1.0,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols)
  dev.off()
}

png(file=file.path(output, "CVL_quant.png"), 
  units="in", width=10, height=10, pointsize=10, res=300, type="cairo")
par(oma=c(0.0, 3.0, 0.3,0.2))  
nf <- layout(matrix(c(1:6,rep(7, 3)), ncol=3, byrow=TRUE),
  heights=c(6, 6, 1.0))
layout.show(nf)
coefPlot(MVL, "Mean Viral Load (HIV+ only)", fname="MVL")
coefPlot(PDV, "Proportion of Detectable Virus (HIV+ only)", fname="PDV")
coefPlot(TI, "Transmission Index (HIV+ only)", fname="TI")
coefPlot(PMVL, "Mean Viral Load (HIV+ and HIV-)", fname="PMVL")
coefPlot(PPDV, "Proportion of Detectable Virus (HIV+ and HIV-)", fname="PPDV")
coefPlot(PTI, "Transmission Index (HIV+ and HIV-)", fname="PTI")
plot(1,1,type="n", xlab='', ylab='', axes=FALSE)
legend("bottom", bty="n",  
  c("Females  ", "Males"), cex=1.5,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols,
  inset=c(5.8,  -1.2))
mtext("Seroconversions per 100 person-years", line=1, cex=1, side=2, outer=TRUE, at=0.55)
mtext("Quartile", line=-7, side=1, outer=TRUE, at=0.54, cex=1)
dev.off()




HR <- read.table(file.path(output, "coefHR.txt"))
HR$Q <- c(c(1:3) - 0.15, c(1:3) + 0.15)

coefPlot <- function(mat, pmain, fname="", ylim2=6) {
  # par(mar=c(3.5,2.4,2.6,0.1))
  png(file=file.path(output, paste0(fname, "_HR.png")))
  Ylab="Hazard Ratio",
  with(mat, 
    plotCI(Q, b, ui=ul, li=ll,
    ylim=c(0.095, 1.30),
    main=pmain, lwd=2, cex=1, pch=19, 
    col=scols, 
    xlab="", 
    ylab=Ylab,
    xaxt="n", bty="n"))
  axis(1, at=c(1:4))
  axis(2, at=c(1:6))
  with(mat, text(Q, lb, round(lb, 2), pos=1, cex=0.8))
  with(mat, text(Q, ub, round(ub, 2), pos=3, cex=0.8))
legend("bottom", bty="n",  
  c("HIV+ Only", "HIV+ and HIV-"), cex=1.0,
  ncol=2, lty=1, pt.cex=1.5, lwd=2, pch=20, col=cols)
  dev.off()
}

coefPlot(MVL, "Mean Viral Load (HIV+ only)", fname="MVL")


abline(h=1.0, lty=2, col="gray")

cvl <- c("MVL", "PDV", "TI")
labx <- c(cvl, paste0("P", cvl))
axis(side=1, at = mat$mod, labels = labx)
legend(1.05, 1.22, 
  c("HIV+ only", "HIV+ and HIV- "),
  ncol=1, lty=1, pch=19, bty="n",
  seg.len=2, lwd=2, col=cols)




