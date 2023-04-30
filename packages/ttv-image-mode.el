;;; ttv-image-mode.el --- Display (some) TTV emotes as inline images -*- lexical-binding: t -*-

;; Author: Rylan Lens Kellogg
;; Maintainer: Rylan Lens Kellogg
;; Version: 0.0.1
;; Package-Requires: (dependencies)
;; Keywords: Images Twitch.tv


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; KEKW

;; NOTE: According to the license this repo is distributed under, it's
;; not really lawful for me to distribute the emoji images that are
;; supposed to be in the `emotes` subdirectory at the time of loading.
;; You can view this as a plus: you get to choose custom emote images
;; to display in *your* Emacs Twitch Chat. Downside is it can be kind
;; of annoying to find good images, so here's a few suggestions on
;; where one might get images *for personal use*.
;;   https://emoji.gg/
;;   https://discadia.com/emojis/

;; For use in ERC twitch chat: (setq ttv-image-mode-erc-refresh t)

;;; Code:

(require 'iimage)


;; REDEFINE iimage-mode-buffer with `(goto-char (point-min))` in proper place.
(defun iimage-mode-buffer (arg)
  "Display images if ARG is non-nil, undisplay them otherwise."
  (let ((image-path (cons default-directory iimage-mode-image-search-path))
        (edges (window-inside-pixel-edges (get-buffer-window)))
	    file)
    (with-silent-modifications
      (save-excursion
        (dolist (pair iimage-mode-image-regex-alist)
          (goto-char (point-min))
          (while (re-search-forward (car pair) nil t)
            (when (and (setq file (match-string (cdr pair)))
                       (setq file (locate-file file image-path)))
              ;; FIXME: we don't mark our images, so we can't reliably
              ;; remove them either (we may leave some of ours, and we
              ;; may remove other packages's display properties).
              (if arg
                  (add-text-properties
                   (match-beginning 0) (match-end 0)
                   `(display
                     ,(create-image file nil nil
                                    :max-width (- (nth 2 edges) (nth 0 edges))
				                    :max-height (- (nth 3 edges) (nth 1 edges)))
                     keymap ,image-map
                     modification-hooks
                     (iimage-modification-hook)))
                (remove-list-of-text-properties
                 (match-beginning 0) (match-end 0)
                 '(display modification-hooks))))))))))



(defvar ttv-image-mode--enabled nil)

(defvar ttv-image-mode-erc-refresh t
  "When non-nil, add redraw function to ERC timer hook, so new messages will be emotized.")

(defvar ttv-image-mode-emotes-directory `(,(expand-file-name "emotes"))
  "A directory that will be searched for emote images.
You probably need to set this as an absolute path to the included `emotes` directory.")

(defun ttv-image-mode--redraw (&optional ARG)
  "Redraw images, when enabled."
  (interactive "P")
  (when ttv-image-mode--enabled
    (let ((case-fold-search nil))
      (save-mark-and-excursion
        (goto-char (point-min))
        (iimage-mode-buffer 0)
        (iimage-mode-buffer 1)))))

(defun ttv-image-mode--enable (&optional ARG)
  "Enable ttv-image-mode."
  (interactive "P")
  (when (not ttv-image-mode--enabled)
    (setq-local iimage-mode-image-search-path `(,@ttv-image-mode-emotes-directory))
    ;; TODO: Build this regexp list from the emotes directory.
    ;; TODO: Maybe have alist of regex -> image?
    ;; TODO: ferrisClueless
    (setq-local
     iimage-mode-image-regex-alist
     '(("HeyGuys" . 0)
       ("Kappa" . 0)
       ("KEKW" . 0)
       ("GOPIUM" . 0)
       ("LULW" . 0)
       ("monkaS" . 0)
       ("OMEGALUL" . 0)
       ("POGGERS" . 0)
       ("Pog" . 0)
       ("PressF" . 0)
       ("TRIGGERED" . 0)
       ("WaitWhat" . 0)
       ("eyes" . 0)
       ))
    (let ((case-fold-search nil))
      (iimage-mode 1))
    (when ttv-image-mode-erc-refresh
      (add-hook 'erc-send-post-hook 'ttv-image-mode--redraw)
      (add-hook 'erc-insert-post-hook 'ttv-image-mode--redraw))
    (setq-local ttv-image-mode--enabled t)
    (message "%s" "ttv-image-mode enabled")))

(defun ttv-image-mode--disable (&optional ARG)
  "Disable ttv-image-mode."
  (interactive "P")
  (when ttv-image-mode--enabled
    (let ((case-fold-search nil))
      (iimage-mode-buffer 0)
      (iimage-mode 0))
    (kill-local-variable 'iimage-mode-image-search-path)
    (kill-local-variable 'iimage-mode-image-regex-alist)
    (remove-hook 'erc-send-post-hook 'ttv-image-mode--redraw)
    (remove-hook 'erc-insert-post-hook 'ttv-image-mode--redraw)
    (setq-local ttv-image-mode--enabled nil)
    (message "%s" "ttv-image-mode disabled")))

(define-minor-mode ttv-image-mode
  "Display some twitch emotes as inline images"
  :lighter "TTV"
  :group lens
  (if ttv-image-mode
      (ttv-image-mode--enable)
    (ttv-image-mode--disable)))

(provide 'ttv-image-mode)

;;; ttv-image-mode.el ends here
