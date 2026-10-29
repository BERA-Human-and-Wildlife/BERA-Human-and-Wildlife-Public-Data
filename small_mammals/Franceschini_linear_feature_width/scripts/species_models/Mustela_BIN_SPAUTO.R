

library(glmmTMB)

data$MUSTELA_ERMINEA_BINOMIAL <- ifelse(data$MUSTELA.ERMINEA > 0, 1, 0)

model_MU <- glmmTMB(MUSTELA_ERMINEA_BINOMIAL ~  log_Width_scale + Habitat  + julian_date_scaled +(1 | SP.Group),
                 family = binomial,
                 data = data)

summary(model_MU)
# Extract residuals
residuals_glmmTMB_MU <- residuals(model_MU, type = "response") # Response residuals
head(residuals_glmmTMB_MU) # View first few residuals

# You can also specify other types:
residuals_pearson_MU <- residuals(model_MU, type = "pearson") # Pearson residuals
residuals_deviance_MU <- residuals(model_MU, type = "deviance") # Deviance residuals


library(mgcv)

residgam_MU <- gam(residuals_glmmTMB_MU ~ s(Longitude,Latitude), family=gaussian)

autocov_MU <- fitted(residgam_MU)
data$autocov_MU <- scale(fitted(residgam_MU))[,1]

model_MU<-glmmTMB(MUSTELA_ERMINEA_BINOMIAL ~  log_Width_scale + julian_date_scaled  + Habitat  + autocov_MU + (1 | SP.Group),
                  family = binomial,
                  data = data)

summary(model_MU)

plot_model(model_MU,type = "pred")



library(glmm.hp)

glmm.hp(model_MU)

# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_MU)
print(r2)
check_model(model_MU)
r2_marginal <- r2$R2_marginal
r2_conditional <- r2$R2_conditional
rounded_r2_marginal <- round(r2_marginal, 2)
rounded_r2_conditional <- round(r2_conditional, 2)



# Extract fixed effect estimates (mean)
estimates <- fixef(model_MU)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_MU, parm = "beta_", method = "Wald")  # Wald CI (default)
# Alternative: Use profile CIs (more accurate but computationally intensive)
# conf_intervals <- confint(model_MY, parm = "beta_", method = "profile")

# Combine estimates and confidence intervals
results <- data.frame(Estimate = estimates, 
                      Lower_95CI = conf_intervals[,1], 
                      Upper_95CI = conf_intervals[,2])

# Print results
print(results)



library(DHARMa)

# Create DHARMa simulation residuals
simulation_output_MU <- simulateResiduals(fittedModel = model_MU, n = 1000)

# Plot diagnostic plots
plot(simulation_output_MU)

testDispersion(simulation_output_MU)

testZeroInflation(simulation_output_MU)





# Load required libraries
library(sjPlot)
library(ggplot2)

