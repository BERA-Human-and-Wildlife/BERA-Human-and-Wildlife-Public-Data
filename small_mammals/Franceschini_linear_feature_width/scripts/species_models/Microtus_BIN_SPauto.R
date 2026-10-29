# Total number of observations
total_observations <- nrow(data)

# Number of detections
detections <- sum(data$MICROTUS_BINARY == 1, na.rm = TRUE)

# Percentage of detections
percentage_detections <- (detections / total_observations) * 100

# Print results
cat("Total observations:", total_observations, "\n")
cat("Number of detections of Microtus:", detections, "\n")
cat("Percentage of detections:", round(percentage_detections, 2), "%\n")


data$MICROTUS_BINARY <- ifelse(data$MICROTUS.DRUMMONDII > 0, 1, 0)

library(glmmTMB)

model_MC <- glmmTMB(MICROTUS_BINARY ~ log_Width_scale   , 
                   
                    family = binomial, data = data)

summary(model_MC)
# Extract residuals
residuals_glmmTMB_MC <- residuals(model_MC, type = "response") # Response residuals
head(residuals_glmmTMB_MC) # View first few residuals

# You can also specify other types:
residuals_pearson_MC <- residuals(model_MC, type = "pearson") # Pearson residuals
residuals_deviance_MC <- residuals(model_MC, type = "deviance") # Deviance residuals


library(mgcv)

residgam_MC <- gam(residuals_glmmTMB_MC ~ s(Longitude,Latitude), family=gaussian)

autocov_MC <- fitted(residgam_MC)
data$autocov_MC <- scale(fitted(residgam_MC))[,1]

model_MC<-glmmTMB(MICROTUS_BINARY ~ log_Width_scale + autocov_MC 
                  , data = data, family = binomial)

summary(model_MC)

plot_model(model_MC,type = "pred")

 
# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_MC)
print(r2)
r2_marginal <- r2$R2_marginal
r2_conditional <- r2$R2_conditional
rounded_r2_marginal <- round(r2_marginal, 2)
rounded_r2_conditional <- round(r2_conditional, 2)

# 1️⃣ Get fixed‐only linear predictor (link scale)
eta_fixed <- predict(model_MC, type = "link", re.form = NA)

# 2️⃣ Compute its variance
Var_fixed <- var(eta_fixed)

# 3️⃣ Residual variance for binomial‐logit
Var_resid <- (pi^2) / 3

# 4️⃣ Calculate R2
R2 <- Var_fixed / (Var_fixed + Var_resid)

# 5️⃣ Print it
cat("R² for model_MC:", round(R2, 3), "\n")



# Extract fixed effect estimates (mean)
estimates <- fixef(model_MC)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_MC, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_MC <- simulateResiduals(fittedModel = model_MC, n = 1000)

# Plot diagnostic plots
plot(simulation_output_MC)

testDispersion(simulation_output_MC)

testZeroInflation(simulation_output_MC)









# Load required libraries
library(sjPlot)
library(ggplot2)

# Compute mean and SD of Width (for back-transformation)
width_mean <- mean(data$Width, na.rm = TRUE)
width_sd <- sd(data$Width, na.rm = TRUE)

# Custom breaks (5m increments for first 25m, then 25m increments)
original_breaks <- c(seq(0, 25, by = 5), seq(50, 200, by = 25))

# Convert breaks to scaled units (the scale used in your model)
scaled_breaks <- (original_breaks - width_mean) / width_sd

# Generate and customize the plot
sjp_MC <- plot_model(model_MC, type = "pred", terms = "log_Width_scale") +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  ) +
  annotate("text", 
           x = 2.5, y = 0.37, 
           label = "Meadow vole (Microtus drummondii)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"
    
  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.40),
    breaks = seq(0, 0.70, 0.10)
  )

# Manually override line & CI transparency (if needed)
sjp_MC$layers[[1]]$aes_params$size <- 1.3
sjp_MC$layers[[1]]$aes_params$colour <- "black"
sjp_MC$layers[[2]]$aes_params$alpha <- 0.2
sjp_MC$layers[[2]]$aes_params$fill <- "#1f77b4"

# Display the final plot
print(sjp_MC)





# Fit the model
model_MC <- glmmTMB( MICROTUS_BINARY ~ log_Width  + autocov_MC , 
                    data = data,
                    
                    family = binomial)

summary(model_MC)

# Plot diagnostic plots

simulation_output_MC <- simulateResiduals(fittedModel = model_MC, n = 1000)

plot(simulation_output_MC)

testDispersion(simulation_output_MC)

testZeroInflation(simulation_output_MC)



# Generate predictions for a sequence of log_Width values while holding other covariates constant
log_width_seq <- seq(min(data$log_Width), max(data$log_Width), length.out = 100)
autocov_mean <- mean(data$autocov_MC, na.rm = TRUE)

new_data_MC <- data.frame(
  log_Width = log_width_seq,
  autocov_MC = autocov_mean,
  SP.Group = NA  # Random effect groups are included implicitly
)

# Get predicted probabilities and confidence intervals
predictions_MC <- predict(model_MC, newdata = new_data_MC, type = "response", se.fit = TRUE)
new_data_MC <- new_data_MC %>%
  mutate(
    probability = predictions_MC$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_MC$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_MC$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Calculate R² values
library(performance)
r2_MC <- r2_nakagawa(model_MC)
r2_marginal_MC <- round(r2_MC$R2_marginal, 2)
r2_conditional_MC <- round(r2_MC$R2_conditional, 2)

# Create a publication-quality plot
ggplot(new_data_MC, aes(x = Width, y = probability)) +
  geom_line(color = "black", size = 1.2) +  # Line for predicted probability
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3, fill = "#1f77b4") +  # Confidence interval ribbon
  scale_x_continuous(name = "Width") +  # Label the x-axis as "Width"
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +  # Set y-axis limits
  annotate("text", x = max(new_data_MC$Width) * 0.9, y = 0.9, 
           label = bquote(Marginal~R^2 == .(r2_marginal_MC)), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data_MC$Width) * 0.9, y = 0.85, 
           label = bquote(Conditional~R^2 == .(r2_conditional_MC)), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +  # Classic theme suitable for publications
  theme(
    plot.title = element_blank(),  # Remove title
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
model_MC <- glmmTMB(
  MICROTUS_BINARY ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_MC + (1 | SP.Group),
  data = data,
  family = betabinomial
)

# Specify the species name
species_name <- "Meadow vole (Microtus drummondii)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_MC)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_MC = "Spatial Autocorr. Term",
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
      term == "autocov_MC" ~ custom_variable_names$autocov_MC,
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
print(doc, target = "Microtus_Model_Summary.docx")

cat("The table has been successfully exported to 'Microtus_Model_Summary.docx'")
