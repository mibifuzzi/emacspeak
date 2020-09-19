;;; emacspeak.el --- The Complete Audio Desktop  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak: A speech interface to Emacs
;;; Keywords: Emacspeak, Speech, Dectalk,
;;{{{  LCD Archive entry:
;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-07-06 16:33:47 -0700 (Sun, 06 Jul 2008) $ |
;;;  $Revision: 4642 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2018, T. V. Raman
;;; Copyright (c) 1994, 1995 by Digital Equipment Corporation.
;;; All Rights Reserved.
;;;
;;; This file is not part of GNU Emacs, but the same permissions apply.
;;;
;;; GNU Emacs is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; GNU Emacs is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;{{{ Introduction

;;; Commentary:

;;;Emacspeak extends Emacs to be a fully functional audio desktop.
;;; This is the main emacspeak module.
;;; It actually does very little:
;;; It sets up Emacs to load package-specific
;;; Emacspeak modules as each package is loaded.
;;; It implements function emacspeak which loads the rest of the system.

;;; Code:

;;}}}
;;{{{ Required modules

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-sounds)

;;}}}
;;{{{  Customize groups

(defgroup emacspeak nil
  "Emacspeak: The Complete Audio Desktop  "
  :link '(url-link :tag "Web" "http://emacspeak.sf.net"
                   :help-echo "Visit Emacspeak Web Site")
  :link '(url-link :tag "Blog" "http://emacspeak.blogspot.com"
                   :help-echo "Read Emacspeak Blog")
  :link '(url-link :tag "Papers"
                   "http://emacspeak.sf.net/publications"
                   :help-echo "Papers describing Emacspeak
design and implementation.")
  :link '(url-link :tag "Gist" "https://gist.github.com/tvraman"
                   :help-echo "Useful Code Fragments")
  :link '(url-link :tag "Emacs Tour" "http://www.gnu.org/s/emacs/tour/"
                   :help-echo "A guided Tour Of Emacs")
  :link '(url-link :tag "Search"
                   "http://www.cs.vassar.edu/cgi-bin/emacspeak-search"
                   :help-echo "Search Emacspeak mail archive at Vassar.")
  :link '(url-link :tag "Apps"
                   "https://tvraman.github.io/emacspeak/applications.html"
                   :help-echo "Browse available  applications on
the Emacspeak desktop.")
  :link '(url-link :tag "Guide"
                   "https://tvraman.github.io/emacspeak/manual"
                   :help-echo "Read online user guide.")
  :link '(url-link :tag "Tips"
                   "https://tvraman.github.io/emacspeak/tips.html"
                   :help-echo "Read Emacspeak Tips and Tricks.")
  :link   (list 'file-link :tag "NEWS" (expand-file-name
                                        "etc/NEWS"
                                        emacspeak-directory)
                :help-echo "What's New In This Release")
  :link '(custom-manual "(emacspeak)Top")
;;; end links
  :prefix "emacspeak-"
  :group 'applications
  :group 'accessibility)

