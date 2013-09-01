::Quick detect&fix
@SET version=3.1.260

::-Settings-
set manualRouter=			Examples: 192.168.0.1 or www.google.com
set manualAdapter=			Examples: Local Area Connection or Wireless Network Connection

set INT_StabilityHistory=25	Default: 25 (number of last tests to determine stability)
set INT_flukechecks=7		Default: 7 (test x times to verify result)
set INT_checkdelay=5		Default: 5 seconds
set INT_fixdelay=2			Default: 2 seconds
set INT_flukecheckdelay=1	Default: 1 seconds
set INT_timeoutsecs=1		Default: 1 seconds
set INT_checkrouterdelay=5	Default: 5 connects (wait x number of connects before verifying router and adapter)

set filterRouters=						:Separate filtered routers with Space
set filterAdapters=Tunnel VirtualBox	:Separate filter keywords with Space

::-GUI-
set pretty=1
set theme=subtle			none,subtle,vibrant,fullsubtle,fullvibrant,crazy



:: -DO NOT EDIT BELOW THIS LINE!-



setlocal enabledelayedexpansion
call :init

call :checkRouterAdapter .. ::

:loop
%debgn%MODE CON COLS=%cols% LINES=13
call :check
call :sleep %INT_checkdelay%
goto :loop




:header
set show_stbtlySTR=%stbltySTR:0=-%
set show_stbtlySTR=%show_stbtlySTR:1==%
set show_stbtlySTR=%show_stbtlySTR:2=*%
set show_stbtlySTR=%aft-%!show_stbtlySTR: =%-%!
if "%stbltySTR%"=="" set show_stbtlySTR=                                                   -
cls
COLOR %curcolor%
echo  --------------------------------------------------
echo  -      %ThisTitle%         -
echo. !show_stbtlySTR:~-%colnum%!
echo.
if not "%cur_ADAPTER%"=="" 		echo  Connection: %cur_ADAPTER%
if not "%cur_ROUTER%"=="" 		echo  Router:     %cur_ROUTER%
if not "%uptime%"=="" 		echo  Uptime:     %uptime%
if not "%stability%"==""	echo  Stability:  %stability%
echo.
if not %numfixes%==0 		echo  Fixes:      %numfixes%
if not "%lastresult%"=="" 	echo  Last Test:  %lastresult%
if not "%curstatus%"=="" 	echo  Status:     %curstatus%
goto :eof





:sleep
if "%1"=="" set pn=3
if not "%1"=="" set pn=%1
if %pn% equ 0 goto :eof
if "%checkconnects%"=="force" call :checkRouterAdapter ..
if not "%stability:~0,4%"=="Calc" if %checkconnects% geq %INT_checkrouterdelay% call :checkRouterAdapter ..&set /a pn-=tot
@set curstatus=Wait %pn% seconds...
%debgn%call :header
set /a timepassed+=pn
set /a pn+=1
if %pn% leq 0 goto :eof
ping -n %pn% -w 1000 127.0.0.1>nul
goto :eof

:crazy
@echo off
set /a cr_num=%random:~-1%
set /a cr_num+=%random:~-1%
if %cr_num% gtr 15 goto :crazy
:crazy2
set /a cr_num2=%random:~-1%-1
set /a cr_num2+=%random:~-1%-1
if %cr_num2% gtr 15 goto :crazy2
if "%cr_num%"=="%cr_num2%" goto :crazy
COLOR !crazystr:~%cr_num%,1!!crazystr:~%cr_num2%,1!
goto :eof




:check
@set curstatus=Testing connectivity...
%debgn%call :header
set result=
set resultUpDown=
set testrouter=www.google.com
if not "%cur_ROUTER%"=="" if %dbl% equ 0 set testrouter=%cur_ROUTER%

for /f "tokens=* delims=" %%p in ('ping -w %timeoutmilsecs% -n 1 %testrouter%') do set ping_test=%%p
echo %ping_test% |findstr "request could not find" >NUL
if %errorlevel% equ 0 set result=NotConnected&set resultUpDown=Down
echo %ping_test% |findstr "Unreachable" >NUL
if %errorlevel% equ 0 set result=Unreachable&set resultUpDown=Down
echo %ping_test% |findstr "General Failure" >NUL
if %errorlevel% equ 0 set result=Connecting...&set /a down+=timepassed&set curcolor=%pend%
echo %ping_test% |findstr "Minimum " >NUL
if %errorlevel% equ 0 set result=Connected&set resultUpDown=Up
if "%result%"=="" set result=TimeOut&set resultUpDown=Down

