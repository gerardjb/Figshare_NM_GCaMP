# Third-party notices

The MIT licence in `LICENSE` applies to Gerard Joey Broussard's original project code and its software documentation. The CC BY 4.0 grant described in the README applies to original study data and artwork. Neither grant replaces the licences or rights of the third-party materials identified below. Existing author credits in the source files are retained.

## Bundled MATLAB helpers

The full copyright notices, conditions, and disclaimers are reproduced in the linked files. The source links identify the distributions used to recover those notices.

| Bundled file | Author | Licence notice | Upstream distribution |
| --- | --- | --- | --- |
| `shared/matlab/linspecer.m` | Jonathan C. Lansey | [BSD-2-Clause, copyright 2015](LICENSES/linspecer-BSD-2-Clause.txt) | [File Exchange 42673](https://www.mathworks.com/matlabcentral/fileexchange/42673), version 1.4.0.0, [download revision 6](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/42673/versions/6/download/zip) |
| `shared/matlab/gaussfilt.m` | James Conder | [BSD-3-Clause, copyright 2018](LICENSES/gaussfilt-BSD-3-Clause.txt) | [File Exchange 43182](https://www.mathworks.com/matlabcentral/fileexchange/43182), version 1.3.0.0, [download revision 4](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/43182/versions/4/download/zip) |
| `shared/matlab/dotPlot_xtr.m` | Taorong Xie | [BSD-3-Clause, copyright 2012](LICENSES/dotPlot_xtr-BSD-3-Clause.txt) | [File Exchange 34515](https://www.mathworks.com/matlabcentral/fileexchange/34515), [download revision 1](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/34515/versions/1/download/zip) |
| `shared/matlab/redblue.m` | Adam Auton | [BSD-2-Clause, copyright 2009](LICENSES/redblue-BSD-2-Clause.txt) | [File Exchange 25536](https://www.mathworks.com/matlabcentral/fileexchange/25536), [download revision 1](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/25536/versions/1/download/zip) |
| `shared/matlab/nancat.m` | Sanjay Manohar | [BSD-2-Clause, copyright 2007](LICENSES/nancat-BSD-2-Clause.txt) | [File Exchange 40416](https://www.mathworks.com/matlabcentral/fileexchange/40416), [download revision 1](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/40416/versions/1/download/zip) |
| `shared/matlab/shadedErrorBar.m` | Rob Campbell | [BSD-2-Clause, copyright 2014](LICENSES/shadedErrorBar-BSD-2-Clause.txt) | [File Exchange 26311](https://www.mathworks.com/matlabcentral/fileexchange/26311), [historical download revision 6](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/26311/versions/6/download/zip) |

The bundled `dotPlot_xtr.m` includes a coloured-scatter adaptation, and `redblue.m` includes a colour-limit branch. The bundled historical `shadedErrorBar.m` uses the `painters` renderer and omits the two edge lines. Its notice is from the corresponding historical BSD distribution; later upstream releases use different licensing.

### ColorBrewer palettes

`linspecer.m` incorporates and adapts ColorBrewer colour specifications by Cynthia Brewer, Mark Harrower, and The Pennsylvania State University. The [ColorBrewer notice](LICENSES/ColorBrewer-NOTICE.txt) and the [Apache License 2.0](LICENSES/Apache-2.0.txt) it references are included. The upstream notice is available at [colorbrewer2.org/export/LICENSE.txt](https://colorbrewer2.org/export/LICENSE.txt).

This product includes color specifications and designs developed by Cynthia Brewer (http://colorbrewer.org/).

## Benchmark data

The benchmark recordings are third-party source material. They have been selected, processed, and reformatted for the analyses and source-data tables in this study. Credit their original creators as well as the analyses in this repository.

- **jGCaMP8f recordings:** Márton Rózsa, Yajie Liang, Yan Zhang, Jeremy Hasseman, Ilya Kolb, Loren Looger, Karel Svoboda, and HHMI (2022), *Simultaneous loose seal cell-attached recordings and two-photon imaging of GCaMP8 expressing mouse V1 neurons with drifting gratings visual stimuli*. [DANDI:000168](https://dandiarchive.org/dandiset/000168/draft), licensed under [CC BY 4.0](LICENSES/CC-BY-4.0.txt). Associated publication: Zhang et al., *Fast and sensitive GCaMP calcium indicators for imaging neural populations*, Nature (2023), [doi:10.1038/s41586-023-05828-9](https://doi.org/10.1038/s41586-023-05828-9). This record currently supplies a draft identifier rather than a versioned dataset DOI.
- **jGCaMP8m recordings:** obtained from the [CASCADE repository](https://github.com/HelmchenLabSoftware/Cascade). Credit Peter Rupprecht, Márton Rózsa, Xusheng Fang, Karel Svoboda, and Fritjof Helmchen, *Spike inference from calcium imaging data acquired with GCaMP8 indicators*, Nature Methods (2026), [doi:10.1038/s41592-026-03183-x](https://doi.org/10.1038/s41592-026-03183-x). Upstream distributes its repository and contents under GNU GPL version 3; the [upstream licence](https://github.com/HelmchenLabSoftware/Cascade/blob/master/LICENSE) is reproduced in [LICENSES/CASCADE-GPL-3.0.txt](LICENSES/CASCADE-GPL-3.0.txt). Imported CASCADE source material retains those terms and is excluded from this repository's grant for original data and artwork.

## Adapted artwork

Main Figure 2a adapts Figure 3a, and Main Figure 3a adapts Figure 6, from Sun et al., *Fast GCaMPs for improved tracking of neuronal activity*, Nature Communications 4, 2170 (2013), [doi:10.1038/ncomms3170](https://doi.org/10.1038/ncomms3170). These source elements retain their original rights and credits. Their inclusion does not extend the repository's CC BY 4.0 grant to the underlying third-party artwork; reuse is governed by the source's applicable rights or permissions.

## Separately installed dependencies and fonts

MATLAB, its toolboxes, the Python packages listed in `requirements-publication.txt`, and optional figure-assembly tools are installed separately and retain their own licences. Table PDFs embed DejaVu Sans supplied with Matplotlib; Arial is used where installed for figure reproduction. Font rights remain with their respective owners and licences.
