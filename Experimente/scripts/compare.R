library(stringr)
library(plotrix)

data_folder = '/home/sbiastoch/Schreibtisch/thesis/Experimente/csv/classifications/'
#data_folder = '~/Schreibtisch/thesis/Experimente/csv/classifications/'
folder = '/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/'
#folder = '/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/'

# Plottet die beste totalperformance je featureset in abhängigkeit zur durchschnittlichen anzahl an binären/numerischen attributen des feautesets
#xs=list(praefix=341.3, suffix=332.5, affix=673.8, phoncat=136.3, sonority=10, weight=23.5, phon=169.8, sylstruct=70, meta=19.6, sparse=130.5, numeric=33.5, all=936.6)
#ys=c(80.3, 79.2, 92.2, 83.2, 75.3, 74.7, 88, 85.3, 71.9, 91.4, 88.8, 96.2)
#data=rbind(xs,ys)
#sorted = data[,order(unlist(data['xs',]))]
#lines(sorted['xs',],sorted['ys',])
#plot(sorted['xs',],sorted['ys',])


pretty_name <- function(str) {
	shorter = gsub('_error', '', str)
	gsub('_', '/', shorter)
}

# Liefert die besten Modelle mit ihren Ergebnissen je Silbe sowie das gewichtete Gesamtergebnis aller Top-Models
performance <- function(table) {
	# liefert beste ergebnisse je silbenanzahl
	best_percent = apply(table[,3:ncol(table)],1, max)

	# liefert modelle, die die besten ergebnisse je silbe erreicht haben
	best_models = apply(table[,3:ncol(table)], 1, function(table) names(which.max(table)))
	
	# liefert die gewichtete gesamtperformance der besten modelle je silbenzahl
	total_top_performance = round(sum(best_percent * table['n'])/sum(table['n']),2)

	tbl = rbind(cbind(best_models,best_percent),c('',total_top_performance))
	matrix(tbl,,2, dimnames=list(c(2:(nrow(table)+1),'weighted'),c('best_model','result')))
}
#perf = performance(main_stats[c(1,2,grep('_',names(main_stats)))])
#barplot(as.numeric(perf[,'result']), names=c(perf[1:6,'best_model'],'weighted'), las=1,horiz=TRUE)

addLabels <- function(x, stat, vertical=FALSE, cex=0.9, yplus = 0, praefix='', suffix='') {
	srt = 90 * vertical
	stat = as.numeric(stat)
	lbl <- paste(round(stat,1),'%',sep='')
	text(x, stat+.3++2*cex+(srt/90)+yplus, labels=paste(praefix, lbl, suffix, sep=''), col="black", cex=cex, srt=srt)
}

plot_bestmodels_stat <- function(models, main_stats) {

	filename = paste(folder,'bagging/bag_of_best_algorithms_for_featuresets.png',sep='')
	png(filename = filename, width = 1080, height = 500, units = "px", bg = "white", pointsize = 20)

	# liefert je featureset bestes kummuliertes ergebnis
	cummulativ_best_stat = matrix(unlist(lapply(models, function(model) {
		p = performance(main_stats[c(1,2,grep(model,names(main_stats)))])
		c(model,unlist(p['weighted','result']))
	}), recursive=FALSE),2)
	zeroR = sum(main_stats['n'] * main_stats['zeroR']) / sum(main_stats['n'])
	par(las=1,
	#	xpd=TRUE,
		cex.lab=0.9,
		cex.axis=0.9,
		cex.main=1,
		mar=c(4,4,1,4)
	)
	bag = matrix(cummulativ_best_stat[2,], 1, dimnames=list('',cummulativ_best_stat[1,]))
	weighted_model_stats = apply(main_stats[4:length(main_stats)-1], 2, function(col) { sum(col * main_stats['n']) / sum(main_stats['n']) })
	unbag = apply(matrix(weighted_model_stats,3),2,max)
	stat = rbind(unbag, as.numeric(bag)- unbag)
	colnames(stat) = colnames(bag)
	x=barplot(stat, las=2, ylim=c(60,95), xpd=FALSE, ylab='Korrekt (%)', col=c('gray', 'green'))
	par(xpd=TRUE)
	abline(h=zeroR,lty=2)
	text(max(x)+1.5,zeroR+1, paste('ZeroR (',round(zeroR,1),'%)',sep=''), cex=.8)
	addLabels(x, as.numeric(stat[2,]), yplus=as.numeric(stat[1,])-.75, praefix='+', cex=.6)
	addLabels(x, as.numeric(stat[1,]), yplus=-2.25, cex=.6)
	addLabels(x, as.numeric(stat[1,]) + as.numeric(stat[2,]), yplus=.75, cex=.8)
	#title('Akkumulierte Erkennungsraten der besten Algorithmen je Featureset (%)')
	dev.off()
}

# 
plot_overview_stat <- function(main_stats, plot_title, colors, fileName) {

	filename = paste(folder,'featuresets/',fileName,sep='')
	png(filename = filename, width = 1080, height = 500, units = "px", bg = "white", pointsize = 20)

	par(#mfrow=c(3,1),
		las=1,
		xpd=TRUE,
		cex.lab=.7,
		cex.axis=.85,
		cex.main=1,
		mar=c(5.4,2.2,.1,.1)
	)
	stats = main_stats[,3:ncol(main_stats)]
	lbls = pretty_name(names(stats))
	boxplot(stats,las=2, col=colors, names=lbls, ylim=c(30,100))
	#title(plot_title)
	dev.off()
}
getStatSubset <- function(rexp) {
	main_stats[c(1,2,grep(rexp,names(main_stats)),length(main_stats))]
}