;;}}}
;;{{{ Package Setup Helper

(defsubst emacspeak-do-package-setup (package module)
  "Setup Emacspeak extension for a specific PACKAGE.
This function adds the appropriate form to `after-load-alist' to
set up Emacspeak support for a given package.  Argument MODULE (a
symbol)specifies the emacspeak module that implements the
speech-enabling extensions for `package' (a string)."
  (with-eval-after-load package (require module)))

;;; DocView
(declare-function doc-view-open-text "doc-view")
(with-eval-after-load "doc-view"
  (add-hook 'doc-view-mode-hook #'doc-view-open-text))

;;; subr.el

;;}}}
;;{{{ Setup package extensions
(defvar emacspeak-packages-to-prepare
  '(
    ("2048-game" emacspeak-2048)
    ("abc-mode" emacspeak-abc-mode)
    ("add-log" emacspeak-add-log)
    ("analog" emacspeak-analog)
    ("ansi-color" emacspeak-ansi-color)
    ("apt-sources" emacspeak-apt-sources)
    ("arc-mode" emacspeak-arc)
    ("bbdb" emacspeak-bbdb)
    ("bibtex" emacspeak-bibtex)
    ("bookmark" emacspeak-bookmark)
    ("browse-kill-ring" emacspeak-browse-kill-ring)
    ("bs" emacspeak-bs)
    ("buff-menu" emacspeak-buff-menu)
    ("calc" emacspeak-calc)
    ("calculator" emacspeak-calculator)
    ("calendar" emacspeak-calendar)
    ("cc-mode" emacspeak-c)
    ("checkdoc" emacspeak-checkdoc)
    ("chess" emacspeak-chess)
    ("cider" emacspeak-cider)
    ("ciel" emacspeak-ciel)
    ("clojure" emacspeak-clojure)
    ("cmuscheme" emacspeak-cmuscheme)
    ("company" emacspeak-company)
    ("compile" emacspeak-compile)
    ("cperl-mode" emacspeak-cperl)
    ("cus-edit" emacspeak-custom)
    ("deadgrep" emacspeak-deadgrep)
    ("debugger" emacspeak-debugger)
    ("desktop" emacspeak-desktop)
    ("dictionary" emacspeak-dictionary)
    ("diff-mode" emacspeak-diff-mode)
    ("dired" emacspeak-dired)
    ("dismal" emacspeak-dismal)
    ("doctor" emacspeak-entertain)
    ("dumb-jump" emacspeak-dumb-jump)
    ("dunnet" emacspeak-entertain)
    ("ecb" emacspeak-ecb)
    ("eclim" emacspeak-eclim)
    ("ediary" emacspeak-ediary)
    ("ediff" emacspeak-ediff)
    ("eglot" emacspeak-eglot)
    ("ein" emacspeak-ein)
    ("ein-notebook" emacspeak-ein)
    ("elfeed" emacspeak-elfeed)
    ("elisp-refs" emacspeak-elisp-refs)
    ("elpy" emacspeak-elpy)
    ("elscreen" emacspeak-elscreen)
    ("emms" emacspeak-emms)
    ("enriched" emacspeak-enriched)
    ("epa" emacspeak-epa)
    ("eperiodic" emacspeak-eperiodic)
    ("erc" emacspeak-erc)
    ("eshell" emacspeak-eshell)
    ("ess" emacspeak-ess)
    ("eudc" emacspeak-eudc)
    ("evil" emacspeak-evil)
    ("eww" emacspeak-eww)
    ("find-func" emacspeak-find-func)
    ("flycheck" emacspeak-flycheck)
    ("flymake" emacspeak-flymake)
    ("flyspell" emacspeak-flyspell)
    ("folding" emacspeak-folding)
    ("forge" emacspeak-forge)
    ("forms" emacspeak-forms)
    ("gdb-ui" emacspeak-gud)
    ("geiser" emacspeak-geiser)
    ("generic" emacspeak-generic)
    ("github-explorer" emacspeak-gh-explorer)
    ("gnuplot" emacspeak-gnuplot)
    ("gnus" emacspeak-gnus)
    ("go-mode" emacspeak-go-mode)
    ("gomoku" emacspeak-gomoku)
    ("gtags" emacspeak-gtags)
    ("gud" emacspeak-gud)
    ("hangman" emacspeak-entertain)
    ("helm" emacspeak-helm)
    ("hide-lines" emacspeak-hide-lines)
    ("hideshow" emacspeak-hideshow)
    ("hydra" emacspeak-hydra)
    ("ibuffer" emacspeak-ibuffer)
    ("ido" emacspeak-ido)
    ("iedit" emacspeak-iedit)
    ("imenu" emacspeak-imenu)
    ("indium" emacspeak-indium)
    ("info" emacspeak-info)
    ("ispell" emacspeak-ispell)
    ("ivy" emacspeak-ivy)
    ("jabber" emacspeak-jabber)
    ("jdee" emacspeak-jdee)
    ("js2-mode" emacspeak-js2)
    ("kmacro" emacspeak-kmacro)
    ("lispy" emacspeak-lispy)
    ("lua-mode" emacspeak-lua)
    ("magit" emacspeak-magit)
    ("make-mode" emacspeak-make-mode)
    ("man" emacspeak-man)
    ("markdown-mode" emacspeak-markdown)
    ("message" emacspeak-message)
    ("meta-mode" emacspeak-metapost)
    ("midge-mode" emacspeak-midge)
    ("mines" emacspeak-mines)
    ("mpuz" emacspeak-entertain)
    ("mspools" emacspeak-mspools)
    ("muse-mode" emacspeak-muse)
    ("navi-mode" emacspeak-navi-mode)
    ("net-utils" emacspeak-net-utils)
    ("newsticker" emacspeak-newsticker)
    ("nov" emacspeak-nov)
    ("nxml-mode" emacspeak-nxml)
    ("org" emacspeak-org)
    ("orgalist" emacspeak-orgalist)
    ("origami" emacspeak-origami)
    ("outline" emacspeak-outline)
    ("package"emacspeak-package)
    ("paradox"emacspeak-paradox)
    ("pcvs" emacspeak-pcl-cvs)
    ("perl-mode" emacspeak-perl)
    ("php-mode" emacspeak-php-mode)
    ("pianobar" emacspeak-pianobar)
    ("popup" emacspeak-popup)
    ("proced" emacspeak-proced)
    ("project" emacspeak-project)
    ("projectile" emacspeak-projectile)
    ("pydoc" emacspeak-pydoc)
    ("python" emacspeak-python)
    ("python-mode" emacspeak-py)
    ("racer" emacspeak-racer)
    ("racket-mode" emacspeak-racket)
    ("re-builder" emacspeak-re-builder)
    ("reftex" emacspeak-reftex)
    ("related" emacspeak-related)
    ("rg" emacspeak-rg)
    ("rmail" emacspeak-rmail)
    ("rpm-spec-mode" emacspeak-rpm-spec)
    ("rst" emacspeak-rst)
    ("ruby-mode" emacspeak-ruby)
    ("rust-mode" emacspeak-rust-mode)
    ("sage-shell-mode" emacspeak-sage)
    ("sdcv" emacspeak-sdcv)
    ("semantic" emacspeak-cedet)
    ("ses" emacspeak-ses)
    ("sgml-mode" emacspeak-sgml-mode)
    ("sh-script" emacspeak-sh-script)
    ("shx" emacspeak-shx)
    ("sigbegone" emacspeak-sigbegone)
    ("slime" emacspeak-slime)
    ("smart-window" emacspeak-smart-window)
    ("smartparens" emacspeak-smartparens)
    ("solitaire" emacspeak-solitaire)
    ("speedbar" emacspeak-speedbar)
    ("sql" emacspeak-sql)
    ("sudoku" emacspeak-sudoku)
    ("supercite" emacspeak-supercite)
    ("syslog" emacspeak-syslog)
    ("tab-bar" emacspeak-tab-bar)
    ("table" emacspeak-etable)
    ("tar-mode" emacspeak-tar)
    ("tcl" emacspeak-tcl)
    ("tempo" emacspeak-tempo)
    ("term" emacspeak-eterm)
    ("tetris" emacspeak-tetris)
    ("tex-site" emacspeak-auctex)
    ("texinfo" emacspeak-texinfo)
    ("threes" emacspeak-threes)
    ("tide" emacspeak-tide)
    ("todo-mode" emacspeak-todo-mode)
    ("transient" emacspeak-transient)
    ("twittering-mode" emacspeak-twittering)
    ("typo" emacspeak-typo)
    ("vdiff" emacspeak-vdiff)
    ("view" emacspeak-view)
    ("vm" emacspeak-vm)
    ("vuiet" emacspeak-vuiet)
    ("wdired" emacspeak-wdired)
    ("wid-edit" emacspeak-widget)
    ("widget" emacspeak-widget)
    ("windmove" emacspeak-windmove)
    ("winring" emacspeak-winring)
    ("woman" emacspeak-woman)
    ("xkcd" emacspeak-xkcd)
    ("xref" emacspeak-xref)
    ("yaml-mode" emacspeak-yaml)
    ("yasnippet" emacspeak-yasnippet)
    ("ytel" emacspeak-ytel))
  "Packages to prepare Emacs to speech-enable.")

(defun emacspeak-prepare-emacs ()
  "Prepare Emacs to speech-enable packages as they are loaded."
  (cl-declare (special emacspeak-packages-to-prepare))
  (mapc
   #'(lambda (pair)
       (emacspeak-do-package-setup  (cl-first pair) (cl-second pair)))
   emacspeak-packages-to-prepare))

;;}}}
;;{{{ setup programming modes

;;; turn on automatic voice locking , split caps and punctuations in
;;; programming  modes

;;;###autoload
(defun emacspeak-setup-programming-mode ()
  "Setup programming mode.
Turns on audio indentation and sets
punctuation mode to all, activates the dictionary and turns on split
caps."
  (cl-declare (special dtk-split-caps emacspeak-audio-indentation))
  (ems-with-messages-silenced
      (dtk-set-punctuations 'all)
    (or dtk-split-caps (dtk-toggle-split-caps))
    (emacspeak-pronounce-refresh-pronunciations)
    (or emacspeak-audio-indentation (emacspeak-toggle-audio-indentation))))

(defsubst emacspeak-setup-programming-modes ()
  "Setup programming modes."
  (add-hook 'prog-mode-hook #'emacspeak-setup-programming-mode)
  (mapc
   #'(lambda (hook)
       (add-hook hook #'emacspeak-setup-programming-mode))
   '(
     conf-unix-mode-hook html-helper-mode-hook
     markdown-mode-hook muse-mode-hook
     sgml-mode-hook xml-mode-hook nxml-mode-hook xsl-mode-hook
     TeX-mode-hook LaTeX-mode-hook bibtex-mode-hook)))

;;}}}
;;{{{ exporting emacspeak environment to subprocesses

(defsubst emacspeak-export-environment ()
  "Export shell environment.
This exports emacspeak's system variables to the environment
so it can be passed to subprocesses."
  (cl-declare (special emacspeak-directory emacspeak-play-program
                       emacspeak-sounds-directory))
  (setenv "EMACSPEAK_DIR" emacspeak-directory)
  (setenv "EMACSPEAK_SOUNDS_DIR" emacspeak-sounds-directory)
  (setenv "EMACSPEAK_PLAY_PROGRAM" emacspeak-play-program))

;;}}}
;;{{{ Emacspeak:

(defcustom emacspeak-play-emacspeak-startup-icon t
  "If set to T, emacspeak plays its icon as it launches."
  :type 'boolean
  :group 'emacspeak)

(defsubst emacspeak-play-startup-icon ()
  "Play startup icon if requested."
  (cl-declare (special emacspeak-play-emacspeak-startup-icon
                       emacspeak-m-player-program))
  (when (and  emacspeak-play-emacspeak-startup-icon emacspeak-m-player-program)
      (start-process
       "mp3" nil
       emacspeak-m-player-program
       (expand-file-name "emacspeak.mp3"
                         emacspeak-sounds-directory))))

(defvar emacspeak-startup-message
  (format
   "  Press %s to get an   overview of emacspeak  %s. \
 I am  completely operational,  and all my circuits are functioning perfectly!"
   (substitute-command-keys
    "\\[emacspeak-describe-emacspeak]")
   emacspeak-version)
  "Emacspeak startup message.")
;;;###autoload
(defun emacspeak()
  "Start the Emacspeak Audio Desktop.
Use Emacs as you normally would,
emacspeak will provide you spoken feedback as you work.  Emacspeak also
provides commands for having parts of the current buffer, the
mode-line etc to be spoken.

If you are hearing this description as a result of pressing
\\[emacspeak-describe-emacspeak] you may want to press use the
arrow keys to move around in the Help buffer to read the rest of
this description, which includes a summary of all emacspeak
keybindings.

All emacspeak commands use \\[emacspeak-prefix-command] as a prefix
key.  You can also set the state of the TTS engine by using
\\[emacspeak-dtk-submap-command] as a prefix.  Here is a summary of all
emacspeak commands along with their bindings.  You need to precede the
keystrokes listed below with \\[emacspeak-prefix-command].

Emacspeak also provides a fluent speech extension to the Emacs
terminal emulator (eterm).  Note: You need to use the term package that
comes with emacs-19.29 and later.

\\{emacspeak-keymap}

Emacspeak provides a set of additional keymaps to give easy access to
its extensive facilities.

Press C-; to access keybindings in emacspeak-hyper-keymap:
\\{emacspeak-hyper-keymap}.

Press C-' or C-.  to access keybindings in emacspeak-super-keymap:
\\{emacspeak-super-keymap}.

Press C-, to access keybindings in emacspeak-alt-keymap:
\\{emacspeak-alt-keymap}.

See the online documentation \\[emacspeak-open-info] for individual
commands and options for details."
  (setq-default line-move-visual nil)
  (setq use-dialog-box nil)
  (when (boundp 'Info-directory-list)
    (push emacspeak-info-directory Info-directory-list))
  (dtk-initialize)
  (emacspeak-pronounce-load-dictionaries)
  (require 'emacspeak-advice)
  (emacspeak-sounds-define-theme emacspeak-sounds-default-theme ".wav")
  (emacspeak-setup-programming-modes)
  (fset 'blink-matching-open (symbol-function 'emacspeak-blink-matching-open))
  (make-thread #'emacspeak-prepare-emacs)
  (tts-with-punctuations 'some (dtk-speak-and-echo emacspeak-startup-message))
  (emacspeak-play-startup-icon)
  (run-hooks 'emacspeak-startup-hook))

(defun emacspeak-describe-emacspeak ()
  "Give a brief overview of emacspeak."
  (interactive)
  (describe-function 'emacspeak)
  (switch-to-buffer "*Help*")
  (dtk-set-punctuations 'all)
  (emacspeak-speak-buffer))

;;}}}
;;{{{  Submit bugs

(defconst emacspeak-bug-address
  "emacspeak@cs.vassar.edu"
  "Address for bug reports and questions.")

(defun emacspeak-submit-bug ()
  "Function to submit a bug to the programs maintainer."
  (interactive)
  (require 'reporter)
  (when
      (yes-or-no-p "Are you sure you want to submit a bug report? ")
    (let (
          (vars '(
                  emacs-version
                  system-type
                  emacspeak-version  dtk-program
                  dtk-speech-rate dtk-character-scale
                  dtk-split-caps dtk-capitalize
                  dtk-punctuation-mode
                  emacspeak-line-echo  emacspeak-word-echo
                  emacspeak-character-echo
                  emacspeak-use-auditory-icons
                  emacspeak-audio-indentation)))
      (mapcar
       #'(lambda (x)
           (if (not (and (boundp x) (symbol-value x)))
               (setq vars (delq x vars))))vars)
      (reporter-submit-bug-report
       emacspeak-bug-address
       (concat "Emacspeak Version: " emacspeak-version)
       vars
       nil nil
       "Description of Problem:"))))

;;}}}
(provide 'emacspeak)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}

;;; emacspeak.el ends here
