-- RewriteSpoon/init.lua
local obj = {}
obj.__index = obj

-- Metadata for the Spoon
obj.name = "RewriteSpoon"
obj.version = "0.1"
obj.author = "Troels Lund"
obj.license = "MIT"

-- Spoon configuration
obj.hyper = {"cmd", "alt", "ctrl"}
obj.autoInstallDeps = true

function obj:init()
    self.scriptPath = hs.spoons.resourcePath("rewrite.py")
    self.apiKey = hs.settings.get("RewriteSpoon.apiKey")

    if not self.apiKey then
        hs.alert("Missing API key: set with hs.settings.set('RewriteSpoon.apiKey', 'your-key')")
    end

    if self.autoInstallDeps then
        self:ensurePythonDeps()
    end
end

function obj:ensurePythonDeps()
    local check = hs.task.new("/usr/bin/python3", function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            hs.alert("Installing Python dependencies...")
            local requirementsPath = hs.spoons.resourcePath("requirements.txt")

            local pip = hs.task.new("/usr/bin/python3", function(code, out, err)
                if code == 0 then
                    hs.alert("Python dependencies installed")
                else
                    hs.alert("Failed to install Python dependencies")
                    print("Pip error:", err)
                end
            end, {"-m", "pip", "install", "--user", "-r", requirementsPath})

            pip:start()
        end
    end, {"-c", "import cohere"})

    check:start()
end

function obj:bindHotkeys(mapping)
    local hotkey = mapping.rewrite or {self.hyper, "R"}

    hs.hotkey.bind(hotkey[1], hotkey[2], function()
        hs.alert("Rewriting text...")

        -- Copy selected text
        hs.eventtap.keyStroke({"cmd"}, "c")

        hs.timer.doAfter(0.2, function()
            local selectedText = hs.pasteboard.getContents()

            if not selectedText or selectedText == "" then
                hs.alert("No text selected")
                return
            end

            local scriptPath = self.scriptPath
            local apiKey = self.apiKey

            local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
                if exitCode == 0 and stdOut and stdOut ~= "" then
                    hs.eventtap.keyStroke({"cmd"}, "x")
                    hs.timer.doAfter(0.1, function()
                        hs.pasteboard.setContents(stdOut)
                        hs.eventtap.keyStroke({"cmd"}, "v")
                        hs.alert("Text rewritten")
                    end)
                else
                    hs.alert("Rewrite failed")
                    print("Error:", stdErr)
                end
            end, {"-c",
                  string.format("COHERE_API_KEY='%s' TEXT='%s' /usr/bin/python3 %s", apiKey, selectedText, scriptPath)})

            task:start()
            task:closeInput()
        end)
    end)
end

return obj
