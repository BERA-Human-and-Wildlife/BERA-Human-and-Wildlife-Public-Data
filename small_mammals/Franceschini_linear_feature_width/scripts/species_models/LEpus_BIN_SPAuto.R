

library(glmmTMB)
data$LEPUS_AMERICANUS_BIN <- ifelse(data$LEPUS.AMERICANUS > 0, 1, 0)

model_LP <- glmmTMB(LEPUS_AMERICANUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled + (1 | SP.Group), 
                    family = binomial, data = data)

summary((model_LP))
# Extract residuals
residuals_glmmTMB_LP <- residuals(model_LP, type = "response") # Response residuals
head(residuals_glmmTMB_LP) # View first few residuals

# You can also specify other types:
residuals_pearson_LP <- residuals(model_LP, type = "pearson") # Pearson residuals
residuals_deviance_LP <- residuals(model_LP, type = "deviance") # Deviance residuals


library(mgcv)

residgam_LP <- gam(residuals_glmmTMB_LP ~ s(Longitude,Latitude), family=gaussian)

autocov_LP <- fitted(residgam_LP)
data$autocov_LP <- scale(fitted(residgam_LP))[,1]

model_LP<-glmmTMB(LEPUS_AMERICANUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled  + autocov_LP
                  + (1 | SP.Group), data = data, family = binomial)

summary(model_LP)
plot_model(model_LP,type = "pred")

library(glmm.hp)

glmm.hp(model_LP)

# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_LP)
print(r2)

check_model(model_LP)




# Extract fixed effect estimates (mean)
estimates <- fixef(model_LP)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_LP, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_LP <- simulateResiduals(fittedModel = model_LP, n = 1000)

# Plot diagnostic plots
plot(simulation_output_LP)

testDispersion(simulation_output_LP)

testZeroInflation(simulation_output_LP)




# Load required libraries
library(sjPlot)
library(ggplot2)

# Compute mean and SD of Width (for back-transformation)
width_mean <- mean(data$Width, na.rm = TRUE)
width_sd <- sd(data$Width, na.rm = TRUE)

# Custom breaks (5m increments for first 25m, then 25m increments)
original_breaks <- c(seq(0, 25, by = 5), seq(50, 125, by = 25))

# Convert breaks to scaled units (the scale used in your model)
scaled_breaks <- (original_breaks - width_mean) / width_sd

# Generate and customize the plot
sjp_LP <- plot_model(model_LP, type = "pred", terms = "log_Width_scale") +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  ) +
  annotate("text", 
           x = Inf, y = 0.30, 
           label = "Snowshoe hare (Lepus americanus)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"
  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.32),
    breaks = seq(0, 0.70, 0.10),
    expand = expansion(mult = c(0, 0.05))
  )

# Manually override line & CI transparency (if needed)
sjp_LP$layers[[1]]$aes_params$size <- 1.3
sjp_LP$layers[[1]]$aes_params$colour <- "black"
sjp_LP$layers[[2]]$aes_params$alpha <- 0.2
sjp_LP$layers[[2]]$aes_params$fill <- "#1f77b4"

# Display the final plot
print(sjp_LP)


library(ggeffects)
library(ggplot2)

# Get predictions, forcing response scale (probabilities)
pred <- as.data.frame(ggeffect(model_LP, terms = "log_Width_scale", type = "response"))

# Back-transform x-axis from `log_Width_scale` to `Width` (meters)
log_width_mean <- mean(log(data$Width), na.rm = TRUE)
log_width_sd <- sd(log(data$Width), na.rm = TRUE)

# Add original Width column to pred object
pred$Width <- exp(pred$x * log_width_sd + log_width_mean)

# Plot using ggplot2 (x-axis is back on original scale in meters)
ggplot(pred, aes(x = Width, y = predicted)) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "#1f77b4", alpha = 0.2) +
  geom_line(size = 1.3, color = "black") +
  theme_classic(base_size = 14) +
  labs(x = "Width (m)", y = "Probability of Use") +
  scale_y_continuous(limits = c(0, 0.70), breaks = seq(0, 0.70, 0.10)) +
  annotate("text", x = max(pred$Width), y = 0.65, 
           label = "Snowshoe Hare", hjust = 1.1, vjust = 0, 
           size = 6, fontface = "italic") +
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12)
  )

