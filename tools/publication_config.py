"""Final publication identities and reproducible build entry points."""

from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PUBLISHED_REFERENCE_ROOT = REPO_ROOT / "reference_figures" / "published"


def _item(
    publication_id: str,
    path: str,
    source_data_item: str | None,
    legacy_id: str | None,
    entrypoints: list[dict[str, str]],
    *,
    static_panels: list[str] | None = None,
    baseline: str | None = None,
    baseline_page: int = 1,
    dynamic_panels: list[str] | None = None,
) -> dict[str, object]:
    return {
        "publication_id": publication_id,
        "path": path,
        "source_data_item": source_data_item,
        "legacy_id": legacy_id,
        "entrypoints": entrypoints,
        "static_panels": static_panels or [],
        "baseline": baseline,
        "baseline_page": baseline_page,
        "dynamic_panels": dynamic_panels or [],
    }


def matlab(*names: str) -> list[dict[str, str]]:
    return [{"language": "matlab", "script": f"code/{name}.m", "call": name} for name in names]


def python(*names: str) -> list[dict[str, str]]:
    return [{"language": "python", "script": f"code/{name}.py", "call": "main"} for name in names]


ITEMS = [
    _item("Figure1", "figures/main/figure1", "Figure1", "figure1", matlab("figure1_B_C_G_I_code", "figure1_D_E_F_code", "figure1_H_J_code", "figure1_K_L_M_csv_code", "figure1_N_code", "figure1_O_code"), static_panels=["A"], dynamic_panels=list("BCDEFGHIJKLMNO"), baseline="MainFigures/NMETH-A59789D_Fig1.pdf"),
    _item("Figure2", "figures/main/figure2", "Figure2", "figure2", matlab("figure2_C_D_code", "figure2_E_F_code", "figure2_G_H_I_code", "figure2_J_code", "figure2_K_L_code"), static_panels=["A", "B"], dynamic_panels=list("CDEFGHIJKL"), baseline="MainFigures/NMETH-A59789D_Fig2.pdf"),
    _item("Figure3", "figures/main/figure3", "Figure3", "figure3", matlab("figure3_B_code", "figure3_D_E_code") + python("figure3_F_G_code"), static_panels=["A", "B"], dynamic_panels=list("CDEFG"), baseline="MainFigures/NMETH-A59789D_Fig3.pdf"),
    _item("Figure4", "figures/main/figure4", "Figure4", "figure4", matlab("figure4B_C_code", "figure4_D_code") + python("figure4_E_code"), static_panels=["A"], dynamic_panels=list("BCDEFG"), baseline="MainFigures/NMETH-A59789D_Fig4.pdf"),
    *[
        _item(f"ED{i}", f"figures/extended_data/figure{i}", f"ED{i}", legacy, entries, static_panels=static, baseline=f"ExtendedData/NMETH-A59789D_ExtendedDataFig{i}.pdf")
        for i, legacy, entries, static in [
            (1, "supp_figure3", python("fast_ed1"), ["E"]),
            (2, "supp_figure4", python("fast_ed2"), ["A", "E"]),
            (3, "supp_figure6", python("fast_ed3"), ["A"]),
            (4, "supp_figure8", python("ED4_code"), []),
            (5, "supp_figure10", matlab("ED5_A_B_csv_code", "ED5_C_to_F_code"), []),
            (6, "supp_figure11", matlab("ED6_code"), []),
            (7, "supp_figure13", python("ED7_code"), []),
            (8, "supp_figure14", matlab("ED8_A_B_code") + python("ED8_C_D_code"), []),
            (9, "supp_figure15", matlab("ED9_A_B_C_csv_code", "ED9_D_E_code") + python("ED9_F_G_code"), []),
        ]
    ],
    _item("SupplementaryFigure1", "figures/supplementary/figure1", "SupplementaryFigure1", "supp_figure2", matlab("suppfigure2_code"), static_panels=["A", "B"], dynamic_panels=list("CDEFGH"), baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=2),
    _item("SupplementaryFigure2", "figures/supplementary/figure2", None, "supp_figure7", [], static_panels=["A", "B"], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=3),
    _item("SupplementaryFigure3", "figures/supplementary/figure3", "SupplementaryFigure3", "supp_figure9", matlab("suppfigure9_A_code", "suppfigure9_B_code"), dynamic_panels=["A", "B"], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=4),
    _item("SupplementaryFigure4", "figures/supplementary/figure4", "SupplementaryFigure4", "supp_figure12", python("suppfigure12_A_B_code"), dynamic_panels=["A", "B"], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=5),
    _item("SupplementaryNote1", "figures/supplementary/note1", "SupplementaryNote1", "supp_figure1", matlab("suppfigure1_A_to_D_code", "suppfigure1_E_to_G_code"), dynamic_panels=list("ABCDEFG"), baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=11),
    _item("SupplementaryNote2", "figures/supplementary/note2", "SupplementaryNote2", "supp_figure5", matlab("suppfigure_5_code"), dynamic_panels=list("ABCD"), baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=13),
    _item("Table1", "tables/main/table1", None, "Table1", [{"language": "powershell", "script": "code/render_table1_precision_recall_fscore_pdf.ps1", "call": "render"}]),
    _item("SupplementaryTable1", "tables/supplementary/table1", "ST1", "Table2", [{"language": "powershell", "script": "code/render_table2_cell_parameters_pdf.ps1", "call": "render"}], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=6),
    _item("SupplementaryTable2", "tables/supplementary/table2", "ST2", "Table3", [{"language": "powershell", "script": "code/render_gcamp_parameter_table_pdf.ps1", "call": "render"}], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=8),
    _item("SupplementaryTable3", "tables/supplementary/table3", "ST3", "Table4", [{"language": "powershell", "script": "code/render_table4_cell_parameter_priors_pdf.ps1", "call": "render"}], baseline="NMETH-A59789D_SupplementaryInformation.pdf", baseline_page=9),
]


