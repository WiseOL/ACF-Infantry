-- SWEP HUD styling matched to ACF-3 core/overlay/overlay_cl.lua.
-- Read ACF's user palette live; no changes to the ACF overlay renderer.
if SERVER then AddCSLuaFile() return end
if ACFSwepsTheme then return end
ACFSwepsTheme = {}
local T = ACFSwepsTheme
local defaults = {
    COLOR_DROP_SHADOW = Color(2, 9, 14, 227),
    COLOR_PRIMARY_BACKGROUND = Color(11, 32, 46, 204),
    COLOR_TEXT = Color(236, 252, 255, 245),
    COLOR_PRIMARY_COLOR = Color(150, 200, 210, 245),
    COLOR_BORDER_LIGHT_COLOR = Color(150, 200, 210, 245),
    COLOR_SECONDARY_COLOR = Color(60, 90, 105, 245),
    COLOR_TERTIARY_COLOR = Color(84, 116, 131, 245),
    COLOR_SUCCESS_TEXT = Color(166, 255, 170),
    COLOR_WARNING_TEXT = Color(255, 220, 50),
    COLOR_ERROR_TEXT = Color(255, 50, 50)
}
function T.Color(key)
    local cv = GetConVar("acf_overlay_" .. string.lower(key))
    if cv then return string.ToColor(cv:GetString()) end
    return defaults[key] or defaults.COLOR_TEXT
end
local fontScale
local function Fonts()
    local scale = math.Clamp(ScrH() / 1080, 0.65, 2)
    if fontScale == scale then return end
    fontScale = scale
    local font = system.IsWindows() and "Conduit ITC Light" or "conduit.ttf"
    surface.CreateFont("ACFSWEP_OverlayHeader", {font=font, size=math.Round(30*scale), weight=900, scanlines=2, antialias=true, extended=true})
    surface.CreateFont("ACFSWEP_OverlayGlow", {font=font, size=math.Round(30*scale), weight=900, blursize=6, scanlines=4, antialias=true, extended=true})
    surface.CreateFont("ACFSWEP_OverlayKey", {font=font, size=math.Round(19*scale), weight=900, antialias=true, extended=true})
    surface.CreateFont("ACFSWEP_OverlayValue", {font=font, size=math.Round(19*scale), weight=500, antialias=true, extended=true})
end
Fonts()
local gradient = Material("vgui/gradient_down")
function T.Panel(_, x, y, w, h)
    local scale = math.Clamp(ScrH()/1080, 0.65, 2)
    local edge = math.max(1, math.Round(2*scale))
    surface.SetDrawColor(T.Color("COLOR_DROP_SHADOW"))
    surface.DrawRect(x+4, y+4, w, h)
    surface.SetDrawColor(T.Color("COLOR_PRIMARY_BACKGROUND"))
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(T.Color("COLOR_BORDER_LIGHT_COLOR"))
    surface.DrawRect(x,y,w,edge) surface.DrawRect(x,y,edge,h)
    surface.SetDrawColor(T.Color("COLOR_TERTIARY_COLOR"))
    surface.DrawRect(x,y+h-edge,w,edge) surface.DrawRect(x+w-edge,y,edge,h)
end
function T.Text(text,font,x,y,color,xa,ya)
    Fonts()
    local header = font == "DermaLarge"
    local chosen = header and "ACFSWEP_OverlayHeader" or "ACFSWEP_OverlayKey"
    color = color or T.Color("COLOR_TEXT")
    if header then
        draw.SimpleText(text,"ACFSWEP_OverlayGlow",x,y,Color(color.r,color.g,color.b,90),xa,ya)
    end
    return draw.SimpleText(text,chosen,x,y,color,xa,ya)
end
function T.Row(key,value,x,y,w,scale)
    Fonts()
    local mid = x + w * 0.44
    draw.SimpleText(key,"ACFSWEP_OverlayKey",mid-10*scale,y,T.Color("COLOR_TEXT"),TEXT_ALIGN_RIGHT)
    draw.SimpleText(":","ACFSWEP_OverlayKey",mid,y,T.Color("COLOR_TEXT"))
    draw.SimpleText(tostring(value),"ACFSWEP_OverlayValue",mid+14*scale,y,T.Color("COLOR_TEXT"))
end
function T.Bar(x,y,w,h,fraction,color)
    fraction = math.Clamp(fraction,0,1)
    surface.SetDrawColor(T.Color("COLOR_SECONDARY_COLOR")) surface.DrawRect(x,y,w,h)
    color = color or Color(112,191,243)
    surface.SetDrawColor(color) surface.DrawRect(x,y,w*fraction,h)
    surface.SetMaterial(gradient)
    surface.SetDrawColor(color.r*0.8,color.g*0.8,color.b*0.8,110)
    local offset = RealTime()%1
    surface.DrawTexturedRectUV(x,y,w*fraction,h,0,offset,0,offset+8)
    draw.NoTexture()
    surface.SetDrawColor(T.Color("COLOR_TERTIARY_COLOR")) surface.DrawOutlinedRect(x,y,w,h,1)
end

T.VerticalHUD = true
