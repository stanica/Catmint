id = node.chipid()
processing = false;
logs = {}

function LoadX()
    s = {ssid="", pwd="", host="", domain="", path="", err="",boot="",update=0}
    if (file.open("s.txt","r")) then
        local sF = file.read()
        file.close()
        for k, v in string.gmatch(sF, "([%w.]+)=([%S ]+)") do    
            s[k] = v
        end
    end
end
LoadX()

function log(text)
    if(processing) then
        print("inserting")
        table.insert(logs, 1, text)
    else
        if(#logs == 0) then
            table.insert(logs, 1, text)
        end
        processing = true
        process()
    end
    
end

function process()
    http.post('http://' .. s.host .. '/' .. s.path .. '/files/'..id .. '/log',
    'Content-Type: application/json\r\n',
    '{"text":"' .. table.remove(logs) .. '"}',
    function(code, data)
        if (code < 0) then
            print("HTTP request failed")
        end
        print("logs size", #logs)
        if(#logs ~= 0) then
            process()
        else
            processing = false
        end
    end)
end