# Per-entrypoint publication semantics. Extended Data scripts and output stems
# use the final ED numbers; legacy input identifiers remain as provenance.
ENTRY_METADATA: dict[str, dict[str, object]] = {
    "figure1_B_C_G_I_code": {"panels": list("BCGI"), "mode": "packaged_csv", "stems": ["figure1_B_C_G_I_01", "figure1_B_C_G_I_02", "figure1_B_C_G_I_03", "figure1_B_C_G_I_04"], "stem_panels": {"figure1_B_C_G_I_01": ["B"], "figure1_B_C_G_I_02": ["C"], "figure1_B_C_G_I_03": ["G"], "figure1_B_C_G_I_04": ["I"]}},
    "figure1_D_E_F_code": {"panels": list("DEF"), "mode": "packaged_csv", "stems": ["figure1_D_E_F_01", "figure1_D_E_F_02", "figure1_D_E_F_03"], "stem_panels": {"figure1_D_E_F_01": ["D"], "figure1_D_E_F_02": ["E"], "figure1_D_E_F_03": ["F"]}},
    "figure1_H_J_code": {"panels": ["H", "J"], "mode": "packaged_csv", "stems": ["figure1_H_J_01", "figure1_H_J_02"], "stem_panels": {"figure1_H_J_01": ["H"], "figure1_H_J_02": ["J"]}},
    "figure1_K_L_M_csv_code": {"panels": list("KLM"), "mode": "packaged_csv", "stems": ["figure1_K_L_M"]},
    "figure1_N_code": {"panels": ["N"], "mode": "packaged_csv", "stems": ["figure1_N"]},
    "figure1_O_code": {"panels": ["O"], "mode": "packaged_csv", "stems": ["figure1_O"]},
    "figure2_C_D_code": {"panels": ["C", "D"], "mode": "packaged_csv", "stems": ["figure2_C_D_01", "figure2_C_D_02"], "stem_panels": {"figure2_C_D_01": ["C"], "figure2_C_D_02": ["D"]}},
    "figure2_E_F_code": {"panels": ["E", "F"], "mode": "packaged_csv", "stems": ["figure2_E_F_01", "figure2_E_F_02"], "stem_panels": {"figure2_E_F_01": ["E"], "figure2_E_F_02": ["F"]}},
    "figure2_G_H_I_code": {"panels": list("GHI"), "mode": "packaged_csv", "stems": ["figure2_G_H_I"]},
    "figure2_J_code": {"panels": ["J"], "mode": "packaged_csv", "stems": ["figure2_J_01", "figure2_J_02"], "stem_panels": {"figure2_J_01": ["J"], "figure2_J_02": ["J"]}},
    "figure2_K_L_code": {"panels": ["K", "L"], "mode": "packaged_csv", "stems": ["figure2_K_L_01", "figure2_K_L_02"], "stem_panels": {"figure2_K_L_01": ["K"], "figure2_K_L_02": ["L"]}},
    "figure3_B_code": {"panels": ["C"], "mode": "packaged_csv", "stems": ["figure3_B"]},
    "figure3_D_E_code": {"panels": ["D", "E"], "mode": "packaged_csv", "stems": ["figure3_D_E_01", "figure3_D_E_02"], "stem_panels": {"figure3_D_E_01": ["D"], "figure3_D_E_02": ["E"]}},
    "figure3_F_G_code": {"panels": ["F", "G"], "mode": "packaged_csv", "stems": ["figure3_F_excitatory_simulation", "figure3_G_inhibitory_simulation"], "stem_panels": {"figure3_F_excitatory_simulation": ["F"], "figure3_G_inhibitory_simulation": ["G"]}},
    "figure4B_C_code": {"panels": ["B", "C"], "mode": "packaged_csv", "stems": ["figure4_B_C"]},
    "figure4_D_code": {"panels": ["D"], "mode": "packaged_csv", "stems": ["figure4_D"]},
    "figure4_E_code": {"panels": list("EFG"), "mode": "packaged_csv", "stems": ["figure4_E_F_G"]},
    "fast_ed1": {"panels": list("ABCDF"), "mode": "packaged_csv", "stems": ["ED1_a_spectra", "ED1_b_counts", "ED1_c_normalized", "ED1_d_dynamic_range", "ED1_f_half_rise"], "stem_panels": {"ED1_a_spectra": ["A"], "ED1_b_counts": ["B"], "ED1_c_normalized": ["C"], "ED1_d_dynamic_range": ["D"], "ED1_f_half_rise": ["F"]}},
    "fast_ed2": {"panels": list("BCDFGH"), "mode": "packaged_csv", "stems": ["ED2_b_components", "ED2_c_fit_traces", "ED2_d_rise_constants", "ED2_f_decay_traces", "ED2_g_decay_constants", "ED2_h_fit_traces"], "stem_panels": {"ED2_b_components": ["B"], "ED2_c_fit_traces": ["C"], "ED2_d_rise_constants": ["D"], "ED2_f_decay_traces": ["F"], "ED2_g_decay_constants": ["G"], "ED2_h_fit_traces": ["H"]}},
    "fast_ed3": {"panels": list("BCDE"), "mode": "packaged_csv", "stems": ["ED3_b_rise_states", "ED3_c_decay_states", "ED3_d_bouton_traces", "ED3_e_bouton_states"], "stem_panels": {"ED3_b_rise_states": ["B"], "ED3_c_decay_states": ["C"], "ED3_d_bouton_traces": ["D"], "ED3_e_bouton_states": ["E"]}},
    "ED4_code": {"panels": list("ABCDE"), "mode": "packaged_csv", "stems": ["ED4_A_single_ap_overlay", "ED4_B_pyramidal_inference", "ED4_C_interneuron_inference", "ED4_D_E_single_ap_recovery", "ED4_full"], "stem_panels": {"ED4_A_single_ap_overlay": ["A"], "ED4_B_pyramidal_inference": ["B"], "ED4_C_interneuron_inference": ["C"], "ED4_D_E_single_ap_recovery": ["D", "E"], "ED4_full": []}},
    "ED5_A_B_csv_code": {"panels": ["A", "B"], "mode": "packaged_csv", "stems": ["ED5_A_B"]},
    "ED5_C_to_F_code": {"panels": list("CDEF"), "mode": "packaged_csv", "stems": ["ED5_C_to_F"]},
    "ED6_code": {"panels": list("ABCD"), "mode": "packaged_csv", "stems": ["ED6"]},
    "ED7_code": {"panels": ["A", "B"], "mode": "packaged_csv", "stems": ["ED7_trace_panels", "ED7_raincloud_downsample"], "stem_panels": {"ED7_trace_panels": [], "ED7_raincloud_downsample": ["A", "B"]}},
    "ED8_A_B_code": {"panels": ["A", "B"], "mode": "packaged_csv", "stems": ["ED8_A_B_global_best"]},
    "ED8_C_D_code": {"panels": ["C", "D"], "mode": "packaged_csv", "stems": ["ED8_C_trace_param_compare", "ED8_D_corr_vs_sigma_param_compare"], "stem_panels": {"ED8_C_trace_param_compare": ["C"], "ED8_D_corr_vs_sigma_param_compare": ["D"]}},
    "ED9_A_B_C_csv_code": {"panels": list("ABC"), "mode": "packaged_csv", "stems": ["ED9_A_B_C_quiescent_binning_dashboard"]},
    "ED9_D_E_code": {"panels": ["D", "E"], "mode": "packaged_csv", "stems": ["ED9_D_E_global_best"]},
    "ED9_F_G_code": {"panels": ["F", "G"], "mode": "packaged_csv", "stems": ["ED9_F_trace_jG8m_compare", "ED9_G_corr_vs_sigma_jG8m"], "stem_panels": {"ED9_F_trace_jG8m_compare": ["F"], "ED9_G_corr_vs_sigma_jG8m": ["G"]}},
    "suppfigure2_code": {"panels": list("CDEFGH"), "mode": "packaged_csv", "stems": ["suppfigure2"]},
    "suppfigure9_A_code": {"panels": ["A"], "mode": "packaged_csv", "stems": ["suppfigure9_A"]},
    "suppfigure9_B_code": {"panels": ["B"], "mode": "packaged_csv", "stems": ["suppfigure9_B"]},
    "suppfigure12_A_B_code": {"panels": ["A", "B"], "mode": "packaged_csv", "stems": ["suppfigure12_A_B"]},
    "suppfigure1_A_to_D_code": {"panels": list("ABCD"), "mode": "packaged_csv", "stems": ["suppfigure1_A_to_D"]},
    "suppfigure1_E_to_G_code": {"panels": list("EFG"), "mode": "packaged_csv", "stems": ["suppfigure1_E_to_G"]},
    "suppfigure_5_code": {"panels": list("ABCD"), "mode": "packaged_csv", "stems": ["suppfigure5_01", "suppfigure5_02", "suppfigure5_03", "suppfigure5_04"], "stem_panels": {"suppfigure5_01": ["A"], "suppfigure5_02": ["B"], "suppfigure5_03": ["C"], "suppfigure5_04": ["D"]}},
    "render_table1_precision_recall_fscore_pdf": {"panels": ["table"], "mode": "packaged_csv", "stems": ["table1_precision_recall_fscore"], "additional_dependencies": ["figures/main/figure4/source_data/01_Matched_spike_bias.csv", "figures/main/figure4/source_data/02_Epoch_precision_recall.csv"]},
    "render_table2_cell_parameters_pdf": {"panels": ["table"], "mode": "packaged_csv", "stems": ["table2_cell_parameters"]},
    "render_gcamp_parameter_table_pdf": {"panels": ["table"], "mode": "packaged_csv", "stems": ["gcamp_parameter_table"]},
    "render_table4_cell_parameter_priors_pdf": {"panels": ["table"], "mode": "packaged_csv", "stems": ["Table4_cell_parameter_priors"]},
}

DYNAMIC_PANELS = {
    "ED1": list("ABCDF"), "ED2": list("BCDFGH"), "ED3": list("BCDE"),
    "ED4": list("ABCDE"), "ED5": list("ABCDEF"), "ED6": list("ABCD"),
    "ED7": list("AB"), "ED8": list("ABCD"), "ED9": list("ABCDEFG"),
}

for configured_item in ITEMS:
    if configured_item["publication_id"] in DYNAMIC_PANELS:
        configured_item["dynamic_panels"] = DYNAMIC_PANELS[str(configured_item["publication_id"])]
    for configured_entry in configured_item["entrypoints"]:
        stem = Path(str(configured_entry["script"])).stem
        configured_entry.update(ENTRY_METADATA[stem])
        configured_entry["required_formats"] = ["pdf"] if configured_entry["language"] != "matlab" else ["pdf", "png", "fig"]

ITEM_BY_SOURCE_DATA = {
    item["source_data_item"]: item
    for item in ITEMS
    if item["source_data_item"] is not None
}

ITEM_BY_ID = {item["publication_id"]: item for item in ITEMS}
