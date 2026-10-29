# 📦 Load Libraries
library(glmmTMB)
library(dplyr)
library(MuMIn)
library(DHARMa)
library(broom.mixed)
library(ggplot2)
library(tidyr)
library(mgcv)
library(readr)
library(spdep)
library(gratia)
library(ggplot2)
library(forcats)
library(stringr)
library(scales)




# === Load and Prepare Data ===
df <- read_csv("Data_60min.csv")
df <- df %>%
  mutate(across(
    c(pair_id, recovery),
    as.factor
  ))



# Set options for MuMIn (dredge)
options(na.action = "na.fail")

# 🐾 Species: Sorex spp. (no filtering required)

# Prep data: ensure correct factor levels, baseline for recovery is level "4"
df <- df %>%
  mutate(
    recovery = factor(recovery, levels = c("1", "2", "3", "4")),
    forest_cover = factor(forest_cover),
    disturbance = factor(disturbance)
  ) %>%
  mutate(recovery = relevel(recovery, ref = "4"))

df <- df %>%
  filter(forest_cover != "Upland Spruce")


##############################################################################################################
##############################################################################################################
##############################################################################################################

# Sorex spp.


# 🔨 Baseline model
model_base <- glmmTMB(
  sorex.spp ~ day_year_zscore + recovery + offset(log(active_hours)) + (1 | pair_id),
  family = nbinom2(),
  data = df
)

# 🌍 Global model INCLUDING all 2-ways + the 3-way:
# forest_cover * recovery * disturbance expands to:
# mains: forest_cover + recovery + disturbance
# 2-ways: forest_cover:recovery + forest_cover:disturbance + recovery:disturbance
# 3-way: forest_cover:recovery:disturbance
model_global <- update(
  model_base,
  . ~ . + forest_cover * recovery * disturbance
)

# 🌪️ Dredge it!
dredge_results <- dredge(model_global, rank = "AICc")

# Get models within ΔAIC ≤ 2
top_models <- get.models(dredge_results, subset = delta <= 2)

cat("Top", length(top_models), "models within ΔAIC ≤ 2 for Sorex spp.\n")

# 🧪 Check DHARMa residuals for each top model
residual_results <- lapply(seq_along(top_models), function(i) {
  cat("\nChecking residuals for Model", i, "\n")
  sim <- simulateResiduals(top_models[[i]], n = 1000)
  plot(sim)
  return(sim)
})

# 📊 Summarize AIC table
print(dredge_results)


summary(top_models[["77"]])
summary(top_models[["78"]])


# 2 models as best (1 eliminates fixed effects) Difference is whether or not to include disturbance

##############################################################################################################
##############################################################################################################
##############################################################################################################

# Picking one model

# 📈 Plot fixed effects of top model (Model 1)
Shrewtop_model <- top_models[["269"]]
Shrewfe_tbl <- tidy(Shrewtop_model, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)")%>%
  # Keep only recovery terms
  filter(str_detect(term, "recovery"))

# Clean up term labels for plotting
Shrewfe_tbl <- Shrewfe_tbl %>%
  mutate(term = recode(term,
                       "recovery1" = "Low",
                       "recovery2" = "Medium",
                       "recovery3" = "High",
                       "forest_coverMixedwood" = "Mixedwood",
                       "disturbanceYes" = "Disturbance Present"
  ))

Shrewfe_tbl <- Shrewfe_tbl %>%
  mutate(term = factor(term, levels = c("Low", "Medium", "High")))

windowsFonts(Arial = windowsFont("Arial"))


# Plot
library(ggplot2)
library(forcats)
library(scales)

axis_text_pt  <- 11
axis_title_pt <- 12  # if you want titles ~11 instead, set to 11

Shrew <- ggplot(Shrewfe_tbl, aes(x = term, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "black") +
  coord_flip() +
  scale_y_continuous(
    breaks = breaks_width(0.5),
    labels = function(x) ifelse(x == 0, "0", format(x, nsmall = 1))
  ) +
  labs(
    x = "Succession stage",
    y = "Estimate (±95% CI)"
  ) +
  theme_minimal(base_size = 14, base_family = "Arial") +   # KEEP SAME THEME
  theme(
    axis.text  = element_text(color = "black", size = axis_text_pt),
    axis.title = element_text(face = "plain", size = axis_title_pt),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(10, 20, 10, 10),
    plot.title  = element_text(hjust = 0.5, face = "plain")
  ) +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = "A",
    hjust = 1.15, vjust = 1.2,
    size = 7, fontface = "plain", family = "Arial"
  )

Shrew


##############################################################################################################
##############################################################################################################
##############################################################################################################

#Predicted counts

install.packages("marginaleffects")  # if not already installed
library(marginaleffects)


library(ggeffects)
library(ggplot2)

# Use mean active hours (un-logged!) and fix bias
mean_hours <- mean(df$active_hours, na.rm = TRUE)

preds <- ggpredict(
  top_models[["269"]],
  terms = "recovery",
  condition = c(active_hours = mean_hours),
  bias_correction = TRUE,
  margin = "empirical",
  type = "fixed"
) %>%
  as.data.frame()

# Order factor correctly
preds$x <- factor(preds$x, levels = c("1", "2", "3", "4"))

# Boxplot-style prediction plot
ggplot(preds, aes(x = x, y = predicted)) +
  geom_col(fill = "#5DADE2", width = 0.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, size = 0.8, color = "#1B4F72") +
  labs(
    title = "Predicted Sorex spp. Counts by Succession Stage",
    x = "Succession Stage",
    y = "Predicted Count (±95% CI)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    panel.grid.major.y = element_line(color = "grey80"),
    panel.grid.minor = element_blank()
  )




# Marginal predictions (population-average across random effects)
library(marginaleffects)

library(ggeffects)
library(ggplot2)

## Marginal predictions (population-average)
Shrewtop_model <- top_models[["269"]]

mean_hours <- mean(df$active_hours, na.rm = TRUE)

preds_marginal <- ggeffects::predict_response(
  Shrewtop_model,
  terms = "recovery",                 # ggeffects makes the grid
  condition = c(active_hours = mean_hours),
  bias_correction = TRUE
)

## Clean up x for plotting: map 1–4 -> Low/Medium/High/Forest interior
preds_marginal$Succession_stage <- factor(
  preds_marginal$x,
  levels = c("1", "2", "3", "4"),
  labels = c("Low", "Medium", "High", "Forest interior")
)



# Final size target: 12 cm wide
final_width_mm <- 120

# Choose ONE depending on what they asked:
base_pt <- 11   # comparable to ~11 pt at final size (use 12 if they want 12)
# base_pt <- 9  # use this for rectangular figures if they specifically allow ~9

p_shrew <- ggplot(preds_marginal, aes(x = Succession_stage, y = predicted)) +
  geom_col(fill = "grey70", width = 0.6, colour = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, linewidth = 0.7, colour = "black") +
  labs(
    x = "Seismic line regeneration stage",
    y = "Predicted detections"
  ) +
  theme_classic(base_size = base_pt, base_family = "Arial") +
  theme(
    axis.title  = element_text(face = "plain", size = 12),
    axis.text   = element_text(size = base_pt, colour = "black"),
    legend.title= element_text(face = "plain", size = base_pt),
    legend.text = element_text(size = base_pt),
    plot.margin = margin(2, 2, 2, 2, unit = "mm")
  )

ggsave(
  filename    = "Fig_shrew_succession4_predictions.tiff",
  plot        = p_shrew,
  device      = ragg::agg_tiff,
  dpi         = 600,
  width       = final_width_mm,
  height      = 90,        # adjust as you like; 90 mm is a nice rectangle at 12 cm wide
  units       = "mm",
  compression = "lzw"
)



# lines + points + CIs
ggplot(pred_ref,
       aes(x = factor(x, levels = c("1","2","3","4")), y = predicted)) +
  geom_line(aes(group = 1), linewidth = 1) +
  geom_point(size = 2.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15) +
  labs(
    title = sprintf("Predicted counts by regeneration stage (active_hours = %.1f)", mean_hours),
    x = "Regeneration stage", y = "Predicted count (±95% CI)"
  ) +
  theme_minimal(base_size = 13)


# 📈 Get predictions
preds_gg <- ggpredict(
  top_models[["269"]],
  terms = "recovery",
  type = "fixed",  # <- marginal prediction
  condition = c(active_hours = mean_hours),
  bias_correction = TRUE
) %>% 
  as.data.frame()

# 🎨 Plot
p1 <- ggplot(preds_gg, aes(x = factor(x), y = predicted)) +
  geom_col(fill = "#5DADE2", width = 0.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "#1B4F72") +
  labs(title = "ggpredict(): Marginal Predicted Counts",
       x = "Succession Stage", y = "Predicted Count (±95% CI)")




