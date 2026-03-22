# AiHelper Spoon for Hammerspoon

`AiHelper.spoon` lets you transform selected text from anywhere on macOS with a hotkey and an LLM.

It currently supports:

- `rewrite`: fix spelling and grammar while preserving the original wording and tone
- `summarize`: return a concise summary of the selected text
- `translate`: translate selected text to Danish
- `translate_to_english`: translate selected text to English

The Spoon supports both OpenAI and Cohere.

## Installation

1. Install Python 3 if it is not already available:

```bash
brew install python
python3 --version
pip3 --version
```

2. Download or clone this repository.
3. Double-click `AiHelper.spoon` to install it in Hammerspoon.

Python dependencies from [`AiHelper.spoon/requirements.txt`](/Users/troelslund/Documents/Code/llm-spoon/AiHelper.spoon/requirements.txt) are installed automatically when the Spoon initializes, unless you disable that behavior.

## Setup

Add this to your Hammerspoon config:

```lua
hs.settings.set("AiHelper.apiKey", "<PROVIDER_API_KEY>")

hs.loadSpoon("AiHelper")
spoon.AiHelper:init({
    provider = "openai",      -- or "cohere"
    model = "gpt-4o",         -- or e.g. "command-r-plus"
    autoInstallDeps = true,   -- optional, default is true
    -- pythonPath = "/opt/homebrew/bin/python3", -- optional override
})

spoon.AiHelper:bindHotkeys({
    rewrite = {{"cmd", "alt", "ctrl"}, "R"},
    summarize = {{"cmd", "alt", "ctrl"}, "S"},
    translate = {{"cmd", "alt", "ctrl"}, "T"},
    translate_to_english = {{"cmd", "alt", "ctrl"}, "E"},
})
```

Then reload your Hammerspoon configuration.

## Defaults

If you do not override them, the Spoon uses these defaults:

- `provider = "cohere"`
- `model = "command-r-plus"`
- `autoInstallDeps = true`
- `pythonPath = "/opt/homebrew/bin/python3"` when available, otherwise `"/usr/bin/python3"`

## Usage

1. Select text in any app.
2. Press one of the configured hotkeys.
3. The Spoon copies the selection, sends it to the configured provider, and pastes the result back in place.

If no text is selected, or the API key is missing, Hammerspoon will show an alert.

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- Python 3
- An OpenAI or Cohere API key

## Project Structure

- [`AiHelper.spoon/init.lua`](/Users/troelslund/Documents/Code/llm-spoon/AiHelper.spoon/init.lua): Hammerspoon integration, hotkeys, clipboard flow, dependency install
- [`AiHelper.spoon/rewrite.py`](/Users/troelslund/Documents/Code/llm-spoon/AiHelper.spoon/rewrite.py): prompt loading and provider API calls
- [`AiHelper.spoon/prompts/`](/Users/troelslund/Documents/Code/llm-spoon/AiHelper.spoon/prompts): prompt templates for each mode
