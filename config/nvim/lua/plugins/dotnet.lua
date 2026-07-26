return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "roslyn-language-server",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.omnisharp = { enabled = false }
      opts.servers.roslyn_ls = { enabled = false }
    end,
  },
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    enabled = false,
  },
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor", "cshtml" },
    init = function()
      vim.lsp.config("roslyn", {
        settings = {
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "openFiles",
            dotnet_compiler_diagnostics_scope = "openFiles",
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = false,
            dotnet_enable_tests_code_lens = false,
          },
          ["csharp|completion"] = {
            dotnet_show_completion_items_from_unimported_namespaces = true,
          },
          ["csharp|symbol_search"] = {
            dotnet_search_reference_assemblies = true,
          },
        },
      })
    end,
    opts = {
      filewatching = "off",
      silent = true,
    },
  },
}
