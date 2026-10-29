# 1️⃣ Load required packages
library(glmmTMB)
library(broom.mixed)   # for tidy()
library(MuMIn)         # for r.squaredGLMM()
library(dplyr)
library(openxlsx)      # for Excel export & styling

# 2️⃣ Put your models in a named list
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

# 3️⃣ Function to extract stats + stars
extract_stats <- function(mod, species) {
  # pull fixed‐effects with 95% CIs
  tab <- broom.mixed::tidy(mod, effects = "fixed", conf.int = TRUE)
  
  # rename columns explicitly with dplyr::rename()
  tab <- tab %>%
    dplyr::rename(
      Predictor   = term,
      Estimate    = estimate,
      `Std Error` = std.error,
      `z value`   = statistic,
      `p value`   = p.value,
      `CI Lower`  = conf.low,
      `CI Upper`  = conf.high
    ) %>%
    dplyr::mutate(
      Species = species,
      Signif  = dplyr::case_when(
        `p value` < 0.001 ~ "***",
        `p value` < 0.01  ~ "**",
        `p value` < 0.05  ~ "*",
        `p value` < 0.1   ~ ".",
        TRUE              ~ ""
      )
    ) %>%
    dplyr::select(
      Species, Predictor, Estimate, `Std Error`, `z value`, `p value`,
      Signif, `CI Lower`, `CI Upper`
    )
  
  # attach model fit stats
  aic_val <- AIC(mod)
  r2_vals <- tryCatch(
    MuMIn::r.squaredGLMM(mod),
    error = function(e) c(NA, NA)
  )
  names(r2_vals) <- c("Marginal_R2", "Conditional_R2")
  
  # repeat AIC & R2 for each row
  tab <- tab %>%
    dplyr::mutate(
      AIC            = aic_val,
      Marginal_R2    = r2_vals["Marginal_R2"],
      Conditional_R2 = r2_vals["Conditional_R2"]
    )
  
  return(tab)
}

# 4️⃣ Build the full combined table
full_table <- dplyr::bind_rows(
  lapply(names(models), function(sp) extract_stats(models[[sp]], sp))
)

# 5️⃣ Export to CSV
write.csv(full_table, "supplement_models.csv", row.names = FALSE)

# 6️⃣ Export to styled XLSX
wb <- createWorkbook()
addWorksheet(wb, "Model Outputs")
writeData(wb, "Model Outputs", full_table)

# 🔥 Bold-red style for significant rows
sig_rows <- which(full_table$Signif != "") + 1  # shift for header row
sig_style <- createStyle(fontColour = "#D7263D", textDecoration = "bold")

addStyle(
  wb, "Model Outputs", style = sig_style,
  rows = sig_rows, cols = 1:ncol(full_table), gridExpand = TRUE
)

saveWorkbook(wb, "supplement_models.xlsx", overwrite = TRUE)

message("✅ Done! Check supplement_models.csv & supplement_models.xlsx in your working dir.")


# 7️⃣ Export to Word (.docx) with 3-decimal formatting
library(officer)
library(flextable)

# Create Word doc
doc <- read_docx()

# Turn df into a flextable
ft <- flextable(full_table)

# 👉 Limit decimals to 3 for all numeric cols
num_cols <- c("Estimate","Std Error","z value","p value",
              "CI Lower","CI Upper","AIC","Marginal_R2","Conditional_R2")

ft <- colformat_double(
  ft,
  j      = num_cols,
  digits = 3
)

# Autofit & add to doc
ft <- autofit(ft)
doc <- body_add_flextable(doc, value = ft)

# Save it
print(doc, target = "supplement_models.docx")

message("📄 Word export with 3-decimal limits is ready in 'supplement_models.docx'. Periodt.")
