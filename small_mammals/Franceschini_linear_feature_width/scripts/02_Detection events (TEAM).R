setwd("E://UoA/Thesis/First_chapter_analysis")

Data<- read.csv("Cleaned Data and matrixes/DataTEAM_STD.csv")


library(overlap)
library(activity)
source("TEAM library 1.8.R") # new version
library(chron)
library(reshape)
library(vegan)
library(plotrix)
library(ggplot2)
library(maptools)
library(rgdal)
library(dplyr)




camera_days<-cam.days(Data1,2023)
camera_days


# Filter the dataset for the specific location
filtered_df <- Data1 %>% filter(Locations == "SM-N-F-554")


# Find the range of 'datetime' values
datetime_min <- min(filtered_df$datetime, na.rm = TRUE)
datetime_max <- max(filtered_df$datetime, na.rm = TRUE)

# Print the range
print(paste("The range of datetime values is from", datetime_min, "to", datetime_max))



dim(camera_days)
summary(camera_days[,2:4]) # calcolo il min, max, mediana, media, 1? e 3?quantile
# di tutte le righe e delle colonne da 2 a 4
Ndays<-camera_days$ndays
Ntot<-sum(Ndays)
Ntot        ##  1945 sampling effort
(Ntot/50)   ##  38.9 sampling effort medio

write.table(camera_days, file="camera_days.txt",quote=F, sep="\t",row.names = F)



unique(Data$Genus)

unique(Data$Genus)


events_15min<-event.sp(dtaframe=Data1, year=2023, thresh=15)
events_60min<-event.sp(dtaframe=Data1, year=2023, thresh=60)
events_1day<-event.sp(dtaframe=Data1, year=2023, thresh=1440)

events_4hours<-event.sp(dtaframe=Data1, year=2023, thresh=240)
write.csv(events_15min, file="events_15min.CSV")
 write.csv(events_60min, file="events_1hour.CSV")
 write.csv(events_1day, file="events_1day.CSV")
 
 install.packages("beepr")
 library(beepr)
 beep(3)
 5beep(3)
 beep(3)
 beep(3)
 
events_1day<-read.csv("events_1day.CSV")
# cumulative events per species
events_15_species<-colSums(events_1day)
events_15_species<-sort(events_15_species, decreasing= TRUE)
write.table(events_15_species, file="cumul_events_1D_species.txt",quote=F, sep="\t")

events_1h_species<-colSums(events_1hour)
events_1h_species<-sort(events_1h_species, decreasing= TRUE)
write.table(events_1h_species, file="cumul_events_1h_species.txt",quote=F, sep="\t")

str(Data)

Data1 <- Data %>% select(- Start.Date, - End.Date)
Data1 <- Data[ , -which(names(Data) %in% c("Start.Date", "End.Date"))]

colnames(Data1)[colnames(Data1) == "Start.Date.1"] <- "Start.Date"
colnames(Data1)[colnames(Data1) == "End.Date.1"] <- "End.Date"
colnames(Data1)[colnames(Data1) == "date"] <- "Date"


accumulation<-acc.curve(Data1, 2023)
write.table(accumulation, file="accum_2023.txt",quote=F, sep="\t")


ggplot(accumulation, aes(x=Camera.trap.days, y=species)) +
  geom_line(aes(y=species-sd), colour="grey50", linetype="dotted") +
  geom_line(aes(y=species+sd), colour="grey50", linetype="dotted") +
  theme_bw() +
  geom_line()


p <- ggplot()
p <- p + geom_point(size = 4)
p <- p + xlab("Camera trap days") + ylab("Species")
p <- p + theme(text = element_text(size=15)) + theme_bw()
p <- p + geom_line(data = accumulation,
                   aes(x =Camera.trap.days, y = species), # devo provare o con F2 o con Capreolus
                   colour = "black") 

p <- p + geom_ribbon(data = predav,
                     aes(x = Camera.trap.days,
                         ymax = species-sd,
                         ymin = species+sd ),
                     alpha = 0.4)


ggplot(accumulation, aes(x=Camera.trap.days, y=species)) +
  geom_line(aes(y=species-sd), colour="grey50", linetype="dotted") +
  geom_line(aes(y=species+sd), colour="grey50", linetype="dotted") +
  theme_bw() +
  geom_line()



##### Naive occupancy

mat<-f.matrix.creator(Data1) # list of matrices camera in righe su days
# in colonne for each species
naive_occu<-naive(mat) # get naive occupancy for each species
write.table(naive_occu, file="naive_occu.txt",quote=F, sep="\t",row.names = F)
write.table(mat, file="mat.txt",quote=F, sep="\t",row.names = F)



##### activity pattern of species 
activity_24h<-events.hours(Data)
write.table(activity_24h, file="activity_24hour_2023.txt",quote=F, sep="\t",row.names = F)

# possiamo fare un plot con gli eventi nelle 24h per una specie focale
clock<-c(0:23)
clock24.plot(activity_24h$MYODES.GAPPERI,clock,
             show.grid=T,lwd=2,line.col="blue", main="Myodes gapperi", 
             cex.lab=0.5)




Data.new <- Data.light[,-41]
### Creating subset

MYODES<-Data.new[ Data.light$Genus=="MYODES",]


MYODES_sep<-f.separate.events(MYODES,30)#by 30 min, adds column 'grp'
str(MYODES_sep$grp)
#lo prende come fattore, mettiamolo numerico
MYODES_sep$grp<-as.numeric(MYODES_sep$grp)
unique(MYODES_sep$grp)


# scarto i duplicati (con 'unique' non funziona...)
MYODES_indip<-MYODES_sep[which(!duplicated(MYODES_sep$grp)),]
dim(MYODES_indip)
head(MYODES_indip)

#estraggo in vettore Photo.Time per 'activity'
MYODESind<-print(MYODES$Photo.Time)
#converto in numerico (0-1)
MYODESind<-as.numeric(MYODESind)
MYODESind
range(MYODESind)
MYODES_activity_plot<-MYODESind*2*pi
timeRadMYODES #serve per il plot overlap
win.graph()
densityPlot(MYODES_activity_plot, rug=T, adjust=0.5)

lynx<-timeRad[events$area==1 & events$Genus==
                'MYODES']
densityPlot(lynx, rug=T)