if "%lastresult%"=="" set lastresult=%result%

if "%resultUpDown%"=="Up" (
set /a checkconnects+=1
if not "%lastresult%"=="Connected" set /a timepassed/=2&set checkconnects=force
if %timepassed% leq 0 set timepassed=1
set /a up+=timepassed
set curcolor=%norm%
set stbltySTR=%stbltySTR% 0
)

if "%resultUpDown%"=="Down" (
if "%lastresult%"=="Connected" set /a timepassed/=2
if %timepassed% leq 0 set timepassed=1
set /a down+=timepassed
if "%result%"=="TimeOut" set /a down+=INT_timeoutsecs
set curcolor=%warn%
set stbltySTR=%stbltySTR% 1
set result=%result% %showdbl%
)

set timepassed=0
set /a dbl+=1
set showdbl=(fluke check %dbl%/%INT_flukechecks%)
call :set_uptime
call :set_stability %stbltySTR%

if "%result%"=="Connected" if not "%lastresult%"=="Connected" if "%resetted%"=="1" set /a numfixes+=1
set lastresult=%result%
if "%result%"=="Connected" set resetted=0
if not "%result%"=="Connected" if not %dbl% gtr %INT_flukechecks% call :sleep %INT_flukecheckdelay%&goto :check
if not "%result%"=="Connected" if %dbl% gtr %INT_flukechecks% call :resetAdapter
set dbl=0
set showdbl=
goto :eof


:set_uptime
if %up% geq 100000 set /a up=up/10&set /a down=down/10
set /a dispUP=up/INT_checkdelay
set /a dispDN=down/INT_checkdelay
set /a uptime=((up*10000)/(up+down))
set /a uptime+=0
set uptime=%uptime:~0,-2%.%uptime:~-2%%%        U:%dispUP% D:%dispDN%
goto :eof

:set_stability
set /a stblty_tests+=1
set /a stblty_val+=%1
if "%stblty_firstval%"=="" set stblty_firstval=%1
shift
if not "%1"=="" goto :set_stability
set stblty_over=0
if %stblty_tests% geq %INT_StabilityHistory% set /a stblty_over=stblty_tests-INT_StabilityHistory&set /a stblty_val-=stblty_firstval
if %stblty_over% geq 1 set /a stblty_over*=2
if %stblty_over% geq 1 set stbltySTR=!stbltySTR:~%stblty_over%!
set /a stblty_result=100-((stblty_val*100)/stblty_tests)
set stability=Very Poor [7]
if %stblty_result% gtr 40 set stability=Poor [6]
if %stblty_result% gtr 55 set stability=Lower [5]
if %stblty_result% gtr 70 set stability=Low [4]
if %stblty_result% gtr 85 set stability=Fair [3]
if %stblty_result% gtr 94 set stability=Normal [2]
if %stblty_result% equ 100 set stability=High [1]
if %stblty_tests% leq %INT_StabilityHistory% set stability=Calculating...(%stblty_tests%/%INT_StabilityHistory%)
if %stblty_tests% gtr %INT_StabilityHistory% set INT_checkdelay=%orig_checkdelay%
set stblty_tests=0
set stblty_val=0
set stblty_firstval=
goto :eof


:resetAdapter
set curcolor=%alrt%
@set curstatus=Resetting connection...
%debgn%call :header
set resetted=1
set stbltySTR=%stbltySTR% 2
if "%cur_Adapter%"=="" (
for /l %%n in (1,1,%con_num%) do netsh interface set interface "!connection%%n_name!" admin=disable>NUL 2>&1
for /l %%n in (1,1,%con_num%) do netsh interface set interface "!connection%%n_name!" admin=enable>NUL 2>&1
)
netsh interface set interface "%cur_ADAPTER%" admin=disable>NUL 2>&1
netsh interface set interface "%cur_ADAPTER%" admin=enable>NUL 2>&1
set checkconnects=force
call :sleep %INT_fixdelay%
goto :eof



