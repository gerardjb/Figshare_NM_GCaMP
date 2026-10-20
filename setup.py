from pathlib import Path

from setuptools import setup

requirements = [
    line.strip()
    for line in (Path(__file__).parent / "requirements-publication.txt").read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]

setup(
    name='gcamp_reproducible_plotting',
    version='0.1',
    license='MIT',
    license_files=['LICENSE', 'LICENSES/*.txt', 'THIRD_PARTY_NOTICES.md'],
    description='Reproducible plotting scripts for the GCaMP model Figshare repository',
    packages=['SharedUtilities'],
    package_dir={'SharedUtilities': 'shared/python/SharedUtilities'},
    classifiers=[
        'Programming Language :: Python :: 3.12',
    ],
    include_package_data=False,
    install_requires=requirements,
    entry_points={
        'console_scripts': [
            'run_figure3_F_G_code=SharedUtilities.entrypoints:run_figure3_f_g',
            'run_figure4_E_code=SharedUtilities.entrypoints:run_figure4_e',
            'run_ED4_code=SharedUtilities.entrypoints:run_ED4',
            'run_supp_figure12_A_B_code=SharedUtilities.entrypoints:run_supp_figure12',
            'run_ED7_code=SharedUtilities.entrypoints:run_ED7',
            'run_ED8_C_D_code=SharedUtilities.entrypoints:run_ED8',
            'run_ED9_F_G_code=SharedUtilities.entrypoints:run_ED9',
        ],
    },
    python_requires='>=3.12,<3.13',
    zip_safe=False,
)
