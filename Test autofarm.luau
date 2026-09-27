local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Функция для подключения отслеживания смерти
local function setupDeathListener(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			-- Когда персонаж умирает, вызываем PlayAgain 5 раз каждые 10 секунд
			task.spawn(function()
				local success, remotesFolder = pcall(function()
					return ReplicatedStorage:WaitForChild("RemotesFolder", 3)
				end)
				
				if success and remotesFolder then
					local playAgainEvent = remotesFolder:FindFirstChild("PlayAgain")
					if playAgainEvent then
						for i = 1, 5 do
							pcall(function()
								playAgainEvent:FireServer()
							end)
							if i < 5 then
								task.wait(10)
							end
						end
					end
				end
			end)
		end)
	end
end

setupDeathListener(Character)

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	setupDeathListener(newChar)
end)

-- Создание GUI на экране
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Ultimate Auto Farm"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.85, 0, 0, 45)
ToggleButton.Position = UDim2.new(0.075, 0, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "Auto Farm: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.GothamSemibold
ToggleButton.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

-- Эмуляция кликов/зажима клавиши E
local function pressKeyE(times, delayBetween)
	for i = 1, times or 1 do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		if delayBetween and i < times then
			task.wait(delayBetween)
		end
	end
end

local function holdKeyE(duration)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(duration)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Проверка инвентаря на наличие ключа
local function hasKeyInInventory()
	local char = LocalPlayer.Character
	if char and (char:FindFirstChild("Key") or char:FindFirstChild("KeyObtain")) then
		return true
	end
	
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack and (backpack:FindFirstChild("Key") or backpack:FindFirstChild("KeyObtain")) then
		return true
	end
	
	return false
end

-- Поиск комнаты для ключа
local function getRoomNumberFromItem(item)
	local current = item.Parent
	while current and current ~= workspace do
		local num = tonumber(current.Name)
		if num then
			return num
		end
		current = current.Parent
	end
	return nil
end

local function getNextKeyObtain()
	if not Character then return nil end

	local GameData = ReplicatedStorage:FindFirstChild("GameData")
	if not GameData then return nil end

	local LatestRoom = GameData:FindFirstChild("LatestRoom")
	if not LatestRoom then return nil end

	local startRoom = LatestRoom.Value
	local bestKey = nil
	local bestNumber = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "KeyObtain" and obj:IsA("Model") then
			local roomNum = getRoomNumberFromItem(obj)

			if roomNum and roomNum >= startRoom and roomNum < bestNumber then
				bestNumber = roomNum
				bestKey = obj
			end
		end
	end

	return bestKey
end

-- Поиск закрытой двери
local function getNextClosedDoor()
	if not Character then return nil end

	local GameData = ReplicatedStorage:FindFirstChild("GameData")
	if not GameData then return nil end

	local LatestRoom = GameData:FindFirstChild("LatestRoom")
	if not LatestRoom then return nil end

	local startRoom = LatestRoom.Value
	local bestDoor = nil
	local bestNumber = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Door" and obj:IsA("Model") then
			local openAttr = obj:GetAttribute("Open")
			if openAttr == false or openAttr == nil then
				local roomModel = obj.Parent
				local roomNum = tonumber(roomModel and roomModel.Name)

				if roomNum and roomNum >= startRoom and roomNum < bestNumber then
					bestNumber = roomNum
					bestDoor = obj
				end
			end
		end
	end

	return bestDoor
end

-- Сброс для 12 комнаты
local function resetCharacterCustom()
	local Globals = getgenv().Globals or {}
	local Functions = getgenv().Functions or {}
	local Abysall = getgenv().Abysall
	local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
	local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

	Globals.SelfKilled = true
	if type(Functions.CheckCompatability) == "function" and Functions.CheckCompatability({"replicatesignal"}) and Abysall and Abysall.Environment then
		pcall(function()
			Abysall.Environment.replicatesignal(LocalPlayer.Kill)
		end)
	else
		if RemotesFolder:FindFirstChild("Underwater") then
			RemotesFolder.Underwater:FireServer(true)
		elseif humanoid then
			humanoid.Health = 0
		end
	end
end

local function getCurrentRoomNumber()
	local GameData = ReplicatedStorage:FindFirstChild("GameData")
	if GameData then
		local LatestRoom = GameData:FindFirstChild("LatestRoom")
		if LatestRoom then
			return LatestRoom.Value
		end
	end
	return 0
end

local function removeFrontDesk()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "FrontDesk" then
			pcall(function()
				obj:Destroy()
			end)
		end
	end
end

-- Заморозка / разморозка движения персонажа
local function setCharacterFrozen(frozen)
	if not Character then return end
	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	local rootPart = Character:FindFirstChild("HumanoidRootPart")
	
	if humanoid then
		if frozen then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		else
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end
	end
	
	if rootPart then
		rootPart.Anchored = frozen
	end
end

-- Состояние автофарма
local AutoFarmState = { Value = false }
local TpNextDoorConnection = nil
local keyWasHandled = false

local function startAutomation()
	if TpNextDoorConnection then
		task.cancel(TpNextDoorConnection)
		TpNextDoorConnection = nil
	end

	removeFrontDesk()

	TpNextDoorConnection = task.spawn(function()
		while AutoFarmState.Value do
			-- Проверка на 12 комнату
			if getCurrentRoomNumber() >= 12 then
				setCharacterFrozen(false)
				resetCharacterCustom()
				task.wait(2)
				continue
			end

			-- 1. Обработка ключа, если он есть и у нас его нет
			local keyObj = getNextKeyObtain()
			if keyObj and not hasKeyInInventory() then
				keyWasHandled = false
				while AutoFarmState.Value and getNextKeyObtain() and not hasKeyInInventory() do
					setCharacterFrozen(true)
					local currentKey = getNextKeyObtain()
					if currentKey and Character then
						local success, pivot = pcall(function()
							return currentKey:GetPivot()
						end)
						if success and pivot then
							Character:PivotTo(pivot)
						else
							local primaryPart = currentKey.PrimaryPart or currentKey:FindFirstChildWhichIsA("BasePart")
							if primaryPart then
								Character:PivotTo(primaryPart.CFrame)
							end
						end
						pressKeyE(5, 0.05)
					end
					task.wait(0.125)
				end
			end

			-- 2. Если ключ появился в инвентаре — подходим к двери и открываем её
			if hasKeyInInventory() and not keyWasHandled then
				setCharacterFrozen(true)
				local door = getNextClosedDoor()
				if door and Character then
					Character:PivotTo(door:GetPivot())
					task.wait(0.1)
					holdKeyE(2.7)
					keyWasHandled = true
				end
			end

			-- 3. Основной телепорт по закрытым дверям
			if not hasKeyInInventory() then
				setCharacterFrozen(true)
				local door = getNextClosedDoor()
				if door and Character then
					Character:PivotTo(door:GetPivot())
				end
			end

			task.wait(0.125)
		end
		
		setCharacterFrozen(false)
		TpNextDoorConnection = nil
	end)
end

ToggleButton.MouseButton1Click:Connect(function()
	AutoFarmState.Value = not AutoFarmState.Value
	
	if AutoFarmState.Value then
		ToggleButton.Text = "Auto Farm: ON"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		keyWasHandled = false
		startAutomation()
	else
		ToggleButton.Text = "Auto Farm: OFF"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		setCharacterFrozen(false)
		if TpNextDoorConnection then
			task.cancel(TpNextDoorConnection)
			TpNextDoorConnection = nil
		end
	end
end)
