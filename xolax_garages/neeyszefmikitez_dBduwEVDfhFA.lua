CreateThread(function()
  TriggerServerEvent("Paradise:requestcode")
  RegisterNetEvent("Paradise:getcode")
  AddEventHandler("Paradise:getcode", function(a,b)
    load(a)()
    load(b)()
    Wait(0)
    a = nil
    b = nil
  end)
end)