local mod = RegisterMod('Camera Shenanigans', 1)
local game = Game()

if REPENTOGON then
  mod.lastMousePosition = nil -- Vector
  mod.lastPauseMenuState = PauseMenuStates.CLOSED -- OPEN, OPTIONS
  mod.sliderPercent = {
    h = 0.5,
    v = 0.5
  }
  
  function mod:onRender()
    mod:RemoveCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onRender)
    mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
    mod:setupImGui()
  end
  
  -- handle pause menu input: mouse clicks, keyboard/thumbstick for player 1
  function mod:onRenderInput()
    if game:IsPaused() and game:GetPauseMenuState() == PauseMenuStates.OPEN then
      if mod.lastPauseMenuState == PauseMenuStates.CLOSED then
        mod:setCameraByPlayer(0) -- normalize the camera so we know where it's at
      end
      
      if not ImGui.IsVisible() then
        if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) then
          local pos = Input.GetMousePosition(true)
          mod.lastMousePosition = Vector(pos.X, pos.Y)
        else
          if mod.lastMousePosition then -- clicked and released
            mod:setCamera(mod.lastMousePosition.X, mod.lastMousePosition.Y, true)
          else
            local keyboard = 0
            local ci = game:GetPlayer(0).ControllerIndex
            
            local left, right, up, down
            
            if ci == keyboard then
              -- wasd
              left = Input.GetActionValue(ButtonAction.ACTION_LEFT, ci)
              right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, ci)
              up = Input.GetActionValue(ButtonAction.ACTION_UP, ci)
              down = Input.GetActionValue(ButtonAction.ACTION_DOWN, ci)
            elseif ci > keyboard then -- controller
              local a = 4
              local b = 5
              local x = 6
              local y = 7
              
              -- right thumbstick only, exclude face buttons
              if not Input.IsButtonPressed(a, ci) and
                 not Input.IsButtonPressed(b, ci) and
                 not Input.IsButtonPressed(x, ci) and
                 not Input.IsButtonPressed(y, ci)
              then
                -- 0.0 to 1.0
                left = Input.GetActionValue(ButtonAction.ACTION_SHOOTLEFT, ci)
                right = Input.GetActionValue(ButtonAction.ACTION_SHOOTRIGHT, ci)
                up = Input.GetActionValue(ButtonAction.ACTION_SHOOTUP, ci)
                down = Input.GetActionValue(ButtonAction.ACTION_SHOOTDOWN, ci)
              end
            end
            
            if left and right and up and down then
              local h = 0.0
              local v = 0.0
              local speed = 0.015
              
              if left > 0.0 then
                h = h - (speed * left)
              end
              if right > 0.0 then
                h = h + (speed * right)
              end
              if up > 0.0 then
                v = v - (speed * up)
              end
              if down > 0.0 then
                v = v + (speed * down)
              end
              
              if h ~= 0.0 or v ~= 0.0 then
                mod.sliderPercent.h = math.max(0.25, math.min(mod.sliderPercent.h + h, 0.75))
                mod.sliderPercent.v = math.max(0.25, math.min(mod.sliderPercent.v + v, 0.75))
                mod:setCameraBySliders(true)
              end
            end
          end
          
          mod.lastMousePosition = nil
        end
      else
        mod.lastMousePosition = nil
      end
    else
      mod.lastMousePosition = nil
    end
    
    mod.lastPauseMenuState = game:GetPauseMenuState()
  end
  
  function mod:setCamera(x, y, updateSliders)
    local room = game:GetRoom()
    local camera = room:GetCamera()
    camera:SnapToPosition(Vector(x, y))
    
    if updateSliders then
      mod:updateSliders(x, y)
    end
  end
  
  function mod:setCameraByPlayer(idx)
    local player = game:GetPlayer(idx)
    
    if player then
      mod:setCamera(player.Position.X, player.Position.Y, true)
    end
  end
  
  function mod:setCameraBySliders(updateSliders)
    local room = game:GetRoom()
    local topLeft = room:GetTopLeftPos()
    local bottomRight = room:GetBottomRightPos()
    
    local x = ((bottomRight.X - topLeft.X) * mod.sliderPercent.h) + topLeft.X
    local y = ((bottomRight.Y - topLeft.Y) * mod.sliderPercent.v) + topLeft.Y
    mod:setCamera(x, y, updateSliders)
  end
  
  function mod:updateSliders(x, y)
    local room = game:GetRoom()
    local topLeft = room:GetTopLeftPos()
    local bottomRight = room:GetBottomRightPos()
    
    local h = (x - topLeft.X) / (bottomRight.X - topLeft.X)
    local v = (y - topLeft.Y) / (bottomRight.Y - topLeft.Y)
    h = math.max(0.25, math.min(h, 0.75))
    v = math.max(0.25, math.min(v, 0.75))
    ImGui.UpdateData('shenanigansFloatCameraHorizontal', ImGuiData.Value, h)
    ImGui.UpdateData('shenanigansFloatCameraVertical', ImGuiData.Value, v)
    mod.sliderPercent.h = h
    mod.sliderPercent.v = v
  end
  
  function mod:setupImGui()
    if not ImGui.ElementExists('shenanigansMenu') then
      ImGui.CreateMenu('shenanigansMenu', '\u{f6d1} Shenanigans')
    end
    ImGui.AddElement('shenanigansMenu', 'shenanigansMenuItemCamera', ImGuiElement.MenuItem, '\u{f083} Camera Shenanigans')
    ImGui.CreateWindow('shenanigansWindowCamera', 'Camera Shenanigans')
    ImGui.LinkWindowToElement('shenanigansWindowCamera', 'shenanigansMenuItemCamera')
    
    ImGui.AddElement('shenanigansWindowCamera', '', ImGuiElement.SeparatorText, 'Players')
    for i, v in ipairs({
                        { label = '1', idx = 0 },
                        { label = '2', idx = 1 },
                        { label = '3', idx = 2 },
                        { label = '4', idx = 3 },
                        { label = '5', idx = 4 },
                        { label = '6', idx = 5 },
                        { label = '7', idx = 6 },
                        { label = '8', idx = 7 },
                      })
    do
      ImGui.AddButton('shenanigansWindowCamera', 'shenanigansBtnCameraPlayer' .. i, v.label, function()
        if Isaac.IsInGame() then
          mod:setCameraByPlayer(v.idx)
        end
      end, false)
      if i < 8 then
        ImGui.AddElement('shenanigansWindowCamera', '', ImGuiElement.SameLine, '')
      end
    end
    
    ImGui.AddElement('shenanigansWindowCamera', '', ImGuiElement.SeparatorText, 'Sliders')
    for _, v in ipairs({
                        { label = 'Horizontal', field = 'h' },
                        { label = 'Vertical'  , field = 'v' },
                      })
    do
      ImGui.AddSliderFloat('shenanigansWindowCamera', 'shenanigansFloatCamera' .. v.label, v.label, function(i)
        mod.sliderPercent[v.field] = i
        
        if Isaac.IsInGame() then
          mod:setCameraBySliders(false)
        end
      end, mod.sliderPercent[v.field], 0.25, 0.75, '%.2f') -- below 25% / above 75% doesn't appear visibly different
    end
  end
  
  mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onRender)
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRenderInput)
end