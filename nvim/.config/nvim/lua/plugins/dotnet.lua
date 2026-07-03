local omnisharp = vim.fn.stdpath("data") .. "/mason/bin/OmniSharp"

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "omnisharp",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.omnisharp = vim.tbl_deep_extend("force", opts.servers.omnisharp or {}, {
        cmd = {
          omnisharp,
          "-z",
          "--hostPID",
          tostring(vim.fn.getpid()),
          "DotNet:enablePackageRestore=false",
          "--encoding",
          "utf-8",
          "--languageserver",
        },
      })
    end,
  },
}
