if game.PlaceId == 10119617028 then


getgenv().AimbotEnabled = false
getgenv().TeamCheck = false
getgenv().AliveCheck = false
getgenv().WallCheck = false
getgenv().Sensitivity = 0
getgenv().TriggerKey = "MouseButton2"
getgenv().Toggle = false
getgenv().LockPart = false
getgenv().ReloadOnTeleport = false

getgenv().FOV = false
getgenv().Visible = false
getgenv().Amount = 90
getgenv().Color = "255, 255, 255"
getgenv().Transparency = 0.5
getgenv().Sides = 60
getgenv().Thickness = 0.5
getgenv().Filled = 0.5


getgenv().ESPEnabled = false

_G.FriendColor = Color3.fromRGB(0, 0, 255)
_G.EnemyColor = Color3.fromRGB(255, 0, 0)
_G.UseTeamColor = false




pcall(function()
    getgenv().Aimbot.Functions:Exit()
end)


getgenv().Aimbot = {}
local Environment = getgenv().Aimbot


local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Camera = game:GetService("Workspace").CurrentCamera


local LocalPlayer = Players.LocalPlayer
local Title = "RocketX_Aimbot"
local FileNames = {"Aimbot", "Configuration.json", "Drawing.json"}
local RequiredDistance = math.huge
local Typing = false
local Running = false
local Animation = nil
local ServiceConnections = {RenderSteppedConnection = nil, InputBeganConnection = nil, InputEndedConnection = nil, TypingStartedConnection = nil, TypingEndedConnection = nil}


Environment.Settings = {
    SendNotifications = true,
    SaveSettings = true, -- Re-execute upon changing
    ReloadOnTeleport = true,
    Enabled = false,
    TeamCheck = false,
    AliveCheck = false,
    WallCheck = false, -- Laggy
    Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
    TriggerKey = "MouseButton2",
    Toggle = false,
    LockPart = "Head" -- Body part to lock on
}

Environment.FOVSettings = {
    Enabled = false,
    Visible = false,
    Amount = 90,
    Color = "183, 0, 255",
    LockedColor = "255, 70, 70",
    Transparency = 0.5,
    Sides = 60,
    Thickness = 1,
    Filled = false
}


Environment.FOVCircle = Drawing.new("Circle")
Environment.Locked = nil


local function Encode(Table)
    if Table and type(Table) == "table" then
        local EncodedTable = HttpService:JSONEncode(Table)

        return EncodedTable
    end
end

local function Decode(String)
    if String and type(String) == "string" then
        local DecodedTable = HttpService:JSONDecode(String)

        return DecodedTable
    end
end

local function GetColor(Color)
    local R = tonumber(string.match(Color, "([%d]+)[%s]*,[%s]*[%d]+[%s]*,[%s]*[%d]+"))
    local G = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*([%d]+)[%s]*,[%s]*[%d]+"))
    local B = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*[%d]+[%s]*,[%s]*([%d]+)"))

    return Color3.fromRGB(R, G, B)
end

local function SendNotification(TitleArg, DescriptionArg, DurationArg)
    if Environment.Settings.SendNotifications then
        StarterGui:SetCore("SendNotification", {
            Title = TitleArg,
            Text = DescriptionArg,
            Duration = DurationArg
        })
    end
end


local function SaveSettings()
    if Environment.Settings.SaveSettings then
        if isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
            writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
        end

        if isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
            writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
        end
    end
end

local function GetClosestPlayer()
    if Environment.Locked == nil then
        if Environment.FOVSettings.Enabled then
            RequiredDistance = Environment.FOVSettings.Amount
        else
            RequiredDistance = math.huge
        end

        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer then
                if v.Character and v.Character[Environment.Settings.LockPart] then
                    if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                    if Environment.Settings.AliveCheck and v.Character.Humanoid.Health <= 0 then continue end
                    if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

                    local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
                    local Distance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude

                    if Distance < RequiredDistance and OnScreen then
                        RequiredDistance = Distance
                        Environment.Locked = v
                    end
                end
            end
        end
    elseif (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
        Environment.Locked = nil
        Animation:Cancel()
        Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
    end
end


ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)


if Environment.Settings.SaveSettings then
    if not isfolder(Title) then
        makefolder(Title)
    end

    if not isfolder(Title.."/"..FileNames[1]) then
        makefolder(Title.."/"..FileNames[1])
    end

    if not isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
        writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
    else
        Environment.Settings = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[2]))
    end

    if not isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
        writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
    else
        Environment.Visuals = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[3]))
    end

    coroutine.wrap(function()
        while wait(10) do
            SaveSettings()
        end
    end)()
