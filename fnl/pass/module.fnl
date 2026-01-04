(local M {})

;; https://oli.me.uk/Guides/Reloadable+Fennel+in+Neovim
(fn M.define [mod-name base]
  "Looks up the mod-name in package.loaded, if it's the same type as base it'll
  use the loaded value. If it's different it'll use base.

  The returned result should be used as your default value for M like so:
  (local M (define :my.mod {}))

  Then return M at the bottom of your file and define functions on M like so:
  (fn M.my-fn [x] (+ x 1))

  This technique helps you have extremely reloadable modules through Conjure.
  You can reload the entire file or induvidual function definitions and the
  changes will be reflected in all other modules that depend on this one
  without having to reload the dependant modules.

  The base value defaults to {}, an empty table."

  (let [loaded (. package.loaded mod-name)]
    (if (and (or (= (type loaded) (type base))
                 (= nil base))
             (not= nil loaded)
             (not= "number" (type loaded)))
      loaded
      (or base {}))))

M
