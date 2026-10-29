################################################################################
# -------------- SMALL MAMMALS OCCUPANCY AND WIDTH --------------------------- #
################################################################################

# Set working directory --------------------------------------------------------
setwd("C:/Users/jacol/OneDrive/Desktop/ALL PAPERS PUBLISHING/THESIS_UoA_PhD_AlessF/")

# Load packages ----------------------------------------------------------------
source("C:/Users/jacol/OneDrive/Desktop/Ph.D. Thesis MODELING/Load_R_Packges_Statistics_Modelling.R")


# ------------------------------------------------------------------------------
# Bringing in the data - PITFALL -----------------------------------------------
data <- tibble(
  read.csv("Data_ALE.CSV", header = T)
)

glimpse(data)


# re category Ale curiosity
# Example: Modify the Footprint_Fine column
# Modify the Footprint_Fine column
data <- data %>%
  mutate(Footprint_Fine = fct_recode(as.factor(Footprint_Fine),
                                     "narrow_tolerance" = "Interior point",
                                     "narrow_tolerance" = "Low-impact seismic",
                                     "beyond_tolerance" = "Conventional Seismic",
                                     "beyond_tolerance" = "Pipeline/Transmission Line"))

# Check the result
table(data$Footprint_Fine)

# Where are there more zero rows
# Remove zerosum rows = no species detected
data_zeros <- data %>%
  filter(rowSums(across(LEPUS.AMERICANUS:ZAPUS.PRINCEPS)) == 0)
table(data_zeros$Position)

table(data$Position)

counts <- matrix(c(42, 18, 146-42, 157-18), nrow = 2, byrow = TRUE)
rownames(counts) <- c("Line", "Forest")  # Swap row labels

# Chi-square test --------------------------------------------------------------
chisq.test(counts)
# Fisher's exact test (useful if sample sizes are small)
fisher.test(counts)


# # Binomial test ----------------------------------------------------------------
# # Observed zero detections and total sample size
# zero_forest <- 18
# total_forest <- 157
# 
# zero_line <- 42
# total_line <- 146
# 
# # Binomial test for Forest (testing against its own proportion)
# binom_forest <- binom.test(zero_forest, total_forest, p = zero_forest/total_forest, alternative = "two.sided")
# 
# # Binomial test for Line (testing against the Forest proportion)
# binom_line <- binom.test(zero_line, total_line, p = zero_forest/total_forest, alternative = "two.sided")
# 
# # Print results
# binom_forest
# binom_line


# Logistic regression ----------------------------------------------------------
dat <- data.frame(
  Treatment = rep(c("Forest", "Line"), each = 2),
  Zero = c(1, 0, 1, 0),  # Now 1 = not detected, 0 = detected
  Count = c(18, 157-18, 42, 146-42)
)
library(glmmTMB)
glm_model <- glmmTMB(Zero ~ Treatment, weights = Count, family = binomial, data = dat)
summary(glm_model)
exp(1.1374)


species_matrix_abu <- data %>% 
  dplyr::select(LEPUS.AMERICANUS:ZAPUS.PRINCEPS) %>% # keep species
  drop_na()  # drops all NAs

species_matrix_abu <- species_matrix_abu %>%
  mutate(Z = ifelse(rowSums(.) > 0, 1, 0))
glimpse(species_matrix_abu)

data$Z <- species_matrix_abu$Z
data$Position <- as.factor(data$Position)
data$SP.Group <- as.factor(data$SP.Group)

library(DHARMa)
library(sjPlot)
glm_model_Position <- glmmTMB(Z ~ Position + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)
summary(glm_model_Position)
plot(simulateResiduals(glm_model_Position))
r.squaredGLMM(glm_model_Position)
plot_model(glm_model_Position, type="pred")

glm_model_WIDTH <- glmmTMB(Z ~ log_Width + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)
summary(glm_model_WIDTH)
plot(simulateResiduals(glm_model_WIDTH))
r.squaredGLMM(glm_model_WIDTH)
plot_model(glm_model_WIDTH, type="pred")


glm_model_FType <- glmmTMB(Z ~ as.factor(Footprint_Type) + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)
summary(glm_model_FType)
plot(simulateResiduals(glm_model_FType))
r.squaredGLMM(glm_model_FType)
plot_model(glm_model_FType, type="pred")


glm_model_FFine <- glmmTMB(Z ~ as.factor(Footprint_Fine) + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)
summary(glm_model_FFine)
plot(simulateResiduals(glm_model_FFine))
r.squaredGLMM(glm_model_FFine)
plot_model(glm_model_FFine, type="pred")






model.sel(glm_model_Position, glm_model_WIDTH)




# Extract fixed effect estimates
intercept <- fixef(glm_model_Position)$cond["(Intercept)"]
position_effect <- fixef(glm_model_Position)$cond["PositionLine"]

# Compute probabilities of species detection instead of zero detection
prob_forest <- 1 - plogis(intercept)
prob_line <- 1 - plogis(intercept + position_effect)

# Compute odds for each treatment
odds_forest <- prob_forest / (1 - prob_forest)
odds_line <- prob_line / (1 - prob_line)

# Compute odds ratio
odds_ratio <- odds_line / odds_forest

# Print results
odds_forest
odds_line
odds_ratio
# Species detection is 4.47 times more likely in Line than in Forest.



glm_model_Position <- glmer(Z ~ Position + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)

glm_model_WIDTH <- glmer(Z ~ log_Width_scale + Habitat + julian_date_scaled + (1|SP.Group), family = binomial, data = data)

glmm.hp(glm_model_Position)
glmm.hp(glm_model_WIDTH)

MuMIn::model.sel(glm_model_Position, glm_model_WIDTH)
mod.sel(glm_model_Position, glm_model_WIDTH)

plot(data$Z, data$Width)


library(ggplot2)
library(dplyr)

# Filter data for Position = "Line"
data_line <- data %>% filter(Position == "Line")

