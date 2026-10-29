
setwd("E:///UoA/Thesis/First_chapter_analysis")

library(dplyr)
library(ggplot2)
library(nlme)
library(plyr)
library(tidyr)
library(lubridate)
library(lattice) 
source("HighstatLibV10.R")

camera_trap_data <- read.csv("events_1day.CSV")
Covs <- read.csv("TableCovs_corrected.csv", sep = ";")
ED<-read.csv("ED.csv")
TE<-read.csv("TE.csv")
Habitat_Amount<-read.csv("Habitat_Amount.csv")
ArcCovs <- read.csv("Covs_ArcGIS.csv", sep = ";")


ArcCovs1 <- ArcCovs[c('Locations', 'Road_DIST', 'WellAct_DIST', 'WellAband_DIST',
                                 'Wells_DIST','Industr_DIST')]

TE$Locations<-TE$Location
ED$Locations<-ED$Location


GLM_covs <- Covs %>%
  left_join(Habitat_Amount, by = "Locations")
GLM_covs <- GLM_covs %>%
  left_join(ED, by = "Locations")
GLM_covs <- GLM_covs %>%
  left_join(TE, by = "Locations")
GLM_covs <- GLM_covs %>%
  left_join(ArcCovs1, by = "Locations")


camera_trap_data$Locations<-camera_trap_data$Sampling.Unit.Name

GLM_data <- camera_trap_data %>%
  left_join(GLM_covs, by = "Locations")


# selected_data <- GLM_data[c('Locations', 'Latitude', 'Longitude')]
# 
# # Write the selected data to a new CSV file
# write.csv(selected_data, "GLM_locations.csv", row.names = FALSE)
# 
# 
# write.csv(GLM_data, "GLM_data.csv", row.names = FALSE)

GLM_data$Width <- as.numeric(GLM_data$Width)
GLM_data$Month <- as.factor(GLM_data$Month)
GLM_data$Month2 <- as.factor(GLM_data$Month2)
GLM_data$Family <- as.factor(GLM_data$Family)
GLM_data = subset(GLM_data, !(Habitat %in% c("Upland Spruce", "Pine")))
GLM_data$Habitat <- as.factor(GLM_data$Habitat)
GLM_data$SP.Group <- as.factor(GLM_data$SP.Group)



# Create a contingency table of Habitat counts within each Position category
habitat_position_counts <- table(GLM_data$Position, GLM_data$Habitat)

# Display the table
print(habitat_position_counts)

#         Deciduous Mixedwood Pine Tamarack/Lowland Spruce Upland Spruce
# Forest        56        51    3                      52            25
# Line          51        52    3                      43            23

GLM_data$Footprint_Fine <- factor(GLM_data$Footprint_Fine,
                                  levels = c("Interior point", "Low-impact seismic (less than 5m)", "Conventional seismic (more than 5m)", "Pipeline"),
                                  labels = c("Interior point", "Low-impact seismic", "Conventional Seismic", "Pipeline/Transmission Line"))



GLM_data$Family <- factor(GLM_data$Family,
                          levels = c("3D", "C", "P", "T"),
                          labels = c("Low-impact seismic", "Conventional Seismic", "Pipeline", "Transmission Line"))





GLM_data$Road_DIST <- gsub(",", ".", GLM_data$Road_DIST)
GLM_data$WellAct_DIST <- gsub(",", ".", GLM_data$WellAct_DIST)
GLM_data$WellAband_DIST <- gsub(",", ".", GLM_data$WellAband_DIST)
GLM_data$Wells_DIST <- gsub(",", ".", GLM_data$Wells_DIST)
GLM_data$Industr_DIST <- gsub(",", ".", GLM_data$Industr_DIST)