getNumberOfRules <- function(fileName) {
#	f = readChar(fileName, file.info(fileName)$size)
#	phrase = 'Number of Rules : '
#	NoR = gregexpr(pattern=phrase, f)[[1]][1] + nchar(phrase)
#	as.numeric(strsplit(substr(f,NoR,NoR+10),'\n')[[1]][1])
	length(getRules(fileName))+1
}


# ohne die letzte Regel!
getRules <- function(fileName) {
	f = readChar(fileName, file.info(fileName)$size)
	phrase = 'JRIP rules:\n===========\n'
	start = gregexpr(pattern=phrase, f)[[1]][1] + nchar(phrase)
	start_to_end = substr(f,start,nchar(f))
	end = gregexpr(pattern='\n =>', start_to_end)[[1]][1]
	rules_string = str_trim(substr(f,start,start+end))
	if(nchar(rules_string) == 0) {
		return(NULL)
	}
	rules = strsplit(rules_string,'\n')[[1]]
	rules
}

getRulesFeatures <- function(rules) {
	ary = sapply(rules, function(t) strsplit(t,' and '))
	features_pre = sapply(ary, function(f) gsub('\\(','',f), simplify=FALSE)
	sapply(features_pre, function(f) gsub(' .*','',f), simplify=FALSE)
}

getJRipRulesFeatures <- function(fileName) {
	rules = getRules(fileName)
	getRulesFeatures(rules)
}

getJ48RulesFeatures <- function(fileName) {
	rules = parseTreeToRules(fileName)
	getRulesFeatures(rules)
}

getRuleNumbers <- function(rule) {
	str = gsub('.*(ultima|sekunda|prima) |\\(|\\)', '', rule)
	as.numeric(strsplit(str,'/')[[1]])
}

getRulesNumbers <- function(fileName) {
	rules = getRules(fileName)
	lapply(rules, function(line) {
		str = gsub('.*(ultima|sekunda|prima) |\\(|\\)', '', line)
		as.numeric(strsplit(str,'/')[[1]])
	})
}

getRulesWordcount <- function(fileName) {
	numbers = getRulesNumbers(fileName)
	unlist(lapply(numbers, function(numbers) {
		if(length(numbers)==1) numbers else sum(numbers)
	}))
}

# ohne die letzte Regel!
getRulesLength <- function(fileName) {
	rules = getRules(fileName)
	unlist(lapply(rules, function(rule) {
		str_count(rule,' and ')+1
	}))
}

getRulesPercentage <- function(fileName) {
	numbers = getRulesNumbers(fileName)
	unlist(lapply(numbers, function(numbers) {
		if(length(numbers)==1) 100 else 100*numbers[1]/sum(numbers)
	}))
}


getTree <- function(fileName) {
	f = readChar(fileName, file.info(fileName)$size)
	phrase = 'J48 pruned tree\n------------------\n'
	start = gregexpr(pattern=phrase, f)[[1]][1] + nchar(phrase)
	start_to_end = substr(f,start,nchar(f))
	end = gregexpr(pattern='\nNumber of Leaves', start_to_end)[[1]][1] - 2
	rules_string = str_trim(substr(f,start,start+end))
	if(nchar(rules_string) == 0) {
		return(NULL)
	}
	rules = strsplit(rules_string,'\n')[[1]]
	rules
}

getCleanedTree <- function(fileName) {
	t = getTreeLeafs(fileName)
	t[!unlist(lapply(t, function(l) grepl('\\(0\\.0\\)', l, perl=TRUE)))]
}

getImportantLeafes <- function(fileName, treshold) {
	t = getCleanedTree(fileName)
	all_numbers = getTreeLeafsNumbers(fileName)
	numbers = subset(matrix(all_numbers), apply(matrix(all_numbers), 1, function(x) sum(unlist(x))) > 0)[,1]
	t[!unlist(lapply(t, function(l) grepl('(0.0))', l)))]
}

# Liefert die Tiefe jeder Regel im Entscheidungsbaum
getTreeDepths <- function(fileName) {
	leaves = getTreeLeafs(fileName)
#	leaves = tree[sapply(tree, function(x) length(x) == 2)]
	unlist(lapply(leaves, function(branch) str_count(branch,'\\|')+1))
}

getTreeLeafs <- function(fileName) {
	t = getTree(fileName)
	t[unlist(lapply(t, function(l) grepl(')', l)))]
}

getTreeLeafsNumbers <- function(fileName) {
	rules = getTreeLeafs(fileName)
	lapply(rules, function(line) {
		str = gsub('^.* |\\(|\\)','',line)
		as.numeric(strsplit(str,'/')[[1]])
	})
}

getTreeLeafsPercentage <- function(fileName) {
	numbers = getTreeLeafsNumbers(fileName)
	unlist(lapply(numbers, function(numbers) {
		if(length(numbers)==1) 100 else 100*numbers[1]/sum(numbers)
	}))
}