# Scatter plot of Z as a function of Width
ggplot(data_line, aes(x = Width, y = Z)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "glm", method.args = list(family = binomial), se = TRUE, color = "red") +
  labs(title = "Zero Detection (Z) vs. Width in Line",
       x = "Width",
       y = "Z (Zero Detection)") +
  theme_minimal()


# Fit a logistic regression model (Binomial GLM)
glm_width <- glm(Z ~ log_Width, family = binomial, data = data_line)

# Summary of the model
summary(glm_width)
plot_model(glm_width, type="pred")


# ------------------------------------------------------------------------------


################################################################################
# COMPOSITION ------------------------------------------------------------------
# TRANSFORMATION BASED RDA (Hellinger)

# Ordinations and allies with WIDTH --------------------------------------------
# -------------------------- Data formatting ----------------------------------- 

# ABUNDANCE MATRIX -------------------------------------------------------------

species_matrix_abu <- data %>% 
  dplyr::select(LEPUS.AMERICANUS:ZAPUS.PRINCEPS) %>% # keep species
  drop_na()  # drops all NAs


# Extract the part before the dot in column names
colnames(species_matrix_abu) <- sub("\\..*", "", colnames(species_matrix_abu))

# Check the updated column names
colnames(species_matrix_bin)

# # Rename columns to keep only genus names
# colnames(species_matrix_abu) <- sub("\\..*", "", colnames(species_matrix_abu))

# Transforming matrix for RDA
species_matrix_abu_hell <- vegan::decostand(species_matrix_abu, method = "hellinger")

# Checking if euclidean as assumption for RDA
ade4::is.euclid(dist(species_matrix_abu_hell))
# The warning message means that there is at least a Zero distance 
# in your d distance matrix. This should be caused by at least two identical rows 
# in your snp matrix (so the distance between them is equal to 0)

data$Width_scl <- scale(data$log_Width)
data$Julian_scl <- data$julian_date_scaled

# Fitting RDA
model_abu <- rda(species_matrix_abu_hell ~ Width_scl + Julian_scl + Habitat, data=data)

anova.cca(model_abu)
anova(model_abu, by = "margin")
RsquareAdj(model_abu)

# plot(model_abu, scaling=1)
# plot(model_abu, scaling=2)
# plot(model_abu, scaling=3
# ordiellipse(model_abu, data$Position, label = T)

# manualplotting
# Load required package
library(vegan)


# TRAITS
traits_select <- tibble(
  read.csv("Species_Traits_selected.csv", header=T)
)
traits <- traits_select %>%
  mutate(phylacine_binomial = sub("\\..*", "", phylacine_binomial))
glimpse(traits_select)


# PLOTTING ---------------------------------------------------------------------
# Base plot with sites as points
plot(model_abu, display = "sites", type = "p", main = "RDA Plot - ABUNDANCE", scaling = 2)

# Extract species scores
species_scores <- scores(model_abu, display = "species", scaling = 2)

# Scale trait values for point size
trait <- traits$Forest

# Add solid species points
points(species_scores, col = "red", cex = trait, pch = 19)

# Generate alternating position indices (left = 2, right = 4)
pos_vector <- rep(c(2, 4), length.out = nrow(species_scores))

# Add text with alternating positions
text(species_scores[,1] + ifelse(pos_vector == 4, 0.05, -0.05), 
     species_scores[,2] + 0.05, 
     labels = rownames(species_scores), 
     col = "Black", cex = 0.7, pos = pos_vector)

# Extract and plot environmental vectors
env_vectors <- scores(model_abu, display = "bp", scaling = 2)

arrows(0, 0, env_vectors[,1], env_vectors[,2], col = "blue", length = 0.1, lwd = 1)
# Add labels for environmental variables
text(env_vectors[,1] * 1.1, env_vectors[,2] * 1.1, 
     labels = rownames(env_vectors), col = "blue", cex = 0.9)
# ------------------------------------------------------------------------------









# BINARY MATRIX -------------------------------------------------------------
species_matrix_bin <- ifelse(species_matrix_abu > 0, 1, 0)
# Extract the part before the dot in column names
colnames(species_matrix_bin) <- sub("\\..*", "", colnames(species_matrix_bin))

# Check the updated column names
colnames(species_matrix_bin)
# Transforming matrix for RDA
species_matrix_bin_hell <- vegan::decostand(species_matrix_bin, method = "hellinger")

# Checking if euclidean as assumption for RDA
ade4::is.euclid(dist(species_matrix_bin_hell))
# The warning message means that there is at least a Zero distance 
# in your d distance matrix. This should be caused by at least two identical rows 
# in your snp matrix (so the distance between them is equal to 0)

data$Width_scl <- scale(data$log_Width)
data$Julian_scl <- data$julian_date_scaled

# Fitting RDA
model_bin <- rda(species_matrix_bin_hell ~ Width_scl + Julian_scl + Habitat, data=data)

anova.cca(model_bin)
anova(model_bin, by = "margin")
RsquareAdj(model_bin)

# plot(model_bin, scaling=1)
# plot(model_bin, scaling=2)
# plot(model_bin, scaling=3)
# ordiellipse(model_bin, data$Position, label = T)

# manualplotting
# Load required package
library(vegan)


# TRAITS
traits_select <- tibble(
  read.csv("Species_Traits_selected.csv", header=T)
)
glimpse(traits_select)

# PLOTTING ---------------------------------------------------------------------
# Base plot with sites as points
plot(model_bin, display = "sites", type = "p", main = "RDA Plot - BINARY", scaling = 2)

# Extract species scores
species_scores <- scores(model_bin, display = "species", scaling = 2)

# Scale trait values for point size
trait <- traits$Forest

# Add solid species points
points(species_scores, col = "red", cex = trait, pch = 19)

# Generate alternating position indices (left = 2, right = 4)
pos_vector <- rep(c(2, 4), length.out = nrow(species_scores))

