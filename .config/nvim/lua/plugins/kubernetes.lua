return {
  {
    "h4ckm1n-dev/kube-utils-nvim",
    config = function()
      require("kube-utils-nvim").setup()
    end,
    ft = { "yaml", "json" },
  },
}