getTreeLeafsWordcount <- function(fileName) {
	numbers = getTreeLeafsNumbers(fileName)
	unlist(lapply(numbers, function(numbers) {
		#if(length(numbers)==1) numbers else sum(numbers)
		sapply(numbers, sum)
	}))
}

getMaxTreeDepth <- function(fileName) {
	depths = getTreeDepths(fileName)
	max(depths)
}

getTreeSize <- function(fileName) {
	depths = getTreeDepths(fileName)
	length(depths)
}

plotTreeRules <- function(fileName) {
	percent = getTreeLeafsPercentage(fileName)
	counts = getTreeLeafsWordcount(fileName)
	depths = getTreeDepths(fileName)
	plot(x=depths, y=percent, cex=log(counts, base=1.6), pty=16)
}



# get the most signifcant rules
#rules = getRules('/home/sbiastoch/Schreibtisch/thesis/Experimente/trained_models/2syl/models-all.txt')
#lapply(rules, function(rule) {
#	start = gregexpr(pattern='a (', rule)[[1]][1]
#	substr(f,start,start+end)
#})

####
# boxplot für anzahl der regeln bei jrip
####


plot_analyze_j48 <- function(models, main_stats) {
	filename = paste(folder,'algorithms/J48.png',sep='')
	png(filename = filename, width = 640, height = 1080, units = "px", bg = "white", pointsize = 20)

	# boxplot der tiefe aller regeln von J48
	treedepth_stat = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getTreeDepths(fileName)
		})
	})
	# boxplot der tiefe aller regeln von J48
	treesize_stat = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getTreeSize(fileName)
		})
	})

	par(mfrow=c(3,1),
		las=1,
		xpd=TRUE,
		cex.lab=1.2,
		cex.axis=1.2,
		cex.main=1.2,
		mar=c(1.5,4.5,.3,3),
		oma=c(6,0,0,0)
	)

	boxplot(lapply(1:12, function(mi) unlist(lapply(1:6, function(i) treedepth_stat[[i]][mi]))),xaxt='n', ylab='Tiefe der Blätter')
#	print(treedepth_stat)
#	title('Tiefe der Blätter des J48-Decision-Trees')

	leaves_stat = lapply(1:12, function(mi) unlist(lapply(1:6, function(i) treesize_stat[[i]][mi])))
#	print(treesize_stat)
	boxplot(leaves_stat,xaxt='n', ylab='Anzahl der Blätter')
#	title('Anzahl der Blätter des J48-Decision-Trees')


	j48_stat = main_stats[c(1,2,grep('48',names(main_stats)),length(main_stats))]
	j48_cum_corr = apply(j48_stat, 2, function(col) sum(col*j48_stat[['n']])/sum(j48_stat[['n']]))
	stat = j48_cum_corr[4:length(j48_cum_corr)-1]
	names(stat) = pretty_name(names(stat))
	x = barplot(stat, ylim=c(60,91), las=2,xpd=FALSE, ylab='Prozent korrekt')
	abline(h=j48_cum_corr['zeroR'],lty=2)
	text(max(x)+1.5,j48_cum_corr['zeroR']+.3, paste('ZeroR (',round(j48_cum_corr['zeroR'],1),'%)',sep=''), cex=.7)
	#title('Erkennungsraten von J48 (%)')
	addLabels(x, j48_cum_corr[3:14], yplus=-1.4)



	dev.off()
}

plot_analyze_jrip <- function(models, main_stats) {
	filename = paste(folder,'algorithms/JRip.png',sep='')
	png(filename = filename, width = 640, height = 1080, units = "px", bg = "white", pointsize = 20)

	syls = 2:7
	ruleslen_stat=lapply(syls, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getRulesLength(fileName)
		})
	})

	par(mfrow=c(3,1),
		las=1,
		xpd=TRUE,
		cex.lab=1.2,
		cex.axis=1.2,
		cex.main=1.2,
		mar=c(1.5,4.5,.3,3),
		oma=c(6,0,0,0)
	)
	colors = c('chartreuse1','brown1','chartreuse2','brown2','chartreuse3','brown3','chartreuse4','brown4')
	#library(vioplot)
	#lapply(seq_along(ruleslen_stat), function(stat_idx) {
	#	filename = paste(folder,'total/',num_syls,'syl-basicstats.png',sep='')
	#	png(filename = filename, width = 1920, height = 1080, units = "px", pointsize = 24, bg = "white")
	#	boxplot(ruleslen_stat[[stat_idx]],horiz=FALSE, col=rainbow(length(ruleslen_stat)), main=paste(stat_idx+1,'Silben'))
	#	dev.off()
	#})

	boxplot(lapply(1:12, function(mi) unlist(lapply(1:5, function(i) ruleslen_stat[[i]][mi]))),xaxt='n', ylab='Regellänge')
	#title('Länge der von JRip generierten Regeln')


	boxplot(t(matrix(unlist(lapply(1:5,function(i) unlist(lapply(ruleslen_stat[[i]],length)))),12)),xaxt='n', ylab='Regelnanzahl')
	#title('Anzahl der von JRip generierten Regeln')

	jrip_stat = main_stats[c(1,2,grep('JRip',names(main_stats)),length(main_stats))]
	jrip_cum_corr = apply(jrip_stat, 2, function(col) sum(col*jrip_stat[['n']])/sum(jrip_stat[['n']]))
	stat = jrip_cum_corr[4:length(jrip_cum_corr)-1]
	names(stat) = pretty_name(names(stat))
	x=barplot(stat, ylim=c(60,91), las=2, ylab='Prozent korrekt', xpd=FALSE)
	abline(h=jrip_cum_corr['zeroR'],lty=2)
	text(max(x)+1.5,jrip_cum_corr['zeroR']+.3, paste('ZeroR (',round(jrip_cum_corr['zeroR'],1),'%)',sep=''), cex=.7)
	#title('Erkennungsraten von JRip (%)')
	addLabels(x, jrip_cum_corr[3:(length(jrip_cum_corr)-1)], yplus=-1.4)

	dev.off()
}