# Add text with alternating positions
text(species_scores[,1] + ifelse(pos_vector == 4, 0.05, -0.05), 
     species_scores[,2] + 0.05, 
     labels = rownames(species_scores), 
     col = "Black", cex = 0.7, pos = pos_vector)

# Extract and plot environmental vectors
env_vectors <- scores(model_bin, display = "bp", scaling = 2)

arrows(0, 0, env_vectors[,1], env_vectors[,2], col = "blue", length = 0.1, lwd = 1)
# Add labels for environmental variables
text(env_vectors[,1] * 1.1, env_vectors[,2] * 1.1, 
     labels = rownames(env_vectors), col = "blue", cex = 0.9)
# ------------------------------------------------------------------------------





# VARIANCE PARTITIONING ---------------------------------------------------
library(vegan)

modelFULL <- rda(species_matrix_bin_hell ~ Width_scl + Julian_scl + Habitat + Latitude + Longitude, data=data)
anova(modelFULL, by="margin")
RsquareAdj(modelFULL)

# Define predictor groups
varpart_result <- varpart(species_matrix_bin_hell, 
                          ~ Width_scl, 
                          ~ Julian_scl, 
                          ~ Habitat, 
                          ~ data$Latitude + data$Longitude,
                          data = data)

# Print results
varpart_result

plot(varpart_result, digits = 3, cutoff = 0, bg = c("blue", "green", "red", "grey50"))


# Test the effect of Width_scl controlling for other predictors
rda_width <- rda(species_matrix_bin_hell ~ Width_scl + Condition(Julian_scl + Habitat + Latitude + Longitude), data = data)
anova(rda_width, permutations = 999)

# Test the effect of Julian_scl controlling for other predictors
rda_julian <- rda(species_matrix_bin_hell ~ Julian_scl + Condition(Width_scl + Habitat + Latitude + Longitude), data = data)
anova(rda_julian, permutations = 999)

# Test the effect of Habitat controlling for other predictors
rda_habitat <- rda(species_matrix_bin_hell ~ Habitat + Condition(Width_scl + Julian_scl + Latitude + Longitude), data = data)
anova(rda_habitat, permutations = 999)

# Test the effect of spatial predictors (Latitude & Longitude) controlling for others
rda_spatial <- rda(species_matrix_bin_hell ~ Latitude + Longitude + Condition(Width_scl + Julian_scl + Habitat), data = data)
anova(rda_spatial, permutations = 999)







# Computation using beta.div {adespatial} on 
# Hellinger-transformed species data
library(adespatial)
spe.beta <- beta.div(species_matrix_bin, method = "hellinger", nperm = 9999)
summary(spe.beta)
spe.beta$beta  # SSTotal and BDTotal


# LCBD values
spe.beta$LCBD
# p-values
spe.beta$p.LCBD

plot(spe.beta$LCBD, spe.beta$p.LCBD)

plot(spe.beta$LCBD, data$Position)
length(spe.beta$LCBD); length(data$Position)

# Which species have a SCBD larger than the mean SCBD?
spe.beta$SCBD[spe.beta$SCBD >= mean(spe.beta$SCBD)]

# Convert vector to dataframe
scbd_df <- data.frame(Taxa = names(spe.beta$SCBD), SCBD = spe.beta$SCBD)

# Reorder taxa by SCBD values in decreasing order
scbd_df <- scbd_df %>%
  arrange((SCBD)) %>%
  mutate(Taxa = factor(Taxa, levels = Taxa))



library(ggplot2)
library(dplyr)

# Reorder taxa by SCBD in decreasing order
scbd_df <- scbd_df %>%
  arrange(desc(SCBD)) %>%  # Arrange in descending order
  mutate(Taxa = factor(Taxa, levels = Taxa))  # Set factor levels to match sorted order

