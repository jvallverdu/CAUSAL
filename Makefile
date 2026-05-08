# Reproducibility Makefile
#
# Usage:
#   make all                  # regenerate every table and figure from cached outputs
#   make stats                # only the McNemar / FDR table
#   make figures              # only the PDFs in figures/
#   make clean                # remove generated artifacts (keeps outputs/ intact)

PYTHON ?= python3
OUT_DIR := analysis/_built
FIG_DIR := figures
TABLE_DIR := tables

.PHONY: all stats bootstrap tokens efficiency calibration ablation_summary audit figures clean \
        table_cladder table_corr2cause table_corr2cause_clean \
        table_cladder_throughput table_corr2cause_throughput

all: $(TABLE_DIR) $(FIG_DIR) \
     table_cladder table_corr2cause table_corr2cause_clean \
     table_cladder_throughput table_corr2cause_throughput \
     audit stats bootstrap tokens efficiency calibration ablation_summary figures
	@echo "[OK] All tables and figures regenerated. See $(TABLE_DIR)/ and $(FIG_DIR)/"

$(TABLE_DIR):
	mkdir -p $(TABLE_DIR)

$(FIG_DIR):
	mkdir -p $(FIG_DIR)

table_cladder: $(TABLE_DIR)
	$(PYTHON) eval/score.py --benchmark cladder --out $(TABLE_DIR)/table2_cladder.tex

table_corr2cause: $(TABLE_DIR)
	$(PYTHON) eval/score.py --benchmark corr2cause --out $(TABLE_DIR)/table4_corr2cause.tex

table_corr2cause_clean: $(TABLE_DIR)
	$(PYTHON) eval/score.py --benchmark corr2cause --exclude phi-4 qwq-32b \
	    --out $(TABLE_DIR)/table5_corr2cause_clean.tex

table_cladder_throughput: $(TABLE_DIR)
	$(PYTHON) analysis/throughput.py --benchmark cladder --out $(TABLE_DIR)/table6_cladder_th.tex

table_corr2cause_throughput: $(TABLE_DIR)
	$(PYTHON) analysis/throughput.py --benchmark corr2cause --out $(TABLE_DIR)/table7_corr2cause_th.tex

audit: $(TABLE_DIR)
	$(PYTHON) audit/memorization.py --out $(TABLE_DIR)/table8_audit.tex

stats: $(TABLE_DIR)
	$(PYTHON) analysis/mcnemar.py --apply-bh --q 0.10 --out $(TABLE_DIR)/table9_stats.tex

bootstrap: $(TABLE_DIR)
	$(PYTHON) analysis/bootstrap.py --resamples 10000 --out $(TABLE_DIR)/table10_bootstrap.tex

tokens: $(TABLE_DIR)
	$(PYTHON) analysis/token_count.py --out $(TABLE_DIR)/table11_tokens.tex

ablation_summary: $(TABLE_DIR)
	$(PYTHON) analysis/ablation_summary.py --grid ablation/grid_index.csv \
	    --reference "A3_T0.7_R4_Von" --out $(TABLE_DIR)/table12_ablation.tex

calibration: $(TABLE_DIR)
	$(PYTHON) calibration/calibrate.py --out $(TABLE_DIR)/table13_calibration.tex

efficiency: $(TABLE_DIR)
	$(PYTHON) analysis/disagg_efficiency.py --out $(TABLE_DIR)/table14_efficiency.tex

figures: $(FIG_DIR)
	$(PYTHON) analysis/make_figures.py --out $(FIG_DIR)

clean:
	rm -rf $(TABLE_DIR) $(FIG_DIR)/*.pdf $(OUT_DIR)
	@echo "[OK] cleaned generated artifacts; outputs/ and ablation/ preserved"