main_stats = read.csv(paste(folder,'stats.csv',sep=''))

#models = c(
#	#'',
#	'NN','J48','JRip',
#	'all','sparse','numeric','phon_','affix',
#	'praefix','suffix','phoncat','sylstruct','weight','sonority','meta'
#	)

models = c(
	'all','numeric','sparse',
	'suffix','praefix', 'affix', 
	'sonority', 'weight', 'phoncat', 'phon',
	'sylstruct','meta'
)

#plot_bestmodels_stat(models, main_stats)

#colors = c(replicate(6,c(replicate(3,'gray65'),replicate(3,'gray90'))),'gray100')
#plot_overview_stat(main_stats, 'Erkennungsraten aller Featuresets (%)', colors, 'all.png')

#colors = c(replicate(3,'gray50'),replicate(2, 'gray90'),'gray50',replicate(3,'gray90'),'gray50',replicate(2,'gray90'),'gray100')
#plot_overview_stat(getStatSubset('NN'), 'Erkennungsraten aller NN (%)', colors, 'NN.png')
#plot_overview_stat(getStatSubset('JRip'), 'Erkennungsraten aller JRip (%)', colors, 'JRip.png')
#plot_overview_stat(getStatSubset('48'), 'Erkennungsraten aller J48 (%)', colors, 'J48.png')

#plot_analyze_jrip(models, main_stats)
#plot_analyze_j48(models, main_stats)



# FÜhrt eine benutzerdefinierten Funktion auf allen Dateinamen aller Modelle aus. 
doForAllModels <- function(func, models = c('all','numeric','sparse','suffix','praefix', 'affix', 'sonority', 'weight', 'phoncat', 'phon','sylstruct','meta'), syls=2:7) {
	result = sapply(models, function(model) {
		sapply(2:7, function(num_syls) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			func(fileName)
		})
	})
#	rownames(result) = 2:7
	result
}

function() {
	syls = 2:7
	rules_stat=t(matrix(unlist(lapply(syls, function(num_syls) {
		matrix(unlist(lapply(jrip_rules_models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getNumberOfRules(fileName)
		})),length(jrip_rules_models))
	}),recursive=FALSE),,6,dimnames=list(jrip_rules_models,2:7)))
	write.csv(rules_stat, paste(folder,'number_of_rules.csv',sep=''))

	# liefert die einflussreichsten rules
	r=unlist(unlist(lapply(jrip_rules_models, function(model) { lapply(syls, function(syl) {
		fileName = paste(folder,'../trained_models/',syl,'syl/models-',model,'.txt',sep='')
		rules = getRules(fileName)
		lapply(rules, function(rule) {
			start_phrase = 'a \\('
			start = gregexpr(pattern=start_phrase, rule)[[1]][1] + nchar(start_phrase)-1
			start_to_end = substr(rule,start,nchar(rule)-1)
			ns = as.numeric(strsplit(start_to_end,'/')[[1]])
			list(corr=ns[1], err=ns[2], rule=rule)
		})
	}) }),recursive=FALSE), recursive=FALSE)
}

function() {
	#models=c("all", "sparse", "numeric", "phon", "affix", "praefix", "suffix", "phoncat", "sylstruct", "weight", "sonority", "meta")
	#par(mfrow=c(3,4))
	folder = '/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/'
	models=c("praefix", "suffix", "phoncat", "sylstruct", "weight", "sonority")
	par(mfrow=c(2,3),
		las=1,
		xpd=TRUE,
		cex.lab=1,
		cex.axis=1.2,
		cex.main=1.2,
		mar=c(0,0,2,0),
		oma=c(1,1,1,1))
	csvs=lapply(models, function(model) {
		csv = read.csv(paste(folder,'../scripts/',model,'01',sep=''),sep='\t',skip=2, col.names=c('n','attr')) # jrip
	#	csv = read.csv(paste(folder,'../scripts/',model,'00',sep=''),sep='\t',skip=2, col.names=c('n','attr')) # j48
		x=subset(csv,csv$n>0)
		pie(x[,1],labels=x[,2], main=model, radius=1.3)
		csv
	})
	title('Verwendungshäufigkeit der Features bei JRip je Featureset', outer=TRUE, cex=1.2)
}