# 📈 Get predictions
preds_response <- predict_response(
  top_models[["77"]],
  newdata = datagrid(
    model = top_models[["77"]],
    recovery = c("1", "2", "3", "4"),
    active_hours = mean(df$active_hours, na.rm = TRUE)
  ),
  terms = "recovery",
  condition = c(active_hours = mean_hours),
  margin = "empirical",
  bias_correction = TRUE  # 👈 this goes here, not inside datagrid!
)


p2 <- ggplot(preds_response, aes(x = factor(x), y = predicted)) +
  geom_col(fill = "#58D68D", width = 0.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "#145A32") +
  labs(title = "predict_response(): Marginal Counts",
       x = "Succession Stage", y = "Predicted Count (±95% CI)")




# This is the correct function from the {marginaleffects} package
preds_effect <- avg_slopes(
  top_models[["77"]],
  variables = "recovery"
)


p3 <- ggplot(preds_effect, aes(x = contrast, y = estimate)) +
  geom_col(fill = "#F5B041", width = 0.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "#7D6608") +
  labs(
    title = "avg_slopes(): Marginal Effects of recovery",
    x = "Succession Contrast (vs ref)",
    y = "Effect on Predicted Count"
  ) +
  theme_minimal(base_size = 14)


library(patchwork)
(p1 | p2) / p3


library(marginaleffects)

comparisons_clean <- comparisons(
  top_models[["77"]],
  variables = "recovery",
  type = "link"
) %>%
  distinct(contrast, estimate, conf.low, conf.high)



ggplot(comparisons_clean, aes(x = contrast, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, size = 0.8, color = "#633974") +
  labs(
    title = "Pairwise Comparisons: recovery",
    x = "Contrast",
    y = "Effect Size (log scale)"
  ) +
  theme_minimal(base_size = 14)




comparisons_link <- comparisons(
  top_models[["77"]],
  variables = "recovery",
  type = "link"
)

comparisons_response <- comparisons_link %>%
  mutate(
    estimate_exp = exp(estimate),
    conf.low_exp = exp(conf.low),
    conf.high_exp = exp(conf.high)
  )


ggplot(comparisons_response, aes(x = contrast, y = estimate_exp)) +
  geom_hline(yintercept = 1, linetype = "dashed") +  # baseline = no change (ratio = 1)
  geom_point(size = 4, color = "#28B463") +
  geom_errorbar(aes(ymin = conf.low_exp, ymax = conf.high_exp),
                width = 0.2, size = 0.8, color = "#1D8348") +
  labs(
    title = "Pairwise Comparisons (Response Scale)",
    x = "recovery Contrast",
    y = "Multiplicative Effect on Shrew Count (Ratio)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))





library(marginaleffects)

ap <- avg_predictions(
  top_models[["77"]],
  by = "recovery",
  type = "response"   # original units (expected counts)
) %>%
  dplyr::select(recovery, estimate, conf.low, conf.high)

ggplot(ap, aes(x = recovery, y = estimate)) +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, size = 0.8, color = "#633974") +
  labs(
    title = "Average expected counts by recovery",
    x = "Succession stage",
    y = "Expected count (response scale)"
  ) +
  theme_minimal(base_size = 14)






# packages
library(broom.mixed)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggeffects)
library(emmeans)
library(marginaleffects)
library(patchwork)

# model + factors
mod <- top_models[["269"]]
df$recovery <- factor(df$recovery, levels = c("1","2","3","4"))

# choose exposure for the offset (rates vs typical-effort counts)
use_rates <- TRUE
exp_hours <- if (use_rates) 1 else mean(df$active_hours, na.rm = TRUE)


# make Stage 4 the baseline for contrasts
df_ref4 <- df %>% mutate(recovery = fct_relevel(recovery, "4"))

# refit model 77 with the relevelled data (same formula as before)
mod77_ref4 <- update(top_models[["269"]], data = df_ref4)


library(broom.mixed)
library(ggplot2)

