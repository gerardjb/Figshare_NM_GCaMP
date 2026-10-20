Source Data for Precise calcium-to-spike inference using biophysical generative models

Using the data

Figure-linked source_data directories contain CSV numerical inputs and XLSX views of those inputs. Full-resolution CSVs feed the plotting code. Workbooks provide panel-organized views suitable for inspecting the values behind each figure; multiple compatible datasets can share a worksheet. Schematics have no numerical source-data requirement.

SourceData_manifest.json maps each dataset to its CSV, source, units, extraction or analysis method, and workbook sheet and cell range. It also records source and output hashes. SourceData_column_dictionary.csv describes columns and units. SourceData_plot_only_registry.json identifies additional numerical arrays used to render panels without adding them to workbook layouts. Legend_statistics_provenance.csv documents the origin and calculation of figure-linked statistical summaries. The per-item figure.json files identify the relevant plotting entry points and datasets.

Continuous curves and exact observations

A continuous workbook curve contains at most 200 points. Longer curves are reduced by linear interpolation over their finite time support, retaining endpoints and treating separate curves and uncertainty boundaries separately. Missing-data gaps are not bridged. The CSVs retain full-resolution arrays. Curves already within the limit, discrete measurements, and exact stimulus or spike times are retained without time interpolation. Workbook row counts can therefore differ from CSV row counts.

NaN or blank measurements indicate unavailable values, not zero. Dataset metadata identifies any selection, display normalization, baseline adjustment, or time-window restriction. Stored SEM polygons are graphical boundaries; they are not independent observations. Individual spikes, trials, epochs, model states, and parameter candidates do not by themselves establish independent biological replicates.

Fluorescence expressed as DeltaF/F uses that unit label. Normalized fluorescence, ratios, probabilities, and other unitless quantities are labeled dimensionless where applicable. Time and concentration units vary by dataset; use the column dictionary and manifest rather than assuming that all time columns use milliseconds or all concentrations use micromolar.

Statistical summaries

Figure-specific legend-statistics CSVs correspond to the Legend statistics worksheets. measure_plotted describes the quantity. Row-specific units and error_type fields distinguish SEM, quartiles, and other summaries. q1/q3 are quartile endpoints; error_bar_lower/error_bar_upper are plotted interval endpoints. Regression ci95_lower/ci95_upper fields are coefficient confidence limits. Statistical provenance and verification notes are stored separately from the plotted values.

For Figure 1f, inferential tests use the stored log10(ms) rise times: ordinary one-way ANOVA and two-sided Tukey-Kramer comparisons across all indicator pairs. Descriptive arithmetic means and SEMs are expressed in milliseconds after back-transformation. The adjacent calculation helper reproduces the test results.

Figures 1h and 2i use the same bouton paired-pulse dataset. Sample sizes count all bouton rows; an unavailable interval remains missing and is omitted only from that interval's numerical summary. Figure 2i uses the 10-ms interval. Its vertical bars span the 25th-75th percentiles. Horizontal bars are fitted early Hill-slope endpoints at 0.631-2.512 micromolar calcium; the central slope is labeled at nominal 1 micromolar. They are not SD bars.

Figure 2f uses mean +/- SEM on both axes: horizontal SEM is across calcium conditions and vertical SEM across boutons. Figure 2l uses medians and quartiles across selected calcium conditions and boutons. When two kinetic components cannot be distinguished, both retain the resolved common time constant, giving accessible slowing of one. OGB-5N is an assigned reference without an empirical interval.

Figure 4d and Extended Data Figure 9g compare method means averaged equally across Gaussian filter widths. Holm correction covers the declared biophysical-versus-comparator family within each cell class. Pointwise confidence intervals and paired effect sizes are identified separately in the analysis outputs. The portable analysis helpers and accompanying inputs preserve the full comparison definitions. Very small P values may underflow in floating-point columns; scientific or log10 P columns retain their magnitude where provided. A stored zero is not evidence of an exact probability of zero.

Panel-specific data interpretation

Extended Data Figure 8c labels use the complete recording-epoch correlations at the specified Gaussian filter width. The example trace shows a shorter window; recalculating correlation only over that display window gives a different quantity.

Extended Data Figure 9 activity bins use spike_count_pre, the spike count in the preceding 500 ms. The separate spike_count_bin field describes a different history window.

Extended Data Figure 1 integrated spectral counts sum 500-550 nm. Raw and background-subtracted spectra are provided separately. Model-state and simulated concentration trajectories elsewhere are computational outputs, not independent measurements.

Figure 4c's dataset named Figure4C_ENS2_displayed_ticks_inherited_from_CASCADE records the event marks inherited from CASCADE by the historical plotting code; those marks are not verified ENS2 inferred events. The ENS2 continuous probability trace is separately identified. Consult the dataset method for the exact time transformation and event origin.

Supplementary Note 1 separates experimental traces from figure-display arrays. Panels a-d retain numerical paths extracted from the reference PDF. Their plot coordinates are display coordinates, not full-precision physical fit coefficients. The panel-c annotations retain the displayed rounded fit values; panel-d physical summaries and SEM endpoints are calibrated from the PDF axes and have that precision limit. The original full-precision fit state for those panels is unavailable. Panels e-g retain native numerical series. No new decay fit is substituted for the reference curves.

Supplementary Note 2 includes the full candidate-parameter matrix and the fixed row order and nine cluster labels for the displayed heatmap. The heatmap's displayed candidates are a subset of the full matrix; they do not provide cluster assignments for every candidate. Panels b-d show example families 1, 5, and 9. Stopped-flow data are normalized fluorescence; bouton traces use DeltaF/F. Paired-pulse times are relative to the last stimulus, and Poisson times are relative to the first stimulus. The cropped Poisson detail reuses the same data and is not an additional measurement.
