

library(glmmTMB)
data$PEROMYSCUS_BIN <- ifelse(data$PEROMYSCUS.MANICULATUS > 0, 1, 0)

model_PM <- glmmTMB(PEROMYSCUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled + (1 | SP.Group), 
                 family = binomial, data = data)

summary(model_PM)
# Extract residuals
residuals_glmmTMB_PM <- residuals(model_PM, type = "response") # Response residuals
head(residuals_glmmTMB_PM) # View first few residuals

# You can also specify other types:
residuals_pearson_PM <- residuals(model_PM, type = "pearson") # Pearson residuals
residuals_deviance_PM <- residuals(model_PM, type = "deviance") # Deviance residuals


library(mgcv)

residgam_PM <- gam(residuals_glmmTMB_PM ~ s(Longitude,Latitude), family=gaussian)

autocov_PM <- fitted(residgam_PM)
data$autocov_PM <- scale(fitted(residgam_PM))[,1]

model_PM<-glmmTMB(PEROMYSCUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled  + autocov_PM
               + (1 | SP.Group), data = data, family = binomial)


summary(model_PM)

plot_model(model_PM,type = "pred")

# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_PM)
print(r2)
check_model(model_PM)
r2_marginal <- r2$R2_marginal
r2_conditional <- r2$R2_conditional
rounded_r2_marginal <- round(r2_marginal, 2)
rounded_r2_conditional <- round(r2_conditional, 2)



# Load necessary package
library(glmmTMB)

# Extract fixed effect estimates (mean)
estimates <- fixef(model_PM)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_PM, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_PM <- simulateResiduals(fittedModel = model_PM, n = 1000)

# Plot diagnostic plots
plot(simulation_output_PM)

testDispersion(simulation_output_PM)

testZeroInflation(simulation_output_PM)



library(glmm.hp)

glmm.hp(model_PM)



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
sjp_PM <- plot_model(model_PM, type = "pred", terms = "log_Width_scale") +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  ) +
  annotate("text", 
           x = Inf, y = 0.45, 
           label = "Deer mouse (Peromyscus maniculatus)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"
   
  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.50),
    breaks = seq(0, 0.70, 0.10)
  )

# Manually override line & CI transparency (if needed)
sjp_PM$layers[[1]]$aes_params$size <- 1.3
sjp_PM$layers[[1]]$aes_params$colour <- "black"
sjp_PM$layers[[2]]$aes_params$alpha <- 0.2
sjp_PM$layers[[2]]$aes_params$fill <- "#1f77b4"

# Display the final plot
print(sjp_PM)












## Fit the model
model_PM <- glmmTMB(PEROMYSCUS_BIN ~ log_Width + Habitat + autocov_PM + (1 | SP.Group), 
                    data = data, family = binomial)

# Generate prediction data
new_data_PM <- expand.grid(
  log_Width = seq(min(data$log_Width), max(data$log_Width), length.out = 100),
  Habitat = unique(data$Habitat),
  autocov_PM = mean(data$autocov_PM),  # Set autocov_PM to its mean
  SP.Group = NA  # Population-level predictions
)

# Generate predictions for the dataset
predictions_PM <- predict(model_PM, newdata = new_data_PM, type = "response", se.fit = TRUE)

# Add predictions and confidence intervals to the dataset
new_data_PM <- new_data_PM %>%
  mutate(
    probability = predictions_PM$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_PM$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_PM$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Set probabilities and confidence intervals to 0 for "Lowland" habitat
new_data_PM <- new_data_PM %>%
  mutate(
    probability = ifelse(Habitat == "Lowland", 0, probability),
    lower_ci = ifelse(Habitat == "Lowland", 0, lower_ci),
    upper_ci = ifelse(Habitat == "Lowland", 0, upper_ci)
  )

# Plot the results
ggplot(new_data_PM, aes(x = Width, y = probability, color = Habitat, group = Habitat)) +
  geom_line(size = 1.2) +
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci, fill = Habitat), alpha = 0.2, color = NA) +
  scale_x_continuous(name = "Width") +
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.9, 
           label = bquote(Marginal~R^2 == .(round(r2$R2_marginal, 2))), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.85, 
           label = bquote(Conditional~R^2 == .(round(r2$R2_conditional, 2))), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )





# Fit the model
model_PM <- glmmTMB(PEROMYSCUS_BIN ~ log_Width + Habitat + autocov_PM + (1 | SP.Group), 
                    data = data, family = binomial)

# Find the most frequent habitat
most_common_habitat <- names(which.max(table(data$Habitat)))

# Generate prediction data with Habitat fixed
new_data_PM <- data.frame(
  log_Width = seq(min(data$log_Width), max(data$log_Width), length.out = 100),
  Habitat = most_common_habitat,  # Fix to the most common habitat
  autocov_PM = mean(data$autocov_PM),  # Set autocov_PM to its mean
  SP.Group = NA  # Population-level predictions
)

# Generate predictions for the dataset
predictions_PM <- predict(model_PM, newdata = new_data_PM, type = "response", se.fit = TRUE)

# Add predictions and confidence intervals
new_data_PM <- new_data_PM %>%
  mutate(
    probability = predictions_PM$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_PM$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_PM$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Plot the effect of Width with fixed habitat
ggplot(new_data_PM, aes(x = Width, y = probability)) +
  geom_line(color = "black", size = 1.2) +
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, fill = "#1f77b4") +
  scale_x_continuous(name = "Width") +
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.9, 
           label = bquote(Marginal~R^2 == .(round(r2$R2_marginal, 2))), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.85, 
           label = bquote(Conditional~R^2 == .(round(r2$R2_conditional, 2))), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )



# Load required libraries
library(glmmTMB)
library(broom.mixed)
library(dplyr)
library(officer)
library(flextable)

# Fit your model
# Replace `data` with your actual dataset
model_PM <- glmmTMB(
  PEROMYSCUS_BIN ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_PM + (1 | SP.Group),
  data = data,
  family = binomial
)

# Specify the species name
species_name <- "Deer Mouse (Peromyscus maniculatus)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_PM)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_PM = "Spatial Autocorr. Term",
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
      term == "autocov_PM" ~ custom_variable_names$autocov_PM,
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
print(doc, target = "Peromyscus_Model_Summary.docx")

cat("The table has been successfully exported to 'Peromyscus_Model_Summary.docx'")

