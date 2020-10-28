-- world.entrance
local code_entity = {}


local TAG = "lclclc_"
local lastExpressionCode = 0
local timeStamp = 0
local currentShowingActor
local isFirstIn = true
local len = 0

---
--- 表示 code 是否包含左移1<<position位
---
function code_entity:hasCode(code, position)
    return self:numberToBits(code)[position + 1] ~= 0
end

function code_entity:numberToBits(src)
    local result = {}
    local bitLen = 12
    for i = 1, bitLen do
        result[i] = src % 2
        src = math.floor(src / 2)
    end
    return result
end

function code_entity:randomActor()
    local seed = tostring(os.time()):reverse():sub(1, 7)
    math.randomseed(seed)

    local sed = math.random(1, len)
    local actor
	local musicIndex
    if sed == 1 then
        actor = self.actors.fa --
		musicIndex = 1
    elseif sed == 2 then
        actor = self.actors.la
		musicIndex = 2
    elseif sed == 3 then
        actor = self.actors.maa
		musicIndex = 3
    elseif sed == 4 then
        actor = self.actors.moa
    end
	print("seed is "..seed)
	print("random action len = "..len)
    print(TAG, "sed is ->", sed)
    if actor then
        self.actors.ba:SetHidden(true)
        actor:SetHidden(false)
        currentShowingActor = actor
        local component = currentShowingActor:GetRootComponent()
        local controller = component:Get2DSequenceFrameAnimPlayListController()
        controller:Play()

		if musicIndex ~= nil then
            print("Play music index is "..musicIndex)
		    self:startPlayMusic(musicIndex)
        end
    else
        print(TAG, "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    end
end

function code_entity:findActors(world)

    local boardActor = world:FindActor("Frame4")
    local fortueActor = world:FindActor("Frame2")
    local luckActor = world:FindActor("Frame3")
    local mascoActor = world:FindActor("Frame1")
    local moneyActor = world:FindActor("moneyActor")
	len = 3 
	if boardActor ~= nil then
	    boardActor:SetHidden(false)
	else
		print("Head frame is nil")
	end

	if fortueActor ~= nil then 
    	fortueActor:SetHidden(true)
	else
		print("First frame is nil")
	end

	if luckActor ~= nil then 
	    luckActor:SetHidden(true)
	else
		print("Second frame is nil")
	end

	if mascoActor ~= nil then 
		mascoActor:SetHidden(true)
	else
		print("Third frame is nil")
	end

	if moneyActor ~= nil then 
	    moneyActor:SetHidden(true)
	else
		print("Fourth frame is nil")

	end    

    currentShowingActor = boardActor
    self.actors = {
        ba = boardActor, fa = fortueActor, la = luckActor, maa = mascoActor, moa = moneyActor
    }
	self.audioList = {
		"Asset/audio/onlycapturebyyou.mp3",
		"Asset/audio/loverday.mp3",
		"Asset/audio/lovehandsup.mp3"
	}
	
	if self.__object_detect_interval == nil then
		self.__object_detect_interval = 0
	end

	if self.__object_detect_name == nil then
		self.__object_detect_name = ""
	end

    print(TAG, "findActors", table.len(self.actors))
end

function code_entity:initAllPath(world)
	if self.sourcePath == nil and world ~= nil then
		self.sourcePath = 	XEPathFileTool.GetPathDir(XEUtility.GetAssetPackageValidPath(XEEngine:GetInstance():GetAppProjectResDir().."/noused",world:GetSceneAssetPath()))
		FileUtils:AddSearchPath(self.sourcePath)
		print("sourcePaht=", self.sourcePath)
	end

end

function code_entity:startPlayMusic(index)
	local arrayLen = #self.audioList
	
	if index < 1 or index > arrayLen then
        print("index["..index.."] is bigger than array length["..arrayLen.."]")
		return 
	end

	local audioPath = self.audioList[index]
	if audioPath == nil then
        print("music path is nil , just return")
		return 
	end

	if self.audioEngine == nil then
		self.audioEngine = audio.AudioEngine:getInstance()
	end

	print("play music " , audioPath)
	self.audioEngine:stopBackgroundMusic()
 	self.audioEngine:setBackgroundMusicVolume(1)
	self.audioEngine:playBackgroundMusic(audioPath,true)
end

function code_entity:run_face_detect_logic(world)

    local envBridge = XEMagicCore.GetDecorationEnvBridge()
    if envBridge ~= nil then
 		local var = XEDecorationEnvBridgeBase:GetDetectParam("video.max_faces")
	 	if var ~= nil then
             local max_faces = var.data:GetInt()
             for i = 1, max_faces, 1 do
                 local entity = XEMagicCore.GetFaceEntityByIndex(i)
                 if entity ~= nil and entity:IsValid() then
                     local currentCode = entity.nCurFaceExpressionCode
                     -- print(TAG, "---currentCode::", currentCode)
                     if self:hasCode(currentCode, 9) and lastExpressionCode ~= currentCode then
                         self:dealActorLogic()
                     end
                     lastExpressionCode = currentCode
                 end
             end
         else
             print(TAG, "GetDetectParam = nil")
         end
     else
         print(TAG, "GetDecorationEnvBridge = nil")
     end

	-- local envBridge = XEMagicCore.GetDecorationEnvBridge()
-- 	if envBridge ~= nil then
-- 		local max_faces = 10
-- 		for i = 1,max_faces,1 do
-- 			local entity = XEMagicCore.GetFaceEntityByIndex(i)
-- 			if entity ~= nil and entity:IsValid() then
-- 				print("found face " .. entity.nFaceIndex .. ", current emotion code is " .. entity.nCurFaceExpressionCode)
-- 				--do other logics here.
-- 				local currentCode = entity.nCurFaceExpressionCode
-- 				print(TAG, "---currentCode::", currentCode)
-- 				if self:hasCode(currentCode, 9) and lastExpressionCode ~= currentCode then
-- 					self:dealActorLogic()
-- 				end
-- 			end
-- 		end
-- 	end

end



function code_entity:run_object_detect_logic(interval)
	local envBridge = XEMagicCore.GetDecorationEnvBridge()
	if envBridge ~= nil then
		local max_objs = 10
			for i = 1,max_objs do
				local entity = XEMagicCore.GetObjectEntity(i)
				if not entity:IsValid() then 

						self.__object_detect_interval = self.__object_detect_interval + interval
						if self.__object_detect_interval > 500 then
							print("invalid!", interval, self.__object_detect_interval)
							self.__object_detect_interval = 0
							self.__object_detect_name = ""
						end
						break
				else
						print("found object entity " .. entity.nObjectIndex .. "," .. entity.strClassName, 	self.__object_detect_name,self.__object_detect_interval)
						if entity.strClassName == "five" then
								if self.__object_detect_name ~= "five" then
									self:dealActorLogic()
								end
								self.__object_detect_interval = 0
								self.__object_detect_name =  entity.strClassName
						end
				end
			end
	end
end

--- 处理隐藏显示逻辑
function code_entity:dealActorLogic()

    if isFirstIn == true then
        -- 首次进入，ba转圈，这时候可以随意触发
		print("trigger random logic ")
        self:randomActor()
        isFirstIn = false
    end
end


-- touch events registers
-- register in your entrance while necessary.
-- e.g :
--  function code_entity:onHolderEntrance(script_ins, actor)
--     self.__script_ins = script_ins
--     self.__holder = actor
-- 	   self:register_gesture_click()
-- 	   self:register_gesture_pinch()
-- end

-- reverse-comment functions like onTouchXXXXEvent that you've called the registered functions.

function code_entity:register_gesture_click()
    local gestureListener = xe.GestureEventListenerV1:Create()
    if self.__gestureListener == nil then self.__gestureListener = {} end
    table.insert(self.__gestureListener, gestureListener)
    gestureListener:RegisterHandler(function(sender, param)
        if self.onTouchClickEvent ~= nil and self.__holder ~= nil then
            self:onTouchClickEvent(self.__holder, param)
        end
    end, xe.Handler.EVENT_GESTURE_CLICK)
    xe.Director:GetInstance():GetEventDispatcher():SetEnabled(true)
    xe.Director:GetInstance():GetEventDispatcher():AddEventListener(
        gestureListener, nil)
end

function code_entity:register_gesture_move()
    local gestureListener = xe.GestureEventListenerV1:Create()
    if self.__gestureListener == nil then self.__gestureListener = {} end
    table.insert(self.__gestureListener, gestureListener)
    gestureListener:RegisterHandler(function(sender, param)
        if self.onTouchMoveEvent ~= nil and self.__holder ~= nil then
            self:onTouchMoveEvent(self.__holder, param)
        end
    end, xe.Handler.EVENT_GESTURE_MOVE)
    xe.Director:GetInstance():GetEventDispatcher():SetEnabled(true)
    xe.Director:GetInstance():GetEventDispatcher():AddEventListener(
        gestureListener, nil)
end

function code_entity:register_gesture_move2()
    local gestureListener = xe.GestureEventListenerV1:Create()
    if self.__gestureListener == nil then self.__gestureListener = {} end
    table.insert(self.__gestureListener, gestureListener)
    gestureListener:RegisterHandler(function(sender, param)
        if self.onTouchMove2Event ~= nil and self.__holder ~= nil then
            self:onTouchMove2Event(self.__holder, param)
        end
    end, xe.Handler.EVENT_GESTURE_MOVE2)
    xe.Director:GetInstance():GetEventDispatcher():SetEnabled(true)
    xe.Director:GetInstance():GetEventDispatcher():AddEventListener(
        gestureListener, nil)
end

function code_entity:register_gesture_pinch()
    local gestureListener = xe.GestureEventListenerV1:Create()
    if self.__gestureListener == nil then self.__gestureListener = {} end
    table.insert(self.__gestureListener, gestureListener)
    gestureListener:RegisterHandler(function(sender, param)
        if self.onTouchPinchEvent ~= nil and self.__holder ~= nil then
            self:onTouchPinchEvent(self.__holder, param)
        end
    end, xe.Handler.EVENT_GESTURE_PINCH)
    xe.Director:GetInstance():GetEventDispatcher():SetEnabled(true)
    xe.Director:GetInstance():GetEventDispatcher():AddEventListener(
        gestureListener, nil)
end

function code_entity:unregister_gesture_events()
    if self.__gestureListener ~= nil then
        for k, v in pairs(self.__gestureListener) do
            xe.Director:GetInstance():GetEventDispatcher()
                :RemoveEventListener(v)
        end
    end
    self.__gestureListener = nil
end

-- delay call
-- this function will be called once when the binding holder is ready to work.
function code_entity:onHolderEntrance(script_ins, world)
    self.__script_ins = script_ins
    self.__holder = world
    -- add something new here.
end

-- this function will be called once when the binding holder is ready to release.
function code_entity:onHolderRelease(world)
    self.__holder = nil
    self:unregister_gesture_events()

    if self.audioEngine == nil then
		self.audioEngine = audio.AudioEngine:getInstance()
	end
    print("stop all stopBackgroundMusic")
    self.audioEngine:stopBackgroundMusic()

    -- add something new here.
end

-- this function will be called each tick after the ticking of the holder.
function code_entity:onHolderTick(world, interval)
    -- add something new here.
	timeStamp = timeStamp + interval
    if not self.actors then
        print(TAG, "onHolderTick")
        self:findActors(world)
    end

--         print(TAG, "onHolderTick")
	self:initAllPath(world)
	self:run_face_detect_logic(interval)

end

-- this function will be called each tick after the rendering of the holder.
function code_entity:onHolderRender(world, viewport)
    -- add something new here.
end

-- this function will return the binding holder
function code_entity:holder()
    return self.__holder -- maybe nil, need to be verify when you use it.
end

-- this function will return the binding script_ins
function code_entity:script_ins()
    return self.__script_ins -- maybe nil, need to be verify when you use it.
end

-- --touch events(inject logics here)
-- function code_entity:onTouchClickEvent(actor, click_param)
--     -- add something new here.
--     if click_param.eState == GestureClickParam.Raised then
--         -- do anything that you want.
--     end
-- end

-- --single finger move
-- function code_entity:onTouchMoveEvent(world, move_param)
-- -- add something new here.
-- end

-- --double fingers move via same direction
-- function code_entity:onTouchMove2Event(world, move2_param)
-- -- add something new here.
-- end

-- --double fingers move via different directions
-- function code_entity:onTouchPinchEvent(world, pinch_param)
-- -- add something new here.
-- end

-- --indicated that the native events.  ids, posX, posY is array.
-- function code_entity:onNativeTouchesBeginEvent(world, number, ids, posX, posY)
-- -- add something new here.
-- end

-- function code_entity:onNativeTouchesMoveEvent(world, number, ids, posX, posY)
-- -- add something new here.
-- end

-- function code_entity:onNativeTouchesEndEvent(world, number, ids, posX, posY)
-- -- add something new here.
-- end

-- others, to be added.

-- add other logics as you want here.
-- This script will run once. code_entity will be built.
-- call something other executable here. 
print("こんにちは、じゃ、まだね。")
-- cannot call the cpp side function immediately.
-- the return value should be a table.
return code_entity
