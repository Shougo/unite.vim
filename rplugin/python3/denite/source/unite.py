# ============================================================================
# FILE: unite.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from .base import Base


class Source(Base):

    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'unite'

    def gather_candidates(self, context):
        if not context['args']:
            return []
        candidates = self.vim.call('unite#get_candidates',
                                   [context['args'][0]])

        # Convert the attributes for compatibility.
        for candidate in candidates:
            if candidate['kind'] == 'jump_list':
                candidate['kind'] = 'file'
        return candidates
