local function position()
  local line = vim.fn.line(".")
  local total = vim.fn.line("$")
  local column = vim.fn.charcol(".")
  local percent = math.floor(line / total * 100)

  return string.format("%d/%d:%d %d%%%%", line, total, column, percent)
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_y = {
      { position },
    }
  end,
}