else
    if isfolder(Title) then
        delfolder(Title)
    end
end

local function Load()
    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
            Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
            Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
            Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
            Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
            Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
            Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
            Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
            Environment.FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        else
            Environment.FOVCircle.Visible = false
        end

        if Running and Environment.Settings.Enabled then
            GetClosestPlayer()

            if Environment.Settings.Sensitivity > 0 then
                Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
                Animation:Play()
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
            end

            Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
        end
    end)

    ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
        if not Typing then
            pcall(function()
                if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
                    if Environment.Settings.Toggle then
                        Running = not Running

                        if not Running then
                            Environment.Locked = nil
                            Animation:Cancel()
                            Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
                        end
                    else
                        Running = true
                    end
                end
            end)

            pcall(function()
                if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
                    if Environment.Settings.Toggle then
                        Running = not Running

                        if not Running then
                            Environment.Locked = nil
                            Animation:Cancel()
                            Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
                        end
                    else
                        Running = true
                    end
                end
            end)
        end
    end)

    ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
        if not Typing then
            pcall(function()
                if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
                    if not Environment.Settings.Toggle then
                        Running = false
                        Environment.Locked = nil
                        Animation:Cancel()
                        Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
                    end
                end
            end)

            pcall(function()
                if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
                    if not Environment.Settings.Toggle then
                        Running = false
                        Environment.Locked = nil
                        Animation:Cancel()
                        Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
                    end
                end
            end)
        end
    end)
end

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
    SaveSettings()

    for _, v in next, ServiceConnections do
        v:Disconnect()
    end

    Environment.FOVCircle:Remove()

    getgenv().Aimbot.Functions = nil
    getgenv().Aimbot = nil
end

function Environment.Functions:Restart()
    SaveSettings()

    for _, v in next, ServiceConnections do
        v:Disconnect()
    end

    Environment.FOVCircle:Remove()

    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings = {
        SendNotifications = true,
        SaveSettings = true, 
        ReloadOnTeleport = true,
        Enabled = false,
        TeamCheck = false,
        AliveCheck = false,
        WallCheck = false, -- Laggy
        Sensitivity = 0, 
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head"
    }
    
    Environment.FOVSettings = {
        Enabled = false,
        Visible = false,
        Amount = 90,
        Color = "255, 255, 255",
        LockedColor = "255, 70, 70",
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    }
    
    SaveSettings()

    for _, v in next, ServiceConnections do
        v:Disconnect()
    end

    Load()
end

--// Support Check

if not Drawing or not writefile or not makefolder then
    SendNotification(Title, "Your exploit does not support this script", 3); return
end

--// Reload On Teleport