# Generate the base sjPlot model prediction plot
sjp_MU <- plot_model(model_MU, type = "pred", terms = "log_Width_scale [all") +
  theme_classic(base_size = 14) +  # Classic theme
  theme(
    plot.title = element_blank(),  # Remove title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )  +
  annotate("text", 
           x = Inf, y = 0.15, 
           label = "Short-tailed weasel (Mustela erminea)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.16),
    breaks = seq(0, 0.70, 0.04)
  )


# Manually override the fitted line and CI transparency
sjp_MU$layers[[1]]$aes_params$size <- 1.3  # Set fitted line thickness
sjp_MU$layers[[1]]$aes_params$colour <- "black"  # Force the fitted line to be black
sjp_MU$layers[[2]]$aes_params$alpha <- 0.2  # Make confidence interval semi-transparent
sjp_MU$layers[[2]]$aes_params$fill <- "#1f77b4"  # Set CI color to light blue

# Display the modified plot
print(sjp_MU)




library(glmmTMB)
library(dplyr)
library(ggplot2)
library(lubridate)
library(performance)

# Manually scale Julian Date and store mean and standard deviation
julian_mean <- mean(data$Julian_Date, na.rm = TRUE)  # Calculate mean
julian_sd <- sd(data$Julian_Date, na.rm = TRUE)      # Calculate standard deviation

data <- data %>%
  mutate(julian_date_scaled = (Julian_Date - julian_mean) / julian_sd)

# Fit the model
model_MU <- glmmTMB(MUSTELA_ERMINEA_BINOMIAL ~ julian_date_scaled + Habitat +
                      log_Width + autocov_MU + (1 | SP.Group),
                    family = binomial,
                    data = data)

summary(model_MU)

simulation_output_MU <- simulateResiduals(fittedModel = model_MU, n = 1000)

# Plot diagnostic plots
plot(simulation_output_MU)

testDispersion(simulation_output_MU)

testZeroInflation(simulation_output_MU)

# Generate predictions for a sequence of julian_date_scaled values while holding other covariates constant
julian_scaled_seq <- seq(min(data$julian_date_scaled), max(data$julian_date_scaled), length.out = 100)
log_width_mean <- mean(data$log_Width, na.rm = TRUE)
autocov_mean <- mean(data$autocov_MU, na.rm = TRUE)

new_data <- data.frame(
  julian_date_scaled = julian_scaled_seq,
  log_Width = log_width_mean,
  autocov_MU = autocov_mean,
  SP.Group = NA  # Random effect groups are included implicitly
)

# Get predicted probabilities and confidence intervals
predictions <- predict(model_MU, newdata = new_data, type = "response", se.fit = TRUE)
new_data <- new_data %>%
  mutate(
    probability = predictions$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions$se.fit)
  )

# Reverse the scaling of julian_date_scaled to get real Julian Dates
new_data <- new_data %>%
  mutate(
    Julian_Date = julian_date_scaled * julian_sd + julian_mean,
    Real_Date = as.Date(Julian_Date - 1, origin = "2023-01-01")  # Convert to real calendar dates
  )

# Calculate R² values
r2 <- r2_nakagawa(model_MU)

# Publication-quality Plot with Real Dates
ggplot(new_data, aes(x = Real_Date, y = probability)) +
  geom_line(color = "black", size = 1.2) +  # Line for predicted probability
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3, fill = "#1f77b4") +  # Confidence interval ribbon
  scale_x_date(name = "Date", date_labels = "%b %d") +  # Format the x-axis as dates
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  annotate("text", x = max(new_data$Real_Date) - 10, y = 0.9, 
           label = bquote(Marginal~R^2 == .(round(r2$R2_marginal, 2))), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data$Real_Date) - 10, y = 0.85, 
           label = bquote(Conditional~R^2 == .(round(r2$R2_conditional, 2))), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +  # Classic theme suitable for publications
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()  # No gridlines for simplicity
  ) 





ggplot(new_data, aes(x = Real_Date, y = probability)) +
  geom_line(color = "black", size = 1.2) +  # Line for predicted probability
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3, fill = "#1f77b4") +  # Confidence interval ribbon
  scale_x_date(name = "Date", date_labels = "%b %d") +  # Format the x-axis as dates
  scale_y_continuous(name = "Detection Probability", limits = c(0, 0.25)) +  # Adjust y-axis to a maximum of 0.25
  annotate("text", x = max(new_data$Real_Date) - 10, y = 0.23, 
           label = bquote(Marginal~R^2 == .(round(r2$R2_marginal, 2))), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data$Real_Date) - 10, y = 0.21, 
           label = bquote(Conditional~R^2 == .(round(r2$R2_conditional, 2))), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +  # Classic theme suitable for publications
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()  # No gridlines for simplicity
  )





# Generate predictions for a sequence of log_Width values while holding other covariates constant
log_width_seq <- seq(min(data$log_Width), max(data$log_Width), length.out = 100)
julian_mean <- mean(data$julian_date_scaled, na.rm = TRUE)
autocov_mean <- mean(data$autocov_MU, na.rm = TRUE)