:checkRouterAdapter
set checkconnects=0
set loading=%1
%2set curstatus=Check valid Router/Adapter&call :header
if not "%manualRouter%"=="" if not "%manualAdapter%"=="" goto :eof
set startsecs=%time:~6,2%
if not %numAdapters% equ 0 for /l %%n in (1,1,%numAdapters%) do set conn_%%n_cn=&set conn_%%n_gw=
call :getIPCONFIG
@echo .|set /p dummy=%loading%
set isConnected=0
if not "%cur_ADAPTER%"=="" set checkadapternum=0&call :checkadapterstatus
if "%isConnected%"=="1" goto :checkRouterAdapter_end
if not "%cur_ROUTER%"=="" if "%manualRouter%"=="" set cur_ROUTER=
if not "%cur_ADAPTER%"=="" if "%manualAdapter%"=="" set cur_ADAPTER=
@echo .|set /p dummy=%loading%
if "%manualrouter%"=="" call :getAutoRouter
@echo .|set /p dummy=%loading%
if "%cur_ADAPTER%"=="" if not "%manualRouter%"=="" call :getAutoAdapter
if "%cur_ADAPTER%"=="" if "%lastresult%"=="Connected" call :Ask4Adapter
if "%cur_ADAPTER%"=="" call :EnumerateAdapters %filterAdapters%

:checkRouterAdapter_end
set endsecs=%time:~6,2%
if %startsecs:~0,1% equ 0 set startsecs=%startsecs:~1,1%
if %endsecs:~0,1% equ 0 set endsecs=%endsecs:~1,1%
if %endsecs% lss %startsecs% set /a endsecs+=60
set /a tot=endsecs-startsecs
goto :eof

:getIPCONFIG
set numAdapters=0
for /f "tokens=* delims=" %%r in ('ipconfig') do call :getIPCONFIG_parse %%r
goto :eof

:getIPCONFIG_parse
set line=%*
echo %line% |findstr "adapter">NUL
if %errorlevel% equ 0 call :getIPCONFIG_parseAdapter %filterAdapters%&goto :eof
echo %line% |findstr "Media State">NUL
if %errorlevel% equ 0 goto :getIPCONFIG_parseMediaState
echo %line% |findstr "Gateway">NUL
if %errorlevel% equ 0 call :getIPCONFIG_parseGateway %filterRouters%&goto :eof
goto :eof

:getIPCONFIG_parseAdapter
@echo .|set /p dummy=%loading%
set line=%line:adapter =:%
set filtered=0
:getIPCONFIG_parseAdapter_loop
if not "%1"=="" echo %line%|FINDSTR /I "%1">NUL
if not "%1"=="" if %errorlevel% equ 0 set filtered=1
if not "%1"=="" shift&goto :getIPCONFIG_parseAdapter_loop
if %filtered% equ 1 goto :eof
set /a numAdapters+=1
for /f "tokens=2 delims=:" %%a in ("%line%") do set conn_%numAdapters%_cn=%%a
goto :eof

:getIPCONFIG_parseMediaState
if %filtered% equ 1 goto :eof
set filtered=1&set conn_%numAdapters%_cn=&set conn_%numAdapters%_gw=&set /a numAdapters-=1
goto :eof

:getIPCONFIG_parseGateway
if %filtered% equ 1 goto :eof
if not "%1"=="" echo %line%|FINDSTR /I "%1">NUL
if not "%1"=="" if %errorlevel% equ 0 set filtered=1&set conn_%numAdapters%_cn=&conn_%numAdapters%_ms=
if not "%1"=="" shift&goto :getIPCONFIG_parseGateway
if %filtered% equ 1 goto :eof
set ipv6=0
for /f "tokens=2-8 delims=:" %%a in ("%line%") do call :setIPv4IPv6 %%a %%b %%c %%d %%e
goto :eof

