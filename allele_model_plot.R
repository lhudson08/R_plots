#
# Libraries
#
library(coda)
library(LaplacesDemon)
library(ggplot2)
library(plyr)

#
# Constants
#

# Data input
data_location <- "~/Documents/PhD/hsd_locus/mapping"

mcmc_file1 <- paste(data_location, "chain1.Rdata", sep="/")
mcmc_file2 <- paste(data_location, "chain2.Rdata", sep="/")
pairs_file <- paste(data_location, "pair_rows.txt", sep="/")

# Outcomes
alleles = c("A", "B", "C", "D", "E", "F")
tissues = c("CSF", "Blood")

# Top level parameters
model1_parameters = c("kappa","mu[1]","mu[2]")
model2_kappa = c("kappa[1]","kappa[2]","kappa[3]","kappa[4]","kappa[5]","kappa[6]")
model2_parameters = c("mu[1,1]", "mu[2,1]", "mu[1,2]", "mu[2,2]", "mu[1,3]", "mu[2,3]",
	"mu[1,4]", "mu[2,4]", "mu[1,5]", "mu[2,5]", "mu[1,6]", "mu[2,6]")

#
# Main
#

#
# mcmc.list data structure
#
# Sample means - pi
# First index is sample number
# Second index is allele: 1 = A; 2 = B ... 6 = E
# summary(coda_samples2[,"pi[1,1]",drop=FALSE])
# plot(coda_samples2[,"pi[1,1]",drop=FALSE])
#
# Tissue means - mu
# First index is tissue: 1 = csf; 2 = blood
# Second index is allele: 1 = A; 2 = B ... 6 = E
# summary(coda_samples2[,"mu[1,2]",drop=FALSE])
# plot(coda_samples2[,"mu[1,2]",drop=FALSE])
#
# Relation between mu and alpha - kappa
# summary(coda_samples2[,"kappa",drop=FALSE])
# plot(coda_samples2[,"kappa",drop=FALSE])
#
# Priors for sample level Dirichlet - alpha
# Indicies as for my
# summary(coda_samples2[,"alpha[1,2]",drop=FALSE])
# plot(coda_samples2[,"alpha[1,2]",drop=FALSE])

#
# Read in data
#

# Read in data from allele_model.R
mcmc_samples_model1 <- readRDS(mcmc_file1)
mcmc_samples_model2 <- readRDS(mcmc_file2)

all_chains1 <- as.matrix(mcmc_samples_model1)
all_chains2 <- as.matrix(mcmc_samples_model2)

# Pair data
paired_samples <- read.delim(pairs_file)

# Chain diagnostics plots

# First chain 1
# Autocorrelation
pdf("model1_autocorr.pdf")
autocorr.plot(mcmc_samples_model1[,model1_parameters,drop=FALSE])
dev.off()

# Chain convergence
gelman <- gelman.diag(mcmc_samples_model1[,model1_parameters,drop=FALSE])
heidel <- heidel.diag(mcmc_samples_model1[,model1_parameters,drop=FALSE])
capture.output(list("gelman"=gelman,"heidel"=heidel),file="model1_convergence_diagnostics.txt")

pdf("kappa_gelman_model1.pdf",width=10,height=7)
gelman.plot(mcmc_samples_model1[,"kappa",drop=FALSE])
dev.off()

# Plot of kappa + chain, ggplot of kappa
pdf("kappa_chain_model1.pdf",width=10,height=7)
plot(mcmc_samples_model1[,"kappa",drop=F])
dev.off()

# Autocorrelation
pdf("model2_autocorr.pdf")
autocorr.plot(mcmc_samples_model2[,c("kappa[1]","mu[1,1]","mu[2,1]"),drop=FALSE])
dev.off()

# Chain convergence
#gelman <- gelman.diag(mcmc_samples_model2[,c(model2_parameters,"kappa"),drop=FALSE])
#Multivariate psf seems to fail if E allele included
gelman <- list(gelman.diag(mcmc_samples_model2[,c(model2_kappa,model2_parameters[1:10]),drop=FALSE]),
	           gelman.diag(mcmc_samples_model2[,model2_parameters[11:12],drop=FALSE]))
