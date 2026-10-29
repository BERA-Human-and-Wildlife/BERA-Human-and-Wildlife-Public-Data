# --- Packages ---
library(glmmTMB)
library(mgcv)
library(sjPlot)
library(ggplot2)

# --- Helpers v2: separate positions for species label and p-value ---
extract_p <- function(model, term = "log_Width_scale") {
  co <- summary(model)$coefficients$cond
  if (!term %in% rownames(co)) stop(sprintf("Term '%s' not found in model.", term))
  co[term, "Pr(>|z|)"]
}

# Safe accessor for panel ranges across ggplot2 versions
.get_panel_ranges <- function(gb) {
  pp <- gb$layout$panel_params[[1]]
  xr <- tryCatch(pp$x.range, error = function(e) NULL)
  yr <- tryCatch(pp$y.range, error = function(e) NULL)
  if (is.null(xr) || is.null(yr)) {
    # older versions sometimes use x$range$range
    xr <- tryCatch(range(pp$x$get_limits()), error = function(e) c(0, 1))
    yr <- tryCatch(range(pp$y$get_limits()), error = function(e) c(0, 1))
  }
  list(x = xr, y = yr)
}

plot_with_p <- function(model, term, species_label,
                        x_name, y_name, y_limits, y_breaks,
                        # species label (like your original)
                        species_x = Inf, species_y = NULL, species_y_frac = 0.95,
                        species_hjust = 1.1, species_vjust = 1,
                        # p-value (defaults to follow species)
                        p_x = NULL, p_y = NULL, p_gap_frac = 0.06,
                        p_hjust = NULL, p_vjust = NULL,
                        # formatting & safety
                        show_p_lt = 0.001,  # show "< 0.001" if p < this
                        top_pad_frac = 0.02, right_pad_frac = 0.01,
                        lock_p_to_species = TRUE, clean_multiline = TRUE) {
  
  if (clean_multiline) species_label <- gsub("\n\\s+", "\n", species_label)
  
  p_val <- extract_p(model, term)
  p_val_str <- if (!is.na(show_p_lt) && p_val < show_p_lt) "p < 0.001" else paste0("p = ", sprintf("%.3f", p_val))
  
  # Build a base plot first so we can read true panel ranges
  base <- sjPlot::plot_model(model, type = "pred", terms = term) +
    theme_classic(base_size = 14) +
    theme(
      plot.title = element_blank(),
      axis.title = element_text(size = 14, face = "bold"),
      axis.text  = element_text(size = 12),
      panel.grid = element_blank(),
      plot.margin = margin(6, 6, 6, 6)
    ) +
    scale_x_continuous(name = x_name) +
    scale_y_continuous(
      name = y_name,
      limits = y_limits,
      breaks = y_breaks,
      expand = expansion(mult = c(0, 0.05))
    ) +
    coord_cartesian(clip = "off")
  
  gb   <- ggplot2::ggplot_build(base)
  rng  <- .get_panel_ranges(gb)
  xmin <- rng$x[1]; xmax <- rng$x[2]
  ymin <- rng$y[1]; ymax <- rng$y[2]
  xpad <- right_pad_frac * (xmax - xmin)
  ypad_top <- top_pad_frac * (ymax - ymin)
  
  # Resolve species coords (support Inf + frac)
  x_species <- if (is.infinite(species_x)) xmax - xpad else species_x
  y_species <- if (is.null(species_y)) ymax - ypad_top - (1 - species_y_frac) * (ymax - ymin) else species_y
  # Clamp inside panel just in case
  y_species <- pmin(pmax(y_species, ymin + 0.01 * (ymax - ymin)), ymax - 0.01 * (ymax - ymin))
  
  # Resolve p coords
  x_p <- if (!is.null(p_x)) p_x else if (lock_p_to_species) x_species else xmax - xpad
  y_p <- if (!is.null(p_y)) p_y else (y_species - p_gap_frac * (ymax - ymin))
  y_p <- pmin(pmax(y_p, ymin + 0.01 * (ymax - ymin)), ymax - 0.01 * (ymax - ymin))
  
  # Justifications
  hjust_p <- if (!is.null(p_hjust)) p_hjust else species_hjust
  vjust_p <- if (!is.null(p_vjust)) p_vjust else species_vjust
  
  # Now add annotations on top of the base
  p <- base +
    annotate("text", x = x_species, y = y_species,
             label = species_label, hjust = species_hjust, vjust = species_vjust,
             size = 5, fontface = "italic",
             lineheight = 0.85) +
    annotate("text", x = x_p, y = y_p,
             label = p_val_str, hjust = hjust_p, vjust = vjust_p,
             size = 5, fontface = "plain")
  
  # Style the fitted line & CI (dashed if p > 0.05)
  p$layers[[1]]$aes_params$size <- 1.3
  p$layers[[1]]$aes_params$colour <- "black"
  p$layers[[1]]$aes_params$linetype <- ifelse(p_val > 0.05, "dashed", "solid")
  p$layers[[2]]$aes_params$alpha <- 0.2
  p$layers[[2]]$aes_params$fill  <- "#1f77b4"
  
  p
}





