# 📦 Packages
library(glmmTMB)
library(dplyr)
library(officer)
library(flextable)

# 🛠️ Make sure your 'data' dataframe has a 'Width' column and all other vars

# 1️⃣ Scale raw Width
data <- data %>%
  mutate(Width_scaled = as.numeric(scale(Width)))

# 2️⃣ Original models list (using your existing model objects)
models <- list(
  Myodes            = model_MY,
  Tamiasciurus      = model_SQ,
  Peromyscus        = model_PM,
  Lepus_americanus  = model_LP,
  Sorex             = model_SX,
  Martes_americana  = model_MA,
  Mustela_erminea   = model_MU,
  Microtus          = model_MC,
  Zapus             = model_ZP
)

# 3️⃣ Refit linear-Width models: replace log_Width_scale with Width_scaled
base_models_width <- lapply(models, function(mod) {
  update(mod, . ~ . - log_Width_scale + Width_scaled)
})
names(base_models_width) <- names(models)

# 4️⃣ Fit quadratic-Width models: add I(Width_scaled^2)
quad_models_width <- lapply(base_models_width, function(mod) {
  update(mod, . ~ . + I(Width_scaled^2))
})
names(quad_models_width) <- names(base_models_width)

# 5️⃣ Build AIC comparison table
aic_table <- data.frame(
  Species       = names(base_models_width),
  AIC_Linear    = sapply(base_models_width, AIC),
  AIC_Quadratic = sapply(quad_models_width, AIC)
) %>%
  mutate(Delta_AIC = AIC_Linear - AIC_Quadratic)

# 6️⃣ Export to Word with flextable styling
doc <- read_docx()

# Add caption
doc <- body_add_par(
  doc,
  "Supplementary Table S2. AIC comparison for models predicting species occurrence using scaled Width: linear (Width_scaled) vs. quadratic (Width_scaled + Width_scaled²) terms.",
  style = "Normal"
)

# Create and format the flextable
ft <- flextable(aic_table) %>%
  colformat_double(
    j = c("AIC_Linear", "AIC_Quadratic", "Delta_AIC"),
    digits = 3
  ) %>%
  autofit()

# Add table and save
doc <- body_add_flextable(doc, value = ft)
print(doc, target = "AIC_comparison_width.docx")

message("📄 'AIC_comparison_width.docx' created! Periodt.")  


# 📦 Packages (load if not already)
library(glmmTMB)
library(dplyr)

# 🛠️ Make sure 'data' has your raw Width variable
#    and your original models (with log_Width_scale) are in env

# 1️⃣ Scale raw Width once
data <- data %>%
  mutate(Width_scaled = as.numeric(scale(Width)))

# 2️⃣ Named list of your original models (log_Width_scale)
orig_models <- list(
  Myodes            = model_MY,
  Tamiasciurus      = model_SQ,
  Peromyscus        = model_PM,
  Lepus_americanus  = model_LP,
  Sorex             = model_SX,
  Martes_americana  = model_MA,
  Mustela_erminea   = model_MU,
  Microtus          = model_MC,
  Zapus             = model_ZP
)

# 3️⃣ Compute AIC for original (log‐based) models
aic_orig <- sapply(orig_models, AIC)

# 4️⃣ Refit linear‐Width models: swap log_Width_scale -> Width_scaled
width_models <- lapply(orig_models, function(mod) {
  update(mod, . ~ . - log_Width_scale + Width_scaled)
})
names(width_models) <- names(orig_models)

# 5️⃣ Compute AIC for linear Width_scaled
aic_width <- sapply(width_models, AIC)

# 6️⃣ Fit quadratic Width_scaled: add I(Width_scaled^2)
quad_width_models <- lapply(width_models, function(mod) {
  update(mod, . ~ . + I(Width_scaled^2))
})
names(quad_width_models) <- names(width_models)

# 7️⃣ Compute AIC for quadratic Width_scaled
aic_quad <- sapply(quad_width_models, AIC)

# 8️⃣ Build the AIC comparison table
aic_comparison <- data.frame(
  Species        = names(orig_models),
  AIC_LogWidth   = as.numeric(aic_orig),
  AIC_Width      = as.numeric(aic_width),
  AIC_Width2     = as.numeric(aic_quad),
  Delta1         = aic_orig - aic_width,    # improvement from log to linear
  Delta2         = aic_width - aic_quad     # improvement from linear to quad
)

# 9️⃣ View it
print(aic_comparison)

# 🔟 (Optional) export to CSV
# write.csv(aic_comparison, "AIC_comparison_all.csv", row.names = FALSE)






# 📦 Load packages
library(dplyr)

# 1️⃣ Scale raw Width
data <- data %>%
  mutate(Width_scaled = as.numeric(scale(Width)))

# 2️⃣ Named list of your original log‐width models
orig_models <- list(
  Myodes           = model_MY,
  Tamiasciurus     = model_SQ,
  Peromyscus       = model_PM,
  Lepus_americanus = model_LP,
  Sorex            = model_SX,
  Martes_americana = model_MA,
  Mustela_erminea  = model_MU,
  Microtus         = model_MC,
  Zapus            = model_ZP
)

# 3️⃣ Fit polynomial‐width models: swap log_Width_scale -> Width_scaled + I(Width_scaled^2)
poly_models <- lapply(orig_models, function(mod) {
  update(mod, . ~ . - log_Width_scale + Width_scaled + I(Width_scaled^2))
})
names(poly_models) <- names(orig_models)

# 4️⃣ Pull AICs
aic_orig <- sapply(orig_models, AIC)
aic_poly <- sapply(poly_models, AIC)

# 5️⃣ Build comparison table
aic_table <- data.frame(
  Species         = names(orig_models),
  AIC_LogWidth    = as.numeric(aic_orig),
  AIC_WidthPoly   = as.numeric(aic_poly),
  Delta_AIC       = as.numeric(aic_orig) - as.numeric(aic_poly)
)

# 6️⃣ Print or export
print(aic_table)
 write.csv(aic_table, "AIC_log_vs_widthpoly.csv", row.names = FALSE)