GLM_data$HF_01_150 <- as.numeric(GLM_data$HF_01_150)
GLM_data$HF_01_500 <- as.numeric(GLM_data$HF_01_500)
GLM_data$HF_01_1500 <- as.numeric(GLM_data$HF_01_1500)
GLM_data$ED150 <- as.numeric(GLM_data$ED150)
GLM_data$ED500 <- as.numeric(GLM_data$ED500)
GLM_data$ED1500 <- as.numeric(GLM_data$ED1500)
GLM_data$TE150 <- as.numeric(GLM_data$TE150)
GLM_data$TE500 <- as.numeric(GLM_data$TE500)
GLM_data$TE1500 <- as.numeric(GLM_data$TE1500)
GLM_data$Road_DIST <- as.numeric(GLM_data$Road_DIST)
GLM_data$WellAct_DIST <- as.numeric(GLM_data$WellAct_DIST)
GLM_data$WellAband_DIST <- as.numeric(GLM_data$WellAband_DIST)
GLM_data$Wells_DIST <- as.numeric(GLM_data$Wells_DIST)
GLM_data$Industr_DIST <- as.numeric(GLM_data$Industr_DIST)

# Convert 'Start_Date' to Date format
GLM_data$Start_Date <- as.Date(GLM_data$Start_Date, format = "%d/%m/%Y")

# Calculate Julian date and add it as a new column
GLM_data$Julian_Date <- yday(GLM_data$Start_Date)
# Scale and center the Julian date
GLM_data$julian_date_scaled <- scale(GLM_data$Julian_Date, center = TRUE, scale = TRUE)

# The result is a matrix; you may want to convert it to a numeric vector
GLM_data$julian_date_scaled <- as.numeric(GLM_data$julian_date_scaled)

GLM_data$Longitude <- gsub(",", ".", GLM_data$Longitude)
GLM_data$Latitude <- gsub(",", ".", GLM_data$Latitude)

Longitude<-as.numeric(GLM_data$Longitude)
Latitude<-as.numeric(GLM_data$Latitude)

GLM_data <- subset(GLM_data, select = -Location.x)
GLM_data <- subset(GLM_data, select = -Location.y)

standardized_columns <- scale(GLM_data[, 41:54])
GLM_data[, 41:54] <- standardized_columns

write.csv(GLM_data, "GLM_data_1day.CSV")





GLM_line = subset(GLM_data, !(Footprint_Type %in% c("Interior point")))
write.csv(GLM_data, "GLM_line.CSV")

# GLM_line$Intensity_Use_2 <- factor(GLM_line$Intensity_Use_2, levels = c("None", "Low", "Moderate", 
#                                                                         "High, Moderate", "High"))


unique(GLM_line$Habitat)
unique(GLM_line$Width)
unique(GLM_line$Footprint_Type)
unique(GLM_line$Intensity_Use_2)


unique(GLM_line$Family)

GLM_Int = subset(GLM_data, (Footprint_Type %in% c("Interior point")))



unique(GLM_Int$Habitat)
unique(GLM_Int$Width)
unique(GLM_Int$Footprint_Type)
unique(GLM_Int$Family)




calculate_column_stats <- function(GLM_line, MYODES.GAPPERI) {
  data <- GLM_line[[MYODES.GAPPERI]]
  median_value <- median(data, na.rm = TRUE)
  mean_value <- mean(data, na.rm = TRUE)
  std_error <- sd(data, na.rm = TRUE) / sqrt(sum(!is.na(data)))
  
  return(list(median = median_value, mean = mean_value, std_error = std_error))
}

# Example usage
# Assuming 'my_data_frame' is your data frame and 'my_column' is the column you're interested in
result <- calculate_column_stats(GLM_line, "MYODES.GAPPERI")
print(result)
# $median
# [1] 0
# 
# $mean
# [1] 2.839572
# 
# $std_error
# [1] 0.448138



str(GLM_line)




########################################################################
#Housekeeping
#Load packages from R and support functions that we wrote
library(lattice)  #For fancy multipanel graphs
source("HighstatLibV10.R")