# Plottet alle Modelle nach Trainingsset gewichtet
function() {
	#par(mfrow=c(1,1),
	#	las=1,
	#	xpd=TRUE,
	#	cex.lab=2,
	#	cex.axis=1.5,
	#	cex.main=1.5,
	#	mar=c(8,3,3,2)
	#)	

	filename = paste(folder,'weighted_performance.png',sep='')
	png(filename = filename, width = 2000, height = 1000, units = "px", bg = "white", pointsize = 35)
	par(mfrow=c(1,1),
			las=1,
			xpd=TRUE,
			cex.lab=.7,
			cex.axis=.85,
			cex.main=1,
			mar=c(5.5,4,.7,2)
		)
	weighted_model_stats = apply(main_stats[4:length(main_stats)-1], 2, function(col) { sum(col * main_stats['n']) / sum(main_stats['n']) })
	colors = c(replicate(12,c(replicate(3,'gray65'),replicate(3,'gray90'))))
	lbls = pretty_name(names(weighted_model_stats))
	x=barplot(weighted_model_stats, ylim=c(60,100), las=2, xpd=FALSE, col=colors, names=lbls, ylab='Korrekt (%)')
	zeroR = sum(main_stats['n'] * main_stats['zeroR']) / sum(main_stats['n'])
	par(xpd=TRUE)
	abline(h=zeroR,lty=2)
	text(max(x)+2.5,zeroR+1, paste('ZeroR (',round(zeroR,1),'%)',sep=''), cex=.6)
	addLabels(x, weighted_model_stats, 1, .7)
	#title('Performance je Model, gewichtet über die Trainingssets (%)', cex=1.2)
	dev.off()
}


# Barplot der besten Ergebnisse je Silbenzahl, Plotbreite entspricht Anzahl
function() {
	filename = paste(folder,'performance_by_syllables.png',sep='')
	png(filename = filename, width = 2000, height = 800, units = "px", bg = "white", pointsize = 30)
	par(	las=1,
			xpd=TRUE,
			cex.lab=.9,
			cex.axis=.85,
			cex.main=1,
			mar=c(4,4,.8,.1)
		)
	best_stat = apply(main_stats[4:length(main_stats)-1], 1, max)
	names(best_stat) = 2:7
	zerors = rbind(2:7,unlist(main_stats['zeroR']))
	stat = rbind(unname(best_stat) - unname(zerors[2,]), unname(zerors[2,]))
	ns = unlist(main_stats['n'])
	colnames(stat) = 2:7
	x=barplot(stat, ylim=c(0,100), width=ns, ylab="Prozent",xlab="Silben", xpd=FALSE)


	addLabels(x, best_stat, 0, .8)
	#text(x, best_stat-2, labels=lapply(ns, function(n) paste('n =',n)), col="black", cex=.7)
	dev.off()
}

# plot der erkennungsraten je silbe und von zeroR
function() {
	filename = paste(folder,'performance_by_syllables_and_zeroR.png',sep='')
	png(filename = filename, width = 300, height = 300, units = "px", bg = "white", pointsize = 20)
	par(	las=1,
			xpd=FALSE,
			cex.lab=.7,
			cex.axis=.85,
			cex.main=1,
			mar=c(4,4,.2,.1),
			bty='n'
		)
	plot(t(zerors), type='l', ylim=c(0,100), xlab='Silben', ylab='Korrekt (%)')
	text(4, 40, 'ZeroR', cex=.6)
	#axis(1, pos=0)
	#axis(2)
	lines(2:7,best_stat)
	text(4.7, 95, 'Beste Modelle', cex=.6)
	#axis(4, ylim=c(100,6000),col="black",las=1)  ## rechte achse
	#lines(2:7,unlist(main_stats['n'])/60)
	dev.off()
}


# NN number of hidden units bei 66% Split
function() {
	folder = "/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/"
	filename = paste(folder,'NN_HUs.png',sep='')
	png(filename = filename, width = 1000, height = 600, units = "px", bg = "white", pointsize = 20)
	par(	xpd=FALSE,
			cex=1,
			mar=c(4,4,.1,.1)
		)
	steps = c(5, 10, 15, 20, 30, 50, 100)
	cols = rainbow(6)
	stat = matrix(list(
		74.6, 75.0, 77.1, 78.0, 80.5, 80.9, 82.3, # 3 sylstruct
		64.7, 70.4, 69.7, 72.2, 74.6, 72.0, 77.4, # 4 sylstruct
		76.6, 79.4, 79.2, 81.4, 82.3, 83.0, 84.2, # 4 phon
		72.5, 75.3, 78.9, 79.4, 79.6, 81.0, 81.8, # 5 phon
		69.3, 74.9, 73.8, 73.8, 74.2, 77.1, 76.0 # 6 phon
	),7,,dimnames=list(steps, c('a', 'b', 'c', 'd', 'e')))
	matplot(x=steps, stat, type='l', lty=1, lwd=1.8, col=cols, xaxt='n', xlab='Anzahl Hidden Units', ylab='Prozent korrekt')
	axis(side = 1, at = steps)
	axis(side = 2, at=c(65,70,75,80,85))
	legend("bottomright", col=cols, legend=c('3syl@sylstruct', '4syl@sylstruct', '4syl@phon', '5syl@phon', '6syl@phon'), lty=1)
	abline(v=50, lty=2)
	dev.off()
}


