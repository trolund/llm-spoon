# LLM Spoon for Hammerspoon

Simple spoon for rewriting selected text.

## Installation

Download this repo then double-click "ai-helper.spoon", and Hammerspoon will install the spoon for you.

## Setting up the Spoon

After installation, you need to set up the Spoon in the Hammerspoon config file as shown below. Get you api key by going to: https://dashboard.cohere.com/api-keys.

```lua
hs.settings.set("AiHelper.apiKey", "<COHERE_API_KEY>")

-- Load your Rewrite Spoon
hs.loadSpoon("AiHelper")

-- Initialize the Spoon
spoon.AiHelper:init()

-- Bind hotkeys
spoon.AiHelper:bindHotkeys({
    rewrite = {{"cmd", "alt", "ctrl"}, "R"}
})
```
