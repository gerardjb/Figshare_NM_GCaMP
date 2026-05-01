from setuptools import find_packages, setup

setup(
    name='gcamp_reproducible_plotting',
    version='0.1',
    description='Reproducible plotting scripts for the GCaMP model Figshare repository',
    packages=find_packages(exclude=['build', 'build.*']),
    package_data={
        'SharedUtilities': ['*.py'],
        'figure3': ['*.mat', '*.dat'],
        'figure4': ['*.csv'],
        'supp_figure8': ['processed/*.csv'],
        'supp_figure11': ['*.csv'],
        'supp_figure12': ['*.csv', '*.npz', '*.mat', 'trace_panel_exports/*.npz', 'trace_panel_exports/*.mat'],
        'supp_figure13': ['*.csv', '*.npz', '*.mat', '*.m', 'jG8f_simple6_Janelia_jG8f_v2/*.mat'],
        'supp_figure14': ['*.csv', '*.npz', '*.mat', '*.m', 'jG8m_simple6_run2/*.mat'],
    },
    include_package_data=True,
    install_requires=[
        'matplotlib>=3.4.3,<3.8.8', 
        'numpy>=1.18.0,<2.0.0',
        'scipy>=1.4.0,<2.0.0',
        'pandas>=1.0.0,<2.0.0',
        'seaborn>=0.11.0,<0.12.0',
        'ptitprince>=0.2.6', 
        'importlib-metadata>=4; python_version < "3.8"',
    ],
    entry_points={
        'console_scripts': [
            'run_figure3_F_G_code=figure3.figure3_F_G_code:main',
            'run_figure4_E_code=figure4.figure4_E_code:main',
            'run_supp_figure8_code=supp_figure8.suppfigure8_code:main',
            'run_supp_figure11_A_code=supp_figure11.suppfigure11_A_code:main',
            'run_supp_figure12_code=supp_figure12.suppfigure12_code:main',
            'run_supp_figure13_C_D_code=supp_figure13.suppfigure13_C_D_code:main',
            'run_supp_figure14_F_G_code=supp_figure14.suppfigure14_F_G_code:main',
        ],
    },
    python_requires='>=3.6',
    zip_safe=False,
)