# Ergebnis/Anzahl Werte
function() {
	folder = "/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/"
	filename = paste(folder,'counts_vs_performance.png',sep='')
	png(filename = filename, width = 1000, height = 1000, units = "px", bg = "white", pointsize = 35)
	counts = t(matrix(list('praefix' , 430 , 711 , 490 , 237 , 115 , 65 , 530.3,
	'suffix' , 437 , 721 , 470 , 213 , 105 , 49 , 529.1,
	'affix' , 867 , 1432 , 960 , 450 , 220 , 114 , 1059.4,
	'phoncat' , 109 , 157 , 176 , 157 , 124 , 95 , 148.1,
	'sonority' , 5 , 7 , 9 , 11 , 13 , 15 , 7.5,
	'weight' , 12 , 15 , 22 , 27 , 30 , 35 , 17.3,
	'phon' , 126 , 179 , 207 , 195 , 167 , 145 , 172.9,
	'sylstruct' , 46 , 71 , 84 , 81 , 77 , 61 , 68.6,
	'meta' , 21 , 26 , 25 , 22 , 15 , 9 , 23.8,
	'sparse' , 80 , 100 , 133 , 151 , 157 , 162 , 108.5,
	'numeric' , 16 , 23 , 30 , 37 , 44 , 51 , 24.6,
	'all' , 1061 , 1710 , 1279 , 752 , 484 , 334 , 1326.9),8))
	featuresets = counts[,1]
	avg_counts = counts[,8]
	rownames(counts) = featuresets
	counts = counts[,2:7]

	rownames(main_stats)=2:7
	par(mar=c(4,4,.1,.1))
#	countstats=lapply(paste(featuresets,'_',sep=''), function(fs) {
#		apply(main_stats[c(grep(fs,names(main_stats)))],1,max)
#	})
	#names(countstats) = featuresets
	countstats = main_stats[3:38]
	countstats = unlist(lapply(paste(featuresets,'_',sep=''), function(fs) main_stats[grep(fs,names(main_stats))]), recursive=FALSE)
	countstats_matrix = t(matrix(unlist(countstats), 6, dimnames=list(2:7, names(countstats))))

	plot(x=unlist(c(counts['all',c(1,2,3,4)], counts['sparse',5], counts['all',6])), 
		 y=apply(countstats_matrix, 2, max),
		 xlim=c(0,1700), 
		 col='black', 
		 pch=4, 
		 ylim=c(35,100), 
		 ylab='Prozent korrekt', 
		 xlab='Anzahl verschiedener Werte im Featureset')
	combined = lapply(1:12, function(n) {
		combined = t(matrix(c(unlist(counts[n,]), unlist(countstats[3*n-2]), unlist(countstats[3*n-1]), unlist(countstats[3*n])),6))
		points(x=combined[1,], y=combined[2,], pch=20, col=rainbow(6))
		points(x=combined[1,], y=combined[3,], pch=20, col=rainbow(6))
		points(x=combined[1,], y=combined[4,], pch=20, col=rainbow(6))
		combined
	})

#	lapply(1:13, function(n) {
#		points(unlist(counts[n,]), unlist(countstats[3*n-2]), pch=20, col=rainbow(6))
#		points(unlist(counts[n,]), unlist(countstats[3*n-1]), pch=20, col=rainbow(6))
#		points(unlist(counts[n,]), unlist(countstats[3*n]), pch=20, col=rainbow(6))
#	})
	legend('bottomright', pch=16, col=rainbow(6), legend=lapply(2:7, function(n) paste(n, 'Silben')))
	dev.off()
}()

# Plottet die Breite des Baumes und Erkennungsrate vs MinWords (J48)
function() {
	folder = "/home/sbiastoch/Schreibtisch/thesis/Experimente/evaluation/"
	filename = paste(folder,'j48_min_leaves.png',sep='')
	png(filename = filename, width = 1000, height = 1000, units = "px", bg = "white", pointsize = 30)
	j48_rules_plot = function(syls, colors) {
		j48_rules_stats = read.csv(paste(folder,'j48_experiment.csv',sep=''))
		w = subset(j48_rules_stats, syl==syls)
		steps = c(2,5,10,15,20,30,50,100)
		plot(steps,w[,'Percent_correct'], type='l', xlab='Minimale Anzahl an Wörter pro Blatt', ylab='Korrekt (%)', axes=0, ylim=c(83,96), col=colors, lwd=3)
		axis(1, at=steps, las=1)
		axis(2, at=c(83,85,87,89,91,93,95,97), las=1)
		par(new=T)
		plot(steps,w[,'measureNumLeaves'], axes=0, type='l', ylim=c(0,1500), xlab='', ylab='', lty=3, col=colors, lwd=3)
		axis(4, col.lab='darkgray', at=c(0,300,600,900,1200,1500), las=1)
		mtext("Anzahl Blätter", side=4, line=3)
		#par(new=F)
	}
	par(mar=c(4,4,.1,4))
	j48_rules_plot(2, 'red')
	par(new=T)
	j48_rules_plot(3, 'green')
	par(new=T)
	j48_rules_plot(4, 'blue')
	abline(v=20, lty=2)
	legend('topright', col=c('red', 'green', 'blue'), c('2 Silben', '3 Silben', '4 Silben'), lty=c(1, 1, 1), lwd=3)
	dev.off()
}

