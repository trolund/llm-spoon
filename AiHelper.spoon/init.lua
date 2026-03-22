local obj = {}
obj.__index = obj

-- Metadata for the Spoon
obj.name = "AiHelper"
obj.version = "0.2"
obj.author = "Troels Lund"
obj.license = "MIT"

-- Spoon configuration
obj.hyper = {"cmd", "alt", "ctrl"}
obj.autoInstallDeps = true

local function fileExists(path)
    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    return false
end

local function shellQuote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function writeTempFile(contents)
    local path = os.tmpname()
    local file, err = io.open(path, "w")

    if not file then
        return nil, err
    end

    file:write(contents)
    file:close()

    return path
end

local function deleteFile(path)
    if path and path ~= "" then
        os.remove(path)
    end
end

local function summarizeError(stdErr)
    if not stdErr or stdErr == "" then
        return "Rewrite failed"
    end

    local message = stdErr:gsub("^%s+", ""):gsub("%s+$", "")
    local lastLine = message:match("([^\n]+)$") or message

    if #lastLine > 120 then
        lastLine = lastLine:sub(1, 117) .. "..."
    end

    return lastLine
end

function obj:init(config)
    config = config or {}

    self.scriptPath = hs.spoons.resourcePath("rewrite.py")
    self.apiKey = hs.settings.get("AiHelper.apiKey")
    self.provider = config.provider or self.provider or "cohere"
    self.model = config.model or self.model or "command-r-plus"
    self.autoInstallDeps = config.autoInstallDeps == nil and self.autoInstallDeps or config.autoInstallDeps
    self.pythonPath = config.pythonPath or self.pythonPath or
        (fileExists("/opt/homebrew/bin/python3") and "/opt/homebrew/bin/python3" or "/usr/bin/python3")
    self.hotkeys = self.hotkeys or {}

    if not self.apiKey then
        hs.alert("Missing API key: set with hs.settings.set('AiHelper.apiKey', 'your-key')")
    end

    if self.autoInstallDeps then
        self:ensurePythonDeps()
    end
end

function obj:ensurePythonDeps()
    local requirementsPath = hs.spoons.resourcePath("requirements.txt")
    local pythonPath = self.pythonPath

    -- Python script to parse and check all packages in requirements.txt
    local checkScript = string.format([[
import sys
import os
req_file = %q
missing = []
imports = {
    "pybars3": "pybars",
}

with open(req_file) as f:
    for line in f:
        pkg = line.strip().split("==")[0] if "==" in line else line.strip()
        if not pkg or pkg.startswith("#"):
            continue
        try:
            __import__(imports.get(pkg, pkg))
        except ImportError:
            missing.append(pkg)

sys.exit(1 if missing else 0)
]], requirementsPath)

    local check = hs.task.new(pythonPath, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            hs.alert("Installing Python dependencies...")
            local pipInstall = hs.task.new(pythonPath, function(code, out, err)
                if code == 0 then
                    hs.alert("Python dependencies installed successfully")
                else
                    hs.alert("Failed to install Python dependencies")
                    print("Pip install error:", err)
                end
            end, {"-m", "pip", "install", "--user", "-r", requirementsPath})

            pipInstall:start()
        else
            hs.alert("Python dependencies already installed")
        end
    end, {"-c", checkScript})

    check:start()
end

function obj:handleRewrite(mode)
    return function()
        hs.alert("Rewriting text...")

        local scriptPath = self.scriptPath
        local apiKey = self.apiKey
        local pythonPath = self.pythonPath
        local originalClipboard = hs.pasteboard.getContents()
        local clipboardMarker = string.format("__AIHELPER_SELECTION__%f", hs.timer.secondsSinceEpoch())

        if not scriptPath or not apiKey or not pythonPath then
            hs.alert("Missing script path, Python path, or API key")
            return
        end

        hs.pasteboard.setContents(clipboardMarker)

        -- Copy selected text
        hs.eventtap.keyStroke({"cmd"}, "c")

        hs.timer.doAfter(0.2, function()
            local selectedText = hs.pasteboard.getContents()

            if not selectedText or selectedText == "" or selectedText == clipboardMarker then
                if originalClipboard then
                    hs.pasteboard.setContents(originalClipboard)
                end
                hs.alert("No text selected")
                return
            end

            local tempPath, tempErr = writeTempFile(selectedText)

            if not tempPath then
                if originalClipboard then
                    hs.pasteboard.setContents(originalClipboard)
                end
                hs.alert("Failed to stage selected text")
                print("Temp file error:", tempErr)
                return
            end

            local command = table.concat({
                "AIHELPER_API_KEY=" .. shellQuote(apiKey),
                shellQuote(pythonPath),
                shellQuote(scriptPath),
                "--provider", shellQuote(self.provider),
                "--model", shellQuote(self.model),
                "--mode", shellQuote(mode),
                "--text-file", shellQuote(tempPath),
            }, " ")

            local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
                deleteFile(tempPath)

                if exitCode == 0 and stdOut and stdOut ~= "" then
                    hs.eventtap.keyStroke({"cmd"}, "x")
                    hs.timer.doAfter(0.1, function()
                        hs.pasteboard.setContents(stdOut)
                        hs.eventtap.keyStroke({"cmd"}, "v")
                        if originalClipboard then
                            hs.timer.doAfter(0.1, function()
                                hs.pasteboard.setContents(originalClipboard)
                            end)
                        end
                        hs.alert("Text rewritten")
                    end)
                else
                    if originalClipboard then
                        hs.pasteboard.setContents(originalClipboard)
                    end
                    hs.alert(summarizeError(stdErr))
                    print("Error:", stdErr)
                end
            end, {"-c", command})

            task:start()
        end)
    end
end

function obj:bindHotkeys(mapping)
    local hotkeyRewrite = mapping.rewrite or {self.hyper, "R"}
    local hotkeySummarize = mapping.summarize or {self.hyper, "S"}
    local hotkeyTranslate = mapping.translate or {self.hyper, "T"}
    local hotkeyTranslateToEnglish = mapping.translate_to_english or {self.hyper, "E"}

    for _, hotkey in pairs(self.hotkeys) do
        hotkey:delete()
    end

    self.hotkeys = {
        rewrite = hs.hotkey.bind(hotkeyRewrite[1], hotkeyRewrite[2], self:handleRewrite("rewrite")),
        summarize = hs.hotkey.bind(hotkeySummarize[1], hotkeySummarize[2], self:handleRewrite("summarize")),
        translate = hs.hotkey.bind(hotkeyTranslate[1], hotkeyTranslate[2], self:handleRewrite("translate")),
        translate_to_english = hs.hotkey.bind(hotkeyTranslateToEnglish[1], hotkeyTranslateToEnglish[2],
            self:handleRewrite("translate_to_english"))
    }
end

return obj
