# ============================================================================
# FILE: unite.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from .base import Base
from copy import copy
from re import sub


class Source(Base):

    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'unite'
        self.kind = 'unite'

    def gather_candidates(self, context):
        if not context['args']:
            return []
        candidates = self.vim.call('unite#get_candidates',
                                   [context['args']])

        # Check multiple unite sources
        is_multiple_sources = len([x for x in context['sources']
                                   if x['name'] == 'unite']) > 1

        # Convert the attributes for compatibility.
        for candidate in candidates:
            candidate['source__candidate'] = copy(candidate)
            candidate['kind'] = 'unite'
            candidate['word'] = sub(r'\n.*', r'', candidate['word'])
            candidate['abbr'] = sub(r'\n.*', r'',
                                    candidate.get('abbr', candidate['word']))
            if is_multiple_sources:
                # Add source prefix
                candidate['abbr'] = (candidate['source'] +
                                     ': ' + candidate['abbr'])
        return candidates