fe_tbl <- tidy(mod77_ref4, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(term = recode(term,
                       "day_year_zscore" = "Julian date (z-scored)",
                       "recovery1" = "Regeneration stage 1 (vs 4)",
                       "recovery2" = "Regeneration stage 2 (vs 4)",
                       "recovery3" = "Regeneration stage 3 (vs 4)"
  ))

ggplot(fe_tbl, aes(x = fct_rev(term), y = estimate)) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  labs(
    title = "Top GLMM Fixed Effects: Sorex spp.",
    x = "Covariate (baseline = Stage 4)",
    y = "Estimate on log scale (±95% CI)"
  ) +
  theme_minimal(base_size = 12)


library(ggeffects)
mean_hours <- mean(df$active_hours, na.rm = TRUE)   # or 1 for per-hour rates

pred_ref <- ggpredict(
  mod77_ref4,
  terms = "recovery",
  condition = c(day_year_zscore = 0, active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) |>
  as.data.frame()

# lines + points + CIs
ggplot(pred_ref,
       aes(x = factor(x, levels = c("1","2","3","4")), y = predicted)) +
  geom_line(aes(group = 1), linewidth = 1) +
  geom_point(size = 2.6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15) +
  labs(
    title = sprintf("Predicted counts by regeneration stage (active_hours = %.1f)", mean_hours),
    x = "Regeneration stage", y = "Predicted count (±95% CI)"
  ) +
  theme_minimal(base_size = 13)

# linerange flavor
ggplot(pred_ref,
       aes(x = factor(x, levels = c("1","2","3","4")), y = predicted)) +
  geom_linerange(aes(ymin = conf.low, ymax = conf.high), linewidth = 1) +
  geom_point(size = 3, fill = "white", stroke = 1) +
  labs(title = "Predicted mean by regeneration stage (reference grid)",
       x = "Regeneration stage", y = "Predicted count (±95% CI)") +
  theme_minimal(base_size = 13)




# --- Packages ---
library(emmeans)
library(dplyr)
library(stringr)
library(officer)
library(flextable)

# --- EMMs (NB GLMM with log link) ---
# NOTE: use your fitted model; if it's top_models[["77"]], replace 'mod77_ref4' below.
emm_stage <- emmeans(
  mod77_ref4, ~ recovery,
  mode    = "latent",
  weights = "proportional"
)

# --- Contrasts ---
# Dunnett vs Stage 4
ref_idx <- match("4", levels(emm_stage)$recovery)
if (is.na(ref_idx)) stop("Level '4' not found in recovery.")
trt_vs_4   <- contrast(emm_stage, "trt.vs.ctrl", ref = ref_idx)

# Tukey all-pairs
pairs_link <- pairs(emm_stage, adjust = "tukey")

# --- Helper: get response-scale estimate (rate ratio) + adjusted p, NO CI ---
ratio_table <- function(contr_obj, adjust_label) {
  tb <- as.data.frame(summary(contr_obj, type = "response"))  # response-scale + adj p
  # Detect the response-scale estimate column name across emmeans variants
  est_col <- intersect(c("ratio", "response", "estimate", "odds.ratio", "rate.ratio"), names(tb))
  if (length(est_col) == 0) {
    stop("Could not find response-scale estimate column. Available: ",
         paste(names(tb), collapse = ", "))
  }
  tb %>%
    mutate(contrast = as.character(contrast)) %>%
    transmute(
      Adjustment     = adjust_label,
      Contrast       = str_replace_all(contrast, "(\\d)\\s*-\\s*(\\d)", "Stage \\1 vs \\2"),
      `Rate ratio`   = .data[[est_col[1]]],
      `Adj. p-value` = p.value
    )
}

dunnett_tbl <- ratio_table(trt_vs_4,  "Dunnett (vs Stage 4)")
tukey_tbl   <- ratio_table(pairs_link, "Tukey (all pairs)")

final_tbl <- bind_rows(dunnett_tbl, tukey_tbl) %>%
  mutate(
    `Rate ratio`   = as.numeric(`Rate ratio`),
    `Adj. p-value` = as.numeric(`Adj. p-value`)
  )

# --- Word table ---
ft <- flextable(final_tbl) %>%
  colformat_double(j = c("Rate ratio", "Adj. p-value"), digits = 3) %>%
  autofit() %>%
  set_caption("Table X. Pairwise contrasts among succession stages: rate ratios (response scale) and multiplicity-adjusted p-values (Dunnett vs Stage 4; Tukey all-pairs).")

doc <- read_docx() %>%
  body_add_par("Succession-stage contrasts (ratios only)", style = "heading 1") %>%
  body_add_flextable(ft)

out_path <- file.path(getwd(), "succession_stage_contrasts_ratios.docx")
print(doc, target = out_path)
message("Word file saved to: ", out_path)



# 
# Primary contrasts vs Stage 4 (Dunnett)
# 
# Stage 1 vs Stage 4: IRR = 0.34, 95% CI 0.16–0.73, p = 0.0023
# → Stage 1 has ~66% lower shrew rates than Stage 4. That’s a solid L for Stage 1.
# 
# Stage 2 vs Stage 4: IRR = 1.08, 95% CI 0.52–2.23, p = 0.978
# → No evidence of a difference (basically a tie).
# 
# Stage 3 vs Stage 4: IRR = 2.08, 95% CI 0.83–5.16, p = 0.150
# → Higher point estimate, but uncertainty is wide; not significant after Dunnett.
# 
# (Dunnett adjustment for 3 tests; CIs are back-transformed from the log scale.)
# 
# All-pairs among stages (Tukey; ratios shown first/second)
# 
# Significant pairs (Tukey-adjusted α = 0.05):
#   
#   Stage 4 / Stage 1: 2.95×, p = 0.0044 → Stage 4 > Stage 1
# 
# Stage 1 / Stage 2: 0.315×, p = 0.0293 → Stage 2 > Stage 1
# 
# Stage 1 / Stage 3: 0.163×, p = 0.0008 → Stage 3 > Stage 1

##############################################################################################################
##############################################################################################################
##############################################################################################################



##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################



##############################################################################################################
##############################################################################################################
##############################################################################################################

# Vole
library(dplyr)
library(forcats)

# Ensure factor + put "4" first (baseline for treatment contrasts)
df <- df %>%
  mutate(recovery = fct_relevel(as.factor(recovery), "4"))

# sanity check
stopifnot(levels(df$recovery)[1] == "4")


# 🔨 Baseline model
model_base <- glmmTMB(
  southern.red.backed.vole ~ day_year_zscore + recovery + offset(log(active_hours)) + (1 | pair_id),
  
  family = nbinom1(),
  data = df
)

# 🌍 Global model with additional terms to dredge
model_global <- update(
  model_base,
  . ~ . + forest_cover * recovery * disturbance
)


# 🌪️ Dredge it, keeping baseline terms fixed
fixed_terms <- c("day_year_zscore", "recovery", "offset(log(active_hours))")
dredge_results <- dredge(model_global, rank = "AICc", fixed = fixed_terms)

# Get models within ΔAIC ≤ 2
top_models <- get.models(dredge_results, subset = delta <= 2)

cat("Top", length(top_models), "models within ΔAIC ≤ 2 for Vole\n")

# 🧪 Check DHARMa residuals for each top model
residual_results <- lapply(seq_along(top_models), function(i) {
  cat("\nChecking residuals for Model", i, "\n")
  sim <- simulateResiduals(top_models[[i]], n = 1000)
  plot(sim)
  return(sim)
})

# 📊 Summarize AIC table
print(dredge_results)

#Used UP
# Only 2 models (other removes fixed effects) the difference is between interaction vs no interaction with disturbance

summary(top_models[["90"]])
summary(top_models[["74"]])


##############################################################################################################
##############################################################################################################
##############################################################################################################

# Picking one model

# 📈 Plot fixed effects of top model (Model 1)
Voletop_model <- top_models[["266"]]
# 📈 Plot fixed effects of top model (Model 1)
Volefe_tbl <- tidy(Voletop_model, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)")%>%
  # Keep only recovery terms
  filter(str_detect(term, "recovery"))

# Clean up term labels for plotting
Volefe_tbl <- Volefe_tbl %>%
  mutate(term = recode(term,
                       "recovery1" = "Low",
                       "recovery2" = "Medium",
                       "recovery3" = "High",
                       "forest_coverMixedwood" = "Mixedwood",
                       "disturbanceYes" = "Disturbance Present"
  ))

Volefe_tbl <- Volefe_tbl %>%
  mutate(term = factor(term, levels = c("Low", "Medium", "High")))

# Plot
library(ggplot2)
library(forcats)

windowsFonts(Arial = windowsFont("Arial"))

axis_text_pt  <- 11
axis_title_pt <- 12
panel_label_size <- 8  # bump to 9 if it looks small in the final composite

Vole <- ggplot(Volefe_tbl, aes(x = term, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "black") +
  coord_flip() +
  scale_y_continuous(
    breaks = breaks_width(0.5),
    labels = function(x) ifelse(x == 0, "0", format(x, nsmall = 1))
  ) +
  labs(
    x = "Succession stage",
    y = "Estimate (±95% CI)"
  ) +
  theme_minimal(base_size = 14, base_family = "Arial") +
  theme(
    axis.text  = element_text(color = "black", size = axis_text_pt),
    axis.title = element_text(face = "plain", size = axis_title_pt),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(6, 8, 6, 6, unit = "mm"),
    plot.title  = element_text(hjust = 0.5, face = "plain")
  ) +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = "B",
    hjust = 1.15, vjust = 1.15,
    size = panel_label_size, fontface = "plain", family = "Arial"
  )

Vole


##############################################################################################################
##############################################################################################################
##############################################################################################################

library(dplyr)
library(ggplot2)

mean_hours <- mean(df$active_hours, na.rm = TRUE)

pred_int_ref <- ggeffects::predict_response(
  top_models[["266"]],
  terms = c("recovery", "disturbance"),
  condition = c(active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) |>
  as.data.frame() |>
  mutate(
    Succession_stage = factor(
      x,
      levels = c("1", "2", "3", "4"),
      labels = c("Low", "Medium", "High", "Forest interior")
    ),
    Line_type = factor(
      group,
      levels = c("C", "N"),                         # underlying codes
      labels = c("Conventional", "Low-impact")      # what you want to show
    )
  )

windowsFonts(Arial = windowsFont("Arial"))

base_pt  <- 11
title_pt <- 12

p_int_ref <- ggplot(
  pred_int_ref,
  aes(x = Succession_stage, y = predicted, fill = Line_type)
) +
  geom_col(
    position = position_dodge(width = 0.7),
    width = 0.6,
    colour = "black"
  ) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.6
  ) +
  scale_fill_manual(values = c("white", "grey60")) +
  labs(
    x    = "Seismic line regeneration stage",
    y    = "Predicted detections",
    fill = "Seismic line type"
  ) +
  theme_classic(base_size = base_pt, base_family = "Arial") +  # no top/right border
  theme(
    axis.title   = element_text(face = "plain", size = title_pt),
    axis.text    = element_text(size = base_pt, colour = "black"),
    legend.title = element_text(face = "plain", size = 12),
    legend.text  = element_text(size = base_pt),
    legend.position  = "bottom",
    legend.direction = "horizontal",
    plot.margin  = margin(6, 6, 6, 6, unit = "mm")
  ) +
  guides(
    fill = guide_legend(nrow = 1, byrow = TRUE)
  )

p_int_ref

ggsave(
  filename    = "VoleSuccession.tiff",
  plot        = p_int_ref,
  device      = ragg::agg_tiff,   # better font handling than base tiff device
  dpi         = 600,
  width       = 120,              # 12 cm final width
  height      = 80,               # adjust if you want (keeps nice proportions)
  units       = "mm",
  compression = "lzw"
)



 # --- Vole pairwise contrasts & marginal means (marginaleffects) ---
 
 library(marginaleffects)
 library(dplyr)
 library(ggplot2)
 
 # Pick the vole model: prefer 'best_mod' if you computed it; else first top model
 fit_vole <- if (exists("best_mod")) best_mod else if (exists("top_models")) top_models[[1]] else stop("No model found.")
 if (!exists("mean_hours")) mean_hours <- mean(df$active_hours, na.rm = TRUE)
 
 # ---------- A) Pairwise contrasts on LINK (log) scale ----------
 comparisons_link_vole <- comparisons(
   top_models[["266"]],
   variables = "recovery",
   type = "link",
   newdata = datagrid(
     model = fit_vole,
     active_hours = mean_hours   # control the offset exposure
     # (other covariates held at reference/means automatically)
   )
 ) %>%
   distinct(contrast, estimate, conf.low, conf.high)
 
 ggplot(comparisons_link_vole, aes(x = contrast, y = estimate)) +
   geom_hline(yintercept = 0, linetype = "dashed") +
   geom_point(size = 4, color = "#AF7AC5") +
   geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                 width = 0.2, size = 0.8, color = "#633974") +
   labs(
     title = "Pairwise Comparisons: recovery (Vole, link scale)",
     x = "Contrast",
     y = "Effect size (log scale)"
   ) +
   theme_minimal(base_size = 14) +
   theme(axis.text.x = element_text(angle = 45, hjust = 1))
 
 # ---------- B) Same contrasts as RATE RATIOS (response scale) ----------
 comparisons_response_vole <- comparisons(
   fit_vole,
   variables = "recovery",
   type = "link",
   newdata = datagrid(
     model = fit_vole,
     active_hours = mean_hours
   )
 ) %>%
   mutate(
     estimate_exp = exp(estimate),
     conf.low_exp = exp(conf.low),
     conf.high_exp = exp(conf.high)
   )
 
 ggplot(comparisons_response_vole, aes(x = contrast, y = estimate_exp)) +
   geom_hline(yintercept = 1, linetype = "dashed") +
   geom_point(size = 4, color = "#28B463") +
   geom_errorbar(aes(ymin = conf.low_exp, ymax = conf.high_exp),
                 width = 0.2, size = 0.8, color = "#1D8348") +
   labs(
     title = "Pairwise Comparisons (Vole, response scale)",
     x = "recovery contrast",
     y = "Multiplicative effect on vole count (ratio)"
   ) +
   theme_minimal(base_size = 14) +
   theme(axis.text.x = element_text(angle = 45, hjust = 1))
 
 # ---------- C) Average expected counts by stage (response/original scale) ----------
 ap_vole <- avg_predictions(
   fit_vole,
   by = "recovery",
   type = "response"     # original units (expected counts)
   # Note: this averages over the empirical distribution of other covariates.
   # If you prefer standardized exposure/covariates, add newdata = datagrid(...)
 ) %>%
   dplyr::select(recovery, estimate, conf.low, conf.high)
 
 ggplot(ap_vole, aes(x = recovery, y = estimate)) +
   geom_point(size = 4, color = "#AF7AC5") +
   geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                 width = 0.15, size = 0.8, color = "#633974") +
   labs(
     title = "Average expected counts by recovery (Vole)",
     x = "Succession stage",
     y = "Expected count (response scale)"
   ) +
   theme_minimal(base_size = 14)
 




 
 
 # --- Vole: stage contrasts collapsed over disturbance (no repetition) ---
 
 library(emmeans)
 library(dplyr)
 library(stringr)
 library(officer)
 library(flextable)
 
 # Use your chosen vole model
 fit_vole <- if (exists("best_mod")) best_mod else if (exists("top_models")) top_models[[1]] else stop("No model found.")
 
 # EMMs for recovery ONLY (collapsed over disturbance and other factors)
 emm_stage <- emmeans(
   fit_vole, ~ recovery,
   mode    = "latent",
   weights = "proportional"
 )
 
 # --- Contrasts ---
 # Dunnett vs Stage 4 (explicit baseline)
 ref_idx <- match("4", levels(emm_stage)$recovery)
 if (is.na(ref_idx)) stop("Level '4' not found in recovery levels.")
 trt_vs_4 <- contrast(emm_stage, "trt.vs.ctrl", ref = ref_idx)
 
 # Tukey all-pairs (among stages)
 pairs_link <- pairs(emm_stage, adjust = "tukey")
 
 # Helper: response-scale rate ratio + adjusted p (NO CI)
 ratio_table <- function(contr_obj, adjust_label) {
   tb <- as.data.frame(summary(contr_obj, type = "response"))  # response scale + adj p
   est_col <- intersect(c("ratio", "response", "estimate", "odds.ratio", "rate.ratio"), names(tb))
   if (length(est_col) == 0) stop("Response-scale estimate column not found. Available: ", paste(names(tb), collapse = ", "))
   tb %>%
     mutate(contrast = as.character(contrast)) %>%
     transmute(
       Adjustment     = adjust_label,
       Contrast       = str_replace_all(contrast, "(\\d)\\s*-\\s*(\\d)", "Stage \\1 vs \\2"),
       `Rate ratio`   = .data[[est_col[1]]],
       `Adj. p-value` = p.value
     )
 }
 
 # Build final table (no disturbance strata)
 dunnett_tbl <- ratio_table(trt_vs_4,  "Dunnett (vs Stage 4)")
 tukey_tbl   <- ratio_table(pairs_link, "Tukey (all pairs)")
 
 final_tbl <- bind_rows(dunnett_tbl, tukey_tbl) %>%
   mutate(
     `Rate ratio`   = as.numeric(`Rate ratio`),
     `Adj. p-value` = as.numeric(`Adj. p-value`)
   ) %>%
   arrange(Adjustment, Contrast)
 
 # OPTIONAL: one-line table for the main effect of disturbance (since no interaction)
 emm_dist <- emmeans(fit_vole, ~ disturbance, mode = "latent", weights = "proportional")
 dist_row <- as.data.frame(summary(pairs(emm_dist), type = "response"))
 dist_est_col <- intersect(c("ratio","response","estimate","odds.ratio","rate.ratio"), names(dist_row))
 if (length(dist_est_col) > 0 && nrow(dist_row) == 1) {
   tbl_dist <- tibble::tibble(
     Adjustment = "Main effect",
     Contrast   = paste0("Disturbance: ", dist_row$contrast),
     `Rate ratio`   = as.numeric(dist_row[[dist_est_col[1]]]),
     `Adj. p-value` = as.numeric(dist_row$p.value)
   )
   final_tbl <- bind_rows(final_tbl, tbl_dist)
 }
 
 # --- Word table ---
 ft <- flextable(final_tbl) %>%
   colformat_double(j = c("Rate ratio", "Adj. p-value"), digits = 3) %>%
   autofit() %>%
   set_caption("Table X. Southern red-backed vole — pairwise contrasts among succession stages (collapsed over disturbance): rate ratios (response scale) and multiplicity-adjusted p-values (Dunnett vs Stage 4; Tukey all-pairs). A single row summarizes the disturbance main effect (no interaction in the selected model).")
 
 doc <- read_docx() %>%
   body_add_par("Vole: Succession-stage contrasts (collapsed over disturbance)", style = "heading 1") %>%
   flextable::body_add_flextable(ft)
 
 out_path <- file.path(getwd(), "vole_stage_contrasts_collapsed_over_disturbance.docx")
 print(doc, target = out_path)
 message("Word file saved to: ", out_path)
 
 
 
 
 
