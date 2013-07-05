Vim-indent
==========

Sick and tired of managing freaking whitespace? This plugin picks the correct
`shiftwidth`, `tabstop`, `expandtab` and `softtabstop` values for you! These
settings make sure that your source code is indented correctly.

It is partly based on tpope's vim-sleuth_ and detectindent_ but works differently:

* The following settings are preferred in an ambigious situation:
  `shiftwidth=4` & `tabstop=4` (1 tab = 4 spaces), `expandtab` (use spaces
  over real tabs).
* Like vim-sleuth_ neighboring files of the same type are searched if the current file is new.
* It allows you to define a custom command to be executed when detection completely
  fails (f.e. `let g:default_indent_php="setl sw=2"`)

Apart from using an indentation guesser like this, another option to consider is to
use project-specific-settings_.

.. _vim-sleuth: https://github.com/tpope/vim-sleuth
.. _detectindent: https://github.com/vim-scripts/DetectIndent
.. _project-specific-settings: http://vim.wikia.com/wiki/Project_specific_settings
