function LoadX()
    s = {ssid="", pwd="", host="", domain="", path="", err="",boot="",update=0}
    if (file.open("s.txt","r")) then
        local sF = file.read()
        --print("setting: "..sF)
        file.close()
        for k, v in string.gmatch(sF, "([%w.]+)=([%S ]+)") do    
            s[k] = v
            --print(k .. ": " .. v)
        end
    end
end

function SaveXY(sErr)
    if (sErr) then
        s.err = sErr
    end
    file.remove("s.txt")
    file.open("s.txt","w+")
    for k, v in pairs(s) do
        --print(k, v)
        file.writeline(k .. "=" .. v)
    end                
    file.close()
    collectgarbage()
end



function update()
conn3=net.createConnection(net.TCP, 0)
    conn3:on("connection",function(conn, payload)
    conn3:send("GET /".. s.path .."/files/"..id.."/update"..
                " HTTP/1.1\r\n".. 
                "Host: "..s.domain.."\r\n"..
                "Accept: */*\r\n"..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                "\r\n\r\n") 
            end)

    conn3:on("receive", function(conn, payload)
        if string.find(payload, "UPDATE")~=nil then
            s.boot=nil
            SaveXY()
            node.restart()
        else
            payload = nil
            conn3:close()
            conn3 = nil
        end
    end)
    conn3:connect(80,s.host)
end

id = node.chipid()
print ("nodeID is: "..id)

print(collectgarbage("count").." kB used")
LoadX()
code, reason = node.bootreason()
if((code == 2 and reason == 3) or code == 4) then
    s.boot=nil
    SaveXY()
    node.restart()
end

if (s.host~="") then
    if (tonumber(s.update)>0) then
        tmr.create():alarm (10000, tmr.ALARM_AUTO, function()
                update()
            end)
    end
    if (s.boot~="") then
        if(file.open(s.boot)) then   
            dofile(s.boot)
        else 
            s.boot=nil
            SaveXY()
            node.restart() 
        end
    else
        dofile("client.lua")
    end
else
    --dofile("server.lua")
    print('shit') 
end 
