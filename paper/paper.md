---
title: 'tools4watlas: An R package for processing and visualizing high-throughput tracking data'
tags:
  - ATLAS tracking
  - biotelemetry
  - high-throughput tracking data
  - movement data processing
  - movement ecology
  - reverse GPS
  - spatial ecology
  - tutorial for analyzing movement data
  - WATLAS tracking

authors:
  - name: Johannes Krietsch 
    orcid: 0000-0002-8080-1734
    affiliation: 1
  - name: Allert I. Bijleveld
    orcid: 0000-0002-3159-8944
    affiliation: 1
affiliations:
 - name: NIOZ Royal Netherlands Institute for Sea Research, Department of Coastal Systems, Den Burg, Texel, The Netherlands
   index: 1
date: 26 January 2026
bibliography: paper.bib
nocite: '@*'
---

# Summary

Tracking animal movement is essential for understanding ecological interactions, predicting responses to environmental change, and informing conservation and management decisions. Advances in high-throughput tracking systems have made it possible to collect ever-larger volumes of movement data, and these technologies are increasingly being adopted by researchers worldwide (Nathan et al., 2022). This growing use enables monitoring of many individuals and species simultaneously, providing unprecedented insights into space use, individual variation, and behavioral responses to environmental conditions. While these data-rich approaches open new opportunities for research and conservation, they also introduce significant challenges, including heavy computational demands, intensive data processing requirements, and the need for reproducible analytical workflows. `tools4watlas` is an R package for processing and visualizing high-throughput animal tracking data. While tailored for the WATLAS system (Wadden Sea Advanced Tracking and Localization of Animals in real-life Systems; Bijleveld et al, 2022), its functions are broadly applicable to other high-throughput tracking datasets, and study system-specific steps can be adapted easily. In addition, the package enables the integration of environmental data (e.g., water level, bathymetry, or any other raster data), allowing to link movement data easily to other ecological data. Beyond data processing workflows, `tools4watlas` includes tutorials, and visualization functions that support static plots, interactive plots and animations of movement data, as well as base map data of the Dutch Wadden Sea. 


# Statement of need

High-resolution animal tracking datasets are rapidly increasing in size, outpacing the capabilities of existing tools that are easily applicable for ecologists. To keep up with this growth, data-processing functions must be adapted for speed and memory efficiency. `tools4watlas` addresses this need by providing flexible, high-performance workflows for processing and visualizing movement data, while also enabling the integration of environmental information to support ecological interpretation. By combining efficiency with extensive documentation and tutorials, the package lowers the barrier to analyze tracking data, promotes reproducible workflows, and facilitates the use of high-throughput tracking systems in both ecological research and applied management.

# State of the field

There is a large body of R packages developed to analyze and visualize movement data, many of which are designed primarily for GPS, GLS, or PTT tracking systems (reviewed in Joo et al., 2020). To our knowledge, `atlastools` (Gupte et al., 2022) is the only open-source R package that explicitly supports the data-processing steps required for working with high-throughput ATLAS tracking data. Given the rapidly increasing volume of data produced by ATLAS deployments, where currently over 300 individuals can be tracked simultaneously at second-by-second resolution, the functions and recommended workflows provided by `atlastools` became too computationally demanding and slow. We therefore derived the data-processing functions of `tools4watlas` from those of `atlastools` and modified them to simplify the workflows and to reduce computation time and memory use.

# Software design

`tools4watlas` is mainly combining the strength of `data.table` for efficient data processing with the flexibility of `ggplot2` for data visualization for movement data analysis. By relying on reference-based, in-place data modification, `data.table` minimizes memory overhead, while its support for low-level parallelization enables fast processing of large tracking datasets. `ggplot2` and its supporting R packages, allow for great flexibility in data visualization and is familiar to most biologists. Tutorials are organized into modular, logically separated steps that can be run independently, supporting flexibility and reproducibility and allow an easy access to the code. Additional tutorials describe how to contribute to `tools4watlas` and how to customize base map data.

# Research impact statement

`tools4watlas` has been developed for the ongoing WATLAS-project at the NIOZ (Royal Netherlands Institute for Sea Research; Bijleveld et al 2022), which is aimed at understanding shorebird movement ecology in the Dutch Wadden Sea (www.nioz.nl/watlas). Previous versions of the code have been used in several publications (e.g. Ersoy et al., 2022; Ersoy et al., 2024; Gobbens et al., 2024; Lameris et al., 2025) and future publications will depend on the continued use of `tools4watlas`. WATLAS is the Wadden Sea deployment ATLAS (Toledo et al., 2016), a tracking system that is increasingly used worldwide. We expect `tools4watlas` can be especially useful for the growing community of movement ecologists using ATLAS. Moreover, as more high throughput  tracking technologies become available, `tools4watlas` can be adapted and provide scientific impact beyond the growing ATLAS community. 

# AI usage disclosure

We used ChatGPT (GPT-4, OpenAI) and Claude (Anthropic) to assist in drafting parts of the package testing structure and to support debugging of code. All outputs were reviewed, modified where necessary, and validated by the authors to ensure correctness, reliability, and consistency.

# Acknowledgements

We particularly thank Pratik Gupte for earlier code development, and Christine Beardsworth, Jet Carabain, Antsje van der Leij Freddie Mckendrick and Hans Linssen for testing and providing valuable feedback. We also thank Sivan Toledo and Ran Nathan for developing ATLAS, and all NIOZ colleagues for their continued support developing and deploying WATLAS. Particularly, Anne Dekinga, Frank van Maarseveen, Bas Denissen, Remko de Haan, Aris van der Vis, Yetzo de Hoo, and Wim Jan Boon.

# References