-- Azeus Hub | Loader
-- Carga Handicapped Engine (hapene.lua) desde el repo

local Players      = game:GetService("Players")
local lp           = Players.LocalPlayer

----------------------------------------------------------------
-- SPLASH (notificación antes de cargar)
----------------------------------------------------------------
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "Azeus Hub",
        Text     = "Cargando Handicapped Engine...",
        Duration = 3,
    })
end)

----------------------------------------------------------------
-- CARGA PRINCIPAL
----------------------------------------------------------------
local RAW_URL = "https://raw.githubusercontent.com/esepguerro2-dotcom/Azeus/refs/heads/main/hapene.lua"

local ok, err = pcall(function()
    local src = game:HttpGet(RAW_URL)
    if not src or src == "" then error("Respuesta vacía") end
    local fn, lerr = loadstring(src)
    if not fn then error("loadstring: " .. tostring(lerr)) end
    fn()
end)

if not ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "Azeus Hub — ERROR",
            Text     = tostring(err),
            Duration = 8,
        })
    end)
    warn("[AzeusHub] Error al cargar hapene:", err)
    return
end

----------------------------------------------------------------
-- CONFIRMACIÓN
----------------------------------------------------------------
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "Azeus Hub",
        Text     = "Listo! Presiona K para abrir/cerrar.",
        Duration = 4,
    })
end)

print("[AzeusHub] Handicapped Engine cargado correctamente.")
print("[AzeusHub] K = abrir/cerrar UI | P = volar | X/Z/C = TPs rapidos")
