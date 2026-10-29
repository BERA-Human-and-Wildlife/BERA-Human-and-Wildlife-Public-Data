data$ZAPUS_BIN <- ifelse(data$ZAPUS.PRINCEPS > 0, 1, 0)

library(glmmTMB)

model_ZP<- glmmTMB(ZAPUS_BIN ~  log_Width_scale     , family = binomial, data = data)


# Extract residuals
residuals_glmmTMB_ZP <- residuals(model_ZP, type = "response") # Response residuals
head(residuals_glmmTMB_ZP) # View first few residuals

# You can also specify other types:
residuals_pearson_ZP <- residuals(model_ZP, type = "pearson") # Pearson residuals
residuals_deviance_ZP<- residuals(model_ZP, type = "deviance") # Deviance residuals


library(mgcv)

residgam_ZP <- gam(residuals_glmmTMB_ZP ~ s(Longitude,Latitude), family=gaussian)

autocov_ZP <- fitted(residgam_ZP)
data$autocov_ZP <- scale(fitted(residgam_ZP))[,1]

model_ZP<-glmmTMB(ZAPUS_BIN ~ log_Width_scale    + autocov_ZP 
                  , data = data, family = binomial)

summary(model_ZP)


# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_ZP)
print(r2)

library(glmm.hp)

glmm.hp(model_LP)




library(DHARMa)

# Create DHARMa simulation residuals
simulation_output_ZP <- simulateResiduals(fittedModel = model_ZP, n = 1000)

# Plot diagnostic plots
plot(simulation_output_ZP)

testDispersion(simulation_output_ZP)

testZeroInflation(simulation_output_ZP)





# Extract fixed effect estimates (mean)
estimates <- fixef(model_ZP)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_ZP, parm = "beta_", method = "Wald")  # Wald CI (default)
# Alternative: Use profile CIs (more accurate but computationally intensive)
# conf_intervals <- confint(model_MY, parm = "beta_", method = "profile")

# Combine estimates and confidence intervals
results <- data.frame(Estimate = estimates, 
                      Lower_95CI = conf_intervals[,1], 
                      Upper_95CI = conf_intervals[,2])

# Print results
print(results)



# Generate the base sjPlot model prediction plot
sjp_ZP <- plot_model(model_ZP, type = "pred", terms = "log_Width_scale [all") +
  theme_classic(base_size = 14) +  # Classic theme
  theme(
    plot.title = element_blank(),  # Remove title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )  +
  annotate("text", 
           x = 2.5, y = 0.28, 
           label = "Western jumping mouse (Zapus princeps)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.3),
    breaks = seq(0, 0.70, 0.1)
  )


# Manually override the fitted line and CI transparency
sjp_ZP$layers[[1]]$aes_params$size <- 1.3  # Set fitted line thickness
sjp_ZP$layers[[1]]$aes_params$colour <- "black"  # Force the fitted line to be black
sjp_ZP$layers[[2]]$aes_params$alpha <- 0.2  # Make confidence interval semi-transparent
sjp_ZP$layers[[2]]$aes_params$fill <- "#1f77b4"  # Set CI color to light blue

# Display the modified plot
print(sjp_ZP)

