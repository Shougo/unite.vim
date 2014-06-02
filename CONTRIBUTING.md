## Reporting an issue

When you report an issue, please use the following issue template.

    * Problems summary

    * Expected

    * Environment Information
     * OS:
     * Vim version:

    * Minimal vimrc less than 50 lines

    ```VimL
    " Your vimrc
    set nocompatible

    set runtimepath+=~/path/to/unite.vim/
    ```

    * How to reproduce

     0. startup vim (Write with option arguments if necessary).
     1.
     2.
     3.

    * Screen shot (if possible)

### Example

* Problems summary

  file/new doesn't work on windows.

* Expected

  I want to save the file there is a space.

* Environment Information
  * OS:Windows7 64bit
  * Vim version:Vim 7.4.111

* Minimal vimrc less than 50 lines

  ```VimL
  " minimal.vimrc
  if has('vim_starting')
  set nocompatible
  set runtimepath+=~/.cache/neobundle/unite.vim/
  endif
  ```

* How to reproduce

  0. startup vim: `vim -u minimal.vimrc`
  1. `:Unite file/new`.
  2. Input `C:/Foo\ Bar/test.txt`
  3. Enter candidate.
  4. `:w`
  5. Can not be saved.
