;;; voice-setup.el --- Setup voices for voice-lock  -*- lexical-binding: t; -*-
;; $Author: tv.raman.tv $
;; Description:  Voice lock mode for Emacspeak
;;;   LCD Archive entry:

;; LCD Archive Entry:
;; emacspeak| T. V. Raman |tv.raman.tv@gmail.com
;; A speech interface to Emacs |
;; 
;;  $Revision: 4672 $ |
;; Location https://github.com/tvraman/emacspeak
;; 

;;;   Copyright:

;; Copyright (C) 1995 -- 2024, T. V. Raman
;; Copyright (c) 1994, 1995 by Digital Equipment Corporation.
;; All Rights Reserved.
;; 
;; This file is not part of GNU Emacs, but the same permissions apply.
;; 
;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;; 
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; A voice is to audio as a font is to a visual display.
;; A personality is to audio as a face is to a visual display.
;; 
;; Voice-lock-mode is a minor mode that causes your comments to be
;; spoken in one personality, strings in another, reserved words in another,
;; documentation strings in another, and so on.
;; 
;; Comments will be spoken in `voice-comment-personality'.
;; Strings will be spoken in `voice-string-personality'.
;; Function  (in their defining forms) will be
;;  spoken in `voice-function-name-personality'.
;; Reserved words will be spoken in `voice-keyword-personality'.
;; 
;; To audio-format  text , use M-x voice-lock-mode.
;; When this minor mode is on, the voices of the current line are
;; updated with every insertion or deletion.
;; 
;; @subsection Voice-Lock And Aural CSS
;; The CSS Speech Style Sheet specification defines a number of
;; abstract device independent voice properties.
;; A setting conforming to the CSS speech specification can be
;; represented in elisp as a structure.
;; 
;; We will refer to this structure as a "speech style".  This
;; structure needs to be mapped to device dependent codes to produce
;; the desired effect.  This module forms a bridge between emacs
;; packages    that wish to implement audio formatting
;; and Emacspeak's TTS module.  Emacspeak produces voice
;; change effects by examining the value of text-property
;; 'personality', as well as the face/font at point.
;; 
;; Think of a buffer of formatted text along with the text-property
;; 'personality appropriately set as a "aural display list".  Module
;; voice-setup.el help applications like EWW produce audio-formatted
;; output by calling function voice-from-acss with
;; a "speech-style" --a structure as defined in this module and get
;; back a symbol that they assign to the value of property
;; 'personality.  Emacspeak's rendering engine then does the needful
;; at the time speech is produced.  Function
;; voice-from-acss does the following: Takes as
;; input a "speech style" (1) Computes a symbol that will be used to
;; refer to this specific speech style.  (2) Examines emacspeak's
;; internal voice table to see if this speech style has a voice
;; already defined.  If so it returns immediately.  Otherwise, it
;; does the additional work of defining a -voice for future use.  See
;; its use in this module to see how voices are defined independent
;; of a given TTS engine.  How faces map to voices: TTS engine
;; specific modules e.g., dectalk-voices.el and outloud-voices.el map
;; ACSS dimensions to engine-specific codes.  Emacspeak modules use
;; voice-setup-add-map when defining face->personality mappings.  For
;; use from other modules.

;;; Code:

;;  Required modules: 

