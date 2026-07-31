return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        -- Use a sub-list to run only the first available formatter
      },
      format_on_save = false, -- This ensures it never runs unless you trigger it
    },
  },
}
