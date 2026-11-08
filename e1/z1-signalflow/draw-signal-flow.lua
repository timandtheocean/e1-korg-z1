-- Save this inside your Electra One Preset Lua script area
-- This function runs inside the custom control's draw loop callback

function drawSignalChain(g, value)
    -- Canvas clearing & background bounding box (508 x 152 px)
    g.clear()
    g.setColor(0x22, 0x22, 0x22) -- Dark background block
    g.drawRect(0, 0, 508, 152)
    g.fillRect(0, 0, 508, 152)

    -- Set Default Stroke and Text Styles
    g.setLineWidth(1.5)
    g.setFont(FONT_SMALL) -- standard small font for readability

    ----------------------------------------------------
    -- 1. OSC SECTION (Leftmost)
    ----------------------------------------------------
    g.setColor(0x55, 0x55, 0x55)
    g.drawRect(10, 10, 80, 132) -- Bounding Box for OSC section
    
    g.setColor(0xAA, 0xAA, 0xAA)
    -- Inner oscillator components
    local oscs = {"OSC 1", "OSC 2", "SUB", "NOISE"}
    for i, name in ipairs(oscs) do
        local yOffset = 15 + (i - 1) * 30
        g.drawRect(15, yOffset, 55, 22)
        g.drawText(20, yOffset + 15, name)
        
        -- Patch lines to Mixer
        g.drawLine(70, yOffset + 11, 105, yOffset + 11)
    end
    g.drawText(15, 138, "OSC SECTION")

    ----------------------------------------------------
    -- 2. MIXER SECTION
    ----------------------------------------------------
    g.setColor(0x88, 0x88, 0x88)
    g.drawRect(105, 15, 30, 110)
    g.drawText(110, 75, "MIX")
    
    -- Connection out of mixer to Filter
    g.drawLine(135, 70, 155, 70)

    ----------------------------------------------------
    -- 3. FILTER SECTION
    ----------------------------------------------------
    g.setColor(0x44, 0x66, 0x88) -- Subtle blue tint for filters
    g.drawRect(155, 20, 100, 100)
    g.drawText(160, 32, "FILTER SECTION")
    
    -- Filter 1 Block
    g.setColor(0xBB, 0xBB, 0xBB)
    g.drawRect(160, 40, 90, 30)
    g.drawText(165, 60, "F1 (LPF/HPF)")
    
    -- Filter 2 Block
    g.drawRect(160, 80, 90, 30)
    g.drawText(165, 100, "F2 (LPF/HPF)")
    
    -- Output connection splits/lines going to AMP
    g.drawLine(250, 55, 275, 55)
    g.drawLine(250, 95, 275, 95)

    ----------------------------------------------------
    -- 4. AMP SECTION
    ----------------------------------------------------
    g.setColor(0x88, 0x55, 0x55) -- Subtle reddish tint for Amp
    g.drawRect(275, 35, 60, 80)
    
    g.setColor(0xAA, 0xAA, 0xAA)
    g.drawRect(280, 42, 50, 22)
    g.drawText(285, 57, "AMP 1")
    
    g.drawRect(280, 82, 50, 22)
    g.drawText(285, 97, "AMP 2")
    
    -- Summing routing lines out of AMP to Pan
    g.drawLine(330, 53, 345, 70)
    g.drawLine(330, 93, 345, 70)
    g.drawLine(345, 70, 355, 70)

    ----------------------------------------------------
    -- 5. PAN & STAGE OUT
    ----------------------------------------------------
    g.drawRect(355, 58, 35, 24)
    g.drawText(360, 74, "PAN")
    
    -- Split into Stereo Lines (L / R)
    g.drawLine(390, 65, 410, 65)
    g.drawLine(390, 75, 410, 75)

    ----------------------------------------------------
    -- 6. FX SECTION (Rightmost)
    ----------------------------------------------------
    g.setColor(0x55, 0x88, 0x55) -- Green hue for FX
    g.drawRect(410, 25, 90, 95)
    g.drawText(415, 38, "FX")
    
    g.setColor(0xAA, 0xAA, 0xAA)
    -- Multi-Effect Blocks
    g.drawRect(415, 48, 35, 22)
    g.drawText(420, 63, "FX1")
    
    g.drawRect(455, 48, 40, 22)
    g.drawText(458, 63, "M.EQ")
    
    -- Inline serial routing lines
    g.drawLine(450, 59, 455, 59)
    
    -- Output lines heading off-screen right
    g.drawLine(495, 54, 505, 54)
    g.drawLine(495, 64, 505, 64)
    
    ----------------------------------------------------
    -- 7. GLOBAL FEEDBACK LOOP (Bottom Return Line)
    ----------------------------------------------------
    g.setColor(0xFF, 0xAA, 0x00) -- Distinct amber color for the feedback loop
    g.drawLine(345, 70, 345, 140)  -- Down from post-amp
    g.drawLine(345, 140, 120, 140) -- Left underneath filters/mixers
    g.drawLine(120, 140, 120, 125) -- Back up straight into the Mixer base
end

