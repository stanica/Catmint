
function SaveX(sErr)
    if (sErr) then
        s.err = sErr
    end
    file.remove("s.txt")
    file.open("s.txt","w+")
    for k, v in pairs(s) do
        file.writeline(k .. "=" .. v)
    end                
    file.close()
    collectgarbage()
end

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function dwn()
    -- body
    n = n + 1
    v = data[n]
    if v == nil then 
        --dofile(data[1]..".lc")
        print('no file name:', dump(data))
        bootfile= string.gsub(data[1], '\.lua$','') --string.gsub(s, '\....$','')
        s.boot = bootfile..".lc"
        SaveX("No error")
        node.restart()

    else 
        print("Filename in dwn: "..v)
        filename=v

            file.remove(v);
            file.open(v, "w+")

            payloadFound = false
            conn=net.createConnection(net.TCP, 0) 
            conn:on("receive", function(conn, payload)
                if (payloadFound == true) then
                    file.write(payload)
                    file.flush()
                else
                    if (string.find(payload,"\r\n\r\n") ~= nil) then
                        file.write(string.sub(payload,string.find(payload,"\r\n\r\n") + 4))
                        file.flush()
                        payloadFound = true
                    end
                end

                payload = nil
                collectgarbage()
            end)
            conn:on("disconnection", function(conn) 
                conn = nil
                file.close()
                ext = string.sub(v, -3)
                if (ext == "lua") then
                    node.compile(filename)
                end
                dwn()

            end)
            conn:on("connection", function(conn)
                conn:send("GET /"..s.path.."/uploads/"..id.."/"..v.." HTTP/1.0\r\n"..
                      "Host: "..s.host.."\r\n"..
                      "Connection: close\r\n"..
                      "Accept-Charset: utf-8\r\n"..
                      "Accept-Encoding: \r\n"..
                      "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n".. 
                      "Accept: */*\r\n\r\n")
            end)
            conn:connect(80,s.host)
    end

end

function FileList(sck,c)
    print ("initialized",c)
    print("done printing")
    local nStart, nEnd = string.find(c, "\n\n")
    if (nEnde == nil) then
        nStart, nEnd = string.find(c, "\r\n\r\n")
    end
    c = string.sub(c,nEnd+1)
    print("length: "..string.len(c))
    if(string.len(c) == 0) then
        return
    end
    data = mysplit(c, "\n") -- fill the field with filenames
    print('data:',dump(data))
    for i=1, #data do
        if(data[i] ~= nil) then
            local extension = string.sub(data[i], -3)
            if (string.len(data[i]) > 0) then
                if (extension == "lua") then
                    data = { data[i] }
                end
            end
        end
    end
    print('data:', dump(data))
    n = 1
    
    v = data[n]
    print("Filename in FileList: ", v)
    if(v ~= nil) then
        filename=v
        file.remove(v);
        file.open(v, "w+")
    
        payloadFound = false
        connection=net.createConnection(net.TCP, 0)
    end
    connection:on("receive", function(conn, payload)
    print('received payload:',payload)
        print('filename after payload: ',v)
        if (payloadFound == true) then
            file.write(payload)
            file.flush()
        else
            if (string.find(payload,"\r\n\r\n") ~= nil) then
                file.write(string.sub(payload,string.find(payload,"\r\n\r\n") + 4))
                file.flush()
                payloadFound = true
            end
        end

        payload = nil
        collectgarbage()
    end)
    connection:on("disconnection", function(conn2) 
        conn2 = nil
        connection = nil
        file.close()
        if(v ~= nil) then
            ext = string.sub(v, -3)
            if (ext == "lua") then
                node.compile(v)
            end
            
        end
        dwn()
    end)
    connection:on("connection", function(conn2)
        print('in connection', v, dump(data))
        if(v ~= nil) then
        print("GET /"..s.path.."/uploads/"..id.."/"..v.." HTTP/1.1\r\n"..
                  "Host: "..s.host.."\r\n"..
                  "Connection: close\r\n"..
                  "Accept-Charset: utf-8\r\n"..
                  "Accept-Encoding: \r\n"..
                  "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n".. 
                  "Accept: */*\r\n\r\n")
            conn2:send("GET /"..s.path.."/uploads/"..id.."/"..v.." HTTP/1.1\r\n"..
                  "Host: "..s.host.."\r\n"..
                  "Connection: close\r\n"..
                  "Accept-Charset: utf-8\r\n"..
                  "Accept-Encoding: \r\n"..
                  "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n".. 
                  "Accept: */*\r\n\r\n")
        end
    end)
    if(connected == false) then
        print('connecting first time')
        connection:connect(80,s.host)
        connected = true
    end

    collectgarbage()
end

print("fetch lua..")
data = {}
filename=nil
LoadX()
connected = false

wifi.setmode (wifi.STATION)
station_cfg = {}
station_cfg.ssid=s.ssid
station_cfg.pwd=s.pwd
wifi.sta.config(station_cfg)
wifi.sta.autoconnect (1)

iFail = 20 -- trying to connect to AP in 20sec, if not then reboot
print('Attempting to connect...')
tmr.alarm (1, 1000, 1, function ( )
  iFail = iFail -1
  if (iFail == 0) then
    SaveX("could not access "..s.ssid)
    file.remove("s.txt")
    node.restart()
  end      
  
   if wifi.sta.getip ( ) ~= nil then
    print ("ip: " .. wifi.sta.getip ( ))
    print("GET /".. s.path .."/node.php?id="..id.."&list"..
                " HTTP/1.1\r\n".. 
                "Host: "..s.domain.."\r\n"..
                "Accept: */*\r\n"..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                "\r\n\r\n")
    tmr.stop (1)
    -- get list of files
    sk=net.createConnection(net.TCP, 0)
    sk:on("connection",function(conn, payload)
                sk:send("GET /".. s.path .."/node.php?id="..id.."&list"..
                " HTTP/1.1\r\n".. 
                "Host: "..s.domain.."\r\n"..
                "Accept: */*\r\n"..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                "\r\n\r\n") 
            end)
    sk:on("receive", FileList)
    
    --sGet = "GET /".. s.path .. " HTTP/1.1\r\nHost: " .. s.domain .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    sk:connect(80,s.host) 
    
  end
  collectgarbage()
 
end)



 print(collectgarbage("count").." kB used")
