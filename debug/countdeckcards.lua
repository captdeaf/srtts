for _, v in ipairs(AVAILABLE_DECKS) do
  printf("%s: %d cards", v.name, #DECKS[v.name])
end
