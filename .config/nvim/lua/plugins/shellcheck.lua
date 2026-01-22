return {
  {
    "creativenull/diagnosticls-configs-nvim",
    ft = { "sh", "bash", "zsh" },
    config = function()
      -- Utilise lspconfig pour shellcheck via diagnostic-languageserver
      require("lspconfig").diagnosticls.setup {
        filetypes = { "sh", "bash", "zsh" },
        init_options = {
          linters = {
            shellcheck = {
              command = "shellcheck",
              rootPatterns = { ".git/" },
              debounce = 100,
              args = { "--format", "json", "-" },
              sourceName = "shellcheck",
              parseJson = {
                errorsRoot = "comments",
                line = "line",
                column = "column",
                endLine = "endLine",
                endColumn = "endColumn",
                message = "message",
                security = "level"
              },
              securities = {
                error = "error",
                warning = "warning",
                info = "info",
                style = "hint"
              }
            }
          },
          filetypes = {
            sh = "shellcheck",
            bash = "shellcheck",
            zsh = "shellcheck"
          }
        }
      }
    end,
  },
}