:setIPv4IPv6
if %ipv6% equ 1 set :=:
set ip_val=%1
if %ipv6% equ 0 set conn_%numAdapters%_gw=%ip_val%
if %ipv6% equ 1 set conn_%numAdapters%_gw=!conn_%numAdapters%_gw!%:%%ip_val:~0,4%
if not "%2"=="" if %ipv6% equ 0 set ipv6=1&set conn_%numAdapters%_gw=!conn_%numAdapters%_gw!:&shift&goto :setIPv4IPv6
if not "%2"=="" set ipv6=1&shift&goto :setIPv4IPv6
goto :eof


:getAutoRouter
set numrouters=0
set routers=0
:getAutoRouter_loop
set /a numrouters+=1
if not "!conn_%numrouters%_gw!"=="" set /a routers+=1&set lastrouter=!conn_%numrouters%_gw!&set lastadapter=!conn_%numrouters%_cn!
if %numrouters% lss %numAdapters% goto :getAutoRouter_loop
if %routers% equ 0 goto :eof
if %routers% equ 1 set cur_ROUTER=%lastrouter%
if %routers% equ 1 if "%manualAdapter%"=="" set cur_ADAPTER=%lastadapter%
if %routers% geq 2 call :Ask4Router
goto :eof


:checkadapterstatus
if %checkadapternum% geq %numAdapters% goto :eof
set /a checkadapternum+=1
if not "!conn_%checkadapternum%_cn!"=="%cur_ADAPTER%" goto :checkadapterstatus
if "!conn_%checkadapternum%_ms!"=="" if "!conn_%checkadapternum%_gw!"=="%cur_ROUTER%" set isConnected=1
goto :eof


:getAutoAdapter
if %numAdapters% equ 0 goto :eof
if %numAdapters% equ 1 set cur_ADAPTER=%conn_1_cn%
goto :eof



:Ask4Router
set /a lines=%numrouters%+6
%debgn%mode con cols=70 lines=%lines%
%debgn%call :header
set cur_ROUTER=
echo which router would you like to use?
echo.
for /l %%n in (1,1,%numrouters%) do set showroutr%%n=!conn_%%n_gw! !conn_%%n_cn!%statspacer%
for /l %%n in (1,1,%numrouters%) do echo -!showroutr%%n:~0,60! [%%n]
echo Or type "x" to skip...
echo.
set usrinput=
set usrinput2=
set /p usrinput=[] 
if "%usrinput%"=="" set usrinput=1
if "%usrinput%"=="x" goto :eof
for /l %%n in (1,1,%numrouters%) do if "%usrinput%"=="%%n" set cur_ROUTER=!conn_%%n_gw!
if "%cur_ROUTER%"=="" cls&echo.&echo.&echo Use "%usrinput%" as router address?
if "%cur_ROUTER%"=="" set /p usrinput2=[y/n] 
if "%usrinput%"=="" set cur_ROUTER=%usrinput%
if /i "%usrinput%"=="y" set cur_ROUTER=%usrinput%
if "%cur_ROUTER%"=="" goto :Ask4Router
set manualrouter=%cur_ROUTER%
echo.
goto :eof


:EnumerateAdapters
set con_num=0
set EA_filters=%*
for /f "tokens=* delims=" %%n in ('wmic nic get NetConnectionID') do call :get_network_connections_parse %%n
goto :eof

:get_network_connections_parse
set line=%*
if "%line%"=="" goto :eof
if "%line%"=="NetConnectionID" goto :eof
set filtered=0
call :get_network_connections_filter %EA_filters%
goto :eof

:get_network_connections_filter
if not "%1"=="" echo %line%|FINDSTR /I "%1">NUL
if not "%1"=="" if %errorlevel% equ 0 set filtered=1
if not "%1"=="" shift&goto :get_network_connections_filter
if %filtered% equ 1 goto :eof
set /a con_num+=1
set connection%con_num%_name=%line%
goto :eof

:Ask4Adapter
call :EnumerateAdapters
set /a lines=%con_num%+5
%debgn%mode con cols=52 lines=%lines%
%debgn%call :header
set cur_ADAPTER=
echo Which connection would you like to monitor?
echo.
for /l %%n in (1,1,%con_num%) do set showconn%%n=!connection%%n_name!%statspacer%
for /l %%n in (1,1,%con_num%) do echo -!showconn%%n:~0,40! [%%n]
echo.
set usrinput=
set /p usrinput=[] 
if "%usrinput%"=="" set usrinput=1
for /l %%n in (1,1,%con_num%) do if "%usrinput%"=="%%n" set cur_ADAPTER=!connection%%n_name!
if "%cur_ADAPTER%"=="" goto :ask4connection
set manualadapter=%cur_ADAPTER%
echo.
goto :eof


