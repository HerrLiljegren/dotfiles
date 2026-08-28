vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.wrap = false
  end,
})

vim.filetype.add({
  extension = {
    props = "xml",
    targets = "xml",
    csproj = "xml",
    fsproj = "xml",
  },
})
