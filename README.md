# swift-playground-mode

Emacs support for Swift playgrounds. An Emacs port of
[SwiftPlayground.vim](https://github.com/jerrymarino/SwiftPlayground.vim).

![Preview](https://giphy.com/gifs/8FVrviZdJgSV4KWKQw/html5)

## Usage

It compiles the playground when you save or invoke `M-x swift-playground-run`.

*Note: Code Completion optionally powered by
[emacs-ycmd](https://github.com/abingham/emacs-ycmd).*


## Installation

#### Requires

* [swift-mode](https://github.com/swift-emacs/swift-mode)

Autoload using `use-package`:

```Emacs Lisp
(use-package swift-playground-mode :defer t :init
  (autoload 'swift-playground-toggle-if-needed "swift-playground-mode" nil t)
  (add-hook 'swift-mode-hook #'swift-playground-toggle-if-needed))
```

or use:

```Emacs Lisp
(require 'swift-playground-mode)
(swift-playground-setup)
```

## Remaining features

- [ ] Support for inline images and views.
- [ ] Support for creating new playgrounds from Emacs. 	

## Contributing

Contributions welcome!