heidel <- heidel.diag(mcmc_samples_model2[,c(model2_kappa,model2_parameters),drop=FALSE])
capture.output(list("gelman"=gelman,"heidel"=heidel),file="model2_convergence_diagnostics.txt")

pdf("kappa_gelman_model2.pdf",width=10,height=7)
gelman.plot(mcmc_samples_model2[,model2_kappa,drop=FALSE])
dev.off()

# Plot of kappa + chain, ggplot of kappa
pdf("kappa_chain_model2.pdf",width=10,height=7)
plot(mcmc_samples_model2[,model2_kappa,drop=F])
dev.off()

pdf("kappa_posteriors.pdf",width=10,height=7)
for (i in 1:length(alleles))
{
	kappa_name <- paste("kappa[",i,"]",sep='')

	kappa_data = as.data.frame(all_chains2[,kappa_name])
	colnames(kappa_data) = "kappa"

	print(ggplot(kappa_data, aes(x=kappa)) +
	geom_histogram(aes(y=..density..), binwidth=(max(kappa_data$kappa) - min(kappa_data$kappa))/15,colour="black",fill="white") +
	geom_density(alpha=0.2, fill="#FF9999") + theme_bw(base_size = 14) + xlab(kappa_name))
}
dev.off()

# means and 95% HPD intervals, concatenating all chains together
conf_intervals <- p.interval(all_chains2,HPD=TRUE)
capture.output(conf_intervals,file="confidence_intervals.txt")
means = colMeans(all_chains2)
capture.output(means,file="means.txt")

# 6*2 means and 95% CIs for mus
# 	geom pointrange plot of this
#   could also try plotting multiple geom_density, for each allele
tissue_alleles <- as.data.frame(rep(alleles,each=length(tissues)))
colnames(tissue_alleles)[1] = "Allele"
tissue_alleles$Tissue <- rep(tissues,length(alleles))
tissue_alleles$Mean = means[model2_parameters]
tissue_alleles$Upper = conf_intervals[model2_parameters,"Upper"]
tissue_alleles$Lower = conf_intervals[model2_parameters,"Lower"]

pdf("tissue_alleles.pdf",width=10,height=7)
ggplot(tissue_alleles) +
geom_pointrange(aes(x=Allele,y=Mean,ymax=Upper,ymin=Lower,colour=Tissue),position=position_dodge(width=0.5),size=0.8) +
xlab("Allele") + ylab("Proportion in tissue") + ylim(0,1) + theme_bw(base_size = 15)
dev.off()

# 6*1192 means and 95% CIs for pis
# 6*(1192/2) means and 95% CIs for pi[csf] - pi[blood] for all pairs
mcmc_diff <- matrix(data=NA,nrow=nrow(all_chains2),ncol=(nrow(paired_samples)*length(alleles)))
col_headers <- vector(mode="character",length=(nrow(paired_samples)*length(alleles)))

for (i in 1:nrow(paired_samples))
{
	csf_sample = paste("pi[",paired_samples$CSF_index[i],",",sep='')
	blood_sample = paste("pi[",paired_samples$Blood_index[i],",",sep='')

	for (j in 1:length(alleles))
	{
		column_number = (i-1)*length(alleles) + j

    csf_allele = paste(csf_sample,j,"]",sep='')
		blood_allele = paste(blood_sample,j,"]",sep='')

		mcmc_diff[,column_number] = all_chains2[,csf_allele] - all_chains2[,blood_allele]
    col_headers[column_number] = paste(paired_samples$Sample[i],alleles[j],sep='_')
	}
}
colnames(mcmc_diff) = col_headers

# Print out confidence intervals
pair_conf_intervals <- p.interval(mcmc_diff,HPD=TRUE)
capture.output(pair_conf_intervals,file="pairs_intervals.txt")