:init
if not "%pretty%"=="1" set debgn=::
%debgn%@echo off
%debgn%cls
@PROMPT=^>
@set cols=52
%debgn%MODE CON COLS=%cols% LINES=20
@echo.
@echo .|set /p dummy=initializing...
@call :init_colors %theme%
%debgn%COLOR %norm%
@SET ThisTitle=Lectrode's Quick Net Fix v%version%
@TITLE %ThisTitle%
@set numfixes=0
@set up=0
@set down=0
@set timepassed=1
@set dbl=0
@set numAdapters=0
@set stbltySTR=
@for /f "tokens=1,* DELIMS==" %%s in ('set INT_') do call :init_settn %%s %%t
@set orig_checkdelay=%INT_checkdelay%
@set INT_checkdelay=1
@set /a timeoutmilsecs=1000*INT_timeoutsecs
@call :init_manualRouter %manualRouter%
@for /f "tokens=1 DELIMS=:" %%a in ("%manualAdapter%") do call :init_manualAdapter %%a
@for /f "tokens=1 DELIMS=:" %%a in ("%filterAdapters%") do call :init_filterAdapters %%a
@for /f "tokens=1 DELIMS=:" %%a in ("%filterRouters%") do call :init_filterRouters %%a
@call :init_bar
@echo .|set /p dummy=..
goto :eof

:init_settn
set /a %1=%2
goto :eof

:init_manualRouter
set manualRouter=%1
set manualRouter=%manualRouter:http:=%
set manualRouter=%manualRouter:https:=%
set manualRouter=%manualRouter:/=%
if "%manualRouter%"=="Examples:" set manualRouter=
if not "%manualRouter%"=="" set cur_ROUTER=%manualRouter%
goto :eof

:init_manualAdapter
set manualAdapter=%*
set manualAdapter=%manualAdapter:Examples=%
if "%manualAdapter%"=="" goto :eof
set manualAdapter=%manualAdapter:	=%
if not "%manualAdapter%"=="" set cur_ADAPTER=%manualAdapter%
goto :eof

:init_filterAdapters
set filterAdapters=%*
if "%filterAdapters%"=="" goto :eof
set filterAdapters=%filterAdapters:	=%
goto :eof

:init_filterRouters
set filterRouters=%*
if "%filterRouters%"=="" goto :eof
set filterRouters=%filterRouters:	=%
goto :eof

:init_bar
set /a colnum=cols-2
set -=
set aft-=
if %colnum% leq %INT_StabilityHistory% goto :eof
set /a numhyp=(colnum/INT_StabilityHistory)
set /a hypleft=(colnum-(numhyp*INT_StabilityHistory))
set /a numhyp-=1
:init_bar_loop
if not %numhyp% leq 0 set -=%-%-&set /a numhyp-=1
if not %hypleft% leq 0 set aft-=%aft-%-&set /a hypleft-=1
set /a bar_loop_tot=numhyp+hypleft
if %bar_loop_tot% gtr 0 goto :init_bar_loop
goto :eof

:init_colors
set theme=%1
call :init_colors_%theme%
goto :eof

:init_colors_none
set norm=
set warn=
set alrt=
goto :eof

:init_colors_subtle
set norm=07
set warn=06
set alrt=04
set pend=03
goto :eof

:init_colors_vibrant
set norm=0a
set warn=0e
set alrt=0c
set pend=0b
goto :eof

:init_colors_fullsubtle
set norm=20
set warn=60
set alrt=40
set pend=30
goto :eof

:init_colors_fullvibrant
set norm=a0
set warn=e0
set alrt=c0
set pend=b0
goto :eof

:init_colors_crazy
set norm=^&call :crazy
set warn=^&call :crazy
set alrt=^&call :crazy
set crazystr=0123456789ABCDEF
goto :eof