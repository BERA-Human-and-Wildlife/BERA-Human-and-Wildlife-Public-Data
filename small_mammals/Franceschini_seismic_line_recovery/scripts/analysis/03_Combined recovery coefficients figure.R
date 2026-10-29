library(broom.mixed)
library(dplyr)
library(stringr)
library(ggplot2)
library(scales)
library(patchwork)
library(cowplot)

## 1. Helper: tidy fixed-effect recovery terms -----------------------------

make_fe_tbl <- function(model) {
  tidy(model, effects = "fixed", conf.int = TRUE) %>%
    filter(term != "(Intercept)") %>%
    filter(str_detect(term, "recovery")) %>%
    mutate(
      term = recode(
        term,
        "recovery1" = "Low",
        "recovery2" = "Medium",
        "recovery3" = "High"
      ),
      term = factor(term, levels = c("Low", "Medium", "High"))
    )
}

Shrewfe_tbl    <- make_fe_tbl(Shrewtop_model)
Volefe_tbl     <- make_fe_tbl(Voletop_model)
Deerfe_tbl     <- make_fe_tbl(Deertop_model)
Squirrelfe_tbl <- make_fe_tbl(Squirreltop_model)

## 2. Combine all species and compute global y-limits --------------------------

all_fe <- bind_rows(
  Shrew    = Shrewfe_tbl,
  Vole     = Volefe_tbl,
  Deer     = Deerfe_tbl,
  Squirrel = Squirrelfe_tbl,
  .id      = "Species"
)

ylims <- range(all_fe$conf.low, all_fe$conf.high, na.rm = TRUE)
ylims <- scales::expand_range(ylims, mul = 0.05)

## 3. Helper: coefficient plot
##    Key trick: keep "blank" axis titles that are TRANSPARENT (so no text),
##    but still reserve the same space as before (so proportions don't change).

make_coef_plot <- function(df, ylims) {
  ggplot(df, aes(x = term, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "black", linewidth = 0.7) +
    geom_point(size = 2.8, colour = "black") +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                  width = 0.2, colour = "black", linewidth = 0.6) +
    scale_y_continuous(
      limits = ylims,
      breaks = pretty_breaks(5),
      labels = function(x) ifelse(x == 0, "0", format(x, nsmall = 1))
    ) +
    # " " keeps the grob; transparent text makes it invisible but keeps spacing
    labs(x = " ", y = " ") +
    theme_bw(base_size = 11) +
    theme(
      text = element_text(face = "plain", colour = "black"),
      
      # Axis titles: invisible BUT still take up space (size=12 as requested)
      axis.title.x = element_text(size = 12, face = "plain", colour = "transparent",
                                  margin = margin(t = 6)),
      axis.title.y = element_text(size = 12, face = "plain", colour = "transparent",
                                  margin = margin(r = 6)),
      
      axis.text          = element_text(size = 11, face = "plain", colour = "black"),
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_blank(),
      plot.margin        = margin(0.5, 0.5, 0.5, 0.5)
    )
}

Shrew    <- make_coef_plot(filter(all_fe, Species == "Shrew"),    ylims)
Vole     <- make_coef_plot(filter(all_fe, Species == "Vole"),     ylims)
Deer     <- make_coef_plot(filter(all_fe, Species == "Deer"),     ylims)
Squirrel <- make_coef_plot(filter(all_fe, Species == "Squirrel"), ylims)

## 4. Combine 2 × 2 with CAPITAL panel tags A–D (top-right, not bold) ----------

combined <- (Shrew | Vole) / (Deer | Squirrel) +
  plot_annotation(tag_levels = "A")

combined <- combined & theme(
  plot.tag = element_text(size = 11, face = "plain", colour = "black",
                          hjust = 1, vjust = 1),
  plot.tag.position = c(0.98, 0.98)
)

## 5. Add ONE shared axis title on borders
##    We keep proportions via the transparent per-panel titles above.
##    Then we just place the shared labels in the outer margin.

final <- ggdraw(combined) +
  draw_label(
    "Seismic line regeneration stage",
    x = 0.5, y = 0.02, vjust = 0.5,   # farther from panels
    size = 12
  ) +
  draw_label(
    "Estimated \u03b2 (95% CI)",
    x = 0.02, y = 0.5, angle = 90, vjust = 0.5,  # farther from panels
    size = 12
  ) +
  theme(
    # extra canvas space so labels sit away from the plots without changing panel proportions
    plot.margin = margin(7, 7, 5, 1)
  )

final

ggsave(
  filename    = "Fig_coef_regen_stage_all_species.tiff",
  plot        = final,
  device      = "tiff",
  dpi         = 600,
  width       = 160,
  height      = 140,
  units       = "mm",
  compression = "lzw",
  bg          = "white"
)