library(emmeans)

mod <- top_models[["74"]]
df$recovery <- factor(df$recovery, levels = c("1","2","3","4"))

# Averaging over other factors:
#   - weights="proportional"  => reflects your observed mix (recommended)
#   - weights="equal"         => equal averaging across levels
wts <- "proportional"

# For GLMMs, integrate over random effects (population-level) with mode="latent"
latent <- "latent"

emm_dist_by_stage <- emmeans(mod, ~ disturbance | recovery,
                             weights = wts, mode = latent)

# With 2 levels, Tukey = same as no adjustment; pairs gives N vs ref per stage
dist_pairs_link <- pairs(emm_dist_by_stage)                      # log scale diffs
dist_pairs_resp <- summary(dist_pairs_link, type = "response")   # IRR + 95% CI
dist_pairs_resp   # <- report these

# Interpretation: low-impact seismic (N) supports substantially higher vole rates than conventional 
# (C), especially in Stage 2, and clearly in Stages 4 and 1. Stage 3 trends up but isn’t convincing.

emm_stage_by_dist <- emmeans(mod, ~ recovery | disturbance,
                             weights = wts, mode = latent)

# All-pairs among stages within each disturbance
pairs_stage_link  <- pairs(emm_stage_by_dist, adjust = "tukey")
summary(pairs_stage_link)                              # log scale
summary(pairs_stage_link, type = "response")           # ratios of means + 95% CI

# Interpretation: Under conventional sites, Stage 2 is the low point; 
# under low-impact seismic, stages are not distinguishable after adjustment

# Stage k vs control Stage 4, in each disturbance panel
# build the EMMs first (I keep your nice defaults)
emm_stage_by_dist <- emmeans(
  top_models[["74"]],
  ~ recovery | disturbance,
  weights = "proportional",
  mode = "latent"
)

# see what emmeans thinks the stage levels are
levels(emm_stage_by_dist)$recovery
# e.g. "1" "2" "3" "4"

# find the index of "4" and use it
ref_idx <- match("4", levels(emm_stage_by_dist)$recovery)
stopifnot(!is.na(ref_idx))

trt_vs_4 <- contrast(emm_stage_by_dist, method = "trt.vs.ctrl", ref = ref_idx)

# link-scale summary + response-scale IRRs with CIs
summary(trt_vs_4)                         # Dunnett p-values
confint(trt_vs_4, type = "response")      # IRR (Stage k / 4) + 95% CI
# IRR (Stage k / 4) + 95% CI

df$recovery <- factor(df$recovery, levels = c("4","1","2","3"))
mod90 <- update(top_models[["90"]], data = df)

emm_stage_by_dist <- emmeans(mod90, ~ recovery | disturbance,
                             weights = "proportional", mode = "latent")

trt_vs_4 <- contrast(emm_stage_by_dist, "trt.vs.ctrl", ref = 1)
summary(trt_vs_4)
confint(trt_vs_4, type = "response")

# Interpretation: Under C, Stage 1 is clearly lower than Stage 4; under N, no stage differs from Stage 4.


