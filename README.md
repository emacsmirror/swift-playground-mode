# swift-playground-mode

Emacs support for Swift playgrounds. An Emacs port of
[SwiftPlayground.vim](https://github.com/jerrymarino/SwiftPlayground.vim).

![Preview](https://camo.githubusercontent.com/302bc851794052507f85e73be3fa92f723329b76/68747470733a2f2f692e696d6775722e636f6d2f4c62413143536a2e676966)

## Usage

It compiles the playground when you save or invoke `M-x swift-playground-run`.

*Note: Code Completion optionally powered by
[emacs-ycmd](https://github.com/abingham/emacs-ycmd).*


## Installation

#### Requires

* [swift-mode](https://github.com/swift-emacs/swift-mode)

Autoload using `use-package`:

```
(use-package swift-playground-mode :defer t :init
  (autoload 'swift-playground-toggle-if-needed "swift-playground-mode" nil t)
  (add-hook 'swift-mode-hook #'swift-playground-toggle-if-needed))
```

or use:

```
(require 'swift-playground-mode)
(swift-playground-setup)
```

## Building Locally

To build the package locally, install [Cask](https://github.com/cask/cask) and
run `make package install`.

## Remaining features

- [ ] Support for inline images and views.
- [ ] Support for creating new playgrounds from Emacs. 	

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can
help:

- [Report bugs](https://gitlab.com/michael.sanders/swift-playground-mode/issues).
- Fix bugs and [submit pull requests](https://gitlab.com/michael.sanders/swift-playground-mode/merge_requests).
- Write, clarify, or fix documentation.
- Suggest or add new features.