library(glmmTMB)
library(ggplot2)
library(dplyr)

# Fit the model
model_LP <- glmmTMB(LEPUS_AMERICANUS_BIN ~ log_Width + Habitat + autocov_LP + (1 | SP.Group), 
                    data = data, family = binomial)

# Common variables
autocov_mean <- mean(data$autocov_LP, na.rm = TRUE)

# ----------------------- 1. Effect of Width (Most Common Habitat) -----------------------

# Find the most common habitat
most_common_habitat <- names(which.max(table(data$Habitat)))

# Generate prediction data
log_width_seq <- seq(min(data$log_Width), max(data$log_Width), length.out = 100)
new_data_LP <- expand.grid(
  log_Width = log_width_seq,
  Habitat = most_common_habitat,  # Fix to the most common habitat
  autocov_LP = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_LP <- predict(model_LP, newdata = new_data_LP, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_LP <- new_data_LP %>%
  mutate(
    probability = predictions_LP$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_LP$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_LP$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Plot the effect of Width
ggplot(new_data_LP, aes(x = Width, y = probability)) +
  geom_line(color = "black", size = 1.2) +
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, fill = "#1f77b4") +
  scale_x_continuous(name = "Width") +
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )

# ----------------------- 2. Effect of Habitat (Fixed Width) -----------------------

# Fix Width to its mean
mean_log_width <- mean(data$log_Width, na.rm = TRUE)

# Generate prediction data for all habitats
new_data_LP_habitat <- data.frame(
  log_Width = mean_log_width,
  Habitat = unique(data$Habitat),
  autocov_LP = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_LP_habitat <- predict(model_LP, newdata = new_data_LP_habitat, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_LP_habitat <- new_data_LP_habitat %>%
  mutate(
    probability = predictions_LP_habitat$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_LP_habitat$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_LP_habitat$se.fit),
    Habitat = factor(Habitat, levels = c("Deciduous", "Mixedwood", "Lowland"))  # Order Habitat levels
  )

# Plot the effect of Habitat
ggplot(new_data_LP_habitat, aes(x = Habitat, y = probability, fill = Habitat)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2) +
  scale_fill_manual(values = c("#66c2a5", "#fc8d62", "#8da0cb")) +  # Custom colors
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "none",
    panel.grid = element_blank()
  )

# ----------------------- 3. Effect of Width by Habitat -----------------------

# Generate prediction data for Width with separate lines for each habitat
new_data_LP_width_habitat <- expand.grid(
  log_Width = seq(min(data$log_Width), max(data$log_Width), length.out = 100),
  Habitat = c("Deciduous", "Mixedwood", "Lowland"),
  autocov_LP = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_LP_width_habitat <- predict(model_LP, newdata = new_data_LP_width_habitat, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_LP_width_habitat <- new_data_LP_width_habitat %>%
  mutate(
    probability = predictions_LP_width_habitat$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_LP_width_habitat$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_LP_width_habitat$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Plot the effect of Width with separate lines for each habitat
ggplot(new_data_LP_width_habitat, aes(x = Width, y = probability, color = Habitat, group = Habitat)) +
  geom_line(size = 1.2) +
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci, fill = Habitat), alpha = 0.2, color = NA) +
  scale_x_continuous(name = "Width") +
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  scale_color_manual(values = c("#66c2a5", "#fc8d62", "#8da0cb")) +  # Custom colors for lines
  scale_fill_manual(values = c("#66c2a5", "#fc8d62", "#8da0cb")) +  # Matching fill colors for ribbons
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    legend.title = element_blank(),
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
model_LP <- glmmTMB(
  LEPUS_AMERICANUS_BIN ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_LP + (1 | SP.Group),
  data = data,
  family = binomial
)

# Specify the species name
species_name <- "Snowshoe hare (Lepus americanus)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_LP)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_LP = "Spatial Autocorr. Term",
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
      term == "autocov_LP" ~ custom_variable_names$autocov_LP,
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
print(doc, target = "Lepus_Model_Summary.docx")

cat("The table has been successfully exported to 'Lepus_Model_Summary.docx'")
