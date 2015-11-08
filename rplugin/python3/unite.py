#=============================================================================
# FILE: unite.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license  {{{
#     Permission is hereby granted, free of charge, to any person obtaining
#     a copy of this software and associated documentation files (the
#     "Software"), to deal in the Software without restriction, including
#     without limitation the rights to use, copy, modify, merge, publish,
#     distribute, sublicense, and/or sell copies of the Software, and to
#     permit persons to whom the Software is furnished to do so, subject to
#     the following conditions:
#
#     The above copyright notice and this permission notice shall be included
#     in all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# }}}
#=============================================================================

import neovim
import traceback
import subprocess
# import time

@neovim.plugin
class UniteHandlers(object):
    def __init__(self, vim):
        self.vim = vim

    def error(self, msg):
        self.vim.call('unite#util#print_error', msg)

    @neovim.command('UniteInitializePython', sync=True, nargs=0)
    def init_python(self):
        self.vim.vars['unite#_channel_id'] = self.vim.channel_id

    @neovim.rpc_export('unite_rec')
    def unite_rec(self, context, commands):
        try:
            # start = time.time()
            candidates = [{ 'word': x, 'action__path': x }
                          for x in subprocess.check_output(commands).decode(
                                  'utf-8').split('\n')]
            # self.error(str(time.time() - start))
            # start = time.time()
            self.vim.call('unite#sources#rec#_remote_append', candidates, 1)
            # self.error(str(time.time() - start))
        except Exception:
            for line in traceback.format_exc().splitlines():
                 self.error(line)
            self.error('An error has occurred. Please execute :messages command.')
            self.vim.call('unite#sources#rec#_remote_append', [], 1)