# =========================================================
# ============== S O R E X (Sorex spp.) ===================
# =========================================================
data$SOREX_BIN <- ifelse(data$SOREX.SPP > 0, 1, 0)

model_SX <- glmmTMB(SOREX_BIN ~ Julian_Date + log_Width_scale + Habitat + (1 | SP.Group),
                    family = binomial, data = data)

# Residual GAM for spatial autocovariate
residuals_glmmTMB_SX <- residuals(model_SX, type = "response")
residgam_SX <- gam(residuals_glmmTMB_SX ~ s(Longitude, Latitude), family = gaussian)
data$autocov_SX <- scale(fitted(residgam_SX))[, 1]

model_SX <- glmmTMB(SOREX_BIN ~ log_Width_scale + Julian_Date + Habitat + autocov_SX + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_SX)

sjp_SX <- plot_with_p(
  model_SX, "log_Width_scale", "Sorex spp.",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.8), seq(0, 0.80, 0.10),
  species_x = 2.5, species_y = 0.8, species_hjust = 1.0, species_vjust = 1, 
  p_gap_frac = 0.12
)
print(sjp_SX)

# =========================================================
# ========== Z A P U S (Western jumping mouse) ============
# =========================================================
data$ZAPUS_BIN <- ifelse(data$ZAPUS.PRINCEPS > 0, 1, 0)

model_ZP <- glmmTMB(ZAPUS_BIN ~ log_Width_scale, family = binomial, data = data)

residuals_glmmTMB_ZP <- residuals(model_ZP, type = "response")
residgam_ZP <- gam(residuals_glmmTMB_ZP ~ s(Longitude, Latitude), family = gaussian)
data$autocov_ZP <- scale(fitted(residgam_ZP))[, 1]

model_ZP <- glmmTMB(ZAPUS_BIN ~ log_Width_scale + autocov_ZP,
                    family = binomial, data = data)
summary(model_ZP)

sjp_ZP <- plot_with_p(
  model_ZP, "log_Width_scale", "Western jumping mouse
  (Zapus princeps)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.30), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.25, species_hjust = 1.0, species_vjust = 0, 
  p_gap_frac = 0.12
  # p_x/p_y omitted -> auto below species label
)
print(sjp_ZP)

# =========================================================
# ====== L E P U S  a m e r i c a n u s (Snowshoe hare) ===
# =========================================================
data$LEPUS_AMERICANUS_BIN <- ifelse(data$LEPUS.AMERICANUS > 0, 1, 0)

model_LP <- glmmTMB(LEPUS_AMERICANUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)

residuals_glmmTMB_LP <- residuals(model_LP, type = "response")
residgam_LP <- gam(residuals_glmmTMB_LP ~ s(Longitude, Latitude), family = gaussian)
data$autocov_LP <- scale(fitted(residgam_LP))[, 1]

model_LP <- glmmTMB(LEPUS_AMERICANUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + autocov_LP + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_LP)

