# Copyright (c) 2016 Bertrand LALLAU
from setuptools import setup

from cov2emacslib import meta

setup(name='cov2emacs',
      version=meta.__version__,
      author=meta.__author__,
      description='FILL IN',
      scripts=['bin/cov2emacs'],
)
