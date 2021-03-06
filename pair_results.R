results <- read.delim("~/Documents/PhD/Pairs/all_results.Rin")

no_outliers <- as.data.frame(subset(x=results,subset=Total<=10))

ggplot(no_outliers, aes(x=Total)) +
  geom_histogram(binwidth=1,colour="black",fill="#FF9999") + theme_bw(base_size = 14) +
  xlab("Number of variants between samples") + ylab("Count") + 
  scale_x_discrete(limits=seq(0,10,1),breaks=seq(0,10,1)) + facet_wrap(~Species,scales="free")

t.test(as.data.frame(subset(x=no_outliers,subset=Species=="Streptococcus pneumoniae"))$Total, 
       as.data.frame(subset(x=no_outliers,subset=Species=="Neisseria meningitidis"))$Total)

outliers <- as.data.frame(subset(x=results,subset=Total>10))
sort(outliers$Total)

# Do something with these

strep_results_stacked <- read.delim("~/Documents/PhD/Pairs/strep_results_stacked.Rin")
no_outliers_stacked <- as.data.frame(subset(x=strep_results_stacked,subset=Count<15 & Count!=0))

ggplot(no_outliers_stacked) + geom_histogram(aes(x=Count,fill=Type),binwidth=1) + 
xlab("Number of variants between samples") + ylab("Count") + 
scale_x_discrete(breaks=seq(1,9,1),limits=seq(1,9,1)) + theme_bw(base_size = 14)
