from setuptools import setup, find_packages

setup(
    name='figure3_F_G_code',
    version='0.1',
    packages=find_packages(),
    package_data={
        'figure3': ['*.mat', '*.dat'],
        'figure4': ['*.csv'],
        'supp_figure10': ['*.csv'],
    },
    include_package_data=True,
    install_requires=[
        'matplotlib>=3.4.3,<3.8.8', 
        'numpy>=1.18.0,<2.0.0',
        'scipy>=1.4.0,<2.0.0',
        'pandas>=1.0.0,<2.0.0',
        'seaborn>=0.11.0,<0.12.0',
        'ptitprince>=0.2.6', 
    ],
    entry_points={
        'console_scripts': [
            'run_figure3_F_G_code=figure3.figure3_F_G_code:main',
            'run_figure4_E_code=figure4.figure4_E_code:main',
            'run_supp_figure10_A_code=supp_figure10.suppfigure10_A_code:main',
        ],
    },
    python_requires='>=3.6',
)