##############################################
#A Outliers
#Copy from here...
par(mfrow = c(1, 2))    # i numeri si riferiscono a righe e colonne#Two graphs next to each other
boxplot(GLM_line$MYODES.GAPPERI, 
        main = "Counts")
dotchart(GLM_line$MYODES.GAPPERI, 
         xlab = "Range of data", 
         ylab = "Order of the data")
# If there are non-numeric strings and you want to avoid warnings


par(mfrow = c(1, 2) #mar is white space: botton/left/top/right
dotchart(GLM_line$Width, main = "Width")

#Apply transformations
GLM_line$LogWidth  <- log(GLM_line$Width)



MyVar <- c("Width", "julian_date_scaled")

MyVar <- c("Width")
Mydotplot(GLM_data[ ,MyVar])


pairs(GLM_data[, MyVar])



#You need HighstatlibV10.R for this. No need to source
#it again though.
pairs(GLM_data[,c("Width", "julian_date_scaled")],
      lower.panel = panel.cor)

# corvif(SQ2[,MyVar])
# # If you are not familiar with VIF values, see our 2010 paper.
# # We tend to use 3 as cut-off level for a VIF.
# # In this case we could decide to keep all 4
# # covariates. But the Pearson correlation coefficient
# # of -0.7 is on the high side. non ? cosi alta 0,7 ma forse ? dovuto al fatto che 
# # la relazione non sembra lineare e pearson prende solo quelle lineari

#This will work as well. It is a wrapper around the pairs
#function. 

Mypairs(GLM_data[,MyVar])

# DONT WORK CAUSE ONLY ONE IS NUMERICAL


#How do you detect collinearity between a continuous covariate
#and a categorical? Make a conditional boxplot
par(mar = c(5,5,2,2))
boxplot(julian_date_scaled ~ factor(Habitat), 
        data = GLM_data,
        ylab = "Width",
        xlab = "Habitat Type",
        cex.lab = 1.5)

boxplot(Family ~ factor(Habitat), 
        data = GLM_Int,
        ylab = "Width",
        xlab = "Habitat Type",
        cex.lab = 1.5)


par(mar = c(5,5,2,2))
boxplot(Width ~ factor(Intensity_Use_2), 
        data = GLM_line,
        ylab = "Width",
        xlab = "Intensity of Use",
        cex.lab = 1.5)

par(mar = c(5,5,2,2))
boxplot(WellAband_DIST  ~ factor(Family), 
        data = GLM_data,
        ylab = "Width",
        xlab = "Footprint Type",
        cex.lab = 1.5)



par(mar = c(5,5,2,2))
boxplot(Width ~ factor(Footprint_Fine), 
        data = GLM_line,
        ylab = "Width",
        xlab = "Footprint Type",
        cex.lab = 1.5)

# #Remove the value with extreme large DBH value
# SQ2 <- subset(SQ, DBH < 0.6)
# dim(SQ)
# dim(SQ2)  #That's a small data set!
# #Remember the rule: We need 10-15-20 
# #observations per parameter (= beta)




######################################################################

MyVar <- c("MYODES.GAPPERI","Width", "julian_date_scaled")
pairs(GLM_data[, MyVar],
      lower.panel = panel.cor)

boxplot(PEROMYSCUS.MANICULATUS ~ factor(Habitat), 
        data = GLM_line,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")


boxplot(PEROMYSCUS.MANICULATUS ~ Month, 
        data = GLM_line,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Month",
        main = "")

boxplot(MYODES.GAPPERI ~ factor(Footprint_Type), 
        data = GLM_line,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Footprint Type",
        main = "")

boxplot(MYODES.GAPPERI ~ factor(Footprint_Fine), 
        data = GLM_line,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Footprint Type",
        main = "")

boxplot(MYODES.GAPPERI ~ factor(Intensity_Use_2), 
        data = GLM_line,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Intensity of Use",
        main = "")

boxplot(MYODES.GAPPERI ~ Family, 
        data = GLM_Int,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Month",
        main = "")


boxplot(PEROMYSCUS.MANICULATUS ~ Month, 
        data = GLM_Int,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Month",
        main = "")

boxplot(PEROMYSCUS.MANICULATUS ~ Habitat, 
        data = GLM_Int,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")

###########################

boxplot(TAMIASCIURUS.HUDSONICUS ~ Habitat, 
        data = GLM_data,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")

boxplot(RowSum ~ Position, 
        data = GLM_data,
        varwidth = TRUE,
        ylab = "Total Count",
        xlab = "Habitat",
        main = "")


boxplot(TAMIASCIURUS.HUDSONICUS ~ Family, 
        data = GLM_data,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")


boxplot(TAMIASCIURUS.HUDSONICUS ~ Month, 
        data = GLM_data,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")

boxplot(TAMIASCIURUS.HUDSONICUS~ Footprint_Type, 
        data = GLM_data,
        varwidth = TRUE,
        ylab = "Myodes Count",
        xlab = "Habitat",
        main = "")


# ####### C'è una conventional where we found 20 Myodes and one Pipeline where we found 35, 
####### Gotta check'em


# INTERACTIONS

xyplot(MYODES.GAPPERI ~ Width | factor(Habitat),
       data = GLM_data, 
       layout = c(3,1),
       xlab = "Width",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })

xyplot(MYODES.GAPPERI ~ Footprint_Type | Month,
       data = GLM_line, 
       layout = c(3,2),
       xlab = "Footprint Type",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })

xyplot(MYODES.GAPPERI ~ Footprint_Fine | Month,
       data = GLM_line, 
       layout = c(3,2),
       xlab = "Footprint Type",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })



xyplot(PEROMYSCUS.MANICULATUS ~ Habitat | Month,
       data = GLM_line, 
       layout = c(3,2),
       xlab = "Habitat",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })

xyplot(MYODES.GAPPERI ~ Habitat | Month,
       data = GLM_Int, 
       layout = c(3,2),
       xlab = "Habitat",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })

xyplot(MYODES.GAPPERI ~ Family | Month,
       data = GLM_Int, 
       layout = c(3,2),
       xlab = "Family",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(lm(y~x))        #Add regression line
       })