(eval-when-compile (require 'cl-lib))
(require 'dtk-speak)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(eval-when-compile (require 'easy-mmode))

;;;  customization group

(defgroup voice-fonts nil
  "Voices"
  :group 'emacspeak)

;;; Configure:

;; This configures Emacspeak for the TTS engine used at start.
;; Subsequent switches to other engines  causes that engine to get
;; configured --- see the various tts-engine startup  commands, e.g.,
;; outloud, dectalk, espeak.
;; Whenever we switch engines, we load voice-definitions for that
;; engine by reloading module voice-defs.
(cl-declaim (special dtk-program))

(cl-defstruct (acss
               (:predicate nil) ;; Don't make a predicate we don't need.
               (:copier nil))   ;; Don't make a copier we don't need.
  family average-pitch pitch-range stress richness)

(defun voice-setup ()
  "Setup voices for selected TTS engine."
  (cond
   ((string-match "outloud" dtk-program)
    (require 'outloud-voices)
    (outloud-configure-tts))
   ((string-match "dtk" dtk-program)
    (require 'dectalk-voices)
    (dectalk-configure-tts))
   ((string-match "swiftmac" dtk-program)
    (require 'swiftmac-voices)
    (swiftmac-configure-tts))
   ((string-match "mac\\'" dtk-program)
    (require 'mac-voices)
    (mac-configure-tts))
   ((string-match "espeak\\'" dtk-program)
    (require 'espeak-voices)
    (espeak-configure-tts))
   (t
    (require 'plain-voices)
    (plain-configure-tts)))
  (ems--fastload "voice-defs"))

(defun voice-from-acss (style)
  "Compute a  name for this STYLE.
Define a voice for it if needed, then return the symbol."
  (let ((f (acss-family style))
        (a (acss-average-pitch style))
        (p (acss-pitch-range style))
        (s (acss-stress style))
        (r (acss-richness style))
        (name nil))
    (setq name
          (intern
           (format "acss%s%s%s%s%s"
                   (if f (format "-%s" f) "")
                   (if a (format "-a%s" a) "")
                   (if p (format "-p%s" p) "")
                   (if s (format "-s%s" s) "")
                   (if r (format "-r%s" r) ""))))
    (unless (tts-voice-defined-p name)
      (tts-define-voice-from-acss name style))
    name))

;;;  map faces to voices

(defvar voice-setup-face-voice-table (make-hash-table :test #'eq)
  "Face to voice mapping.")

(defsubst voice-setup-set-voice-for-face (face voice)
  "Map face  to  voice."
  (cl-declare (special  voice-setup-face-voice-table))
  (setf (gethash face voice-setup-face-voice-table) voice))

(defsubst voice-setup-get-voice-for-face (face)
  "Return face to  voice."
  (cl-declare (special  voice-setup-face-voice-table))
  (gethash face voice-setup-face-voice-table))

(defun voice-setup-add-map (fv-alist)
  "Sets up face to voice mapping given in fv-alist."
  (cl-loop
   for fv in fv-alist
   do
   (voice-setup-set-voice-for-face (cl-first fv) (cl-second fv))))

;;;   special form defvoice

(defun voice-setup-acss-from-style (style-list)
  "Define an ACSS-voice  from   speech style."
  (let ((voice
         (voice-from-acss
          (make-acss
           :family (nth 0 style-list)
           :average-pitch (nth 1 style-list)
           :pitch-range (nth 2 style-list)
           :stress (nth 3 style-list)
           :richness (nth 4  style-list)))))
    voice))

(defmacro defvoice (voice settings)
  "Define voice using ACSS setting.  Setting is a list ---
(list paul 5 5 5 5) for  the standard male voice.  It can
 be customized by  \\[customize-variable] on
 <voice>-settings. "
  (declare (indent 1) (debug t))
  `(progn
     (defvar  ,voice
       (voice-setup-acss-from-style ,settings)
       ,(format "Customize  via %s-settings." voice))
     (defcustom ,(intern (format "%s-settings"  voice))
       ,settings
       ,(format "Settings for %s" voice)
       :type
       '(list
         (const :tag "Unspecified" nil)
         (choice :tag "Average Pitch"
                 (const :tag "Unspecified" nil)
                 (integer :tag "Number"))
         (choice :tag "Pitch Range"
                 (const :tag "Unspecified" nil)
                 (integer :tag "Number"))
         (choice :tag "Stress"
                 (const :tag "Unspecified" nil)
                 (integer :tag "Number"))
         (choice :tag "Richness"
                 (const :tag "Unspecified" nil)
                 (integer :tag "Number")))
       :group 'voice-fonts
       :set
       #'(lambda  (sym val)
           (setq ,voice (voice-setup-acss-from-style val))
           (set-default sym val)))))

;;;  new light-weight voice lock
(declare-function emacspeak-icon "emacspeak-sounds" (icon))


(define-minor-mode voice-lock-mode
  "Toggle voice lock mode."
  :init-value t
  :keymap nil
  (when (called-interactively-p 'interactive)
    (let ((state (if voice-lock-mode 'on 'off)))
      (emacspeak-icon state))))

(defun voice-lock-mode--turn-on ()
  "Turn on Voice Lock mode ."
  (interactive)
  (voice-lock-mode))

(define-globalized-minor-mode global-voice-lock-mode
  voice-lock-mode
  voice-lock-mode--turn-on
  :init-value t
  :group 'voice-lock
  (when (called-interactively-p 'interactive)
    (let ((state (if global-voice-lock-mode 'on 'off)))
      (emacspeak-icon state)))
  )

;; Install ourselves:
(cl-declaim (special text-property-default-nonsticky))
(unless (assq 'personality text-property-default-nonsticky)
  (push  (cons 'personality t) text-property-default-nonsticky))

(unless (assq 'voice-lock-mode minor-mode-alist)
  (setq minor-mode-alist (cons '(voice-lock-mode " Voice") minor-mode-alist)))

;;;  interactively silence personalities

(defvar  voice-setup-local-map (make-hash-table :test #'eq)
  "Buffer local face->personality.")
;; We toggle audibility at point by:
;; If face at point is currently audible, its face->personality
;; map is cached in hash-table voice-setup-local-map, and its
;; face->personality map is updated to be inaudible.
;; If personality at point is inaudible, and there is a cached value,
;; then the original face->personality mapping is restored from the
;; cached value.


(defun voice-setup-toggle-silence-personality ()
  "Toggle audibility of personality under point  . "
  (interactive)
  (cl-declare (special voice-setup-local-map))
  (let* ((face (get-text-property (point) 'face))
         (f (if (listp face)   (cl-first face)face))
         (personality (voice-setup-get-voice-for-face f))
         (orig (gethash f voice-setup-local-map)))
    (cond
     ((null personality) (message "No personality here."))
     ((and orig (eq personality  'inaudible))  ; currently inaudible,
      (voice-setup-set-voice-for-face f  orig) ; restore orig
      (remhash f voice-setup-local-map)        ; clean cache
      (message "Made face %s audible." f)
      (emacspeak-icon 'item))
     (t
      (voice-setup-set-voice-for-face f  'inaudible) ; update
      (puthash f personality voice-setup-local-map)  ; cache
      (message "Silenced face %s" f)
      (emacspeak-icon 'close-object)))))

(provide 'voice-setup)
;;;  end of file