# Plottet die Breite des Baumes und Erkennungsrate vs MinWords (JRip)
function() {
	filename = paste(folder,'jrip_min_leaves.png',sep='')
	png(filename = filename, width = 1000, height = 1000, units = "px", bg = "white", pointsize = 30)
	jrip_rules_plot = function(syls, colors) {
		jrips_stats = read.csv(paste(folder,'jrip_experiment_NoR.csv',sep=''))
		w = subset(jrips_stats, syl==syls)
		steps = c(2,5,10,15,20,30,50,100)
		plot(steps,w[,'measureNumRules'], axes=0, type='l', xlab='', ylab='', ylim=c(0,60), lty=3, col=colors, lwd=3)
		axis(4, col.lab='darkgray', at=c(0,10,20,30,40,50,60), las=1)
		mtext("Anzahl Regeln", side=4, line=3)
		par(new=T)
		plot(steps,w[,'Percent_correct'], type='l', xlab='Minimale Anzahl an Wörter pro Regel', ylab='Korrekt (%)', axes=0, ylim=c(75,100), col=colors, lwd=3)
		axis(1, at=steps, las=1)
		axis(2, at=c(75,80,85,90,95,100), las=1)
		#par(new=F)
	}
	par(mar=c(4,4,.1,4))
	jrip_rules_plot(2, 'red')
	par(new=T)
	jrip_rules_plot(3, 'green')
	par(new=T)
	jrip_rules_plot(4, 'blue')
	abline(v=20, lty=2)
	legend('topright', col=c('red', 'green', 'blue'), c('2 Silben', '3 Silben', '4 Silben'), lty=c(1, 1, 1), lwd=3)
	#legend(50, 100, c('Korrekt', '#Regeln'), lty=c(1,3), lwd=3, bty='n')
	dev.off()
}


# Plottet alle Blätter aller Modelle mit ihrer individuellen Erkennungsrate, der Tiefe des Blattes als Punktgröße und die Anzahl betroffenr Wörter
function() {
	depths = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getTreeDepths(fileName)
		})
	})
	counts = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getTreeLeafsWordcount(fileName)
		})
	})
	percent = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getTreeLeafsPercentage(fileName)
		})
	})
	depths_all_syls = lapply(1:6, function(syl) unlist(lapply(1:12, function(fs) depths[[syl]][[fs]])))
	counts_all_syls = lapply(1:6, function(syl) unlist(lapply(1:12, function(fs) counts[[syl]][[fs]])))
	percent_all_syls = lapply(1:6, function(syl) unlist(lapply(1:12, function(fs) percent[[syl]][[fs]])))
	par(mar=c(4,4,.1,.1))
	layout(matrix(c(1,1,1,2), 1, byrow = TRUE))
	plot(x=counts_all_syls[[1]], y=percent_all_syls[[1]], xlim=c(0,950), col=rainbow(1,start=1/7), pch=21, cex=.65)#,cex=6*1/depths_all_syls[[1]])
	lapply(2:6, function(n) points(x=counts_all_syls[[n]], y=percent_all_syls[[n]], xlim=c(0,950), col=rainbow(1,start=n/7), cex=.65))#,cex=6*1/depths_all_syls[[1]]))
	par(mar=c(4,1,.1,.1))
	plot(x=counts_all_syls[[1]], y=percent_all_syls[[1]], xlim=c(950,4000), yaxt='n', ylab='', xlab='', col=rainbow(1,start=1/7), cex=.65)#,cex=6*1/depths_all_syls[[1]])
	lapply(2:6, function(n) points(x=counts_all_syls[[n]], y=percent_all_syls[[n]], xlim=c(950,4000), yaxt='n', ylab='', col=rainbow(1,start=n/7), cex=.65))#,cex=6*1/depths_all_syls[[n]]))
	#legend('bottomright', pch=1, pt.cex=round(6*1/1:11,1), legend=paste('Länge = ',1:11))
}()



# Plottet alle Regnel aller Modelle mit ihrer individuellen Erkennungsrate, der Länge  als Punktgder Regel und die Anzahl betroffenr Wörter
function() {
	depths = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getRulesLength(fileName)
		})
	})
	counts = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getRulesWordcount(fileName)
		})
	})
	percent = lapply(2:7, function(num_syls) {
		lapply(models, function(model) {
			fileName = paste(folder,'../trained_models/',num_syls,'syl/models-',model,'.txt',sep='')
			getRulesPercentage(fileName)
		})
	})
	depths_all_syls = lapply(1:12, function(a) unlist(lapply(1:6, function(b) depths[[b]][[a]])))
	counts_all_syls = lapply(1:12, function(a) unlist(lapply(1:6, function(b) counts[[b]][[a]])))
	percent_all_syls = lapply(1:12, function(a) unlist(lapply(1:6, function(b) percent[[b]][[a]])))
	par(mar=c(4,4,.1,.1))
	layout(matrix(c(1,1,1,2), 1, byrow = TRUE))
	plot(x=counts_all_syls[[1]], y=percent_all_syls[[1]], xlim=c(200,600), col=rainbow(1,start=1/12), lwd=2)
	lapply(2:6, function(n) points(x=counts_all_syls[[n]], y=percent_all_syls[[n]], xlim=c(200,600), col=rainbow(1,start=n/12), lwd=2))
	par(mar=c(4,1,.1,.1))
	plot(x=counts_all_syls[[1]], y=percent_all_syls[[1]], xlim=c(600,1600), yaxt='n', ylab='', xlab='', col=rainbow(1,start=1/12), lwd=2)
	lapply(2:6, function(n) points(x=counts_all_syls[[n]], y=percent_all_syls[[n]], xlim=c(600,1600), yaxt='n', ylab='', col=rainbow(1,start=n/12), lwd=2))
	#legend('bottomright', pch=1, pt.cex=round(6*1/1:11,1), legend=paste('Länge = ',1:11))
}()


