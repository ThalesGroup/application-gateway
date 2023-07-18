local defaultPlugin = {}
--local session = require "resty.session"
local log = ngx.log
local DEBUG = ngx.DEBUG
local ERROR = ngx.ERR
local WARN = ngx.WARN
local basicAuthScheme = "HTTP BASIC"
local defaultPluginName = "defaultPlugin"
local formAuthScheme = "Form Authentication"

local HeaderAttributeTypes = {
    Header = "header",
    Cookie = "cookie",
    queryParam = "param",
    Form = "form"
}


------------------------------------------------------------------------------------------------------------------------
-- INTERFACE METHODS
------------------------------------------------------------------------------------------------------------------------


-- this method would be called before STA login flow starts
function defaultPlugin.preLoginRequestHandler()
    print ("application1 preLoginHandler called")
end
 
-- this method would be called after STA login flow has completed successfully
-- attributeValues parameter - would contain the key-value pair for the attributes configured in the application template in STA console
function defaultPlugin.postLoginRequestHandler(attributeValues,id_token,authScheme,loginUrl,authSession)
    
    defaultPlugin.processAttributes(attributeValues,id_token,authScheme,loginUrl,authSession) 

end
 
-- this method would be called before end application logout is called
function defaultPlugin.preLogoutRequestHandler(attributeValues,authScheme,logoutUrl)
    print ("application1 preLogoutHandler called")
end

-- This method is called before the response is returned to the HTTP clients (browsers)
function defaultPlugin.PreResponseHandler(authScheme,loginUrl,logoutUrl)
    print ("application1 preResponseHandler called")
end

-- this method will be called to get the application name for which this plugin methods would be invoked
function defaultPlugin.getAppFriendlyName()
    return "Generic Template for SafeNet App Gateway New"
end
 
-- this method will be called to get the html page from which form would be posted
function defaultPlugin.getFormHtml()
    return "/customPlugins/customPluginTemplate.html"
end

------------------------------------------------------------------------------------------------------------------------
-- HELPER METHODS
------------------------------------------------------------------------------------------------------------------------


defaultPlugin.processAttributes =function(headerAttributes,id_token,authScheme,loginUrl,authSession)

    defaultPlugin.setHeaderAttributes(headerAttributes,id_token,authScheme)
    defaultPlugin.setCookieAttributes(headerAttributes,id_token,authScheme)
    defaultPlugin.setQueryParamAttributes(headerAttributes,id_token,authScheme)

 if ngx.var.request_method == "POST" and ngx.var.request_uri == loginUrl then
	   defaultPlugin.setFormAttributes(headerAttributes,id_token,authScheme,authSession)
  end
end

defaultPlugin.setHeaderAttributes = function(headerAttributes,id_token,authScheme)
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Header then
            ngx.req.set_header(value.HeaderName, defaultPlugin.getHeaderAttributeValue(value,id_token))
        end
    end
end


ngx.req.set_header("X-USER", id_token.sub)
--if authScheme ~=nil and authScheme ~='' then
--    if authScheme == basicAuthScheme and session.data.authHeader then
  --      ngx.req.set_header("Authorization", session.data.authHeader)
  --  end
--end
end

defaultPlugin.setCookieAttributes = function(headerAttributes,id_token,authScheme)
local concatCookieValues = ngx.req.get_headers()['Cookie']
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
	local cookieValue = defaultPlugin.getHeaderAttributeValue(value, id_token)
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Cookie then
            concatCookieValues = concatCookieValues .. "" .. cookieValue
        end
    end
    ngx.req.set_header("Cookie", concatCookieValues)
end
end

defaultPlugin.setQueryParamAttributes = function(headerAttributes,id_token,authScheme)
local concatParamTable = {}
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Param then
            concatParamTable[value.HeaderName] = defaultPlugin.getHeaderAttributeValue(value,id_token)
        end
    end
    ngx.req.set_uri_args(concatParamTable)
end
end


--this method is related to fetch cookie

