# ============================
# AFTER dredge(): Sorex spp. tables + selection (min K within Δ≤2)
# ============================

library(dplyr)
library(purrr)
library(MuMIn)
library(broom.mixed)
library(flextable)
library(officer)
library(stringr)
library(tibble)

# -- Get ΔAICc ≤ 2 models from this dredge run
mods <- MuMIn::get.models(dredge_results, subset = delta <= 2)
if (length(mods) == 0) stop("No candidate models with ΔAICc ≤ 2 for Sorex spp..")

# -- Helper: full conditional formula string for glmmTMB objects
full_formula_str <- function(m, include_response = TRUE) {
  fm <- tryCatch(stats::formula(m), error = function(e) NULL)
  
  # Conditional (mean) formula
  cond <- if (is.list(fm) && !is.null(fm$cond)) fm$cond else if (inherits(fm, "formula")) fm else NULL
  if (is.null(cond)) {
    cond <- tryCatch(eval(m$call$formula), error = function(e) NULL)
  }
  if (is.null(cond)) return(NA_character_)
  
  cond_str <- paste(deparse(cond), collapse = " ")
  cond_str <- gsub("\\s+", " ", cond_str)
  if (!include_response) cond_str <- sub("^[^~]*~\\s*", "", cond_str)
  
  # Zero-inflation & dispersion (include only if non-default)
  zi_txt <- ""
  if (is.list(fm) && !is.null(fm$zi)) {
    zi_str <- paste(deparse(fm$zi), collapse = " ")
    zi_str <- gsub("\\s+", " ", zi_str)
    if (!grepl("^~\\s*0\\s*$", zi_str)) zi_txt <- paste0(" ; zi: ", zi_str)
  }
  disp_txt <- ""
  if (is.list(fm) && !is.null(fm$disp)) {
    disp_str <- paste(deparse(fm$disp), collapse = " ")
    disp_str <- gsub("\\s+", " ", disp_str)
    if (!grepl("^~\\s*1\\s*$", disp_str)) disp_txt <- paste0(" ; disp: ", disp_str)
  }
  
  paste0(cond_str, zi_txt, disp_txt)
}

# -- Build candidate table
top_tbl <- purrr::map_df(seq_along(mods), function(i) {
  m  <- mods[[i]]
  ll <- logLik(m)
  tibble(
    Rank    = i,
    K       = attr(ll, "df"),               # total parameters AICc penalizes
    logLik  = as.numeric(ll),
    AICc    = MuMIn::AICc(m),
    Formula = full_formula_str(m, include_response = TRUE)
  )
}) %>%
  mutate(
    Delta  = AICc - min(AICc),
    Weight = { w <- exp(-0.5 * Delta); w / sum(w) }
  )

# -- Selection rule: min K within Δ≤2, then min AICc, then max logLik
tol <- 2.0
cands <- dplyr::filter(top_tbl, Delta <= tol)
minK <- min(cands$K, na.rm = TRUE)
cands_minK <- dplyr::filter(cands, K == minK)
minAICc <- min(cands_minK$AICc, na.rm = TRUE)
cands_best <- dplyr::filter(cands_minK, AICc == minAICc)
best_row <- dplyr::arrange(cands_best, dplyr::desc(logLik)) %>% dplyr::slice(1)

best_idx <- best_row$Rank
best_mod <- mods[[best_idx]]

cat(sprintf(
  "Sorex spp.: selected Rank %d by rule = min K within Δ≤%.1f, then min AICc, then max logLik.\n",
  best_idx, tol
))

# -- Pretty tables
ft_models <- flextable(
  top_tbl %>% dplyr::arrange(Delta, K) %>% dplyr::select(Rank, K, logLik, AICc, Delta, Weight, Formula)
) %>%
  colformat_double(j = c("logLik", "AICc", "Delta", "Weight"), digits = 3) %>%
  width(j = "Formula", width = 6) %>%
  autofit() %>%
  set_caption("Sorex spp. — Candidate models with ΔAICc ≤ 2 (full formula shown)")

coef_tbl <- broom.mixed::tidy(best_mod, effects = "fixed", conf.int = TRUE, conf.method = "Wald") %>%
  mutate(
    Term   = dplyr::recode(term, `(Intercept)` = "Intercept"),
    Signif = dplyr::case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      p.value < 0.1   ~ ".",
      TRUE            ~ ""
    )
  ) %>%
  transmute(Term, Estimate = estimate, SE = std.error,
            `CI 2.5%` = conf.low, `CI 97.5%` = conf.high, z = statistic, p = p.value, Signif)

ft_coefs <- flextable(coef_tbl) %>%
  colformat_double(j = c("Estimate", "SE", "CI 2.5%", "CI 97.5%", "z", "p"), digits = 3) %>%
  autofit() %>%
  set_caption("Sorex spp. — Most parsimonious model (fixed effects; baseline = Succession 4)")

# -- Export to Word
doc <- read_docx()
doc <- body_add_par(doc, "Sorex spp. — Model selection & coefficients", style = "heading 1")
doc <- body_add_par(doc, "Top models (ΔAICc ≤ 2)", style = "heading 2")
doc <- flextable::body_add_flextable(doc, ft_models)
doc <- body_add_par(doc, "", style = "Normal")
doc <- body_add_par(doc, "Most parsimonious model — Fixed effects (β, 95% CI, z, p)", style = "heading 2")
doc <- flextable::body_add_flextable(doc, ft_coefs)
doc <- body_add_par(doc, "", style = "Normal")
doc <- body_add_par(
  doc,
  "Notes: Selection = min K within ΔAICc ≤ 2, tie by min AICc then max logLik. K = parameters used by AICc. Weights = Akaike weights. Models fit with glmmTMB (nbinom2, log link), offset(log(active_hours)), random intercept for pair_id; recovery baseline = '4'.",
  style = "Normal"
)

out_path <- file.path(getwd(), "dusky_shrew_model_tables_minK_within_delta.docx")
print(doc, target = out_path)
message("Word file saved to: ", out_path)
