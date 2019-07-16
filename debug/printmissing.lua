for dname, cards in pairs(MISSING_CARDS) do
  local cnames = {}
  for v in pairs(cards) do
    table.insert(cnames, v)
  end
  printf("%s: %s", dname, table.concat(cnames, ", "))
end
