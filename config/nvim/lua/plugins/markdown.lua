local config = vim.fn.stdpath("config") .. "/markdownlint-cli2.jsonc"

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", config, "-" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = function(_, ctx)
            local ft = vim.bo[ctx.buf].filetype
            if ft ~= "markdown" and ft ~= "markdown.mdx" then
              return {}
            end
            -- Project settings take precedence over these Markdown defaults.
            return { "--print-width", "100", "--prose-wrap", "always", "--config-precedence", "file-override" }
          end,
        },
        -- Keep diagnostics and markdownlint fixes on the same base rules.
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", config },
        },
      },
    },
  },
}