sjp_LP <- plot_with_p(
  model_LP, "log_Width_scale", "Snowshoe hare\n(Lepus americanus)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.32), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.27, species_hjust = 1.0, species_vjust = 0,
  p_gap_frac = 0.12
)

print(sjp_LP)

# =========================================================
# ====== M a r t e s  a m e r i c a n a (American marten) =
# =========================================================
data$Martes_Americana_bin <- ifelse(data$MARTES.AMERICANA > 0, 1, 0)

model_MA <- glmmTMB(Martes_Americana_bin ~ log_Width_scale, family = binomial, data = data)

residuals_glmmTMB_MA <- residuals(model_MA, type = "response")
residgam_MA <- gam(residuals_glmmTMB_MA ~ s(Longitude, Latitude), family = gaussian)
data$autocov_MA <- scale(fitted(residgam_MA))[, 1]

model_MA <- glmmTMB(Martes_Americana_bin ~ log_Width_scale + autocov_MA,
                    family = binomial, data = data)
summary(model_MA)

sjp_MA <- plot_with_p(
  model_MA, "log_Width_scale", "American marten 
  (Martes americana)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.10), seq(0, 0.70, 0.02),
  species_x = 2.5, species_y = 0.08, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_MA)

# =========================================================
# ====== M i c r o t u s  (Meadow vole / drummondii) ======
# =========================================================
data$MICROTUS_BINARY <- ifelse(data$MICROTUS.DRUMMONDII > 0, 1, 0)

model_MC <- glmmTMB(MICROTUS_BINARY ~ log_Width_scale, family = binomial, data = data)

residuals_glmmTMB_MC <- residuals(model_MC, type = "response")
residgam_MC <- gam(residuals_glmmTMB_MC ~ s(Longitude, Latitude), family = gaussian)
data$autocov_MC <- scale(fitted(residgam_MC))[, 1]

model_MC <- glmmTMB(MICROTUS_BINARY ~ log_Width_scale + autocov_MC,
                    family = binomial, data = data)
summary(model_MC)

sjp_MC <- plot_with_p(
  model_MC, "log_Width_scale", "Meadow vole 
  (Microtus drummondii)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.32), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.26, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_MC)

# =========================================================
# ====== M u s t e l a  e r m i n e a (Short-tailed weasel)
# =========================================================
data$MUSTELA_ERMINEA_BINOMIAL <- ifelse(data$MUSTELA.ERMINEA > 0, 1, 0)

model_MU <- glmmTMB(MUSTELA_ERMINEA_BINOMIAL ~ log_Width_scale + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)

residuals_glmmTMB_MU <- residuals(model_MU, type = "response")
residgam_MU <- gam(residuals_glmmTMB_MU ~ s(Longitude, Latitude), family = gaussian)
data$autocov_MU <- scale(fitted(residgam_MU))[, 1]

model_MU <- glmmTMB(MUSTELA_ERMINEA_BINOMIAL ~ log_Width_scale + julian_date_scaled + Habitat + autocov_MU + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_MU)

sjp_MU <- plot_with_p(
  model_MU, "log_Width_scale", "Short-tailed weasel 
  (Mustela erminea)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.16), seq(0, 0.70, 0.04),
  species_x = 2.5, species_y = 0.13, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_MU)

# =========================================================
# ====== P e r o m y s c u s  (Deer mouse) =================
# =========================================================
data$PEROMYSCUS_BIN <- ifelse(data$PEROMYSCUS.MANICULATUS > 0, 1, 0)

model_PM <- glmmTMB(PEROMYSCUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)

residuals_glmmTMB_PM <- residuals(model_PM, type = "response")
residgam_PM <- gam(residuals_glmmTMB_PM ~ s(Longitude, Latitude), family = gaussian)
data$autocov_PM <- scale(fitted(residgam_PM))[, 1]

model_PM <- glmmTMB(PEROMYSCUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + autocov_PM + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_PM)

sjp_PM <- plot_with_p(
  model_PM, "log_Width_scale", "Deer mouse 
  (Peromyscus maniculatus)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.50), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.43, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_PM)

# =========================================================
# ====== M y o d e s  g a p p e r i (Red-backed vole) =====
# =========================================================
data$MYODES_BINARY <- ifelse(data$MYODES.GAPPERI > 0, 1, 0)