table(GLM_line$Month)
table(GLM_Int$Month)

##############
xyplot(MYODES.GAPPERI ~ factor(Habitat),
       data = GLM_line, 
       layout = c(1,1),
       xlab = "Width",
       ylab = "Myodes Count",
       panel=function(x,y){
         panel.points(x, y, col = 1)  #Add points
         panel.abline(glm(y~x))        #Add regression line
       })


##############################################
#F. Zero inflation
sum(GLM_line$MYODES.GAPPERI == 0)
100 * sum(GLM_line$MYODES.GAPPERI == 0) / nrow(GLM_line)
# [1] 123

# [1] 65.7754


# Based on our experience, you should raise your eyebrow
# if you have more than 20% of zeros. But this may be
# different for your data set.

##############################################



##############################################
#G. Are categorical covariates balanced?
table(GLM_line$Habitat) 
# Deciduous               Mixedwood Tamarack/Lowland Spruce 
# 70                      65                      52 
table(GLM_line$Footprint_Fine)
# Conventional seismic (more than 5m)   Low-impact seismic (less than 5m) 
# 63                                  53 
# Pipeline 
# 71 
table(GLM_line$Intensity_Use_2)
# None            Low       Moderate High, Moderate           High 
# 94             72             16              1              4 
# Intensity of Use isn't balanced at all
##############################################


#D. Spatial/temporal aspects of sampling

#We have already done part of this:
xyplot( Longitude ~ Latitude, 
       aspect = "iso", 
       data = GLM_line,
       col = GLM_line$Width, #1 = black, 2 = red
       pch = 16)

xyplot(Latitude ~ Longitude | factor(Habitat), 
       aspect = "iso", 
       data = GLM_line,
       col = 1,
       pch = 16)