# Disturbance simple effects (IRR, N vs C):
#   “Within Stage 2, vole rates were ~14.7× higher on low-impact seismic (N) than conventional (C) (p = 0.0011).
# Within Stage 4, rates were ~3.46× higher (p = 0.036); within Stage 1, ~2.30× higher (p = 0.0058).
# Stage 3 showed a non-significant trend (~1.84×, p = 0.239).
# Estimates are population-level (RE-integrated) and averaged over the observed mix of other factors.”
# 
# Stage differences within disturbance:
#   “Under C, Stage 2 was markedly lower than Stages 1, 3, and 4 (Tukey-adjusted: S1/S2 ≈ 11.82, p = 0.0045; S2/S3 ≈ 0.10, p = 0.0319; S2/S4 ≈ 0.10, p = 0.0380).
# Under N, no stage contrasts were significant (all p > 0.29).”
# 
# Vs Stage 4 (Dunnett):
#   “Under C, Stage 1 was substantially lower than Stage 4 (IRR ≈ 0.085, 95% CI 0.020–0.359; Dunnett-adjusted p < 0.001); other stages did not differ from Stage 4. Under N, no stages differed from Stage 4.”
# 
# Interaction (RORR):
#   “Differences in the disturbance effect across stages were not significant after Tukey adjustment (largest RORR ≈ 6.4, adjusted p ≈ 0.106).”








##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################



##############################################################################################################
##############################################################################################################
##############################################################################################################

# Deer mouse

df_Deer <- df %>%
  filter(forest_cover != "Lowland Spruce")

# 🔨 Baseline model
model_base <- glmmTMB(
  deer.mouse ~ day_year_zscore + recovery + offset(log(active_hours)) + (1 | pair_id),
  
  family = nbinom1(),
  data = df_Deer
)

# 🌍 Global model with additional terms to dredge
model_global <- update(
  model_base,
  . ~ . + forest_cover * recovery * disturbance
)

# 🌪️ Dredge it, keeping baseline terms fixed
fixed_terms <- c("day_year_zscore", "recovery", "offset(log(active_hours))")
dredge_results <- dredge(model_global, rank = "AICc", fixed = fixed_terms)

# Get models within ΔAIC ≤ 2
top_models <- get.models(dredge_results, subset = delta <= 2)

cat("Top", length(top_models), "models within ΔAIC ≤ 2 for Deer Mouse\n")

# 🧪 Check DHARMa residuals for each top model
residual_results <- lapply(seq_along(top_models), function(i) {
  cat("\nChecking residuals for Model", i, "\n")
  sim <- simulateResiduals(top_models[[i]], n = 1000)
  plot(sim)
  return(sim)
})

# 📊 Summarize AIC table
print(dredge_results)



summary(top_models[["11"]])
summary(top_models[["12"]])

# Only one model (the other ones are removing fixed effects)

##############################################################################################################
##############################################################################################################
##############################################################################################################

# ============================
# Deer mouse — model: deer.mouse ~ forest_cover + (1 | pair_id)
# Use top_models[[8]]
# ============================

library(broom.mixed)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggeffects)
library(marginaleffects)
library(emmeans)
library(stringr)
library(officer)
library(flextable)
library(tibble)

# ---- pick model ----
Deertop_model <- top_models[["11"]]

# -------- 1) Fixed-effects plot (forest_cover only) --------
# 📈 Plot fixed effects of top model (Model 1)
Deerfe_tbl <- tidy(Deertop_model, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)")%>%
  # Keep only recovery terms
  filter(str_detect(term, "recovery"))

# Clean up term labels for plotting
Deerfe_tbl <- Deerfe_tbl %>%
  mutate(term = recode(term,
                       "recovery1" = "Low",
                       "recovery2" = "Medium",
                       "recovery3" = "High",
                       "forest_coverMixedwood" = "Mixedwood",
                       "disturbanceYes" = "Disturbance Present"
  ))

Deerfe_tbl <- Deerfe_tbl %>%
  mutate(term = factor(term, levels = c("Low", "Medium", "High")))

# Plot
library(ggplot2)
library(forcats)


# (Windows) register Arial once per session
windowsFonts(Arial = windowsFont("Arial"))

axis_text_pt  <- 11
axis_title_pt <- 12
panel_label_size <- 8  # bump to 9 if it looks small in the final composite

Deer <- ggplot(Deerfe_tbl, aes(x = term, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "black") +
  coord_flip() +
  scale_y_continuous(
    breaks = breaks_width(0.5),
    labels = function(x) ifelse(x == 0, "0", format(x, nsmall = 1))
  ) +
  labs(
    x = "Succession stage",
    y = "Estimate (±95% CI)"
  ) +
  theme_minimal(base_size = 14, base_family = "Arial") +
  theme(
    axis.text  = element_text(color = "black", size = axis_text_pt),
    axis.title = element_text(face = "plain", size = axis_title_pt),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(6, 8, 6, 6, unit = "mm"),
    plot.title  = element_text(hjust = 0.5, face = "plain")
  ) +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = "C",
    hjust = 1.15, vjust = 1.15,
    size = panel_label_size, fontface = "plain", family = "Arial"
  )

Deer

# -------- 2) Predicted counts by forest_cover (response scale) --------
pred_fc <- ggeffects::predict_response(
  top_models[["11"]],
  terms = "recovery",     # ggeffects builds the grid over levels
  type = "fixed",
  bias_correction = TRUE
) %>% as.data.frame()

ggplot(pred_fc, aes(x = factor(x), y = predicted)) +
  geom_col(width = 0.55, fill = "#58D68D") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "#145A32") +
  labs(
    title = "Deer mouse: Predicted counts by forest cover",
    x = "Forest cover",
    y = "Predicted count (±95% CI)"
  ) +
  theme_minimal(base_size = 14)






library(ggeffects)
library(dplyr)
library(ggplot2)

## Pick exposure
mean_hours <- mean(df$active_hours, na.rm = TRUE)

pred_int_ref <- ggeffects::predict_response(
  top_models[["11"]],
  terms = c("recovery", "forest_cover"),
  condition = c(active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) %>%
  as.data.frame() %>%
  mutate(
    Succession_stage = factor(
      x,
      levels = c("1", "2", "3", "4"),
      labels = c("Low", "Medium", "High", "Forest interior")
    ),
    Forest_cover = factor(
      group,
      # 🔁 adjust these if your levels are named slightly differently
      levels = c("Deciduous", "Mixedwood", "Lowland Spruce"),
      labels = c("Deciduous", "Mixedwood", "Lowland spruce")
    )
  )

## Professional-looking plot
# (Windows) register Arial once per session
windowsFonts(Arial = windowsFont("Arial"))

library(ggplot2)
library(ragg)

base_pt  <- 11
title_pt <- 12

p_fcover <- ggplot(
  pred_int_ref,
  aes(x = Succession_stage, y = predicted, fill = Forest_cover)
) +
  geom_col(
    position = position_dodge(width = 0.7),
    width = 0.6,
    colour = "black"
  ) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.6
  ) +
  scale_fill_manual(values = c("white", "grey60", "grey20")) +
  labs(
    x    = "Seismic line regeneration stage",
    y    = "Predicted detections",
    fill = "Forest cover type"
  ) +
  theme_classic(base_size = base_pt, base_family = "Arial") +  # no top/right border
  theme(
    axis.title   = element_text(face = "plain", size = title_pt),
    axis.text    = element_text(size = base_pt, colour = "black"),
    legend.title = element_text(face = "plain", size = title_pt),
    legend.text  = element_text(size = base_pt),
    legend.position  = "bottom",
    legend.direction = "horizontal",
    plot.margin  = margin(6, 6, 6, 6, unit = "mm")
  ) +
  guides(
    fill = guide_legend(nrow = 1, byrow = TRUE)
  )

p_fcover

ggsave(
  filename    = "DeerSuccession.tiff",
  plot        = p_fcover,
  device      = ragg::agg_tiff,
  dpi         = 600,
  width       = 120,   # 12 cm final width
  height      = 80,    # tweak if needed
  units       = "mm",
  compression = "lzw"
)


# -------- 3) Pairwise contrasts among forest_cover levels --------

library(marginaleffects)
library(dplyr)

# Your dredged model:
fit_deer <- top_models[[8]]

# 1) Make sure the model knows its data (dredge can drop this pointer)
fit_deer$call$data <- quote(df_Deer)

# 2) Ensure factor levels are exactly those used for fitting
#    (drop any unused levels in the analysis data)
df_Deer <- droplevels(df_Deer)

# levels known to the MODEL (safe source is the model frame)
mf <- model.frame(fit_deer)  # uses the stored data/terms
fc_levels <- levels(mf$forest_cover)

# Build a minimal grid with the SAME factor (and SAME levels attr)
grid_fc <- data.frame(
  forest_cover = factor(fc_levels, levels = fc_levels)
)

# 3) Do comparisons with a matching grid and population-level preds
cmp_link <- comparisons(
  fit_deer,
  variables = "forest_cover",
  type = "link",
  newdata = grid_fc,
  re.form = NA            # ignore REs; fixed-effects only
) %>%
  distinct(contrast, estimate, conf.low, conf.high)


