from setuptools import setup

setup(
    name="example_pkg",
    version="0.1.0",
    description="A simple Flask application",
    packages=["example_pkg"],
    package_dir={"example_pkg": "src/example_pkg"},
    author="Haitao Pan",
    author_email="manbuzhe2009@qq.com",
    url="https://github.com/scaffolding-design/python.git",
    install_requires=["Flask"],
    tests_require=["pytest", "pytest-cov"],
    package_data={
      "example_pkg": [ "tests/*.py" ],
    },
)
