function love.conf(t)
    t.window.title = "Keyboard vs. Mouse"
     t.window.icon = "/resources/images/icon.png"
    
    t.window.width = 1200
    t.window.height = 800
    
    t.modules.joystick = false
    t.modules.physics = false
end