defaultPlugin.setCustomCookieAttributes = function()
    local httpc = require("resty.http").new()
    local res,err = httpc:request_uri("http://10.164.44.72:8080/Logon/login.jsp", { method = "GET", ssl_verify=false})
    if not res then
        ngx.log(ngx.ERR, "error:", err)
        return
    end
    local status = res.status
    local cookies = res.headers["Set-Cookie"]
    local body = res.body

    local function get_cookie_table_list(cookies)
        local type          = type
        local byte          = string.byte
        local sub           = string.sub
        local format        = string.format
        local log           = ngx.log
        local ERR           = ngx.ERR
        local WARN          = ngx.WARN
        local ngx_header    = ngx.header

        local EQUAL         = byte("=")
        local SEMICOLON     = byte(";")
        local SPACE         = byte(" ")
        local HTAB          = byte("\t")
    
        local ok, new_tab = pcall(require, "table.new")
        if not ok then
            new_tab = function () return {} end
        end
    
        local ok, clear_tab = pcall(require, "table.clear")
        if not ok then
            clear_tab = function(tab) for k, _ in pairs(tab) do tab[k] = nil end end
        end
    
        local _M = new_tab(0, 2)
        
        _M._VERSION = '0.01'
    
        if type(cookies) ~= "string" then
            log(ERR, format("expect text_cookie to be \"string\" but found %s",
                type(cookies)))
                return {}
        end
        local EXPECT_KEY    = 1 
        local EXPECT_VALUE  = 2
        local EXPECT_SP     = 3

        local n = 0
        local len = #cookies

        for i=1, len do
            if byte(cookies, i) == SEMICOLON then
                n = n + 1
            end
        end

        local cookie_table_list  = new_tab(0, n + 1)

        local state = EXPECT_SP
        local i = 1
        local j = 1
        local count = 0
        local key, value, cookie
        while j <= len do
            if state == EXPECT_KEY then
                if byte(cookies, j) == EQUAL then
                    cookie = new_tab(0,2)
                    count = count + 1
                    key = sub(cookies, i, j - 1)
                    cookie["name"] = key
                    state = EXPECT_VALUE
                    i = j + 1
                end
            elseif state == EXPECT_VALUE then
                if byte(cookies, j) == SEMICOLON
                        or byte(cookies, j) == SPACE
                        or byte(cookies, j) == HTAB
                then
                    value = sub(cookies, i, j - 1)
                    cookie["value"] = value
                    cookie_table_list[count] = cookie

                    key, value, cookie = nil, nil, nil
                    state = EXPECT_SP
                    i = j + 1
                end
            elseif state == EXPECT_SP then
                if byte(cookies, j) ~= SPACE
                    and byte(cookies, j) ~= HTAB
                then
                    state = EXPECT_KEY
                    i = j
                    j = j - 1
                end
            end
            j = j + 1
        end
        if key ~= nil and value == nil then
            cookie["value"] = sub(cookies, i)
            cookie_table_list[count] = cookie
        end
        return cookie_table_list
    end
    local function dump(o)
        if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"'
        end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
        else
        return tostring(o)
        end
    end
    --ngx.say("csrfToken:"..csrfToken)
    --ngx.say(dump(cookies))
    local temp1 = get_cookie_table_list(cookies[1])
    local c_name1 = (temp1[1]["name"])
    local c_val1 = (temp1[1]["value"])
    c1 = (c_name1.."="..c_val1)
    local temp2 = get_cookie_table_list(cookies[2])
    local c_name2 = (temp2[1]["name"])
    local c_val2 = (temp2[1]["value"])
    c2 = (c_name2.."="..c_val2)
    local temp3 = get_cookie_table_list(cookies[3])
    local c_name3 = (temp3[1]["name"])
    local c_val3 = (temp3[1]["value"])
    c3 = (c_name3.."="..c_val3)
    local temp4 = get_cookie_table_list(cookies[4])
    local c_name4 = (temp4[1]["name"])
    local c_val4 = (temp4[1]["value"])
    c4 = (c_name4.."="..c_val4)
    local gumbo = require "gumbo"
    local document = gumbo.parse(body)
    local hidden = document:getElementsByTagName('input')
    for i, element in ipairs(hidden) do
        if element:getAttribute("name") == "csrfToken" then
            csrfToken = element:getAttribute("value")
            c5 = ("csrfToken="..csrfToken)
	    ngx.log(DEBUG, "token value:", c5)
        end
    end
--return c1, c2, c3, c4, c5
return c5
end

--TODO :complete this
defaultPlugin.setFormAttributes = function(headerAttributes,id_token,authScheme,authSession)
    ngx.req.read_body()
    local oldbody = ngx.req.get_body_data()
    ngx.log(ERROR, "oldbody:", oldbody)
    local params = ngx.req.get_post_args()
    local newFormFields = ""
    local custom = defaultPlugin.setCustomCookieAttributes()
    if headerAttributes ~= nil and next(headerAttributes) ~= nil then
        ngx.log(ERROR, "token value:", custom)
        for key, value in next, headerAttributes do
	local formvalue = defaultPlugin.getHeaderAttributeValue(value, id_token)
	     if string.lower(value.HeaderType) == HeaderAttributeTypes.Form then
              --if custom value is '$passowrd then replace the value of formvalue with session password
		if formvalue == '$password' then
		formvalue = authSession.password
        end
		newFormFields = newFormFields .. "&" .. value.HeaderName .. "=" .. formvalue              
                ngx.log(ERROR, "newfields:", newFormFields)
	    end
        end
    end
    local newbody = oldbody .. "&" .. custom .. newFormFields
    ngx.log(ERROR, "newbody:", newbody)
    ngx.req.set_body_data(newbody)
