vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- Remap all Greek letters to their English counterparts (lowercase)
local remap = {
    ["α"] = "a",
    ["β"] = "b",
    ["γ"] = "g",
    ["δ"] = "d",
    ["ε"] = "e",
    ["ζ"] = "z",
    ["γ"] = "g",
    ["η"] = "h",
    ["ι"] = "i",
    ["κ"] = "k",
    ["λ"] = "l",
    ["μ"] = "m",
    ["ν"] = "n",
    ["ξ"] = "j",
    ["ο"] = "o",
    ["π"] = "p",
    ["ρ"] = "r",
    ["σ"] = "s",
    ["τ"] = "t",
    ["υ"] = "y",
    ["θ"] = "u",
    ["ω"] = "v",
    ["ς"] = "w",
    ["χ"] = "x",

    ["Α"] = "A",
    ["Β"] = "B",
    ["Γ"] = "G",
    ["Δ"] = "D",
    ["Ε"] = "E",
    ["Ζ"] = "Z",
    ["Γ"] = "G",
    ["Η"] = "H",
    ["Ι"] = "I",
    ["Κ"] = "K",
    ["Λ"] = "L",
    ["Μ"] = "M",
    ["Ν"] = "N",
    ["Ξ"] = "J",
    ["Ο"] = "O",
    ["Π"] = "P",
    ["Ρ"] = "R",
    ["Σ"] = "S",
    ["Τ"] = "T",
    ["Υ"] = "Y",
    ["Θ"] = "U",
    ["Ω"] = "V",
    ["Σ"] = "W",
    ["Χ"] = "X",
  }
    
-- Function to set the remaps
for greek, english in pairs(remap) do
    -- Map in Normal mode
    vim.api.nvim_set_keymap('n', greek, english, { noremap = true, silent = true })
end

