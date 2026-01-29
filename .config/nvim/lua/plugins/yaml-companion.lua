return {
  {
    "someone-stole-my-name/yaml-companion.nvim",
    requires = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      -- Charger l'extension Telescope pour yaml-companion
      require("telescope").load_extension("yaml_schema")

      -- Configuration de yaml-companion avec options par défaut
      local yaml_companion_cfg = require("yaml-companion").setup({
        -- Optionnel : ajouter des schemas supplémentaires disponibles dans le picker Telescope
        schemas = {
          -- Exemple d'ajout d'un schema personnalisé
          -- {
          --   name = "Flux GitRepository",
          --   uri = "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json",
          -- },
          {
            name = "Stack 3S",
            uri = "https://github.com/dktunited/cpe-application-provisioning-system/blob/maintenance/v1.4.x/schema_validators/json_schema.json",
          },
        },

        -- Configuration LSP qui sera fusionnée avec celle de yamlls
        lspconfig = {
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              validate = true,
              format = { enable = true },
              hover = true,
              schemaStore = {
                enable = false, -- Désactivation du schemaStore intégré de yamlls pour éviter les conflits
                url = "",
              },
              schemaDownload = { enable = true },
              schemas = {
                -- Exemple : charger automatiquement le schema GitHub Actions pour les fichiers correspondants
                ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
              },
              trace = { server = "debug" },
            },
          },
          flags = {
            debounce_text_changes = 150,
          },
        },
      })

      -- Setup du serveur LSP yamlls avec la config yaml-companion
      require("lspconfig")["yamlls"].setup(yaml_companion_cfg)

      -- Exemple de fonction pour afficher le schema actif dans la statusline (optionnel)
      _G.get_yaml_schema = function()
        local schema = require("yaml-companion").get_buf_schema(0)
        if schema.result.name == "none" then
          return ""
        end
        return schema.result.name
      end

      -- Exemple de mapping pour ouvrir le picker de schemas manuellement
      vim.api.nvim_set_keymap("n", "<leader>ys", "<cmd>Telescope yaml_schema<cr>", { noremap = true, silent = true })
    end,
  },
}