ggplot(cmp_link, aes(x = contrast, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, size = 0.8, color = "#633974") +
  labs(
    title = "Pairwise Comparisons: recovery (Deer Mouse, link scale)",
    x = "Contrast",
    y = "Effect size (log scale)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))




## B) Response-scale RATE RATIOS
cmp_resp <- comparisons(
  fit_deer,
  variables = "forest_cover",
  type = "link",
  newdata = grid_fc,
  re.form = NA
) %>%
  mutate(
    estimate_exp = exp(estimate),
    conf.low_exp = exp(conf.low),
    conf.high_exp = exp(conf.high)
  )


ggplot(cmp_resp, aes(x = contrast, y = estimate_exp)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_point(size = 4, color = "#28B463") +
  geom_errorbar(aes(ymin = conf.low_exp, ymax = conf.high_exp),
                width = 0.2, size = 0.8, color = "#1D8348") +
  labs(
    title = "Deer mouse — Pairwise comparisons (response scale)",
    x = "forest_cover contrast",
    y = "Multiplicative effect (rate ratio)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------- 4) Average expected counts by forest_cover (response scale) --------
ap_deer <- avg_predictions(
  fit_deer,
  by = "forest_cover",
  type = "response"   # averages over empirical distribution of random effects at population level
) %>%
  select(forest_cover, estimate, conf.low, conf.high)

ggplot(ap_deer, aes(x = forest_cover, y = estimate)) +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, size = 0.8, color = "#633974") +
  labs(
    title = "Deer mouse — Average expected counts by forest cover",
    x = "Forest cover",
    y = "Expected count (response scale)"
  ) +
  theme_minimal(base_size = 14)

# -------- 5) EMMs: pairwise contrasts (no CI table, ratios + adjusted p) --------
emm_fc <- emmeans(
  top_models[["11"]], ~ recovery,
  mode    = "latent",
  weights = "proportional"
)

# All-pairs Tukey among forest_cover levels
pairs_fc <- pairs(emm_fc, adjust = "tukey")

# Helper: response-scale rate ratio + adjusted p (NO CI)
ratio_table <- function(contr_obj, adjust_label) {
  tb <- as.data.frame(summary(contr_obj, type = "response"))
  est_col <- intersect(c("ratio","response","estimate","odds.ratio","rate.ratio"), names(tb))
  if (length(est_col) == 0) stop("Response-scale estimate column not found. Available: ", paste(names(tb), collapse = ", "))
  tb %>%
    mutate(contrast = as.character(contrast)) %>%
    transmute(
      Adjustment     = adjust_label,
      Contrast       = contrast,                 # keep original labels (forest cover vs forest cover)
      `Rate ratio`   = .data[[est_col[1]]],
      `Adj. p-value` = p.value
    )
}

tukey_tbl <- ratio_table(pairs_fc, "Tukey (all pairs)")

final_tbl <- tukey_tbl %>%
  mutate(
    `Rate ratio`   = as.numeric(`Rate ratio`),
    `Adj. p-value` = as.numeric(`Adj. p-value`)
  ) %>%
  arrange(Adjustment, Contrast)

# --- Word table export ---
ft <- flextable(final_tbl) %>%
  colformat_double(j = c("Rate ratio", "Adj. p-value"), digits = 3) %>%
  autofit() %>%
  set_caption("Table X. Deer mouse — pairwise contrasts among forest-cover classes: rate ratios (response scale) and multiplicity-adjusted p-values (Tukey all-pairs).")

doc <- read_docx() %>%
  body_add_par("Deer mouse: forest-cover contrasts (ratios only)", style = "heading 1") %>%
  flextable::body_add_flextable(ft)

out_path <- file.path(getwd(), "deer_mouse_forest_cover_contrasts.docx")
print(doc, target = out_path)
message("Word file saved to: ", out_path)





best_mod <- top_models[["11"]]


library(emmeans)

# 1) Match the model’s simple 1 vs 4 contrast (no averaging, no adjust)
emm_link <- emmeans(best_mod, ~ recovery)          # link scale by default
contrast(emm_link, method = list("1 - 4" = c(-1,0,0,1)), adjust = "none")

# 2) Do the standard Tukey across all levels (link scale)
pairs(emm_link, adjust = "tukey")

# 3) If you have interactions, test within levels of the interacting var:
#    Example: recovery * forest_cover
emm_by_fc <- emmeans(best_mod, ~ recovery | forest_cover)
pairs(emm_by_fc, adjust = "tukey")

# 4) Force z-tests (to mirror glmmTMB summary) and/or set df:
pairs(emm_link, adjust = "tukey", infer = c(TRUE, TRUE), df = Inf)
# (df = Inf → z; omit/finite df may yield t-like inference)

# 5) Compare on response scale (p-values still from link-scale linear predictor)
pairs(emmeans(best_mod, ~ recovery, type = "response"), adjust = "tukey")





library(emmeans)
mod <- top_models[["12"]]


# EMMs by forest cover, for each recovery level
emm_fc_by_stage <- emmeans(mod, ~ forest_cover | recovery)

# Pairwise contrasts with Tukey adjustment
pairs_fc_link <- pairs(emm_fc_by_stage, adjust = "tukey")
summary(pairs_fc_link)
confint(pairs_fc_link)

# Response-scale summaries (ratio, lower.CL, upper.CL)
pairs_fc_resp <- summary(pairs_fc_link, type = "response",
                         bias.adjust = TRUE)  # small-sample correction
pairs_fc_resp


emm_stage_by_fc <- emmeans(mod, ~ recovery | forest_cover)

# Link scale
pairs_stage_link <- pairs(emm_stage_by_fc, adjust = "tukey")
summary(pairs_stage_link)

# Response scale (ratios for stage comparisons)
pairs_stage_resp <- summary(pairs_stage_link, type = "response",
                            bias.adjust = TRUE)
pairs_stage_resp


emm_fc_overall <- emmeans(mod, ~ forest_cover)

# Link scale:
pairs_fc_overall_link <- pairs(emm_fc_overall, adjust = "tukey")
summary(pairs_fc_overall_link)

# Response scale (IRRs):
pairs_fc_overall_resp <- summary(pairs_fc_overall_link, type = "response",
                                 bias.adjust = TRUE)
pairs_fc_overall_resp


# A) Directly ask for response-scale CIs from the link-scale pairs
confint(pairs_fc_overall_link, type = "response")
# B) Regrid to response scale first, then pairwise + CIs
emm_fc_overall     <- emmeans(mod, ~ forest_cover)                 # or weights="proportional"
emm_fc_overall_resp<- regrid(emm_fc_overall, type = "response")    # on response scale
pairs_fc_overall_r <- pairs(emm_fc_overall_resp, adjust = "tukey")
summary(pairs_fc_overall_r)        # ratios
confint(pairs_fc_overall_r)        # CI for ratios


pairs_fc_overall_link <- pairs(emmeans(mod, ~ forest_cover), adjust = "tukey")
confint(pairs_fc_overall_link, type = "response")   # => ratio, asymp.LCL, asymp.UCL

emm_fc_overall_resp <- regrid(emmeans(mod, ~ forest_cover), type = "response")
pairs_fc_overall_r  <- pairs(emm_fc_overall_resp, adjust = "tukey")
confint(pairs_fc_overall_r)                          # => estimate (diff), CI


# Report line:
#   “Deer mouse rates in Deciduous were 4.27× those in Mixedwood
# (95% CI 1.79–10.17; z = 3.28; p = 0.001), averaged over disturbance and stages.”
# In terms of animals tho that means 1.73 (0.414-3.05) more deer mouse in the deciduous


library(emmeans)
mod <- top_models[["8"]]

# Pairwise among all four stages
emm_stage_overall   <- emmeans(mod, ~ forest_cover, weights = "proportional")  # or "equal"
pairs_stage_link    <- pairs(emm_stage_overall, adjust = "tukey")
summary(pairs_stage_link)                         # log scale diffs
confint(pairs_stage_link, type = "response")      # IRRs + CIs


# Make 4 the control without refitting
emm_stage_overall <- emmeans(mod, ~ forest_cover, weights = "proportional")
trtvctrl_link     <- contrast(emm_stage_overall, method = "trt.vs.ctrl")
summary(trtvctrl_link)                             # log scale
summary(trtvctrl_link, type = "response")          # IRR (Stage k / Stage 4)


library(emmeans)

emm_stage_overall <- emmeans(mod, ~ forest_cover, weights = "proportional")

# 1) See what emmeans thinks the stage levels are (and their order)
levels(emm_stage_overall)$forest_cover
# e.g. "1" "2" "3" "4"

# 2) Grab the index of "4" safely
ref_idx <- match("4", levels(emm_stage_overall)$forest_cover)

# 3) Now run treatment-vs-control using the index
trtvctrl_link <- contrast(emm_stage_overall, method = "trt.vs.ctrl")

# Link scale (log differences)
summary(trtvctrl_link)

# Response scale (rate ratios)
confint(trtvctrl_link, type = "response")

# Report line template:
#   “Compared to Stage 4, deer mouse rates were 0.42× at Stage 1 
# (95% CI: …; Dunnett-adjusted p = 0.096), 0.52× at Stage 2 (p = 0.199), and 0.85× at Stage 3 
# (p = 0.952); averages are over disturbance and forest cover.”



library(emmeans)

# overall EMMs for stages (averaged over other factors)
emm_stage_overall <- emmeans(mod, ~ forest_cover, weights = "proportional")
ref_idx <- match("4", levels(emm_stage_overall)$forest_cover)
trt <- contrast(emm_stage_overall, "trt.vs.ctrl", ref = ref_idx)

ci_resp <- confint(trt, type = "response")  # → ratio, lower.CL, upper.CL
ci_resp

# contrast                      ratio    SE  df asymp.LCL asymp.UCL
# recovery1 / recovery4 1.171 0.541 Inf     0.394      3.48
# recovery2 / recovery4 0.486 0.297 Inf     0.115      2.05
# recovery3 / recovery4 0.608 0.351 Inf     0.156      2.37
# 
# Results are averaged over the levels of: disturbance, forest_cover 
# Confidence level used: 0.95 
# Conf-level adjustment: dunnettx method for 3 estimates 
# Intervals are back-transformed from the log scale




emm_stage_by_fc   <- emmeans(mod, ~ recovery | forest_cover, weights = "proportional")
pairs_stage_by_fc <- pairs(emm_stage_by_fc, adjust = "tukey")
summary(pairs_stage_by_fc)                          # link
summary(pairs_stage_by_fc, type = "response")       # IRR

emm_fc_by_stage <- emmeans(mod, ~ forest_cover | recovery, weights = "proportional")
summary(pairs(emm_fc_by_stage, adjust = "tukey"), infer = c(TRUE, TRUE))








##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################
##############################################################################################################



##############################################################################################################
##############################################################################################################
##############################################################################################################

# Red Squirrel
# Removed the Upland


 df_SQ <- df %>%
   filter(forest_cover != "Upland Spruce")

# 🔨 Baseline model
model_base <- glmmTMB(
  red.squirrel ~ day_year_zscore + recovery + offset(log(active_hours)) + (1 | pair_id),
  
  family = nbinom2(),
  data = df_SQ
)

# 🌍 Global model with additional terms to dredge
model_global <- update(
  model_base,
  . ~ . + forest_cover * recovery * disturbance
)

# 🌪️ Dredge it, keeping baseline terms fixed
fixed_terms <- c("day_year_zscore", "recovery", "offset(log(active_hours))")
dredge_results <- dredge(model_global, rank = "AICc", fixed = fixed_terms)

# Get models within ΔAIC ≤ 2
top_models <- get.models(dredge_results, subset = delta <= 2)

cat("Top", length(top_models), "models within ΔAIC ≤ 2 for Squirrel\n")

# 🧪 Check DHARMa residuals for each top model
residual_results <- lapply(seq_along(top_models), function(i) {
  cat("\nChecking residuals for Model", i, "\n")
  sim <- simulateResiduals(top_models[[i]], n = 1000)
  plot(sim)
  return(sim)
})

# 📊 Summarize AIC table
print(dredge_results)


# Only one model (the other ones are removing fixed effects)

##############################################################################################################
##############################################################################################################
##############################################################################################################

# Picking one model

# 📈 Plot fixed effects of top model (Model 1)
Squirreltop_model <- top_models[["266"]]
# 📈 Plot fixed effects of top model (Model 1)
Squirrelfe_tbl <- tidy(Squirreltop_model, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)")%>%
  # Keep only recovery terms
  filter(str_detect(term, "recovery"))

# Clean up term labels for plotting
Squirrelfe_tbl <- Squirrelfe_tbl %>%
  mutate(term = recode(term,
                       "recovery1" = "Low",
                       "recovery2" = "Medium",
                       "recovery3" = "High",
                       "forest_coverMixedwood" = "Mixedwood",
                       "disturbanceYes" = "Disturbance Present"
  ))

Squirrelfe_tbl <- Squirrelfe_tbl %>%
  mutate(term = factor(term, levels = c("Low", "Medium", "High")))

# Plot
library(ggplot2)
library(forcats)

# (Windows) register Arial once per session (run once; safe to re-run)
windowsFonts(Arial = windowsFont("Arial"))

axis_text_pt  <- 11
axis_title_pt <- 12
panel_label_size <- 8  # bump to 9 if it looks small in the final composite

Squirrel <- ggplot(Squirrelfe_tbl, aes(x = term, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, color = "black") +
  coord_flip() +
  scale_y_continuous(
    breaks = breaks_width(0.5),
    labels = function(x) ifelse(x == 0, "0", format(x, nsmall = 1))
  ) +
  labs(
    x = "Succession stage",
    y = "Estimate (±95% CI)"
  ) +
  theme_minimal(base_size = 14, base_family = "Arial") +
  theme(
    axis.text  = element_text(color = "black", size = axis_text_pt),
    axis.title = element_text(face = "plain", size = axis_title_pt),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(6, 8, 6, 6, unit = "mm"),
    plot.title  = element_text(hjust = 0.5, face = "plain")
  ) +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = "D",
    hjust = 1.15, vjust = 1.15,
    size = panel_label_size, fontface = "plain", family = "Arial"
  )

Squirrel


##############################################################################################################
##############################################################################################################
##############################################################################################################


# ============================
# Red squirrel — model: red.squirrel ~ disturbance + (1 | pair_id) + offset(log(active_hours))
# Use top_models[[4]]
# ============================

library(broom.mixed)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggeffects)
library(marginaleffects)
library(emmeans)
library(stringr)
library(officer)
library(flextable)
library(tibble)

# ---- pick model ----
fit_sq <- top_models[["266"]]

# mean exposure for the offset
mean_hours <- mean(df_SQ$active_hours, na.rm = TRUE)

# -------- 1) Fixed-effects plot (disturbance only) --------
fe_tbl <- tidy(fit_sq, effects = "fixed", conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    # prettify labels if they exist; unmatched terms are left as-is
    term = recode(term,
                  "disturbanceN"  = "Low-impact Seismic",
                  "disturbanceC"= "Conventional Seismic"
    )
  )

ggplot(fe_tbl, aes(x = fct_rev(term), y = estimate)) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  labs(
    title = "Top GLMM Fixed Effects: Red squirrel",
    x = "Disturbance (baseline = model reference level)",
    y = "Estimate (±95% CI, log scale)"
  ) +
  theme_minimal(base_size = 12)

# -------- 2) Predicted counts by disturbance (response scale) --------
pred_dist <- ggeffects::predict_response(
  fit_sq,
  terms = "recovery",
  condition = c(active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) %>% as.data.frame()

ggplot(pred_dist, aes(x = factor(x), y = predicted)) +
  geom_col(width = 0.55, fill = "#58D68D") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "#145A32") +
  labs(
    title = "Red squirrel: Predicted counts by disturbance",
    x = "Disturbance",
    y = "Predicted count (±95% CI)"
  ) +
  theme_minimal(base_size = 14)




pred_dist <- ggeffects::predict_response(
  fit_sq,
  terms = "recovery",
  condition = c(active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) %>% as.data.frame()

library(ggeffects)
library(dplyr)
library(ggplot2)

# (Windows) register Arial once per session
windowsFonts(Arial = windowsFont("Arial"))

library(ggplot2)
library(ragg)
library(dplyr)
library(ggeffects)
fit_sq <- top_models[["266"]]
# Pick exposure
mean_hours <- mean(df$active_hours, na.rm = TRUE)

pred_int_ref <- ggeffects::predict_response(
  fit_sq,
  terms = c("recovery", "disturbance"),
  condition = c(active_hours = mean_hours),
  type = "fixed",
  bias_correction = TRUE
) |>
  as.data.frame() |>
  mutate(
    Succession_stage = factor(
      x,
      levels = c("1", "2", "3", "4"),
      labels = c("Low", "Medium", "High", "Forest interior")
    ),
    Line_type = factor(
      group,
      levels = c("C", "N"),
      labels = c("Conventional", "Low-impact")
    )
  )

base_pt  <- 11
title_pt <- 12

p_sq <- ggplot(
  pred_int_ref,
  aes(x = Succession_stage, y = predicted, fill = Line_type)
) +
  geom_col(
    position = position_dodge(width = 0.7),
    width = 0.6,
    colour = "black"
  ) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = 0.7),
    width = 0.2,
    linewidth = 0.6
  ) +
  scale_fill_manual(values = c("white", "grey60")) +
  labs(
    x    = "Seismic line regeneration stage",
    y    = "Predicted detections",
    fill = "Seismic line type"
  ) +
  theme_classic(base_size = base_pt, base_family = "Arial") +   # no top/right border
  theme(
    axis.title   = element_text(face = "plain", size = title_pt),
    axis.text    = element_text(size = base_pt, colour = "black"),
    legend.title = element_text(face = "plain", size = title_pt),
    legend.text  = element_text(size = base_pt),
    legend.position  = "bottom",
    legend.direction = "horizontal",
    plot.margin  = margin(6, 6, 6, 6, unit = "mm")
  ) +
  guides(fill = guide_legend(nrow = 1, byrow = TRUE))

p_sq

ggsave(
  filename    = "SquirrelSuccession.tiff",
  plot        = p_sq,
  device      = ragg::agg_tiff,
  dpi         = 600,
  width       = 120,   # 12 cm final width
  height      = 80,    # tweak if needed
  units       = "mm",
  compression = "lzw"
)


# -------- 3) Pairwise contrasts among disturbance levels --------
# Reattach data pointer (dredge sometimes drops it) & drop unused levels
fit_sq$call$data <- quote(df_SQ)
df_SQ <- droplevels(df_SQ)

# exact factor levels from the model frame
mf <- model.frame(fit_sq)
dist_levels <- levels(mf$disturbance)

# grid with the SAME factor levels + standardized exposure
grid_dist <- data.frame(
  disturbance  = factor(dist_levels, levels = dist_levels),
  active_hours = mean_hours
)

## A) LINK (log) scale
cmp_link <- comparisons(
  fit_sq,
  variables = c("recovery", "disturbance"),
  type = "link",
  newdata = grid_dist,
  re.form = NA
) %>%
  distinct(contrast, estimate, conf.low, conf.high)

ggplot(cmp_link, aes(x = contrast, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.2, size = 0.8, color = "#633974") +
  labs(
    title = "Red squirrel — Pairwise comparisons: disturbance (link scale)",
    x = "Contrast",
    y = "Effect size (log scale)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

## B) Response-scale RATE RATIOS
cmp_resp <- comparisons(
  fit_sq,
  variables = "disturbance",
  type = "link",
  newdata = grid_dist,
  re.form = NA
) %>%
  mutate(
    estimate_exp = exp(estimate),
    conf.low_exp = exp(conf.low),
    conf.high_exp = exp(conf.high)
  )

ggplot(cmp_resp, aes(x = contrast, y = estimate_exp)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_point(size = 4, color = "#28B463") +
  geom_errorbar(aes(ymin = conf.low_exp, ymax = conf.high_exp),
                width = 0.2, size = 0.8, color = "#1D8348") +
  labs(
    title = "Red squirrel — Pairwise comparisons (response scale)",
    x = "Disturbance contrast",
    y = "Multiplicative effect (rate ratio)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------- 4) Average expected counts by disturbance (response scale) --------
# Make sure the dredged model knows its data (common gotcha)
fit_sq$call$data <- quote(df_SQ)
df_SQ <- droplevels(df_SQ)

# Standardize exposure for the offset
mean_hours <- mean(df_SQ$active_hours, na.rm = TRUE)

# Pull the EXACT disturbance levels used by the model
mf <- model.frame(fit_sq)
dist_levels <- levels(mf$disturbance)

# Build a grid with BOTH levels + fixed exposure
grid_dist <- datagrid(
  model        = fit_sq,
  disturbance  = factor(dist_levels, levels = dist_levels),
  active_hours = mean_hours
)

# Average predictions on the response scale for BOTH levels
ap_sq <- avg_predictions(
  fit_sq,
  by = "disturbance",
  type = "response",
  newdata = grid_dist,   # <- key line to show both levels
  re.form = NA           # population-level (ignore REs)
) |>
  dplyr::select(disturbance, estimate, conf.low, conf.high)

# Plot
ggplot(ap_sq, aes(x = disturbance, y = estimate)) +
  geom_point(size = 4, color = "#AF7AC5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, size = 0.8, color = "#633974") +
  labs(
    title = "Red squirrel — Average expected counts by disturbance",
    x = "Disturbance",
    y = "Expected count (response scale)"
  ) +
  theme_minimal(base_size = 14)


# -------- 5) EMMs: pairwise contrasts (ratios + adjusted p) + Word table --------

library(emmeans)
library(dplyr)
library(flextable)
library(officer)

# --- Model you specified ---
fit_sq <- top_models[["266"]]  # red.squirrel ~ disturbance + recovery + (1|pair_id) + offset(log(active_hours))

# --- Standardize offset exposure (mean active_hours); compute if not already set
if (!exists("mean_hours")) {
  mean_hours <- mean(model.frame(fit_sq)$active_hours, na.rm = TRUE)
}

# ---------- helpers ----------
ratio_table <- function(contr_obj, adjust_label) {
  tb <- as.data.frame(summary(contr_obj, type = "response"))
  est_col <- intersect(c("rate.ratio","ratio","response","estimate","odds.ratio"), names(tb))
  if (length(est_col) == 0) stop("Response-scale estimate column not found. Available: ", paste(names(tb), collapse = ", "))
  tb %>%
    mutate(contrast = as.character(contrast)) %>%
    transmute(
      Adjustment     = adjust_label,
      Contrast       = contrast,
      `Rate ratio`   = as.numeric(.data[[est_col[1]]]),
      `Adj. p-value` = as.numeric(p.value)
    )
}
# ----------------------------

# === A) disturbance (as you had) ===
emm_dist <- emmeans(
  fit_sq, ~ disturbance,
  mode    = "latent",
  weights = "proportional",
  at      = list(active_hours = mean_hours)
)
pairs_dist <- pairs(emm_dist, adjust = "tukey")
final_tbl_dist <- ratio_table(pairs_dist, "Tukey (all pairs) — disturbance")

# === B) recovery Tukey (averaged over disturbance) ===
emm_s4 <- emmeans(
  fit_sq, ~ recovery,
  mode    = "latent",
  weights = "proportional",
  at      = list(active_hours = mean_hours)
)
pairs_s4 <- pairs(emm_s4, adjust = "tukey")
final_tbl_s4 <- ratio_table(pairs_s4, "Tukey (all pairs) — recovery")

# --- Word export with both tables ---
ft_dist <- flextable(final_tbl_dist) %>%
  colformat_double(j = c("Rate ratio", "Adj. p-value"), digits = 3) %>%
  autofit() %>%
  set_caption("Table X1. Red squirrel — disturbance: rate ratio (response scale) and Tukey-adjusted p-value. Predictions standardized at mean active_hours.")

ft_s4 <- flextable(final_tbl_s4) %>%
  colformat_double(j = c("Rate ratio", "Adj. p-value"), digits = 3) %>%
  autofit() %>%
  set_caption("Table X2. Red squirrel — recovery: rate ratio (response scale) and Tukey-adjusted p-value. Predictions standardized at mean active_hours.")

doc <- read_docx() %>%
  body_add_par("Red squirrel: pairwise contrasts (ratios only)", style = "heading 1") %>%
  body_add_par("Disturbance (averaged over recovery)", style = "heading 2") %>%
  flextable::body_add_flextable(ft_dist) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("recovery (averaged over disturbance)", style = "heading 2") %>%
  flextable::body_add_flextable(ft_s4)

out_path <- file.path(getwd(), "red_squirrel_disturbance_and_succession4_contrasts.docx")
print(doc, target = out_path)
message("Word file saved to: ", out_path)

# ===== OPTIONAL: within-disturbance contrasts for recovery =====
# Only needed if you wanna see S4 pairwise differences separately for each disturbance level.
# (Model is additive here, so averaged vs within should be similar; this is for completeness.)
# emm_s4_by_dist <- emmeans(
#   fit_sq, ~ recovery | disturbance,
#   mode    = "latent",
#   at      = list(active_hours = mean_hours)
# )
# pairs_s4_by_dist <- pairs(emm_s4_by_dist, adjust = "tukey")
# final_tbl_s4_by <- as.data.frame(summary(pairs_s4_by_dist, type = "response")) %>%
#   mutate(est = dplyr::coalesce(rate.ratio, ratio, response, estimate, odds.ratio)) %>%
#   transmute(
#     disturbance,
#     Contrast       = as.character(contrast),
#     `Rate ratio`   = as.numeric(est),
#     `Adj. p-value` = as.numeric(p.value),
#     Adjustment     = "Tukey (within disturbance)"
#   )
# View(final_tbl_s4_by)








library(patchwork)
combined <- (Shrew | Vole) / (Deer | Squirrel)
combined


# Pick limits you want across all species (edit as needed)
ylims <- c(-2.0, 1.5)

Shrew     <- Shrew     + coord_cartesian(ylim = ylims)
Vole      <- Vole      + coord_cartesian(ylim = ylims)
Deer      <- Deer      + coord_cartesian(ylim = ylims)
Squirrel  <- Squirrel  + coord_cartesian(ylim = ylims)

combined <- (Shrew | Vole) / (Deer | Squirrel) 

combined


ggsave(
  filename = "succession_effects_combined.tiff",  # output file name
  plot = combined,                                # the patchwork object
  device = "tiff",
  dpi = 600,                                      # 600 dpi
  width = 8, height = 6.5, units = "in",          # adjust size as needed
  compression = "lzw"                             # good for journals
)

