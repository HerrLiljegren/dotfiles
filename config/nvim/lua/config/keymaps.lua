vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
vim.keymap.set({ "n", "x", "i" }, "<S-ScrollWheelUp>", "<ScrollWheelLeft>")
vim.keymap.set({ "n", "x", "i" }, "<S-ScrollWheelDown>", "<ScrollWheelRight>")
