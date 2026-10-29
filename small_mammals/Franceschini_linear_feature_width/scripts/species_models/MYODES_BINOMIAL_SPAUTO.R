# Base R histogram
hist(data$Width, 
     main = "Histogram of Width", 
     xlab = "Width", 
     col = "lightblue", 
     border = "black")

# ggplot2 for better visualization
library(ggplot2)
ggplot(data, aes(x = Width)) +
  geom_histogram(binwidth = 0.5, fill = "lightblue", color = "black") +
  theme_minimal() +
  labs(title = "Histogram of Width", x = "Width", y = "Frequency")


data$MYODES_BINARY <- ifelse(data$MYODES.GAPPERI > 0, 1, 0)


library(glmmTMB)



model_MY<-glmmTMB(MYODES_BINARY ~ log_Width_scale  + Habitat  + julian_date_scaled
                 + (1 | SP.Group), data = data, family = binomial)
summary(model_MY)

# Extract residuals
residuals_glmmTMB_MY <- residuals(model_MY, type = "response") # Response residuals
head(residuals_glmmTMB_MY) # View first few residuals

# You can also specify other types:
residuals_pearson_MY <- residuals(model_MY, type = "pearson") # Pearson residuals
residuals_deviance_MY <- residuals(model_MY, type = "deviance") # Deviance residuals


library(mgcv)

residgam_MY <- gam(residuals_glmmTMB_MY ~ s(Longitude,Latitude), family=gaussian)

autocov_MY <- fitted(residgam_MY)
data$autocov_MY <- scale(fitted(residgam_MY))

model_MY<-glmmTMB(MYODES_BINARY ~ log_Width_scale  + autocov_MY + Habitat  + julian_date_scaled
                 + (1 | SP.Group), data = data, family = binomial)

summary(model_MY)


# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_MY)
print(r2)
check_model(model_MY)
# Extract the marginal and conditional R² values
r2_marginal <- r2$R2_marginal
r2_conditional <- r2$R2_conditional
rounded_r2_marginal <- round(r2_marginal, 2)
rounded_r2_conditional <- round(r2_conditional, 2)



# Load necessary package
library(glmmTMB)

# Extract fixed effect estimates (mean)
estimates <- fixef(model_MY)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_MY, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_MY <- simulateResiduals(fittedModel = model_MY, n = 1000)

# Plot diagnostic plots
plot(simulation_output_MY)

testDispersion(simulation_output_MY)

testZeroInflation(simulation_output_MY)



# Load required libraries
library(glmmTMB)
library(ggplot2)
library(dplyr)





# Fit the model
model_MY <- glmmTMB(MYODES_BINARY ~ log_Width_scale + autocov_MY + Habitat  + julian_date_scaled + (1 | SP.Group), 
                    data = data, family = binomial)

summary(model_MY)

# Generate predictions for a sequence of Width values while holding other covariates constant
width_seq <- seq(min(data$log_Width_scale), max(data$log_Width_scale), length.out = 100)
autocov_mean <- mean(data$autocov_MY)

new_data <- data.frame(
  log_Width_scale = width_seq,
  autocov_MY = autocov_mean,
  SP.Group = NA  # Random effect groups are included implicitly
)

# Get predicted probabilities and confidence intervals
predictions <- predict(model_MY, newdata = new_data, type = "response", se.fit = TRUE)
new_data <- new_data %>%
  mutate(
    logit_pred = predictions$fit,
    lower_logit = logit_pred - 1.96 * predictions$se.fit,
    upper_logit = logit_pred + 1.96 * predictions$se.fit,
    probability = plogis(logit_pred),
    lower_ci = plogis(lower_logit),
    upper_ci = plogis(upper_logit)
  )

# Convert log_Width back to original Width
new_data <- new_data %>%
  mutate(Width = exp(log_Width))

# Publication-quality Plot
ggplot(new_data, aes(x = Width, y = probability)) +
  geom_line(color = "black", size = 1.2) +  # Line for predicted probability
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3, fill = "#1f77b4") +  # Confidence interval ribbon
  scale_x_continuous(name = "Width") +
  scale_y_continuous(name = "Detection Probability", limits = c(0, 1)) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.9, 
           label = bquote(Marginal~R^2 == .(round(r2$R2_marginal, 2))), 
           size = 5, hjust = 1) +
  annotate("text", x = max(new_data$Width) * 0.9, y = 0.85, 
           label = bquote(Conditional~R^2 == .(round(r2$R2_conditional, 2))), 
           size = 5, hjust = 1) + 
  theme_classic(base_size = 14) +  # Classic theme suitable for publications
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank(),  # No gridlines for simplicity
  ) 



install.packages("sjPlot")

library(sjPlot)

plot_model(model_MY,type = "pred")

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
sjp_MY <- plot_model(model_MY, type = "pred", terms = "log_Width_scale") +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  ) +
  annotate("text", 
           x = Inf, y = 0.65, 
           label = "Southern red-backed vole (Myodes gapperi)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.70),
    breaks = seq(0, 0.70, 0.10)
  )

# Manually override line & CI transparency (if needed)
sjp_MY$layers[[1]]$aes_params$size <- 1.3
sjp_MY$layers[[1]]$aes_params$colour <- "black"
sjp_MY$layers[[2]]$aes_params$alpha <- 0.2
sjp_MY$layers[[2]]$aes_params$fill <- "#1f77b4"

# Display the final plot
print(sjp_MY)

# Load required libraries
library(glmmTMB)
library(broom.mixed)
library(dplyr)
library(officer)
library(flextable)

# Fit your model
# Replace `data` with your actual dataset
model_MY <- glmmTMB(
  MYODES_BINARY ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_MY + (1 | SP.Group),
  data = data,
  family = binomial
)

# Specify the species name
species_name <- "Southern red-backed vole (Myodes gapperi)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_MY)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_MY = "Spatial Autocorr. Term",
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
      term == "autocov_MY" ~ custom_variable_names$autocov_MY,
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
print(doc, target = "Myodes_Model_Summary.docx")

cat("The table has been successfully exported to 'Myodes_Model_Summary.docx'")

write.csv(data, "Data_ALE.csv")
