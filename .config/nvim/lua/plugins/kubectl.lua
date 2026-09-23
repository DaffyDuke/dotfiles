return {
  {
    "ramilito/kubectl.nvim",
    version = "2.*",
    cmd = { "Kubectl", "Kubectx", "Kubens" },
    keys = {
      {
        "<leader>k",
        function()
          require("kubectl").toggle()
        end,
        desc = "Kubectl",
      },
    },
    dependencies = { "saghen/blink.lib" },
    config = function()
      require("kubectl").setup()
    end,
  },
}
