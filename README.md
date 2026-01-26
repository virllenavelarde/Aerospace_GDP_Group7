# MSc Group Design Project – Cargo Aircraft MDO Framework

## Overview
This repository contains the Multidisciplinary Design Optimisation (MDO) framework
developed as part of the MSc Group Design Project (CADEM0016).

The objective of the project is the conceptual design of a cargo aircraft intended
to support Formula 1 logistics operations in 2040, with a focus on minimising
Direct Operating Cost (DOC) and climate impact.

## Repository Structure
- `src/` – Discipline-specific analysis tools and MDO integration
- `data/` – Input data, reference aircraft data, and processed datasets
- `configs/` – Centralised design assumptions and mission definitions
- `results/` – Selected outputs, figures, and trade-study results
- `docs/` – Meeting minutes, methodology notes, and supporting documentation
- `tests/` – Basic checks to ensure model consistency

## MDO Philosophy
The framework follows a progressive fidelity approach:
- Class I: Empirical and statistical methods for rapid assessment
- Class II: Semi-empirical methods with simplified physics
- Class II.5: Physics-based models calibrated to reference aircraft

## Version Control
Git is used for version control with a central GitHub repository.
All changes are tracked through commits to ensure traceability
and reproducibility of results.

## How to Run (High-Level)
1. Configure design parameters in `configs/`
2. Run the main MDO script in `src/core/`
3. Post-process results from `results/`

## Contributors
MSc Group Design Project Team – University of Bristol

## Licence
This project is released under the MIT Licence for academic use.
