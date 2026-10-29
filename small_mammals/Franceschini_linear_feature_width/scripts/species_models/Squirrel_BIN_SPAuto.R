

library(glmmTMB)
data$TAMIASCIURUS_BIN <- ifelse(data$TAMIASCIURUS.HUDSONICUS > 0, 1, 0)

model_SQ <- glmmTMB(TAMIASCIURUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled + (1 | SP.Group), 
                    family = binomial, data = data)

summary(model_SQ)
# Extract residuals
residuals_glmmTMB_SQ <- residuals(model_SQ, type = "response") # Response residuals
head(residuals_glmmTMB_SQ) # View first few residuals

# You can also specify other types:
residuals_pearson_SQ <- residuals(model_SQ, type = "pearson") # Pearson residuals
residuals_deviance_SQ <- residuals(model_SQ, type = "deviance") # Deviance residuals


library(mgcv)

residgam_SQ <- gam(residuals_glmmTMB_SQ ~ s(Longitude,Latitude), family=gaussian)

autocov_SQ <- fitted(residgam_SQ)
data$autocov_SQ <- scale(fitted(residgam_SQ))[,1]

model_SQ<-glmmTMB(TAMIASCIURUS_BIN ~ log_Width_scale + Habitat  + julian_date_scaled  + autocov_SQ
                  + (1 | SP.Group), data = data, family = binomial)

summary(model_SQ)

plot_model(model_SQ,type = "pred")

# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_SQ)
print(r2)



# Load necessary package
library(glmmTMB)

# Extract fixed effect estimates (mean)
estimates <- fixef(model_SQ)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_SQ, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_SQ <- simulateResiduals(fittedModel = model_SQ, n = 1000)

# Plot diagnostic plots
plot(simulation_output_SQ)

testDispersion(simulation_output_SQ)

testZeroInflation(simulation_output_SQ)





library(glmm.hp)

glmm.hp(model_SQ)




# Load required libraries
library(sjPlot)
library(ggplot2)

# Generate the base sjPlot model prediction plot
sjp_SQ <- plot_model(model_SQ, type = "pred", terms = "log_Width_scale [all") +
  theme_classic(base_size = 14) +  # Classic theme
  theme(
    plot.title = element_blank(),  # Remove title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )  +
  annotate("text", 
           x = Inf, y = 0.37, 
           label = "American red squirrel (Tamiasciurus hudsonicus)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.40),
    breaks = seq(0, 0.70, 0.10)
  )


# Manually override the fitted line and CI transparency
sjp_SQ$layers[[1]]$aes_params$size <- 1.3  # Set fitted line thickness
sjp_SQ$layers[[1]]$aes_params$colour <- "black"  # Force the fitted line to be black
sjp_SQ$layers[[2]]$aes_params$alpha <- 0.2  # Make confidence interval semi-transparent
sjp_SQ$layers[[2]]$aes_params$fill <- "#1f77b4"  # Set CI color to light blue

# Display the modified plot
print(sjp_SQ)




library(glmmTMB)
library(ggplot2)
library(dplyr)
library(performance)

# Fit the model
model_SQ <- glmmTMB(TAMIASCIURUS_BIN ~ log_Width + Habitat + autocov_SQ + (1 | SP.Group), 
                    data = data, family = binomial)

most_common_habitat <- names(which.max(table(data$Habitat)))


# Generate prediction data for all habitats
log_width_seq <- seq(min(data$log_Width), max(data$log_Width), length.out = 100)
autocov_mean <- mean(data$autocov_SQ, na.rm = TRUE)

new_data_SQ <- expand.grid(
  log_Width = log_width_seq,
  Habitat = most_common_habitat,  # Fix to the most common habitat
  autocov_SQ = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_SQ <- predict(model_SQ, newdata = new_data_SQ, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_SQ <- new_data_SQ %>%
  mutate(
    probability = predictions_SQ$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_SQ$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_SQ$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )


# Plot the effect of Width
ggplot(new_data_SQ, aes(x = Width, y = probability)) +
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




# Fix Width to its mean
mean_log_width <- mean(data$log_Width, na.rm = TRUE)

# Generate prediction data for all habitats
new_data_SQ_habitat <- data.frame(
  log_Width = mean_log_width,
  Habitat = unique(data$Habitat),
  autocov_SQ = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_SQ_habitat <- predict(model_SQ, newdata = new_data_SQ_habitat, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_SQ_habitat <- new_data_SQ_habitat %>%
  mutate(
    probability = predictions_SQ_habitat$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_SQ_habitat$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_SQ_habitat$se.fit)
  )

# Order Habitat levels
new_data_SQ_habitat <- new_data_SQ_habitat %>%
  mutate(Habitat = factor(Habitat, levels = c("Deciduous", "Mixedwood", "Lowland")))

# Plot the effect of Habitat
ggplot(new_data_SQ_habitat, aes(x = Habitat, y = probability, fill = Habitat)) +
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



# Generate prediction data for Width with separate lines for each habitat
new_data_SQ_width_habitat <- expand.grid(
  log_Width = seq(min(data$log_Width), max(data$log_Width), length.out = 100),
  Habitat = c("Deciduous", "Mixedwood", "Lowland"),
  autocov_SQ = autocov_mean,
  SP.Group = NA
)

# Generate predictions
predictions_SQ_width_habitat <- predict(model_SQ, newdata = new_data_SQ_width_habitat, type = "response", se.fit = TRUE)

# Add predictions to the dataset
new_data_SQ_width_habitat <- new_data_SQ_width_habitat %>%
  mutate(
    probability = predictions_SQ_width_habitat$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions_SQ_width_habitat$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions_SQ_width_habitat$se.fit),
    Width = exp(log_Width)  # Convert log_Width back to original scale
  )

# Plot the effect of Width with separate lines for each habitat
ggplot(new_data_SQ_width_habitat, aes(x = Width, y = probability, color = Habitat, group = Habitat)) +
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
model_SQ <- glmmTMB(
  TAMIASCIURUS_BIN ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_SQ + (1 | SP.Group),
  data = data,
  family = binomial
)

# Specify the species name
species_name <- "American red squirrel (Tamiasciurus hudsonicus)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_SQ)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_SQ = "Spatial Autocorr. Term",
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
      term == "autocov_SQ" ~ custom_variable_names$autocov_SQ,
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
print(doc, target = "Tamiasciurus_Model_Summary.docx")

cat("The table has been successfully exported to 'Tamiasciurus_Model_Summary.docx'")
