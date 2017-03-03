-- ### Networkservice ###
-- ### Autor: NightDragon 	###
-- ### Version 1.1 					###
-- ### Datum 12.04.2016 			###


--## Variablen und Basisobjekt

-- Include API-Commands
os.loadAPI("/libs/netapi")
os.loadAPI("/libs/telegramapi")
os.loadAPI("/libs/iniapi")

app_version = "1.0"
modem_channel_r = 1
modem_channel_t = 1
modem_side = "top"
monitor_side = "left"
computer_type = 0
ht_max = 1000
upst = "deaktivieren"
screen1 = nil

-- Tabelle der Netzteilnehmer
hosttable = {}

-- Initialisierung
local function Init()
	print("Initialisierung laeuft...")
    local temp = nil
	netapi.open(modem_side, modem_channel_t, modem_channel_r)
	screen1 = deviceapi.monitor_init(monitor_side)
	-- Hosttable erstellen und initialisieren
    temp = iniapi.load("hosts")
    if temp[1] then
        hosttable = temp
        print("Hoststable loaded")
    else
        for i=1, ht_max do
            hosttable[i] = {
                id = 0,
                label = "",
                systype = 0
            }
        end
    end
	print("Initialisierung beendet.")
end

-- Herunterfahren
local function Final()
	print("System faehrt herunter...")
	netapi.close()
    iniapi.save("hosts",hosttable)
	print("Erledigt.")
	print("Good bye!")
end

local function CheckHostRecord(sysid)
	local found = 0
    local i = 0
    
	for i=1, ht_max do
		if hosttable[i].id == sysid then return i end
	end
    return 0
end

local function CheckHostSlot()
	local found = 0
    local i=0
    
	for i=1, ht_max do
		if hosttable[i].id == 0 then return i end
	end
    return 0
end

local function UpdateHostRecord(insert, sysid, label, systype)
	local tableid = 0
    if sysid == nil then sysid = 0 end
    if label == nil then label = "" end
    if systype == nil then systype = 0 end
	
	if insert then
		tableid = CheckHostRecord(sysid)
		if tableid > 0 then
			hosttable[tableid].id = sysid
			hosttable[tableid].label = label
            hosttable[tableid].systype = systype
            deviceapi.monitor_write(screen1, "Upd. Host '"..sysid.."'")
		else
			tableid = CheckHostSlot()
			assert(tableid, "Error, no free slot in host database!")
			hosttable[tableid].id = sysid
			hosttable[tableid].label = label
            hosttable[tableid].systype = systype
            deviceapi.monitor_write(screen1, "+ Host '"..sysid.."'")
		end
	else
        tableid = CheckHostRecord(sysid)
        if tableid > 0 then
            hosttable[tableid].id = 0
            hosttable[tableid].label = ""
            hosttable[tableid].systype = 0
            deviceapi.monitor_write(screen1, "- Host '"..sysid.."'")
        end
	end
end

local function PrintHostRecors()
    deviceapi.monitor_write(screen1, "### Hosttable ###")
    deviceapi.monitor_tab(screen1, {"ID","Hostname","Type"})
    deviceapi.monitor_br(screen1)
    for i=1, ht_max do
        if hosttable[i].id > 0 then
            deviceapi.monitor_tab(screen1, {tostring(hosttable[i].id),hosttable[i].label,tostring(hosttable[i].systype)})
            deviceapi.monitor_br(screen1)
        end
    end
        deviceapi.monitor_br(screen1)
end

local function NetService()
	while true do
		local message = netapi.modem_receive(true, true)
		if message ~= nil and type(message.cmd) == "table" then
			if message.cmd.name == "attach" then
				UpdateHostRecord(true, message.cmd.p1, message.cmd.p2, message.cmd.p3)
			elseif message.cmd.name == "deattach" then
				UpdateHostRecord(false, message.cmd.p1, "", 0)		
			end
		end
	end
end


local function CyclicUpdate()
    while true do
        sleep(600)
        print("\nCyclic Network Update in progress...\n")
        for i=1, ht_max do
            netapi.net_ping(i)
        end
        iniapi.save("hosts",hosttable)
        print("\nCyclic Update done!\n")
    end
end


-- #### Programmstart #### 
print("Welcome to the Net Server (Network Server)")
print("Version: "..app_version)
print("This is System ID "..os.getComputerID())

local function Main()
	local Mainloop = true
	
	while Mainloop do
		local Antwort = ""
        print("## Hauptmenue ##")
        print("---------------")
        print("1 Hosts im Netzwerk")
		print("2 Hosts aktualiseren")
		print("9 Angeschlossene Geraete")
        print("u Updates "..upst)
        print("c Monitor leeren")
        print("q Programm beenden")
        print("\nEingabe: ")
		Antwort=read()
		
		if Antwort == "q" then
            Mainloop = false
		elseif Antwort == "c" then
            deviceapi.monitor_clear(screen1)
		elseif Antwort == "1" then
            print("Table printed on big screen!")
            PrintHostRecors()
        elseif Antwort == "2" then
            print("Netz wird durchsucht, das kann etwas dauern. Bitte warten...")
            for i=1, ht_max do
                netapi.net_ping(i)
            end
            iniapi.save("hosts",hosttable)
            sleep(2)
            print("Erledigt!")
        elseif Antwort == "9" then
            local periList = peripheral.getNames()
            for i = 1, #periList do
                print(peripheral.getType(periList[i]).."::=\""..periList[i].."\".")
            end

        elseif Antwort == "u" then
            if upst == "aktivieren" then
                netapi.accept_update(false)
                upst = "deaktivieren"
            else
                netapi.accept_update(true)
                upst = "aktivieren"
            end
        else
            print("Eingabe ungueltig!")
        end
	end

end

Init() -- Initialisierung
parallel.waitForAny(NetService, Main, CyclicUpdate)
Final() -- Herunterfahren