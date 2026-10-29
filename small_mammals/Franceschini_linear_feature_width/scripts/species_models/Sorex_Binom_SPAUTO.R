data$SOREX_BIN <- ifelse(data$SOREX.SPP > 0, 1, 0)

library(glmmTMB)

model_SX<- glmmTMB(SOREX_BIN ~ Julian_Date + log_Width_scale  + Habitat  +(1 | SP.Group), family = binomial, data = data)


# Extract residuals
residuals_glmmTMB_SX <- residuals(model_SX, type = "response") # Response residuals
head(residuals_glmmTMB_SX) # View first few residuals

# You can also specify other types:
residuals_pearson_SX <- residuals(model_SX, type = "pearson") # Pearson residuals
residuals_deviance_SX <- residuals(model_SX, type = "deviance") # Deviance residuals


library(mgcv)

residgam_SX <- gam(residuals_glmmTMB_SX ~ s(Longitude,Latitude), family=gaussian)

autocov_SX <- fitted(residgam_SX)
data$autocov_SX <- scale(fitted(residgam_SX))[,1]

model_SX<-glmmTMB(SOREX_BIN ~ log_Width_scale + Julian_Date + Habitat  + autocov_SX
                  + (1 | SP.Group), data = data, family = binomial)

summary(model_SX)
plot_model(model_SX,type = "pred")


# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_SX)
print(r2)
check_model(model_SX)
r2_marginal <- r2$R2_marginal
r2_conditional <- r2$R2_conditional
rounded_r2_marginal <- round(r2_marginal, 2)
rounded_r2_conditional <- round(r2_conditional, 2)



# Extract fixed effect estimates (mean)
estimates <- fixef(model_SX)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_SX, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_SX <- simulateResiduals(fittedModel = model_SX, n = 1000)

# Plot diagnostic plots
plot(simulation_output_SX)

testDispersion(simulation_output_SX)

testZeroInflation(simulation_output_SX)







# Load required libraries
library(sjPlot)
library(ggplot2)

# Generate the base sjPlot model prediction plot
sjp_SX <- plot_model(model_SX, type = "pred", terms = "log_Width_scale") +
  theme_classic(base_size = 14) +  # Classic theme
  theme(
    plot.title = element_blank(),  # Remove title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  )  +
  annotate("text", 
           x = Inf, y = 0.75, 
           label = "Sorex spp.", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"
  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.8),
    breaks = seq(0, 0.80, 0.10),
    expand = expansion(mult = c(0, 0.05))
  )


# Manually override the fitted line and CI transparency
sjp_SX$layers[[1]]$aes_params$size <- 1.3  # Set fitted line thickness
sjp_SX$layers[[1]]$aes_params$colour <- "black"  # Force the fitted line to be black
sjp_SX$layers[[2]]$aes_params$alpha <- 0.2  # Make confidence interval semi-transparent
sjp_SX$layers[[2]]$aes_params$fill <- "#1f77b4"  # Set CI color to light blue

# Display the modified plot
print(sjp_SX)



# Fit the model
model_SX <- glmmTMB(SOREX_BIN ~ Julian_Date + log_Width  + Habitat - 1 + autocov_SX + (1 | SP.Group), 
                    data = data, family = binomial)

# Generate predictions for a sequence of Julian_Date values while holding other covariates constant
julian_seq <- seq(min(data$Julian_Date), max(data$Julian_Date), length.out = 100)
autocov_mean <- mean(data$autocov_SX)

new_data <- data.frame(
  Julian_Date = julian_seq,
  Habitat = unique(data$Habitat),
  autocov_SX = autocov_mean,
  SP.Group = NA  # Random effect groups are included implicitly
)

# Get predicted probabilities and confidence intervals
predictions <- predict(model_SX, newdata = new_data, type = "response", se.fit = TRUE)
new_data <- new_data %>%
  mutate(
    probability = predictions$fit,
    lower_ci = plogis(qlogis(probability) - 1.96 * predictions$se.fit),
    upper_ci = plogis(qlogis(probability) + 1.96 * predictions$se.fit)
  )

# Convert Julian_Date to a real date
reference_year <- 2023  # Define a reference year
new_data <- new_data %>%
  mutate(
    Real_Date = as.Date(Julian_Date - 1, origin = paste0(reference_year, "-01-01"))  # Convert Julian date
  )

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




# Load required libraries
library(glmmTMB)
library(broom.mixed)
library(dplyr)
library(officer)
library(flextable)

# Fit your model
# Replace `data` with your actual dataset
model_SX <- glmmTMB(
  SOREX_BIN ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_SX + (1 | SP.Group),
  data = data,
  family = binomial
)

# Specify the species name
species_name <- "Shrews spp."

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_SX)

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
print(doc, target = "Sorex_Model_Summary.docx")

cat("The table has been successfully exported to 'Myodes_Model_Summary.docx'")
