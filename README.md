# LLM Spoon for Hammerspoon

## Installation

Double-click the "ai-helper.spoon" file, and Hammerspoon will install it for you.

## Setting up the Spoon

After installation, you need to set up the Spoon in the Hammerspoon config file as shown below. Get you api key by going to: https://dashboard.cohere.com/api-keys.

```lua
hs.settings.set("RewriteSpoon.apiKey", "<COHERE_API_KEY>")

-- Load your Rewrite Spoon
hs.loadSpoon("RewriteSpoon")

-- Initialize the Spoon
spoon.RewriteSpoon:init()

-- Bind hotkeys
spoon.RewriteSpoon:bindHotkeys({
    rewrite = {{"cmd", "alt", "ctrl"}, "R"}
})
```