if Environment.Settings.ReloadOnTeleport then
    local queueonteleport = queue_on_teleport or syn.queue_on_teleport

    if queueonteleport then
        queueonteleport(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V2/main/Resources/Scripts/Main.lua"))
    else
        SendNotification(Title, "Your exploit does not support \"syn.queue_on_teleport()\"")
    end
end

--// Load

Load();

function newPrint(text)
    print('[Universal ESP]: '..text)
end
function round(n) 
    return math.floor(n + 0.5) 
end

newPrint('Waiting for game to load.')

repeat
    wait()
until game:IsLoaded()

newPrint('Game Loaded! Initializing Universal ESP')

pcall(function()
    for _,v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
           for _,c in pairs(v.Character:GetDescendants()) do
                if c:IsA('BillboardGui') or c:IsA('BoxHandleAdornment') then
                    c:Destroy()
                end
           end  
        end
    end
end)

local Settings = {
    Enabled               = false,
    Titles = {
        Enabled           = false,
        Name              = false,
        Distance          = false,
        TeamTextColor     = Color3.fromRGB(0, 255, 149),
        EnemyTextColor    = Color3.fromRGB(183, 0, 255)
    },
    Chams = {
        Enabled           = false,
        Transparency      = 0.5,
        TeamHeadColor     = Color3.fromRGB(0, 255, 149),
        TeamBodyColor     = Color3.fromRGB(0, 255, 149),
        EnemyHeadColor    = Color3.fromRGB(255, 0, 0),
        EnemyBodyColor    = Color3.fromRGB(183, 0, 255)
    },
    Box = {
        Enabled           = false,
        Transparency      = 0.5,
        TeamBoxColor      = Color3.fromRGB(0, 255, 149),
        EnemyBoxColor     = Color3.fromRGB(255, 0, 0),
        BoxOutlineColor   = Color3.fromRGB(255, 255, 255)
    },
    TeamCheck             = false
}

local Players     = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

function ESP()
while Settings.Enabled do
    if Settings.Enabled then
        pcall(function()
            for _,v in pairs(Players:GetPlayers()) do
                wait()
                if v ~= LocalPlayer then
                    if Settings.TeamCheck then
                        if v.Team.Name ~= LocalPlayer.Team.Name or v.Team.TeamColor ~= LocalPlayer.TeamColor then
                            for _,c in pairs(v.Character:GetDescendants()) do
                                if c:IsA('BillboardGui') or c:IsA('BoxHandleAdornment') then
                                    c:Destroy()
                                end
        
                                if Settings.Chams.Enabled then
                                    if c:IsA('Part') or c:IsA('MeshPart') then
                                        if c.Name == 'Head' then
                                            local Box = Instance.new('BoxHandleAdornment', c)
                                            Box.Size = Box.Parent.Size
                                            Box.Transparency = Settings.Chams.Transparency
                                            Box.Adornee = Box.Parent
                                            Box.AlwaysOnTop = true
                                            Box.Visible = true
                                            Box.ZIndex = 2
                                            Box.Color3 = Settings.Chams.EnemyHeadColor
                                            Box.Name = HttpService:GenerateGUID(false):lower():sub(1, 10);
                                        else
                                            local Box = Instance.new('BoxHandleAdornment', c)
                                            Box.Size = Box.Parent.Size
                                            Box.Transparency = Settings.Chams.Transparency
                                            Box.Adornee = Box.Parent
                                            Box.AlwaysOnTop = true
                                            Box.Visible = true
                                            Box.ZIndex = 2
                                            Box.Color3 = Settings.Chams.EnemyBodyColor
                                            Box.Name = HttpService:GenerateGUID(false):lower():sub(1, 10);
                                        end
                                    end
                                end

                                if Settings.Box.Enabled then
                                    if c.Name == 'HumanoidRootPart' then
                                        local GUI = Instance.new('BillboardGui', c)
                                        local Frame = Instance.new('Frame', GUI)
    
                                        GUI.Adornee = c
                                        GUI.Size = UDim2.new(0.7, 0, 1, 0)
                                        GUI.StudsOffset = Vector3.new(-1.3, 2, 0)
                                        GUI.Parent = c
                                        GUI.AlwaysOnTop = true
    
                                        Frame.BackgroundTransparency = Settings.Box.Transparency
                                        Frame.ZIndex = 5
                                        Frame.Size = UDim2.new(5, 0, 5, 0)
                                        Frame.BackgroundColor3 = Settings.Box.EnemyBoxColor
                                        Frame.BorderColor3 = Settings.Box.BoxOutlineColor
                                    end
                                end
        
                                if Settings.Titles.Enabled then
                                    if c.Name == 'Head' then
                                        if Settings.Titles.Name then
                                            local DistanceFromPlayer = (LocalPlayer.Character.PrimaryPart.Position - v.Character.PrimaryPart.Position).Magnitude
                                            local GUI = Instance.new('BillboardGui', c)
                                            local Label = Instance.new('TextLabel', GUI)
            
                                            GUI.Adornee = c
                                            GUI.Size = UDim2.new(12, 0, 1, 0)
                                            GUI.StudsOffset = Vector3.new(0, 2, 0)
                                            GUI.Parent = c
                                            GUI.AlwaysOnTop = true
            
                                            if Settings.Titles.Distance then
                                                Label.BackgroundTransparency = 1
                                                Label.ZIndex = 5
                                                Label.Size = UDim2.new(1, 0, 1, 0)
                                                Label.TextColor3 = Settings.Titles.EnemyTextColor
                                                Label.TextScaled = false
                                                Label.Text = v.Name..'\n['..round(DistanceFromPlayer)..'] Studs Away'
                                                Label.TextStrokeTransparency = 0
                                                Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                            else
                                                Label.BackgroundTransparency = 1
                                                Label.ZIndex = 5
                                                Label.Size = UDim2.new(1, 0, 1, 0)
                                                Label.TextColor3 = Settings.Titles.EnemyTextColor
                                                Label.TextScaled = false
                                                Label.Text = v.Name
                                                Label.TextStrokeTransparency = 0
                                                Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                            end
                                        end
                                    end
                                end
                            end
                        else

                        end
                    else
                        for _,c in pairs(v.Character:GetDescendants()) do
                            if c:IsA('BillboardGui') or c:IsA('BoxHandleAdornment') then
                                c:Destroy()
                            end
    
                            if Settings.Chams.Enabled then
                                if c:IsA('Part') or c:IsA('MeshPart') then
                                    if c.Name == 'Head' then
                                        local Box = Instance.new('BoxHandleAdornment', c)
                                        Box.Size = Box.Parent.Size
                                        Box.Transparency = Settings.Chams.Transparency
                                        Box.Adornee = Box.Parent
                                        Box.AlwaysOnTop = true
                                        Box.Visible = true
                                        Box.ZIndex = 2
                                        Box.Color3 = Settings.Chams.TeamHeadColor
                                        Box.Name = HttpService:GenerateGUID(false):lower():sub(1, 10);
                                    else
                                        local Box = Instance.new('BoxHandleAdornment', c)
                                        Box.Size = Box.Parent.Size
                                        Box.Transparency = Settings.Chams.Transparency
                                        Box.Adornee = Box.Parent
                                        Box.AlwaysOnTop = true
                                        Box.Visible = true
                                        Box.ZIndex = 2
                                        Box.Color3 = Settings.Chams.TeamBodyColor
                                        Box.Name = HttpService:GenerateGUID(false):lower():sub(1, 10);
                                    end
                                end
                            end
    
                            if Settings.Box.Enabled then
                                if c.Name == 'HumanoidRootPart' then
                                    local GUI = Instance.new('BillboardGui', c)
                                    local Frame = Instance.new('Frame', GUI)

                                    GUI.Adornee = c
                                    GUI.Size = UDim2.new(0.7, 0, 1, 0)
                                    GUI.StudsOffset = Vector3.new(-1.3, 2, 0)
                                    GUI.Parent = c
                                    GUI.AlwaysOnTop = true

                                    Frame.BackgroundTransparency = Settings.Box.Transparency
                                    Frame.ZIndex = 5
                                    Frame.Size = UDim2.new(5, 0, 5, 0)
                                    Frame.BackgroundColor3 = Settings.Box.TeamBoxColor
                                    Frame.BorderColor3 = Settings.Box.BoxOutlineColor
                                end
                            end


                            if Settings.Titles.Enabled then
                                if c.Name == 'Head' then
                                    if Settings.Titles.Name then
                                        local DistanceFromPlayer = (LocalPlayer.Character.PrimaryPart.Position - v.Character.PrimaryPart.Position).Magnitude
                                        local GUI = Instance.new('BillboardGui', c)
                                        local Label = Instance.new('TextLabel', GUI)
        
                                        GUI.Adornee = c
                                        GUI.Size = UDim2.new(12, 0, 1, 0)
                                        GUI.StudsOffset = Vector3.new(0, 2, 0)
                                        GUI.Parent = c
                                        GUI.AlwaysOnTop = true
        
                                        if Settings.Titles.Distance then
                                            Label.BackgroundTransparency = 1
                                            Label.ZIndex = 5
                                            Label.Size = UDim2.new(1, 0, 1, 0)
                                            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                            Label.TextScaled = false
                                            Label.Text = v.Name..'\n['..round(DistanceFromPlayer)..'] Studs Away'
                                            Label.TextStrokeTransparency = 0
                                            Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                        else
                                            Label.BackgroundTransparency = 1
                                            Label.ZIndex = 5
                                            Label.Size = UDim2.new(1, 0, 1, 0)
                                            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                            Label.TextScaled = false
                                            Label.Text = v.Name
                                            Label.TextStrokeTransparency = 0
                                            Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                         end
                                    end
                                end 
                            end
                        end
                    end
                end
            end
        end)
    else
        pcall(function()
            for _,v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                   for _,c in pairs(v.Character:GetDescendants()) do
                        if c:IsA('BillboardGui') or c:IsA('BoxHandleAdornment') then
                            c:Destroy()
                        end
                   end  
                end
            end
        end)
    end
end
end



local Config = {
    WindowName = "RocketX | Airsoft Center",
	Color = Color3.fromRGB(104, 36, 138),
	Keybind = Enum.KeyCode.RightBracket
}

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Roblox/main/BracketV3.lua"))()
local Window = Library:CreateWindow(Config, game:GetService("CoreGui"))


local AimTab = Window:CreateTab("Aimbot")
local VisualTab = Window:CreateTab("Visuals")
local MiscTab = Window:CreateTab("Miscellaneous")
local CreditsTab = Window:CreateTab("Credits")

local AimbotSection = AimTab:CreateSection("Aimbot")
local ESPSection = VisualTab:CreateSection("ESP Master Switch")
local TitlesSection = VisualTab:CreateSection("Titles")
local ChamsSection = VisualTab:CreateSection("Chams")
local BoxSection = VisualTab:CreateSection("Box")

local MiscSection = MiscTab:CreateSection("Misc")
local CreditsSection = CreditsTab:CreateSection("Credits")

local Label1 = CreditsSection:CreateLabel("Scripter: zer#6969")
local Label2 = CreditsSection:CreateLabel("AntiCheat Bypass: zer#6969")
local Label3 = CreditsSection:CreateLabel("Rocket X Owner: zer#6969")




local Brightness = MiscSection:CreateSlider("Brightness", -1,100,nil,true, function(Value)
	game.Lighting.Brightness = Value
end)

local NightMode = MiscSection:CreateToggle("Night Mode", nil, function(State)
    if State == true then
        while State == true do
        game.Lighting.Brightness = -1
        game.Lighting.FogEnd = 0
        game.Lighting:FindFirstChild("NVGColor").Brightness = -0.3
        wait()
        end
    end
end)

local ESPToggle = ESPSection:CreateToggle("ESP", nil, function(State)
    Settings.Enabled = State
    ESP()
end)
ESPToggle:AddToolTip("WARNING: SELECT ALL SETTINGS YOU WOULD LIKE BEFORE ACTIVATING!")

local TeamCheckToggle = ESPSection:CreateToggle("Team Check", nil, function(State)
    Settings.TeamCheck = State
end)
TeamCheckToggle:AddToolTip("WARNING: YOU NEED TO BE ON A VALID TEAM BEFORE ACTIVATING")

local TitlesToggle = TitlesSection:CreateToggle("Titles", nil, function(State)
    Settings.Titles.Enabled = State
end)

local TitlesToggle2 = TitlesSection:CreateToggle("Name", nil, function(State)
    Settings.Titles.Name = State
end)

local TitlesToggle3 = TitlesSection:CreateToggle("Distance", nil, function(State)
    Settings.Titles.Distance = State
end)

local ChamsToggle1 = ChamsSection:CreateToggle("Chams", nil, function(State)
    Settings.Chams.Enabled = State
end)

local BoxToggle1 = BoxSection:CreateToggle("Box", nil, function(State)
    Settings.Box.Enabled = State
end)



wait()
Environment.Settings.Enabled = false


local AimbotToggle = AimbotSection:CreateToggle("Aimbot", nil, function(State)
        Environment.Settings.Enabled = State
        Environment.FOVSettings.Enabled = State
end)

AimbotToggle:AddToolTip("WARNING: RECOMENDED TO TOGGLE BEFORE TOGGLING ESP")

local TeamCheckToggle = AimbotSection:CreateToggle("Team Check", nil, function(State)
    Environment.Settings.TeamCheck = State
end)
local AliveCheckToggle = AimbotSection:CreateToggle("Alive Check", nil, function(State)
    Environment.Settings.AliveCheck = State
end)
local WallCheckToggle = AimbotSection:CreateToggle("Wall Check", nil, function(State)
    Environment.Settings.WallCheck = State
end)
WallCheckToggle:AddToolTip("WARNING: BUGGY DUE TO ANTICHEAT!")

local Slider1 = AimbotSection:CreateSlider("Sensitivity", 0,100,nil,true, function(Value)
	Environment.Settings.Sensitivity = Value
end)

local TextBox1 = AimbotSection:CreateTextBox("Trigger Key", "MouseButton2", true, function(Value)
	Environment.Settings.TriggerKey = Value
end)

local ToggleToggle = AimbotSection:CreateToggle("Toggle", nil, function(State)
    Environment.Settings.TeamCheck = State
end)

local LockPartTextbox = AimbotSection:CreateTextBox("Lock Part", "Head", true, function(Value)
	Environment.Settings.LockPart = Value
end)

local FOVSection = AimTab:CreateSection("FOV")

local FOVCircle = FOVSection:CreateToggle("FOV Circle", nil, function(State)
    Environment.FOVSettings.Visible = State
end)

local Slider1 = FOVSection:CreateSlider("Amount", 0,200,nil,true, function(Value)
    Environment.FOVSettings.Amount = Value
end)

local Slider2 = FOVSection:CreateSlider("Transparency", 0,100,nil,true, function(Value)
    Environment.FOVSettings.Transparency = Value
end)

local Slider3 = FOVSection:CreateSlider("Thickness", 0,100,nil,true, function(Value)
    Environment.FOVSettings.Thickness = Value
end)

end