# SEE CHAT ON HOW TO MAKE IT WORK
##############################################

M0 <- glm(MYODES.GAPPERI ~ Width,  data = GLM_line, family = poisson)

summary(M0)

drop1(M0, test = "F")


##############################################################
# Model validation

# Homogeneity
par(mfrow = c(1,1))
E0 <- resid(M0)   #better: E0 <- rstandard(M0)
F0 <- fitted(M0)
plot(x = F0,
     y = E0,
     xlab = "Fitted values",
     ylab = "Residuals",
     cex.lab = 1.5)
abline(h = 0, lty = 2)
#Ok-ish la variazione ? la stessa, si direbbe "minor indication for
# heterogenety

# boxplot(E0 ~ Ecosystem, data = Methane)
# #Hmmm


par(mfrow = c(1, 1))
hist(E0, breaks = 10)

# Dependence due to model misfit
plot(x = GLM_line$Width,
     y = E0,
     xlab = "Width",
     ylab = "Residuals")
abline(h = 0, lty = 2)


#G. Non-linear patterns

MyVar <- c("Width")
GLM_line$E0 <- E0  
MyMultipanel.ggp2(Z = GLM_line, 
                  varx = MyVar, 
                  vary = "E0", 
                  ylab = "Pearson residuals",
                  addSmoother = TRUE,
                  addRegressionLine = FALSE,
                  addHorizontalLine = TRUE)

# Patterns
plot(y = GLM_line$Width, 
     x = F0,
     xlab = "Fitted values",
     ylab = "Observed data",
     cex.lab = 1.5,
     xlim = c(0,60), 
     ylim = c(0,60) )
abline(coef = c(0, 1), lty = 2) 

# #Or use the Myxyplot function to plot E1 vs each continous (!!) covariate
# Birds$E1 <- E1   #Put E inside the Birds object (which will give trouble if there are NAs)
# MySel <- c("LogAREA","LogDIST","LogLDIST", "YR.ISOL","ALT")
# 
# Myxyplot(Birds, MySel, "E1", MyYlab = "Residuals")

##########
#Look at influential observations
par(mfrow = c(1, 1))
plot(cooks.distance(M0), type = "h", ylim = c(0, 1))
abline(h = 1, col = 2,lwd = 3)

#Or:
plot(M0, which = c(4))

# Obs 351, 396 and 410 are driving things

E0 <- resid(M0, type = "pearson")
N  <- nrow(GLM_line)
p  <- length(coef(M0))
sum(E0^2) / (N - p)   # Should be 1-ish. At the end of this
# solution file we will do a small simulation
# study to get a feel for the amount of variation
# that you can expect.
# Here it is: 11.44746
# That is way too large!

# Why do we have overdispersion?
# A. Outliers Y?           ==> Remove them?
# B. Missing covariates?   ==> Add them (or add a latent variable)
# C. Missing interactions? ==> Add them
# D. Zero inflation?       ==> ZIP / ZAP
# E. Large variance?       ==> NB or Generalized Poisson
# F. Correlation?          ==> GLMM
# G. Non-linear patterns   ==> GAM 
# H. Wrong link function   ==> Change it 


####################################################


############################################################################################
# Spatial independence?
MyCex <- abs(E0) / max(abs(E0)) # con abs do il valore assoluto dei residui
# cosi avro punti piu grandi se il residuo ? grande. vogli assicurarmi che residui 
# piccoli e grandi siano sovrapposti
MyCol <- E0
MyCol[E0 >= 0 ] <- 1  #black
MyCol[E0 < 0 ]  <- 2  #red

xyplot(Latitude ~ Longitude,
       cex =  4 * sqrt(MyCex),  #This is trial and error
       pch = 1, # con  questo valore dico quanto i punti debbano essere riempiti
       col = MyCol,
       data = GLM_line,
       main = "Sky at night?")