end

defaultPlugin.getHeaderAttributeValue = function(headerAttribute, idToken)
    local name = headerAttribute.HeaderName
    local value = ""
    local returnValue = ""
    if string.lower(headerAttribute.HeaderValue) == "custom value" then
        value = headerAttribute.CustomHeaderValue
    else
        local headerAttributeValue = defaultPlugin.fetchClaimValueBasedOnHeaderAttribute(idToken, headerAttribute.HeaderValue)
        if headerAttributeValue ~= "" then
            value = headerAttributeValue
        end
    end
    if value ~= "" then
        if string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Header then
            returnValue = value
        elseif  string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Cookie then
            returnValue = value -- name .." = " .. value .. ";"
        elseif  string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Params then
            returnValue = value
        elseif string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Form then
            returnValue = value
        end
    else
        ngx.log(ngx.ERR, "Header Attribute Value is empty for the following Header: " .. name)
    end
    return returnValue
end


defaultPlugin.fetchClaimValueBasedOnHeaderAttribute = function(id_token, headerAttribute)
    local headerAttributeValue = ""
   ngx.log(ngx.DEBUG, "header attribute :: " .. headerAttribute)

    if headerAttribute ~= nil and headerAttribute ~= "" then
        if string.lower(headerAttribute) == string.lower("SAS User ID") then
            headerAttributeValue = id_token.preferred_username and id_token.preferred_username or ""
        elseif string.lower(headerAttribute) == string.lower("Email Address") then
            headerAttributeValue = id_token.EmailAddress and id_token.EmailAddress or ""
        elseif string.lower(headerAttribute) == string.lower("Name") then
            headerAttributeValue = id_token.name and id_token.name or ""
        elseif string.lower(headerAttribute) == string.lower("First Name") then
            headerAttributeValue = id_token.given_name and id_token.given_name or ""
        elseif string.lower(headerAttribute) == string.lower("Last Name") then
            headerAttributeValue = id_token.family_name and id_token.family_name or ""
        elseif string.lower(headerAttribute) == string.lower("Groups") then
            headerAttributeValue = id_token.Groups and id_token.Groups or ""
        elseif string.lower(headerAttribute) == string.lower("User Object GUID") then
            headerAttributeValue = id_token.UserObjectGUID and id_token.UserObjectGUID or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #1") then
            headerAttributeValue = id_token.Alias1 and id_token.Alias1 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #2") then
            headerAttributeValue = id_token.Alias1 and id_token.Alias2 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #3") then
            headerAttributeValue = id_token.Alias1 and id_token.Alias3 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #4") then
            headerAttributeValue = id_token.Alias1 and id_token.Alias4 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #1") then
            headerAttributeValue = id_token.Custom1 and id_token.Custom1 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #2") then
            headerAttributeValue = id_token.Custom1 and id_token.Custom2 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #3") then
            headerAttributeValue = id_token.Custom1 and id_token.Custom3 or ""
        end
    end

    return headerAttributeValue
end

defaultPlugin.dump = function(o)
        if type(o) == 'table' then
           local s = '{ '
           for k,v in pairs(o) do
              if type(k) ~= 'number' then k = '"'..k..'"'
          end
              s = s .. '['..k..'] = ' .. defaultPlugin.dump(v) .. ','
           end
           return s .. '} '
        else
           return tostring(o)
        end
end



defaultPlugin.setHeaderAttribute = function(name, value, authScheme)
        ngx.req.set_header(name, value)
end

defaultPlugin.setCookieValue = function(name, value)
    local cookieValue = name .." = " .. value .. ";"
    return cookieValue
end

defaultPlugin.setQueryParam = function(concatParamTable)
	ngx.req.set_uri_args(concatParamTable)
end 

defaultPlugin.setCookies = function(concatCookieValues)
	ngx.req.set_header("Cookie", "" .. concatCookieValues)
end

defaultPlugin.setHeader = function(id_token)
	ngx.req.set_header("X-USER", id_token.sub)
end

return defaultPlugin