model_MY <- glmmTMB(MYODES_BINARY ~ log_Width_scale + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)

residuals_glmmTMB_MY <- residuals(model_MY, type = "response")
residgam_MY <- gam(residuals_glmmTMB_MY ~ s(Longitude, Latitude), family = gaussian)
data$autocov_MY <- scale(fitted(residgam_MY))[, 1]  # ensure vector

model_MY <- glmmTMB(MYODES_BINARY ~ log_Width_scale + autocov_MY + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_MY)

sjp_MY <- plot_with_p(
  model_MY, "log_Width_scale", "Southern red-backed vole 
  (Myodes gapperi)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.70), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.56, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_MY)

# =========================================================
# ====== T a m i a s c i u r u s  (Red squirrel) ==========
# =========================================================
data$TAMIASCIURUS_BIN <- ifelse(data$TAMIASCIURUS.HUDSONICUS > 0, 1, 0)

model_SQ <- glmmTMB(TAMIASCIURUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + (1 | SP.Group),
                    family = binomial, data = data)

residuals_glmmTMB_SQ <- residuals(model_SQ, type = "response")
residgam_SQ <- gam(residuals_glmmTMB_SQ ~ s(Longitude, Latitude), family = gaussian)
data$autocov_SQ <- scale(fitted(residgam_SQ))[, 1]

model_SQ <- glmmTMB(TAMIASCIURUS_BIN ~ log_Width_scale + Habitat + julian_date_scaled + autocov_SQ + (1 | SP.Group),
                    family = binomial, data = data)
summary(model_SQ)

sjp_SQ <- plot_with_p(
  model_SQ, "log_Width_scale", "American red squirrel 
  (Tamiasciurus hudsonicus)",
  "Log Width (scaled)", "Probability of Use",
  c(0, 0.40), seq(0, 0.70, 0.10),
  species_x = 2.5, species_y = 0.33, species_hjust = 1, species_vjust = 0,
  p_gap_frac = 0.12
)
print(sjp_SQ)





# Load required libraries
library(ggplot2)
library(patchwork)
library(patchwork)
library(cowplot)

combined_plot <- wrap_plots(
  sjp_MY, sjp_SX,  # Row 1
  sjp_SQ, sjp_PM,  # Row 2
  sjp_MC, sjp_LP,  # Row 3
  sjp_MA, sjp_MU,  # Row 4
  sjp_ZP,          # Row 5 (if you have it)
  ncol = 2
) + 
  plot_layout(guides = "collect") &
  theme(plot.margin = margin(5, 5, 5, 5))


library(ggplot2)
library(patchwork)
library(cowplot)
library(purrr)

# 👇 List of all your plots
plot_list <- list(
  sjp_MY, sjp_SX, sjp_SQ, sjp_PM,
  sjp_MC, sjp_LP, sjp_MA, sjp_MU, sjp_ZP
)

# ❌ Remove plot titles only (leave other text alone)
plot_list <- map(plot_list, ~ .x + theme(plot.title = element_blank()))

# 🧩 Combine plots with 2 columns, collect guides
combined_plot <- wrap_plots(plot_list, ncol = 2) +
  plot_layout(guides = "collect") &
  theme(plot.margin = margin(5, 5, 5, 5))

# 🖊️ Add "Figure 4" label (bottom-right)
final_plot <- ggdraw(combined_plot) +
  draw_label(
    "Figure 4",
    x = 0.98, y = 0.02,
    hjust = 1, vjust = 0,
    fontface = "bold", size = 9
  )

# 💾 Save A4 size (portrait), 600 dpi, under 40MP
ggsave(
  filename = "Figure4_A4_600dpi.tiff",
  plot = final_plot,
  width = 8.27,
  height = 11.69,
  dpi = 600,
  units = "in",
  device = "tiff",
  limitsize = FALSE
)


tiff(
  filename = "Figure3.tiff",
  width = 8.27, height = 11.69, units = "in",
  res = 600, compression = "lzw"
)
print(final_plot)
dev.off()

