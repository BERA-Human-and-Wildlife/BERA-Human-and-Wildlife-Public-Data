

library(glmmTMB)
data$Martes_Americana_bin <- ifelse(data$MARTES.AMERICANA > 0, 1, 0)

model_MA <- glmmTMB(Martes_Americana_bin ~ log_Width_scale , 
                    family = binomial, data = data)


summary(model_MA)
# Extract residuals
residuals_glmmTMB_MA <- residuals(model_MA, type = "response") # Response residuals
head(residuals_glmmTMB_MA) # View first few residuals

# You can also specify other types:
residuals_pearson_MA <- residuals(model_MA, type = "pearson") # Pearson residuals
residuals_deviance_MA <- residuals(model_MA, type = "deviance") # Deviance residuals


library(mgcv)

residgam_MA <- gam(residuals_glmmTMB_MA ~ s(Longitude,Latitude), family=gaussian)

autocov_MA <- fitted(residgam_MA)
data$autocov_MA <- scale(fitted(residgam_MA))[,1]

model_MA<-glmmTMB(Martes_Americana_bin ~ log_Width_scale   + autocov_MA, data = data, family = binomial)

summary(model_MA)
plot_model(model_MA,type = "pred")

 
# Calculate R²
library(performance)

r2 <- r2_nakagawa(model_MA)
print(r2)




# 1️⃣ Get fixed‐only linear predictor (link scale)
eta_fixed <- predict(model_MA, type = "link", re.form = NA)

# 2️⃣ Compute its variance
Var_fixed <- var(eta_fixed)

# 3️⃣ Residual variance for binomial‐logit
Var_resid <- (pi^2) / 3

# 4️⃣ Calculate R2
R2 <- Var_fixed / (Var_fixed + Var_resid)

# 5️⃣ Print it
cat("R² for model_MC:", round(R2, 3), "\n")





# Extract fixed effect estimates (mean)
estimates <- fixef(model_MA)$cond

# Compute 95% Confidence Intervals
conf_intervals <- confint(model_MA, parm = "beta_", method = "Wald")  # Wald CI (default)
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
simulation_output_MA <- simulateResiduals(fittedModel = model_MA, n = 1000)

# Plot diagnostic plots
plot(simulation_output_MA)

testDispersion(simulation_output_MA)

testZeroInflation(simulation_output_MA)






# Load required libraries
library(sjPlot)
library(ggplot2)

# Generate the base sjPlot model prediction plot
sjp_MA <- plot_model(model_MA, type = "pred", terms = "log_Width_scale [all") +
  theme_classic(base_size = 14) +  # Classic theme
  theme(
    plot.title = element_blank(),  # Remove title
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid = element_blank()
  ) +
  annotate("text", 
           x = Inf, y = 0.095, 
           label = "American marten (Martes americana)", 
           hjust = 1.1, vjust = 0, 
           size = 5, fontface = "italic") +
  scale_x_continuous(
    name = "Log Width (scaled)"
  ) +
  scale_y_continuous(
    name = "Probability of Use",
    limits = c(0, 0.10),
    breaks = seq(0, 0.70, 0.02),
    expand = expansion(mult = c(0, 0.05))
  )


# Manually override the fitted line and CI transparency
sjp_MA$layers[[1]]$aes_params$size <- 1.3  # Set fitted line thickness
sjp_MA$layers[[1]]$aes_params$colour <- "black"  # Force the fitted line to be black
sjp_MA$layers[[2]]$aes_params$alpha <- 0.2  # Make confidence interval semi-transparent
sjp_MA$layers[[2]]$aes_params$fill <- "#1f77b4"  # Set CI color to light blue

# Display the modified plot
print(sjp_MA)





# Load required libraries
library(glmmTMB)
library(broom.mixed)
library(dplyr)
library(officer)
library(flextable)

# Fit your model
# Replace `data` with your actual dataset
model_MA <- glmmTMB(
  Martes_Americana_bin ~ log_Width + Habitat - 1 + julian_date_scaled + autocov_MA + (1 | SP.Group),
  family = binomial,
  data = data
)

# Specify the species name
species_name <- "American Marten (Martes americana)"

# Extract and tidy the model summary
model_summary <- broom.mixed::tidy(model_MA)

# Define custom variable names with "Ecosite:" prefix for habitat levels
custom_variable_names <- list(
  log_Width = "Log (Width)",
  julian_date_scaled = "Julian Date (Scaled)",
  autocov_MA = "Spatial Autocorr. Term",
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
      term == "autocov_MA" ~ custom_variable_names$autocov_MA,
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
print(doc, target = "Martes_Model_Summary.docx")

cat("The table has been successfully exported to 'Martes_Model_Summary.docx'")