# Plot Taxa vs. SCBD
ggplot(scbd_df, aes(x = Taxa, y = SCBD)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +  # Flip axes for better readability
  labs(title = "SCBD Values by Taxa",
       x = "Taxa",
       y = "SCBD") +
  theme_minimal()








###############################################################################
library(ade4)

env <- as.data.frame(cbind(scale(log10(data$Width+1)), scale(data$Julian_Date)))
colnames(env) <- c("WIDTH", "JULIAN")
env$HABITAT <- as.factor(data$Habitat)


y <- as.data.frame(species_matrix_abu)
X <- env
TR <- as.data.frame(scale(as.numeric(traits$Forest)))

fourth <- ade4::fourthcorner(tabR = X, 
                             tabL = y, 
                             tabQ = TR, 
                             modeltype = 6, 
                             nrepet = 9999, 
                             p.adjust.method.G = "none", 
                             p.adjust.method.D = "none",
                             tr01 = FALSE)
fourth

# fourth.adj <- ade4::p.adjust.4thcorner(fourth,
#                                        p.adjust.method.G = "fdr", 
#                                        p.adjust.method.D = "fdr",
#                                        p.adjust.D = "global")
# fourth.adj

# plot(fourth, alpha = 0.05, stat="D2") 
# ERROR - Error in plot.window(...) : need finite 'ylim' values





####################################################################################
#  WITHIN GROUP BETA DIVERSITY---------------------------------------------------
# TURNOVER-ONLY COMPONENT

library(dplyr)

dat <- data %>%
  filter(rowSums(across(LEPUS.AMERICANUS:ZAPUS.PRINCEPS)) != 0)

species_matrix_abu <- dat %>% 
  dplyr::select(LEPUS.AMERICANUS:ZAPUS.PRINCEPS) %>% # keep species
  drop_na()  # drops all NAs

species_matrix_bin <- ifelse(species_matrix_abu>0,1,0)


dist <- beta.pair(species_matrix_bin, index.family="sorensen")
# Yields 3 distance matrices accounting for the spatial turnover and the nestedness components 
# To get the turnover partition between communities, type: dist[[1]].
# To get nestedness partition, type: dist[[2]]. 
# REPLACEMENT component

sim <- mean(dist$beta.sim) 
sor <- mean(dist$beta.sor)
sim*100/sor


turnover <- dist$beta.sim
nestedness <- dist$beta.sne

bd_repl <- betadisper(turnover, dat$Position) # Note this is all beta diversity.
bd_repl
anova(bd_repl)

plot(bd_repl)


bd_repl <- betadisper(turnover, dat$Habitat) # Note this is all beta diversity.
bd_repl
anova(bd_repl)

plot(bd_repl)


model_bin <- dbrda(turnover ~ log_Width + Julian_Date + Habitat, data=dat)
plot(model_bin)
anova.cca(model_bin)
anova(model_bin, by = "margin")
RsquareAdj(model_bin)




# SPECIES RICHNESS --------------------------------------------------------

################################################################################################

species_matrix_abu <- data %>% 
  dplyr::select(LEPUS.AMERICANUS:ZAPUS.PRINCEPS) %>% # keep species
  drop_na()  # drops all NAs
rich <- hill_taxa(species_matrix_abu, q=0)
data$rich <- rich
hist(rich)
summary(rich)

data$rich <- rich

glm_model_Position <- glmmTMB(rich ~ Position + Habitat + julian_date_scaled, family = nbinom2, data = data)
summary(glm_model_Position)
plot(simulateResiduals(glm_model_Position))
r.squaredGLMM(glm_model_Position)
plot_model(glm_model_Position, type="pred")

glm_model_WIDTH <- glmmTMB(rich ~ poly(Width_scale,2) + Habitat + julian_date_scaled, family = nbinom2, data = data)
summary(glm_model_WIDTH)
plot(simulateResiduals(glm_model_WIDTH))
r.squaredGLMM(glm_model_WIDTH)
plot_model(glm_model_WIDTH, type="pred")


glm_model_FType <- glmmTMB(rich ~ as.factor(Footprint_Type) + Habitat + julian_date_scaled + (1|SP.Group), family = nbinom2, data = data)
summary(glm_model_FType)
plot(simulateResiduals(glm_model_FType))
r.squaredGLMM(glm_model_FType)
plot_model(glm_model_FType, type="pred")


glm_model_FFine <- glmmTMB(rich ~ as.factor(Footprint_Fine) + Habitat + julian_date_scaled + (1|SP.Group), family = nbinom2, data = data)
summary(glm_model_FFine)
plot(simulateResiduals(glm_model_FFine))
r.squaredGLMM(glm_model_FFine)
plot_model(glm_model_FFine, type="pred")




















library(mvabund)
# MULTIVARIATE ABUNDANCE MODELS
# ABUNDANCE --------------------------------------------------------------------------

data$data_multiv_abu <- mvabund(species_matrix_abu)
data_multiv_abu <- data$data_multiv_abu
plot(data_multiv_abu)
meanvar.plot(data_multiv_abu)

plot(data_multiv_abu ~ as.factor(data$Habitat))
plot(data_multiv_abu ~ as.factor(data$Position))

multi_model <- manyglm(data_multiv_abu ~ Width + Julian_Date + Habitat, data=data, family="negative.binomial")
plot(multi_model)

anova(multi_model)

run <- anova(multi_model, p.uni = "adjusted")
run



ft=traitglm(y,X,scale(TR))
ft$fourth #print fourth corner terms
anova(ft)

ft1=traitglm(y,X,scale(TR),method="glm1path")
ft1$fourth #notice LASSO penalty has shrunk many interactions to zero
anova(ft1)



library(lattice)
a        = max( abs(ft1$fourth.corner) )
colort   = colorRampPalette(c("blue","white","red")) 
plot.4th = levelplot(t(as.matrix(ft1$fourth.corner)), xlab="Environmental Variables",
                     ylab="Species traits", col.regions=colort(100), at=seq(-a, a, length=100),
                     scales = list( x= list(rot = 45)))
print(plot.4th)

# ftspp1=traitglm(y,X,method="glm1path")

# ------------------------------------------------------------------------------


# gllvm -----------------------------------------------------------------------
# install.packages("gllvm")
library(gllvm)


# # Where are there more zero rows
# # Remove zerosum rows = no species detected
# data_zeros <- data %>%
#   filter(rowSums(across(LEPUS.AMERICANUS:ZAPUS.PRINCEPS)) != 0)
# table(data_zeros$Position)

species_matrix_abu <- data %>% 
  dplyr::select(LEPUS.AMERICANUS:ZAPUS.PRINCEPS) %>% # keep species
  drop_na()  # drops all NAs

data_multiv_abu <- mvabund(species_matrix_abu)
# Model where environmental variables, that is, all variables in X are included:
fit_ord <- gllvm(y = data_multiv_abu, family = "negative.binomial")
# Plot residuals for the NB model
par(mfrow = c(3, 2), mar = c(4, 4, 2, 1))
plot(fit_ord, var.colors = 1)
dev.off()

ordiplot(fit_ord, biplot = TRUE, ind.spp = 9, 
         # xlim = c(-3, 3), ylim = c(-3, 3), 
         main = "Biplot")
ordiplot(fit_ord, biplot = FALSE, ind.spp = 15, 
         # xlim = c(-3, 3), ylim = c(-3, 3), 
         main = "Ordination plot", predict.region = TRUE)

rownames(fit_ord$params$theta) <- paste("spp", 1:ncol(fit_ord$y), sep = "")
ordiplot(fit_ord, biplot = TRUE, ind.spp = 15, 
         # xlim = c(-3, 3), ylim = c(-2, 1.6), 
         main = "Biplot", jitter = TRUE, cex.spp = 0.8)



criteria <- NULL
for(i in 1:3){
  fiti <- gllvm(y, X, family = "negative.binomial", num.lv = i, sd.errors = FALSE,
                formula = ~ WIDTH + JULIAN + HABITAT, seed = 1234)
  criteria[i] <- summary(fiti)$AICc
  names(criteria)[i] = i
}

criteria # 1 latent variable


fit_env <- gllvm(y, X, family = "negative.binomial", num.lv = 1,
                 formula = ~ WIDTH + JULIAN + HABITAT, seed = 1234)

coefplot(fit_env, cex.ylab = 0.7, mar = c(4, 9, 2, 1), mfrow=c(1,1), order = F)

vp <- gllvm::varPartitioning(fit_env,
                             group = NULL,
                             groupnames = NULL,
) 
plotVarPartitioning(vp)

g=c(1, 1, 2, 2)
# # Specify group names m$covNames[-1] gives the included covariate names excluding the intercept
# groupnames = m$covNames[-1]
names = c("ENV", "HABITAT")

vp <- gllvm::varPartitioning(fit_env,
                      group = g,
                      groupnames = names,
) 

plotVarPartitioning(vp)



library(MuMIn)
fit_table <- dredge(fit_env,varying=list(num.lv=1), rank="AICc")
fit_table
# subset(fit_table, delta<2)


# Residual correlation matrix:
cr <- getResidualCor(fit_env)
library(corrplot); library(gclus)
#> corrplot 0.94 loaded
#> Loading required package: cluster

corrplot(cr[order.single(cr), order.single(cr)], diag = FALSE, type = "lower", 
         method = "square", tl.cex = 0.5, tl.srt = 45, tl.col = "red")




# TRAITS
traits_select <- tibble(
  read.csv("Species_Traits_selected.csv", header=T)
  )
glimpse(traits_select)

traits <- traits_select %>% 
  dplyr::select(phylacine_binomial, Forest)

traits <- as.data.frame(traits)
rownames(traits) <- traits$phylacine_binomial
traits <- traits %>% 
  dplyr::select(-phylacine_binomial)
traits <- scale(as.matrix(traits))

library(gllvm)

TR <- scale(as.matrix(traits))




fit_4th <- gllvm(y, X, TR, family = "negative.binomial", num.lv = 1,
                 formula = ~ WIDTH + JULIAN + HABITAT + WIDTH:Forest, 
                 row.eff = "random", seed = 123,
                 control.start =list(n.init = 3, jitter.var = 0.01),
                 )
plot(fit_4th)
coefplot.gllvm(fit_4th)


dev.off()
randomCoefplot(fit_4th,
               which.Xcoef = "WIDTH", order=T)






fourth <- fit_4th$fourth.corner
a <- 1.5
colort <- colorRampPalette(c("blue", "white", "red"))
plot.4th <- levelplot((as.matrix(fourth)), xlab = "Environmental Variables", 
                      ylab = "Species traits", col.regions = colort(100), cex.lab = 1.3, 
                      at = seq(-a, a, length = 100), scales = list(x = list(rot = 45)))
plot.4th



anova(fit_4th, fit_env)


dev.off()


g=c(1, 2, 3, 3)
# # Specify group names m$covNames[-1] gives the included covariate names excluding the intercept
# groupnames = m$covNames[-1]
names = c("WIDTH", "JULIAN", "HABITAT")
vp <- varPartitioning(fit_4th,
                      group = g,
                      groupnames = names,
                      ) 

plotVarPartitioning(vp)









par(mfrow=c(1,1))  # Single panel for clarity

library(RColorBrewer)  # For better colors

# Extract original environmental variables
X_original <- as.data.frame(fit_4th$X)

# Identify species in the model
species_names <- colnames(fit_4th$y)

# Select range of WIDTH for prediction
WIDTH_range <- seq(min(X_original$WIDTH, na.rm=TRUE), max(X_original$WIDTH, na.rm=TRUE), length.out=100)

# Fix other environmental variables at their median
newX_template <- apply(X_original, 2, median, na.rm=TRUE)

# Prepare a dataframe for prediction
newX <- as.data.frame(matrix(rep(newX_template, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
colnames(newX) <- colnames(X_original)  # Ensure names match
newX$WIDTH <- WIDTH_range  # Only vary WIDTH

# Use mean latent variables for predictions
LVs <- getLV(fit_4th)
mean_LVs <- colMeans(LVs, na.rm = TRUE)
newLV <- as.data.frame(matrix(rep(mean_LVs, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
colnames(newLV) <- colnames(LVs)

# **Predict responses for all species (USE "LINK" SCALE FIRST)**
pred_link <- predict(fit_4th, type = "link", newLV = newLV, newX = newX)  # Keep on link scale

# **Transform to response scale manually**
preds <- plogis(pred_link)  # Convert to response probability (ensures correct scaling)

# **Choose more distinctive colors**
num_species <- ncol(preds)
species_colors <- brewer.pal(min(num_species, 9), "Set1")  # Use Set1 for better contrast

# **Fix y-axis scaling**
plot(NA, ylim = c(0, 0.7), xlim = range(WIDTH_range, na.rm=TRUE),
     ylab = "Predicted Occurrence Probability", xlab = "WIDTH")

# Add curves for each species with thicker lines
for (j in 1:ncol(preds)) {
  lines(WIDTH_range, preds[, j], lwd = 3, col = species_colors[j])
}

# Add legend
legend("topright", legend = species_names, col = species_colors, lwd = 3, cex = 0.9)






# Extract original environmental variables
X_original <- as.data.frame(fit_4th$X)

# Identify species in the model
species_names <- colnames(fit_4th$y)

# Select range of WIDTH for prediction
WIDTH_range <- seq(min(X_original$WIDTH, na.rm=TRUE), max(X_original$WIDTH, na.rm=TRUE), length.out=100)

# Fix other environmental variables at their median
newX_template <- apply(X_original, 2, median, na.rm=TRUE)

# Use mean latent variables for predictions
LVs <- getLV(fit_4th)
mean_LVs <- colMeans(LVs, na.rm = TRUE)

# Set up plotting layout (adjust depending on number of species)
num_species <- length(species_names)
par(mfrow=c(ceiling(sqrt(num_species)), ceiling(sqrt(num_species))))  # Grid layout

# Loop over species and plot each separately with confidence intervals
for (j in 1:num_species) {
  # Prepare a dataframe for prediction
  newX <- as.data.frame(matrix(rep(newX_template, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
  colnames(newX) <- colnames(X_original)  # Ensure names match
  newX$WIDTH <- WIDTH_range  # Only vary WIDTH
  
  # Create newLV using mean latent variables
  newLV <- as.data.frame(matrix(rep(mean_LVs, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
  colnames(newLV) <- colnames(LVs)
  
  # Predict responses (returns a matrix)
  pred_link <- predict(fit_4th, type = "link", newLV = newLV, newX = newX, se = TRUE)
  
  # Extract predictions for species j
  pred_fit <- pred_link[, j]  # Mean predicted value
  pred_se <- sqrt(var(pred_link[, j]))  # More stable SE estimation
  
  # Convert to response scale (if using logit/probit link function)
  preds <- plogis(pred_fit)  # Convert predictions
  lower_CI <- plogis(pred_fit - 1.96 * pred_se)  # Lower 95% CI
  upper_CI <- plogis(pred_fit + 1.96 * pred_se)  # Upper 95% CI
  
  # Ensure probability limits between 0 and 1
  lower_CI <- pmax(lower_CI, 0)
  upper_CI <- pmin(upper_CI, 1)
  
  # **Fix axis scaling: Set ylim to include CIs**
  y_limits <- range(c(preds, lower_CI, upper_CI), na.rm = TRUE)
  
  # Plot species-specific response
  plot(WIDTH_range, preds, type = "l", lwd = 2, col = "black",
       xlab = "WIDTH", ylab = "Predicted Occurrence Probability",
       main = species_names[j], ylim = y_limits)
  
  # Add confidence intervals as shaded area
  polygon(c(WIDTH_range, rev(WIDTH_range)), 
          c(lower_CI, rev(upper_CI)), 
          col = rgb(0, 0, 0, 0.2), border = NA)
  
  # Add CI lines
  lines(WIDTH_range, lower_CI, lty = 2, col = "gray")
  lines(WIDTH_range, upper_CI, lty = 2, col = "gray")
}






# Extract original environmental variables
X_original <- as.data.frame(fit_4th$X)

# Identify species in the model
species_names <- colnames(fit_4th$y)

# Select range of WIDTH for prediction
WIDTH_range <- seq(min(X_original$WIDTH, na.rm=TRUE), max(X_original$WIDTH, na.rm=TRUE), length.out=100)

# Fix other environmental variables at their median
newX_template <- apply(X_original, 2, median, na.rm=TRUE)

# Use mean latent variables for predictions
LVs <- getLV(fit_4th)
mean_LVs <- colMeans(LVs, na.rm = TRUE)

# Set up plotting layout (adjust depending on number of species)
num_species <- length(species_names)
par(mfrow=c(ceiling(sqrt(num_species)), ceiling(sqrt(num_species))))  # Grid layout

# Loop over species and plot each separately with confidence intervals
for (j in 1:num_species) {
  # Prepare a dataframe for prediction
  newX <- as.data.frame(matrix(rep(newX_template, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
  colnames(newX) <- colnames(X_original)  # Ensure names match
  newX$WIDTH <- WIDTH_range  # Only vary WIDTH
  
  # Create newLV using mean latent variables
  newLV <- as.data.frame(matrix(rep(mean_LVs, each = length(WIDTH_range)), nrow = length(WIDTH_range)))
  colnames(newLV) <- colnames(LVs)
  
  # Predict responses (returns a matrix)
  pred_link <- predict(fit_4th, type = "link", newLV = newLV, newX = newX, se = TRUE)
  
  # Extract predictions for species j
  pred_fit <- pred_link[, j]  # Mean predicted value
  pred_se <- sqrt(var(pred_link[, j]))  # More stable SE estimation
  
  # Convert to response scale (if using logit/probit link function)
  preds <- plogis(pred_fit)  # Convert predictions
  lower_CI <- plogis(pred_fit - 1.96 * pred_se)  # Lower 95% CI
  upper_CI <- plogis(pred_fit + 1.96 * pred_se)  # Upper 95% CI
  
  # Ensure probability limits between 0 and 1
  lower_CI <- pmax(lower_CI, 0)
  upper_CI <- pmin(upper_CI, 1)
  
  # **Fix axis scaling: Set ylim to include CIs**
  y_limits <- range(c(preds, lower_CI, 0.85), na.rm = TRUE)
  
  # Plot species-specific response
  plot(WIDTH_range, preds, type = "l", lwd = 2, col = "black",
       xlab = "WIDTH", ylab = "Predicted Occurrence Probability",
       main = species_names[j], ylim = y_limits)
  
  # Add confidence intervals as shaded area
  polygon(c(WIDTH_range, rev(WIDTH_range)), 
          c(lower_CI, rev(upper_CI)), 
          col = rgb(0, 0, 0, 0.2), border = NA)
  
  # Add CI lines
  lines(WIDTH_range, lower_CI, lty = 2, col = "gray")
  lines(WIDTH_range, upper_CI, lty = 2, col = "gray")
}






# HMSC --------------------------------------------------------------------

library(Hmsc) 
library(tidyverse)
library(viridis)
library(vioplot)
library(abind)
library(RColorBrewer)
library(ape)
library(corrplot)



traits <- traits_select %>% 
  dplyr::select(phylacine_binomial, adult_mass_g, habitat_breadth_n, dispersal_km, Home_Range_km2, Forest)

traits <- as.data.frame(traits)
rownames(traits) <- traits$phylacine_binomial
traits <- traits %>% 
  dplyr::select(-phylacine_binomial)

traits <- traits %>%
  mutate(adult_mass_g = log10(adult_mass_g))  

traits <- scale(as.matrix(traits))
TR <- traits
dim(TR)

TR


env <- as.data.frame(cbind(data$Habitat, scale(log10(data$Width+1)), scale(data$Julian_Date)))
colnames(env) <- c("HABITAT", "WIDTH", "JULIAN")
dim(env)
env$HABITAT <- as.factor(env$HABITAT)
env$WIDTH <- as.numeric(env$WIDTH)
env$JULIAN <- as.numeric(env$JULIAN)
env


taxo <- traits_select %>% 
  dplyr::select(order, family, genus, phylacine_binomial)

taxo <- as.data.frame(lapply(taxo, as.factor)) # make factors
str(taxo) # now they are!

# build the tree  
tree<-as.phylo(~order/family/genus/phylacine_binomial, data=taxo, collapse = FALSE) 
plot(tree)

# Assuming your tree is named `tree`
# is.ultrametric(tree)  # Should return TRUE if branch lengths are set correctly
is.rooted(tree)  # Should be TRUE (Hmsc requires a rooted tree)
sum(tree$edge.length)  # If branch lengths exist, this should return a positive number
# you can set all branches to 1 (not recommended for real analyses):
tree$edge.length <- rep(1, nrow(tree$edge))  # Uniform branch lengths
sum(tree$edge.length)

# C_phylo <- vcv(tree, cor = TRUE)  # Compute phylogenetic correlation matrix
# tree$edge.length <- compute.brL_sampleen(tree, method = "Grafen")  # Adds branch lengths



# Setting HMSC model

# Define regression model for environmental covariates
XFormula = as.formula(paste("~",paste(colnames(env), collapse="+")))
XFormula 
# XFormula = ~ WIDTH + JULIAN

# Define regression model for traits
TrFormula = as.formula(paste("~",paste(colnames(TR), collapse="+")))
# TrFormula
TrFormula = ~Forest

# Specify (unfitted) HMSC model structure

abu <- as.data.frame(species_matrix_abu)
traits <- as.data.frame(TR)
env <- as.data.frame(env)




# Set up study design with spatial random effect
coo <- data %>% 
  dplyr::select(Longitude, Latitude)
coo <- as.data.frame(coo)

site <- data %>% 
  dplyr::select(SP.Group)
site <- as.data.frame(site)


studyDesign <- data.frame(
  sample = as.factor(rownames(coo)),  # Spatial level (303 rows)
  site = as.factor(site$SP.Group)        # Site-level effect (303 rows)
)

# Spatially explicit random effect (existing)
rL_sample <- HmscRandomLevel(sData = coo) # random effect defined as spatially explicit based on the coords of the grid cell
rL_sample
head(rL_sample$pi)

# Site-level random effect (SP.group) - no spatial structure, just grouping
sites <- studyDesign$site
rL_site <- HmscRandomLevel(units = levels(sites))  
rL_site
head(rL_site$pi)


# rL_phylo <- HmscRandomLevel(sData = C_phylo)
# # # Species level random effect
# # # species should NOT be included in studyDesign, because species are modeled as a separate random effect, and abu is structured as sites × species (i.e., species are columns, not rows).
# # species <- as.factor(colnames(abu))
# # rL_species <- HmscRandomLevel(units = levels(species))
# # rL_species
# # head(rL_species$pi)



# occu <- as.data.frame(ifelse(abu > 1, 1, 0))

m <- Hmsc(
  Y = abu, 
  XData = env, 
  XFormula = XFormula, 
  TrFormula = TrFormula,  
  TrData = traits,        
  phyloTree = tree,       
  studyDesign = studyDesign,  
  ranLevels = list(
    "sample" = rL_sample,    # Spatial effect
    "site" = rL_site         # Site-level effect
  ),
  distr = "normal"
)

m


# MCMC specifications ---------------------------------------------------------
# test.run = TRUE  
# 
# if (test.run) {
#   thin = 1  
#   samples = 1000  
#   transient = ceiling(0.1 * samples * thin)
#   nChains = 4  
#   adapt = 1000  
# } else { 
#   thin = 1  
#   samples = 10000  # Increase samples
#   transient = ceiling(0.1 * samples * thin)
#   nChains = 4  # Increase chains
#   adapt = 2000  
# }

thin = 1  
samples = 1000  
transient = ceiling(0.1 * samples * thin)
nChains = 4  
adapt = 1000  

# MODEL FITTING ---------------------------------------------------------------------------------
m = sampleMcmc(m, thin = thin, samples = samples, transient = transient, nChains = nChains, nParallel = nChains) 
# # You can also run chains in parallel by adding 'nParallel = nChains' in the sampleMCMC() function, but you won't see the progress of the run until it finished.
# 
# filename =  paste("NorthAtlantic","_thin_", as.character(thin),"_samples_", as.character(samples),"_chains_", as.character(nChains), ".Rdata",sep = "")
# 
# save(m,file=filename)
saveRDS(m, file = "hmsc_model.rds")

m <- readRDS("hmsc_model.rds")

# convert model to coda object
mpost = convertToCodaObject(m)

plot(mpost$Beta)

# check effective sample size 
# should ideally be close to your drawn samples, here, 4 (chains) * 250 (samples) = 1000 samples)
summary(effectiveSize(mpost$Beta)) 

gelman.diag(mpost$Beta)  # Check convergence across chains
gelman.diag(mpost$Gamma)  # Check convergence across chains

# check the distribution of the effective sample size (ess) 
# and the Gelman-Rubin potential scale reduction factor (psrf), 
# the latter should be ideally (very) close to 1, if not, 
# chains did not properL_sampley converge and need more iterations. 
# These should be checked for all parameters of interest, i.e. beta and gamma
# Provided model looks quite okay already but could be better.

par(mfrow=c(1,3))
# Beta parameters (species-environment) 
hist(effectiveSize(mpost$Beta), main="ess(beta)")
hist(gelman.diag(mpost$Beta, multivariate = FALSE)$psrf, main="psrf(beta)")
vioplot(gelman.diag(mpost$Beta,multivariate = FALSE)$psrf,main="psrf(beta)")


# Gamma parameters (trait-environment)
hist(effectiveSize(mpost$Gamma), main="ess(gamma)")
hist(gelman.diag(mpost$Gamma, multivariate = FALSE)$psrf, main="psrf(gamma)")
vioplot(gelman.diag(mpost$Gamma,multivariate = FALSE)$psrf,main="psrf(gamma)")


head(m$X)



# compute predicted species abundance matrix/ posterior samples 
predY=computePredictedValues(m)



MF = evaluateModelFit(hM = m, predY = predY)
# MF
mean(MF$R2)


#Here, we take the mean of posterior samples for further processing
predY = apply(abind(predY,along=3),c(1,2), mean)
dev.off()
# Plot species specific R2 in relation to prevalence
plot(colSums(((m$Y>0)*1)/m$ny), MF$R2,main=paste("Mean R2 = ", round(mean(MF$R2),2),".", sep=""), xlab = "Prevalence")


# 4.3 Varience Partitioning
par(mfrow=c(1,1))
# # Specify groups of how the variation should be partitioned You can also combine groups 
group=c(1,1, 1, 2, 3)
# # Specify group names m$covNames[-1] gives the included covariate names excluding the intercept
# groupnames = m$covNames[-1]
groupnames = c("HABITAT", "WIDTH", "JULIAN")

# group=c(1,2)
# # Specify group names m$covNames[-1] gives the included covariate names excluding the intercept
# groupnames = m$covNames[-1]


#compte species specific variance partitioning
VP = computeVariancePartitioning(hM = m, group = group, groupnames = groupnames)

plotVariancePartitioning(m, VP, viridis(5))


# 4.4 Plot species-environment relationships
# Shown are all species with 90% posterior support for having positive (red) or negative(blue) responses to environmental covariates
beta = getPostEstimate(m, "Beta")
plotBeta(m, beta, supportLevel=.75, spNamesNumbers = c(FALSE, FALSE), covNamesNumbers = c(TRUE, FALSE), plotTree = T)


# 4.5 Plot trait-environment relationships
gamma = getPostEstimate(m, "Gamma")
plotGamma(m, gamma, supportLevel=.75) 


# We can ask about the influence of traits on species abundances, i.e. how much do traits explain out of the variation in species abundances
VP$R2T$Y

# The traits explain only 6% of variation in species abundances 
# Let us then ask how much the traits explain out of the variation among the species 
# in their responses to environmental covariates.

VP$R2T$Beta
barplot(VP$R2T$Beta[-1])



# Construct environmental Gradient based on fitted model, specify your focal variable. 
Gradient = constructGradient(m, focalVariable="WIDTH")
# make predictions based on fitted model 
predYgradient = predict(m,
                        XData=Gradient$XDataNew, 
                        ranLevels = Gradient$rLNew, 
                        studyDesign = Gradient$studyDesignNew, 
                        expected = TRUE) 

# par(mfrow=c(2,4))
# measure = T implies trait relationship to focal variable, 
# index = 2 implies second trait of trait matrix (1 is the intercept). 

# traits ~ WIDTH 
plotGradient(m, Gradient, pred=predYgradient, measure="T", index = 2, showData =F)
# plotGradient(m, Gradient, pred=predYgradient, measure="T", index = 3, showData =F)
# plotGradient(m, Gradient, pred=predYgradient, measure="T", index = 4, showData =F)
# plotGradient(m, Gradient, pred=predYgradient, measure="T", index = 5, showData =F)


plotGradient(m, Gradient, pred=predYgradient, measure="S", showData =F)


# 4.8 Species co-occurrance patterns at random effect level
# Here we illustrate the residual association plot among species at the level of grid cell. 
# sites of species illustrated by red and blue show positive and negative associations, respectively, 
# with statistical support of at least 75% posterior probability

par(mfrow=c(1,1))
OmegaCor = computeAssociations(m)
supportLevel = 0.75
for (r in 1:m$nr){ 
  plotOrder = corrMatOrder(OmegaCor[[r]]$mean,order="AOE") 
  toPlot = ((OmegaCor[[r]]$support>supportLevel) + (OmegaCor[[r]]$support<(1-supportLevel))>0)*OmegaCor[[r]]$mean 
  par(xpd=T) 
  colnames(toPlot)=rownames(toPlot)=gsub("_"," ",x=colnames(toPlot)) 
  corrplot(toPlot[plotOrder,plotOrder], method = "color", col=colorRampPalette(c("blue","white","red"))(200), title=paste("random effect level:",m$rL_sampleNames[r]),type="full",tl.col="black",tl.cex=1, mar=c(0,0,6,0))
}  





# Step 1: Construct Environmental Gradient for WIDTH
Gradient = constructGradient(m, focalVariable = "WIDTH")

# Step 2: Predict Species-Specific Responses Along WIDTH
predYgradient = predict(m, 
                        XData = Gradient$XDataNew, 
                        ranLevels = Gradient$rLNew, 
                        studyDesign = Gradient$studyDesignNew, 
                        expected = T)

# Step 3: Plot Responses for All Species
par(mfrow = c(3, 3))  # Adjust layout (3x3 grid for 9 species)
for (species_index in 1:9) {
  plotGradient(m, Gradient, pred = predYgradient, measure = "Y",
               index = species_index, showData = F,
               main = paste("Species", species_index))
}

# Step 3: Plot Responses for All Species
par(mfrow = c(3, 3))  # Adjust layout (3x3 grid for 9 species)
for (species_index in 1:9) {
  plotGradient(m, Gradient, pred = predYgradient, measure = "Y", 
               index = species_index, showData = T, 
               main = paste("Species", species_index))
}











# Fitting RDA
model_bin <- rda(species_matrix_bin_hell ~ Footprint_Fine + Julian_scl, data=data)
plot(model_bin)
ordiellipse(model_bin, data$Footprint_Fine, label=T)
anova.cca(model_bin)
anova(model_bin, by = "margin")
RsquareAdj(model_bin)
