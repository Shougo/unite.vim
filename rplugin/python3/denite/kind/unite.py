# ============================================================================
# FILE: unite.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from .base import Base


class Kind(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'unite'
        self.default_action = 'do'

    def action_do(self, context):
        self.vim.call('unite#action#do_candidates', 'default',
                      [x['source__candidate'] for x in context['targets']])