#Check spatial independence 
# The 'Check spatial independence' part is outside the scope of 
# the course and will not be discussed.
# Google variogram if you want to know what this is.
install.packages("gstat")
library(gstat)
library(sp)
library(rgdal)

#Transfer Longitude and Latitude to UTM coordinates
GLM_data$x<-GLM_data$Longitude
GLM_data$y<-GLM_data$Latitude
coordinates(GLM_data) <- c("x", "y")
proj4string(GLM_data) <- CRS("+proj=longlat +datum=WGS84")
latlong<-as.data.frame(spTransform(GLM_data, CRS("+init=epsg:28992"))) 



write.csv(GLM_line, file = "GLM_line.CSV")
#Datum = gps coordinate system you are using
#epsg = xy coordinate system you want your xy values to be in 
# Rijksdriehoek new (Amersfoort new)= 28992
# WGS 84 = 4326

#Convert from meters to km
latlong$xkm <- latlong$x / 1000
latlong$ykm <- latlong$y / 1000

#And finally make the variogram
mydata <- data.frame(E0, latlong$xkm, latlong$ykm)
coordinates(mydata) <- c("latlong.xkm", "latlong.ykm")
V1 <- variogram(E1 ~ 1, mydata, cutoff = 50)
plot(V1)



#Informal way to check spatial independence
plot(x = jitter(GLM_data$Longitude),
     y = jitter(GLM_data$Latitude),
     pch = 1,
     cex = 4 * sqrt(abs(E0) /max(abs(E0))),
     col = as.numeric(E0>1) + 1) #<---red for positive residuals, black for negative residuals
#This should be sky at night..no pattenrs
#I think there is spatial correlation



# #Identify the outlier
# #Copy and paste from here...
# par(mfrow = c(1, 1))
# plot(x = Fish$Xkm, 
#      y = Fish$Ykm)
# identify(x = Fish$Xkm, 
#          y = Fish$Ykm)
# #..to here. Click close to a point
# #Press ESCAPE to quit
# 
# 
# #Remove the spatial outlier
# Fish2 <- Fish[-136, ]
# dim(Fish2)






# USARE CHATGPT TO  SOLVE THIS AND FIND DEPENDENCE

################################################

library(MASS)
M2 <- glm.nb(MYODES.GAPPERI ~ Width,
             data = GLM_line)

# Dispersion statistic:
E2 <- resid(M2, type = "pearson")
N  <- nrow(GLM_line)
p  <- length(coef(M2)) + 1  # '+1' is due to theta
sum(E2^2) / (N - p) #0.7435763
# Minor underdispersion..so we can inspect the numerical output

plot(simulateResiduals(M2))


#Numerical output of the NB GLM:
summary(M2)


#Generalized R^2:

#                   Null deviance - residual deviance
#Generalized R^2 = ------------------------------------
#                           Null deviance
(150.46 - 128.85) / 150.46  # 0.1436262
#Small-ish
drop1(M2, test = "Chi")



######################################
# Model validation of the optimal NB GLM

# Plot residuals vs fitted values
F2 <- fitted(M2)
E2 <- resid(M2, type = "pearson")
par(mfrow = c(1,1), mar = c(5,5,2,2))
plot(x = F2, 
     y = E2,
     xlab = "Fitted values",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h = 0, lty = 2)
# ? buono, non ci sono pattern a cono e non ho molti zero


# Plot the residuals vs each covariate     
GLM_line$E2 <- E2
Myxyplot(GLM_line, MyVar, "E2")
# Don't get too fusy about points at the edges.
# We can't really fault the model. The small sample 
# size does not make it easy neither.
###########################################################







M1 <- glm(MYODES.GAPPERI ~ Width*Habitat,  data = GLM_line, family = poisson)

summary(M1)

drop1(M1, test = "F")

# Interaction non significativa





library(lme4)
# Fitting a GLMM with binary response
model <- glmer(MYODES.GAPPERI ~ Habitat + Width + (1|Month + ), 
               data = GLM_line, family = poisson())

summary(model)
