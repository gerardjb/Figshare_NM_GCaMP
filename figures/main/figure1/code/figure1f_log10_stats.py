"""Recompute Figure1f ANOVA/Tukey-Kramer statistics on stored log10(ms) values.

Arithmetic descriptive means/SEMs remain in milliseconds; inferential tests use
the stored log10(ms) observations directly. Writes a separate CSV proposal only.
Example: python figure1f_log10_stats.py --points ../source_data/03_Panel_F_points.csv
 --legend-statistics ../source_data/SourceData_Fig1_legend_statistics.csv --output proposal.csv
"""
from __future__ import annotations

import argparse
import csv
import itertools
import json
import math
from pathlib import Path

import numpy as np
from scipy import stats
from scipy.integrate import quad
from scipy.special import gammaln, ndtr


KEYS = ["G6f", "jG7f", "jG8f", "O5N"]
NAMES = ["GCaMP6f", "jGCaMP7f", "jGCaMP8f", "OGB-5N"]


def tukey_survival_four(q: float, df: int) -> float:
    """Evaluate the positive survival integral without tiny-tail cancellation."""

    def range_tail(width: float) -> float:
        def integrand(x: float) -> float:
            a = ndtr(-x)
            b = ndtr(-x - width)
            return (
                4
                * math.exp(-(x**2) / 2)
                / math.sqrt(2 * math.pi)
                * b
                * (3 * a * a - 3 * a * b + b * b)
            )

        return quad(
            integrand,
            -width / 2 - 12,
            -width / 2 + 12,
            epsabs=1e-100,
            epsrel=2e-10,
            limit=150,
        )[0]

    constant = (1 - df / 2) * math.log(2) - gammaln(df / 2)

    def integrand(t: float) -> float:
        if t <= 0:
            return 0.0
        return math.exp(constant + (df - 1) * math.log(t) - t * t / 2) * range_tail(
            q * t / math.sqrt(df)
        )

    return quad(integrand, 0, 25, epsabs=1e-65, epsrel=3e-9, limit=150)[0]



def compute_log10(points: Path) -> dict[str, object]:
    with points.open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    groups = [np.asarray([float(row["plotted_value"]) for row in rows
                          if row["indicator"] == key]) for key in KEYS]
    if any(len(group) == 0 or not np.isfinite(group).all() for group in groups):
        raise ValueError("Each indicator must have finite values; no silent exclusions allowed.")
    n = np.asarray([len(group) for group in groups])
    means = np.asarray([group.mean() for group in groups])
    df = int(sum(n) - len(groups))
    mse = sum(np.sum((group - group.mean())**2) for group in groups) / df
    f_value, p_value = stats.f_oneway(*groups)
    q_critical = stats.studentized_range.ppf(0.95, len(groups), df)
    comparisons = []
    for first, second in itertools.combinations(range(len(groups)), 2):
        difference = means[first] - means[second]
        se = np.sqrt(mse / 2 * (1/n[first] + 1/n[second]))
        comparisons.append({"group1": NAMES[first], "group2": NAMES[second],
            "difference_log10_ms": float(difference),
            "ci95_low": float(difference - q_critical*se),
            "ci95_high": float(difference + q_critical*se),
            "p": tukey_survival_four(abs(difference)/se, df)})
    return {"scale": "Stored log10(ms) values; no inverse transformation for inference",
        "test": "Ordinary one-way ANOVA; two-sided Tukey-Kramer all-pairs comparisons",
        "F": float(f_value), "df1": len(groups)-1, "df2": df, "p": float(p_value),
        "groups": [{"group": name, "n": len(group),
            "mean_log10_ms": float(group.mean()), "sem_log10_ms": float(stats.sem(group)),
            "descriptive_mean_ms": float((10.0**group).mean()),
            "descriptive_sem_ms": float(stats.sem(10.0**group))}
            for name,group in zip(NAMES,groups)], "comparisons": comparisons}

def write_proposal(source: Path, output: Path, result: dict[str, object]) -> dict[str, object]:
    if source.resolve() == output.resolve():
        raise ValueError("Proposal must be a separate output file.")
    with source.open(encoding="utf-8-sig", newline="") as stream:
        reader=csv.DictReader(stream);fields=reader.fieldnames;rows=list(reader)
    if not fields: raise ValueError("Missing CSV header.")
    summary={row["group"]:row for row in rows
             if row["panel"].lower()=="f" and row["record_type"]=="descriptive"}
    text="Rise times (arithmetic mean ± SEM in milliseconds): "
    text+="; ".join(f"{name}, {summary[name]['estimate']} ± {summary[name]['error']} ms"
        for name in ["jGCaMP8f","GCaMP6f","jGCaMP7f","OGB-5N"])
    text+=(f"; inferential tests use all 84 stored log10(ms) values without inverse transformation: "
        f"ordinary one-way ANOVA, F({result['df1']},{result['df2']}) = {result['F']:.1f}, "
        f"p = {result['p']:.2g}; two-sided Tukey-Kramer comparisons (all six pairs): ")
    text+="; ".join(f"{entry['group1']} vs. {entry['group2']}, p = {entry['p']:.2g}"
        for entry in result["comparisons"])+"."
    pairs={(entry['group1'],entry['group2']):entry for entry in result['comparisons']}
    updated=[];seen=set();omnibus=0
    for row in rows:
        record=dict(row)
        if record['panel'].lower()=='f':
            record['measure_plotted']=text
            if record['record_type']=='comparison':
                key=tuple(record['comparison'].split(' vs. '));entry=pairs[key];seen.add(key)
                record.update(p=f"{entry['p']:.2g}",p_relation='=',
                    test='Two-sided Tukey-Kramer post hoc (all six pairs; log10(ms))')
            elif record['record_type']=='omnibus_test':
                omnibus+=1
                record.update(test='Ordinary one-way ANOVA (log10(ms))',F=f"{result['F']:.1f}",
                    df1=str(result['df1']),df2=str(result['df2']),p=f"{result['p']:.2g}",p_relation='=')
        updated.append(record)
    assert len(seen)==6 and omnibus==1
    assert [r for r in rows if r['panel'].lower()!='f']==[r for r in updated if r['panel'].lower()!='f']
    for a,b in zip(rows,updated):
        if a['panel'].lower()=='f' and a['record_type']=='descriptive':
            assert all(a[k]==b[k] for k in fields if k!='measure_plotted')
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open('w',encoding='utf-8',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=fields);writer.writeheader();writer.writerows(updated)
    return {'original_rows':len(rows),'proposal_rows':len(updated),'non_f_cells_preserved':True,
        'descriptive_ms_fields_preserved':True,'inferential_scale':'log10(ms)'}

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument('--points',required=True,type=Path)
    parser.add_argument('--legend-statistics',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args()
    result=compute_log10(args.points)
    validation=write_proposal(args.legend_statistics,args.output,result)
    args.output.with_suffix('.validation.json').write_text(
        json.dumps({'result':result,'validation':validation},indent=2)+'\n',encoding='utf-8')
    print(json.dumps(validation,indent=2))

if __name__=='__main__': main()