# Summiert die Anzahl der Wörter auf, die von einer Regel betroffen sind, je Feature
function() {
	tie = TRUE
	algo = if(1) 'jrip' else 'j48'
	filename = paste(folder,algo,'_feature_influence',if(tie) '_grouped' else '','.png',sep='')
	height = if(tie) 1200 else 2000
	png(filename = filename, height = height, width = 700, units = "px", bg = "white", pointsize = 30)
	par(mar=c(4,8,0,1.5))

	all_features = doForAllModels(if(algo == 'jrip') getJRipRulesFeatures else getJ48RulesFeatures)
	all_feature_names = names(table(unname(unlist(all_features))))
	stats <<- list()
	percent_stats <<- list()
	if(tie) {
		void=sapply(unique(gsub('[0-9]','',all_feature_names)), function(f) stats[[f]]<<-0)
		void=sapply(unique(gsub('[0-9]','',all_feature_names)), function(f) percent_stats[[f]]<<-0)
	} else {
		void=sapply(all_feature_names, function(f) stats[[f]]<<-0)
		void=sapply(all_feature_names, function(f) percent_stats[[f]]<<-0)
	}
	void=features_with_total=sapply(1:12, function(fs) { 
		sapply(1:6, function(syls) {
			rules = names(all_features[syls,fs][[1]])
			#file = paste(folder,'../trained_models/',syls+1,'syl/models-',models[fs],'.txt',sep='')
			#rules = getRules(file)
			numbers = as.numeric(sapply(rules, function(rule) sum(getRuleNumbers(rule))))
			features_and_weight = matrix(c(numbers, unname(all_features[syls,fs][[1]])),,2)
			if(length(features_and_weight) > 0) {
				sapply(1:nrow(features_and_weight), function(n) {
					sapply(features_and_weight[,2][[n]], function(feature) {
						if(tie) { feature = gsub('[0-9]','',feature) }
						sum_words = as.numeric(features_and_weight[n,1][[1]])
						stats[[feature]] <<- stats[[feature]] + sum_words
						n = getRuleNumbers(rules[n])
						percent_stats[[feature]] <<- percent_stats[[feature]] + n[1]
					})
				})
			}
		})
	})
	x=unlist(stats) # nominale anzahl
	p=unlist(percent_stats)/unlist(stats)
	x2 = rbind(p*x, x-(p*x)) # anzahl und gewichtete TP/FP
	if(tie) {
		barplot(x2, las=1, xlab='Nominale Anzahl Wörter', horiz=TRUE)
	} else {
		limit = 75
		barplot(x[1:limit], las=1, xlab='Nominale Anzahl Wörter', horiz=TRUE, cex.names=.8)
		x[(limit+1):length(x)]
	}
	dev.off()
}()


depth <- function(tree, row_index) {
	str_count(tree[row_index], '\\|')
}

find_direct_children_indices <- function(tree, vater_index=1) {
	father_depth = depth(tree, vater_index)
	children_depth = father_depth + 1
	children_indices = list()

	possible_child_index = vater_index + 1
	while(possible_child_index < length(tree) & depth(tree, possible_child_index) > father_depth) {
		if(depth(tree, possible_child_index) == children_depth) {
			children_indices = c(children_indices, possible_child_index)
		}
		possible_child_index = possible_child_index + 1
	}

	children_indices
}

isLeaf <- function(tree, index) {
	return(str_count(tree[index], ':') == 1)
}

# stellt die komponenten im gleichen format wie JRip dar
cleanNode <- function(tree, index) {
	untabbed = gsub('\\|   ', '', tree[index])
	brackets = paste('(', untabbed, sep='')
	if(isLeaf(tree, index)) {
		gsub(': ', ') => stress_class=', brackets)
	} else {
		paste(brackets, ')', sep='')
	}
}

parseTreeToRulesWorker <- function(tree, index=1, rule_str='') {
	cleaned_node = cleanNode(tree[index])
	seperator = if(nchar(rule_str) > 0) ' and ' else ''
	appended_rule_str = paste(rule_str, cleaned_node, sep=seperator)

	if(isLeaf(tree[index])) {
		appended_rule_str
	} else {
		children_indices = find_direct_children_indices(tree, index)
		sapply(children_indices, function(i) {
			parseTreeToRulesWorker(tree, i, appended_rule_str)
		})
	}
}
parseTreeToRules <- function(fileName) {
	tree = getTree(fileName)
	unlist(parseTreeToRulesWorker(tree))
}