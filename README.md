# 📚🥄 LLM Spoon for Hammerspoon

Simple spoon for rewriting selected text via an LLM from Cohere or OpenAI.

The Spoon contains four prompts designed to assist users with their writing: Rewrite, which improves sentence structure, grammar, and spelling; Summarize, which provides a concise summary of a longer text; and Translate, which offers translation services between Danish and English.

## 🚀 Installation

Download this repo then double-click "AiHelper.spoon", and Hammerspoon will install the spoon for you.

The spoon is using Python3. You can install Python 3 with Homebrew like this:

```bash
brew install python
```

After installation, verify it works:

```bash
python3 --version
pip3 --version
```

The Python scripts dependencies, are automatically installed when you refresh the Hammerspoon configuration, unless they are already installed.

## 🛠️ Setting up the Spoon

After installation, you need to set up the Spoon in the Hammerspoon config file as shown below. Get your API key by going to the LLM providers website.

```lua
-- Set Api key
hs.settings.set("AiHelper.apiKey", "<PROVIDER_API_KEY>")
🥄
-- Load your Rewrite Spoon
hs.loadSpoon("AiHelper")
spoon.AiHelper:init({
    provider = "openai", -- or "cohere"
    model = "gpt-4o" -- or "command-r-plus"
})

-- Bind hotkeys
spoon.AiHelper:bindHotkeys({
    rewrite = {{"cmd", "alt", "ctrl"}, "R"}
})
```

Then you can reload the Hammerspoon configuration and start using the Spoon 🥄!
