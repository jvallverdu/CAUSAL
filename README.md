# Multi-Agent LLMs and Causal Identification: Reproducibility Package

Anonymous reproducibility package for the manuscript
**"Do Multi-Agent LLMs Improve Causal Identification? A Controlled, Cost-Aware
Study on CLadder"**, currently under review at *Array* (Elsevier).

This repository contains the complete code, prompts, sampled item IDs, evaluation
scripts, and raw outputs needed to reproduce every table and figure in the paper.

> **Status:** review-blind release on `anonymous.4open.science`. After acceptance
> the repository will be moved to a public GitHub mirror with an archived
> Zenodo DOI.

---

## Quick start

```bash
# 1. Install dependencies
pip install -r requirements.txt
# Plus: install Ollama (https://ollama.com) and pull the model weights:
bash runners/pull_models.sh

# 2. Reproduce all tables and figures from the included raw outputs
make all
```

The `make all` target runs the analysis pipeline against the cached raw outputs
in `outputs/` and regenerates every numerical result, table, and figure shipped
with the manuscript. It does **not** re-run inference; for that, see
[Re-running inference from scratch](#re-running-inference-from-scratch) below.

---

## Repository layout

```
.
├── README.md                  <-- this file
├── requirements.txt           <-- pinned Python dependencies
├── Makefile                   <-- single-command reproduction
│
├── prompts/                   <-- all prompt templates used in the paper
│   ├── vanilla.txt
│   ├── simple_cot.txt
│   ├── guided_cot.txt
│   ├── self_consistency_wrapper.py
│   ├── multi_agent_reasoner.txt
│   ├── multi_agent_validator.txt
│   ├── het1_system_prompts.json   <-- HET-1 (cross-family trio) overrides
│   └── het2_system_prompts.json   <-- HET-2 (mixed-paradigm) overrides
│
├── data/
│   └── sampled_ids/
│       ├── sample_ids.py     <-- deterministic sampler (seed=42)
│       ├── cladder_500.json  <-- 500 IDs used in the paper
│       └── corr2cause_500.json
│
├── runners/                   <-- inference drivers
│   ├── ollama_client.py
│   ├── single_agent.py        <-- vanilla / simple_cot / guided_cot
│   ├── self_consistency.py    <-- K=5 sampling + majority vote
│   ├── multi_agent.py         <-- same-model role-specialization
│   ├── multi_agent_het.py     <-- HET-1 / HET-2 cross-family
│   ├── pull_models.sh         <-- one-shot Ollama model pull
│   ├── model_quantization.csv <-- the exact GGUF tag used per model
│   └── seeds.csv              <-- per-run inference seeds
│
├── eval/                      <-- answer parsing & per-item scoring
│   ├── parse_answer.py
│   └── score.py               <-- writes per-item correct/incorrect CSVs
│
├── analysis/                  <-- statistics + figures
│   ├── mcnemar.py             <-- generates Table 9 (per-pair stats)
│   ├── bootstrap.py           <-- generates Table 10 (bootstrap CIs)
│   ├── bh_correction.py       <-- BH FDR adjustment
│   ├── make_figures.py        <-- generates every figure in the paper
│   ├── token_count.py         <-- the chars/3.7 approximator + table 11
│   └── disagg_efficiency.py   <-- generates Appendix B table
│
├── audit/                     <-- contamination audit (Section 5.5)
│   ├── memorization.py        <-- min-K and percentage-above-threshold
│   ├── paraphrase_templates.txt
│   └── README.md
│
├── calibration/               <-- tokenizer calibration (Appendix A)
│   ├── calibrate.py           <-- compares chars/3.7 vs real tokenizers
│   ├── traces/                <-- 50 sample traces per family (truncated)
│   └── results.csv            <-- the numbers in Appendix A's table
│
├── ablation/                  <-- ablation cells (Section 5.8)
│   ├── README.md              <-- grid layout + missing cells documented
│   ├── grid_index.csv
│   ├── A2_T0.6_R1_Voff/       <-- one of 51 completed cells (full)
│   │   ├── config.json
│   │   ├── 2026_03_28_..._19366.json   (per-item run with conversation)
│   │   └── ...
│   └── ...
│
├── outputs/                   <-- raw per-item outputs for ALL main runs
│   ├── cladder/
│   │   ├── qwen3-4b-instruct/{vanilla,simple_cot,guided_cot,self_consistency,multi_agent}/
│   │   ├── qwen2.5-7b/...
│   │   └── ...
│   ├── corr2cause/...
│   └── heterogeneous/{het1,het2}/...
│
└── docs/
    ├── notation.md            <-- A, tau_c, R, V, T cheatsheet
    └── changelog.md            <-- what changed between revision rounds
```

---

## Re-running inference from scratch

Inference uses [Ollama](https://ollama.com) so the same code path works on
Linux, macOS, and Windows (the paper's runs were on Windows 11 + RTX 5090,
but the code is OS-agnostic).

```bash
# Pull all 9 models in their exact quantization
bash runners/pull_models.sh

# Run a single (model, strategy, benchmark) cell
python runners/single_agent.py \
    --model qwen3:4b-instruct \
    --strategy guided_cot \
    --benchmark cladder \
    --ids data/sampled_ids/cladder_500.json \
    --out outputs/cladder/qwen3-4b-instruct/guided_cot/

# Run the multi-agent reference configuration
python runners/multi_agent.py \
    --model qwen3:4b-instruct \
    --benchmark cladder \
    --ids data/sampled_ids/cladder_500.json \
    --A 3 --tau_c 0.9 --R 4 --V on --T 0.7 \
    --out outputs/cladder/qwen3-4b-instruct/multi_agent/
```

Full grid replication takes approximately 3 days of wall-clock time on a single
RTX 5090; see `runners/run_all.sh` for the orchestration script.

---

## Reproducing each table/figure

Every numerical claim in the paper maps to one entry below. Each `make` target
is independent and can be run in isolation.

| Paper element                                  | Generator                                     |
|------------------------------------------------|-----------------------------------------------|
| Table 2 (CLadder accuracy)                     | `make table_cladder`                          |
| Table 4 (Corr2Cause accuracy)                  | `make table_corr2cause`                       |
| Table 5 (Corr2Cause clean)                     | `make table_corr2cause_clean`                 |
| Table 6 (CLadder throughput)                   | `make table_cladder_throughput`               |
| Table 7 (Corr2Cause throughput)                | `make table_corr2cause_throughput`            |
| Table 8 (memorization audit)                   | `make audit`                                  |
| Table 9 (per-pair McNemar / FDR)               | `make stats`                                  |
| Table 10 (bootstrap CIs)                       | `make bootstrap`                              |
| Table 11 (token distributions)                 | `make tokens`                                 |
| Table 12 (ablation summary)                    | `make ablation_summary`                       |
| Appendix A Table 13 (tokenizer calibration)    | `make calibration`                            |
| Appendix B Table 14 (disaggregated efficiency) | `make efficiency`                             |
| All figures (PDFs in `figures/`)               | `make figures`                                |

---

## Notation cheat-sheet

(Reproduced from Section 3.2 of the paper to avoid the τ ambiguity flagged
by Reviewer 1.)

| Symbol | Meaning                                                                 |
|--------|-------------------------------------------------------------------------|
| `A`    | Number of reasoner agents in the multi-agent framework                  |
| `tau_c` | Consensus threshold (fraction of reasoners that must agree); default 0.9 |
| `R`    | Maximum number of debate rounds; default 4                              |
| `V`    | Validator presence (`on`/`off`); default `on`                           |
| `T`    | Sampling temperature passed to the inference engine; default 0.7        |
| `K`    | Number of self-consistency samples; default 5                           |

---

## Hardware and environment

| Component | Specification                                       |
|-----------|-----------------------------------------------------|
| GPU       | NVIDIA GeForce RTX 5090 (32 GB GDDR7)               |
| CPU       | Intel Core Ultra 9 285K                             |
| RAM       | 128 GB DDR5-6000                                    |
| OS        | Windows 11 Pro                                      |
| Inference | Ollama (2025 stable release), default Q4_K_M / Q8_0 |
| Python    | 3.11.7 (see `requirements.txt`)                     |

---

## Citation

```bibtex
@article{anonymous2026multiagent,
  title  = {Do Multi-Agent {LLMs} Improve Causal Identification?
            A Controlled, Cost-Aware Study on {CL}adder},
  author = {Anonymous},
  year   = {2026},
  note   = {Under review at Array (Elsevier).}
}
```

## Licence

Code: MIT.  Prompts and outputs: CC-BY-4.0.
The CLadder and Corr2Cause benchmarks are redistributed under their original
licences; see `data/sampled_ids/LICENCE.md`.
