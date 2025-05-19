local obj = {}
obj.__index = obj

-- Metadata for the Spoon
obj.name = "AiHelper"
obj.version = "0.1"
obj.author = "Troels Lund"
obj.license = "MIT"

-- Spoon configuration
obj.hyper = {"cmd", "alt", "ctrl"}
obj.autoInstallDeps = true

function obj:init()
    self.scriptPath = hs.spoons.resourcePath("rewrite.py")
    self.apiKey = hs.settings.get("AiHelper.apiKey")

    if not self.apiKey then
        hs.alert("Missing API key: set with hs.settings.set('AiHelper.apiKey', 'your-key')")
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

local function handleRewrite(mode, scriptPath, apiKey)
    return function()
        hs.alert("Rewriting text...")

        -- Copy selected text
        hs.eventtap.keyStroke({"cmd"}, "c")

        hs.timer.doAfter(0.1, function()
            local selectedText = hs.pasteboard.getContents()

            if not selectedText or selectedText == "" then
                hs.alert("No text selected")
                return
            end

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
                  string.format("COHERE_API_KEY='%s' TEXT='%s' MODE='%s' /usr/bin/python3 %s", apiKey, selectedText,
                mode, scriptPath)})

            task:start()
            task:closeInput()
        end)
    end
end

function obj:bindHotkeys(mapping)
    local hotkeyRewrite = mapping.rewrite or {self.hyper, "R"}
    local hotkeySummarize = mapping.summarize or {self.hyper, "S"}
    local hotkeyTranslate = mapping.translate or {self.hyper, "T"}
    local hotkeyTranslateToEnglish = mapping.translate_to_english or {self.hyper, "E"}

    local scriptPath = self.scriptPath
    local apiKey = self.apiKey

    if not scriptPath or not apiKey then
        hs.alert("Missing script path or API key")
        return
    end

    hs.hotkey.bind(hotkeyRewrite[1], hotkeyRewrite[2], handleRewrite("rewrite", scriptPath, apiKey))
    hs.hotkey.bind(hotkeySummarize[1], hotkeySummarize[2], handleRewrite("summarize", scriptPath, apiKey))
    hs.hotkey.bind(hotkeyTranslate[1], hotkeyTranslate[2], handleRewrite("translate", scriptPath, apiKey))
    hs.hotkey.bind(hotkeyTranslateToEnglish[1], hotkeyTranslateToEnglish[2],
        handleRewrite("translate_to_english", scriptPath, apiKey))
end

return obj