new_data_width <- data.frame(
  log_Width = log_width_seq,
  julian_date_scaled = julian_mean,
  autocov_MU = autocov_mean,
  SP.Group = NA  # Random effect groups are included implicitly
)

# Get predicted probabilities and confidence intervals
predictions_width <- predict(model_MU, newdata = new_data_width, type = "response", se.fit = TRUE)
new_data_width <- new_data_width %>%
  mutate(
    probability = predictions_width$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_width$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_width$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to the original scale
  )

# Plot the effect of Width
ggplot(new_data_width, aes(x = Width, y = probability)) +
  geom_line(color = "black", size = 1.2) +  # Line for predicted probability
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3, fill = "#1f77b4") +  # Confidence interval ribbon
  scale_x_continuous(name = "Width") +  # Label the x-axis as "Width"
  scale_y_continuous(name = "Detection Probability", limits = c(0, 0.25)) +  # Adjust y-axis limits
  theme_classic(base_size = 14) +  # Classic theme suitable for publications
  theme(
    plot.title = element_blank(),  # Remove the title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()  # No gridlines for simplicity
  )





# Load required libraries
library(glmmTMB)
library(broom.mixed)
library(dplyr)
library(officer)
library(flextable)

# Fit your model
# Replace `data` with your actual dataset
model_MU <- glmmTMB(
  MUSTELA_ERMINEA_BINOMIAL ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_MU + (1 | SP.Group),
  family = betabinomial,
  data = data
)

# Specify the species name
species_name <- "Weasel spp."

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_MU)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_MU = "Spatial Autocorr. Term",
  HabitatDeciduous = "Ecosite: Deciduous",
  HabitatMixedwood = "Ecosite: Mixedwood",
  HabitatLowland = "Ecosite: Lowland Conifer"
)

# Reformat the table and exclude `sd__(Intercept)`
model_table <- model_summary %>%
  filter(effect == "fixed") %>%  # Keep only fixed effects
  mutate(
    term = case_when(
      term == "log_Width" ~ custom_variable_names$log_Width,
      term == "julian_date_scaled" ~ custom_variable_names$julian_date_scaled,
      term == "autocov_MU" ~ custom_variable_names$autocov_MU,
      term == "HabitatDeciduous" ~ custom_variable_names$HabitatDeciduous,
      term == "HabitatMixedwood" ~ custom_variable_names$HabitatMixedwood,
      term == "HabitatLowland" ~ custom_variable_names$HabitatLowland,
      TRUE ~ term
    )
  ) %>%
  filter(!is.na(term)) %>%  # Ensure no NA terms remain
  dplyr::select(term, estimate, std.error, p.value) %>%
  dplyr::rename(
    Covariate = term,
    Estimate = estimate,
    `Std. Error` = std.error,
    `P-value` = p.value
  ) %>%
  dplyr::mutate(Species = ifelse(row_number() == 1, species_name, "")) %>%
  dplyr::select(Species, everything())

# Explicitly set the custom covariate order
custom_order <- c(
  "Log (Width)",
  "Ecosite: Deciduous", "Ecosite: Mixedwood", "Ecosite: Lowland Conifer",
  "Julian Date (Scaled)",
  "Spatial Autocorr. Term"
)

# Apply the custom order
model_table$Covariate <- factor(model_table$Covariate, levels = custom_order)

# Reorder rows based on the custom order
model_table <- model_table %>%
  arrange(Covariate)

# Create a flextable
ft <- flextable(model_table) %>%
  bold(part = "header") %>%
  align(j = 1:5, align = "center", part = "all") %>%
  autofit()

# Export the table to a Word document
doc <- read_docx() %>%
  body_add_flextable(ft)

# Save the Word document
print(doc, target = "Mustela_Model_Summary.docx")

cat("The table has been successfully exported to 'Mustela_Model_Summary.docx'")
